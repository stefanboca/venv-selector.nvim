local utils = require("venv-selector.utils")
local log = require("venv-selector.logger")

local get_clients = vim.lsp.get_clients or vim.lsp.get_active_clients

local M = {}

function M.list_folders()
    local workspace_folders = {}

    for _, client in ipairs(get_clients()) do
        if
            vim.tbl_contains({
                "basedpyright",
                "pyright",
                "pylance",
                "pylsp",
            }, client.name)
        then
            for _, folder in ipairs(client.workspace_folders or {}) do
                workspace_folders[#workspace_folders + 1] = folder.name
            end
        end
    end

    if not vim.tbl_isempty(workspace_folders) then
        log.debug("Workspace folders: ", workspace_folders)
    else
        log.debug("No workspace folders.")
    end

    return workspace_folders
end

return M
