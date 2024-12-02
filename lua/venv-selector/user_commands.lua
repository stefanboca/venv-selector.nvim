local search = require("venv-selector.search")
local gui = require("venv-selector.gui")

local M = {}

function M.register()
    vim.api.nvim_create_user_command("VenvSelect", function(opts)
        gui.open(search.search_in_progress)
        search.New(opts)
    end, { nargs = "*", desc = "Activate venv" })
end

return M
