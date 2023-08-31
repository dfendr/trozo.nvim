--- Creta Module
--
-- This module provides functionality to capture a selection in Neovim,
-- upload it to a paste.rs service, and open the resulting URL in a web browser.

local M = {}
local log = require("creta.log")
-- defalt options
local opts = {
    browser = true,
    clipboard = false,
}

--- Handles the stdout of the paste.rs upload job.
--
-- @param filetype string: The filetype or extension of the file being uploaded.
-- @param fd number: file descriptor of the stdout channel.
-- @param data table: The stdout data from the job.
local function on_stdout(filetype, fd, data)
    if data then
        local headers = table.concat(data, "")
        local status = headers:match("HTTP/%d+%.%d+ (%d+)")
        local url = headers:match("https://paste%.rs/%S+")

        if status == "201" then
            log.info("Successfully uploaded the entire paste to paste.rs.")
            local paste_url = url .. filetype

            -- Copy to clipboard if enabled
            if opts.clipboard then
                vim.fn.setreg("+", paste_url)
            end

            if opts.browser then
                local open_cmd = ""
                if vim.fn.has("win32") == 1 then
                    open_cmd = "start"
                elseif vim.fn.has("mac") == 1 then
                    open_cmd = "open"
                else
                    open_cmd = "xdg-open"
                end

                -- Open the URL in the default web browser
                vim.fn.jobstart({ open_cmd, paste_url })
            end
        elseif status == "206" then
            log.warn("Partial upload, paste too large.")
        else
            log.error("Failed to upload to paste.rs. HTTP status: " .. (status or "unknown"))
        end
    end
end
--- Handles the exit event of the paste.rs upload job.
--
-- @param code number: The exit code of the job.
local function on_exit(_, code)
    if code == 0 then
        vim.notify("Upload Successful", vim.log.levels.INFO)
    else
        log.warn("Error. cURL exit code: " .. code)
    end
end

--- Deletes a paste from paste.rs given its ID.
--
-- @param id string: The ID of the paste to delete.
function M.delete_paste(id)
    local opts = {
        on_exit = vim.schedule_wrap(function(_, code)
            if code == 0 then
                log.info("Successfully deleted paste with ID: " .. id)
            else
                log.error("Failed to delete paste with ID: " .. id .. ". Exit code: " .. code)
            end
        end),
    }

    local job_id = vim.fn.jobstart({ "curl", "-X", "DELETE", "https://paste.rs/" .. id }, opts)

    if job_id <= 0 then
        log.error("Failed to start job for paste deletion.")
    end
end

--- Uploads the selected text to paste.rs
--
-- @param lines table: The lines of text to upload.
-- @param filetype string: The filetype or extension of the file being uploaded.
local function upload_selection(lines, filetype)
    local job_opts = {
        on_stdout = vim.schedule_wrap(function(fd, data)
            on_stdout(filetype, fd, data)
        end),
        on_exit = vim.schedule_wrap(on_exit),
        stdout_buffered = true,
        stderr_buffered = true,
    }

    local job_id = vim.fn.jobstart({ "curl", "-i", "--data-binary", "@-", "https://paste.rs/" }, job_opts)

    if job_id > 0 then
        local text_to_paste = table.concat(lines, "\n") .. "\n"
        vim.fn.chansend(job_id, text_to_paste)
        vim.fn.chanclose(job_id, "stdin")
    else
        log.error("Failed to start job for paste.rs upload.")
    end
end
--- Sets up the Creta module.
--
-- @param opts table: Configuration options.
function M.setup(user_opts)
    opts = vim.tbl_extend("force", opts, user_opts or {})
    vim.api.nvim_create_user_command("Creta", 'lua require("creta").capture_selection()', { range = true })
    vim.api.nvim_create_user_command("CretaDelete", 'lua require("creta").delete_paste("<args>")', {})
end

--- Captures the current visual selection and uploads it to paste.rs.
--
-- @return table: A table containing the lines and filetype of the selection.
function M.capture_selection()
    local buf = vim.api.nvim_get_current_buf()

    -- Get the line numbers for the start '< and end '> of the visual selection
    local start_line = vim.fn.line("'<") - 1 -- 0-based indexing
    local end_line = vim.fn.line("'>")

    -- Get the lines in the visual selection
    local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)

    -- Get the current file name and extract its extension
    local filename = vim.fn.expand("%:t")
    local filetype = filename:match("^.+(%..+)$")

    if filetype == nil then
        filetype = vim.bo.filetype -- fallback to Vim's filetype if no extension found
    end

    -- Upload the selected lines to paste.rs
    upload_selection(lines, filetype)

    return { lines, filetype }
end

return M
