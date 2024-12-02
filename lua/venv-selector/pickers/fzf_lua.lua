local config = require("venv-selector.config")
local utils = require("venv-selector.utils")
local venv = require("venv-selector.venv")

local M = {}

function M.format_result(result)
    -- TODO: color
    return string.format(
        "%s\t%s\t%s\t%s",
        result.icon,
        result.name,
        config.user_settings.options.show_search_type and utils.draw_icons_for_types(result) or "",
        config.user_settings.options.show_search_type and result.source or ""
    )
end

function M.update_results(results)
    M.open(results)
end

function M.open(results)
    local entries = {}

    local function process_results(fzf_cb)
        for _, result in ipairs(results or {}) do
            local text = M.format_result(result)
            entries[text] = result
            fzf_cb(text)
        end
        fzf_cb(nil) -- EOF
    end

    local fzf_lua = require("fzf-lua")
    fzf_lua.fzf_exec(process_results, {
        prompt = "Virtual environments > ",
        fzf_opts = {
            ["--header"] = "Results (ctrl-r to refresh)",
            ["--tabstop"] = "4",
        },
        winopts = {
            height = 0.4,
            width = 120,
            row = 0.5,
        },
        actions = {
            ["default"] = function(selected)
                if selected and #selected > 0 then
                    local selected_entry = entries[selected[1]]
                    if selected_entry then
                        venv.set_source(selected_entry.source)
                        venv.activate(selected_entry.path, selected_entry.type, true)
                    end
                end
            end,
            ["ctrl-r"] = function()
                require("venv-selector.search").run_search()
            end,
        },
    })
end

return M
