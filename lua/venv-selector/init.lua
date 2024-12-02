local user_commands = require("venv-selector.user_commands")
local config = require("venv-selector.config")
local venv = require("venv-selector.venv")
local path = require("venv-selector.path")
local ws = require("venv-selector.workspace")

local function on_lsp_attach()
    if vim.bo.filetype == "python" then
        require("venv-selector.cache").retrieve()
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    pattern = "*",
    callback = on_lsp_attach,
})

local M = {}

function M.python()
    return path.current_python_path
end

function M.venv()
    return path.current_venv_path
end

function M.source()
    return venv.current_source
end

function M.workspace_paths()
    return ws.list_folders()
end

function M.cwd()
    return vim.fn.getcwd()
end

function M.file_dir()
    return path.get_current_file_directory()
end

function M.stop_lsp_servers()
    venv.stop_lsp_servers()
end

function M.activate_from_path(python_path)
    venv.activate(python_path, "activate_from_path", true)
end

function M.deactivate()
    path.remove_current()
    venv.unset_env_variables()
end

function M.setup(opts)
    config.setup(opts or {})

    require("venv-selector.cache").setup()

    vim.api.nvim_command("hi VenvSelectActiveVenv guifg=" .. config.select.active_venv_color)

    user_commands.register()
end

return M
