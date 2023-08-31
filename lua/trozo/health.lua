local M = {}

local health_start = vim.fn["health#report_start"]
local health_ok = vim.fn["health#report_ok"]
local health_warn = vim.fn["health#report_warn"]
local health_error = vim.fn["health#report_error"]

local function binary_installed(name)
    if vim.api.nvim_call_function("has", { "win32" }) == 1 then
        name = name .. ".exe"
    end

    return vim.fn.executable(name) == 1
end

function M.check()
    health_start("Checking for external dependencies")
    if binary_installed("curl") then
        health_ok("curl installed")
    else
        health_error("curl not found")
    end

    if binary_installed("xdg-open") then
        health_ok("xdg-open installed")
    elseif binary_installed("open") then
        health_ok("open installed")
    else
        health_warn("xdg-open or open not found")
    end
end

return M
