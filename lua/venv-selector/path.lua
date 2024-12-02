local config = require("venv-selector.config")
local log = require("venv-selector.logger")

local M = {}
M.current_python_path = nil
M.current_venv_path = nil
local previous_dir = nil

function M.save_selected_python(python_path)
    M.current_python_path = python_path
    M.current_venv_path = vim.fs.dirname(vim.fs.dirname(python_path))
    log.debug('Setting require("venv-selector").python() to \'' .. M.current_python_path .. "'")
    log.debug('Setting require("venv-selector").venv() to \'' .. M.current_venv_path .. "'")
end

function M.add(newDir)
    if config.activate.activate_in_terminal then
        if newDir ~= nil then
            if previous_dir ~= nil then
                M.remove(previous_dir)
            end
            local path = vim.fn.getenv("PATH")
            local path_separator = package.config:sub(3, 3)
            local clean_dir = M.remove_trailing_slash(newDir)
            local updated_path = clean_dir .. path_separator .. path
            previous_dir = clean_dir
            vim.fn.setenv("PATH", updated_path)
            log.debug("Setting new terminal path to: " .. updated_path)
        end
    end
end

function M.update_python_dap(python_path)
    local dap_python_installed, dap_python = pcall(require, "dap-python")
    local dap_installed, dap = pcall(require, "dap")
    if dap_python_installed and dap_installed then
        log.debug("Setting dap python interpreter to '" .. python_path .. "'")
        dap_python.resolve_python = function()
            return python_path
        end
    else
        log.debug("Debugger not enabled: dap or dap-python not installed.")
    end
end

function M.remove_trailing_slash(path)
    -- Check if the last character is a slash
    if path:sub(-1) == "/" or path:sub(-1) == "\\" then
        -- Remove the last character
        return path:sub(1, -2)
    end
    return path
end

function M.remove_current()
    if M.current_python_path ~= nil then
        M.remove(vim.fs.dirname(M.current_python_path))
    end
end

function M.remove(removalDir)
    local clean_dir = M.remove_trailing_slash(removalDir)
    local path = vim.fn.getenv("PATH")
    log.debug("Path before venv removal: ", path)
    local pathSeparator = package.config:sub(3, 3)
    local paths = {}
    for p in string.gmatch(path, "[^" .. pathSeparator .. "]+") do
        if p ~= clean_dir then
            table.insert(paths, p)
        end
    end
    local updatedPath = table.concat(paths, pathSeparator)
    vim.fn.setenv("PATH", updatedPath)
    log.debug("Path after venv removal: ", updatedPath)
end

function M.get_current_file_directory()
    local opened_filepath = vim.fn.expand("%:p")
    if opened_filepath ~= nil then
        return vim.fs.dirname(opened_filepath)
    end
end

return M
