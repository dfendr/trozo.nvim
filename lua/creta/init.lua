--- Creta Module
--
-- This module provides functionality to capture a selection in Neovim,
-- upload it to a paste.rs service, and open the resulting URL in a web browser.

local M = {}

-- defalt options
local opts = {
    browser = true,
    clipboard = false,
}

--- Handles the stdout of the paste.rs upload job.
--
-- @param filetype string: The filetype or extension of the file being uploaded.
-- @param err string: Error message, if any.
-- @param data table: The stdout data from the job.
local function on_stdout(filetype, err, data)
    if err then
        vim.notify("Error:", err)
    end

    if data then
        local paste_url = table.concat(data, "\n") .. filetype

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
    end
end
--- Handles the exit event of the paste.rs upload job.
--
-- @param code number: The exit code of the job.
local function on_exit(_, code)
    if code == 0 then
        vim.notify("Successfully uploaded to paste.rs.", vim.log.levels.INFO)
    else
        vim.notify("Failed to upload to paste.rs. Exit code: " .. code, vim.log.levels.ERROR)
    end
end

--- Uploads the selected text to paste.rs
--
-- @param lines table: The lines of text to upload.
-- @param filetype string: The filetype or extension of the file being uploaded.
local function upload_selection(lines, filetype)
    local opts = {
        on_stdout = vim.schedule_wrap(function(err, data)
            on_stdout(filetype, err, data)
        end),
        on_exit = vim.schedule_wrap(on_exit),
        stdout_buffered = true,
    }

    local job_id = vim.fn.jobstart({ "curl", "--data-binary", "@-", "https://paste.rs/" }, opts)

    if job_id > 0 then
        local text_to_paste = table.concat(lines, "\n") .. "\n"
        vim.fn.chansend(job_id, text_to_paste)
        vim.fn.chanclose(job_id, "stdin")
    else
        vim.notify("Failed to start job for paste.rs upload.", vim.log.levels.ERROR)
    end
end

--- Sets up the Creta module.
--
-- @param opts table: Configuration options.
function M.setup(user_opts)
    opts = vim.tbl_extend("force", opts, user_opts or {})
    vim.api.nvim_create_user_command("Creta", 'lua require("creta").capture_selection()', { range = true })
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
