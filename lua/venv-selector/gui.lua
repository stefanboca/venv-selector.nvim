local config = require("venv-selector.config")
local log = require("venv-selector.logger")
local path = require("venv-selector.path")

local M = {}

M.results = {}

function M.clear_results()
    M.results = {}
end

function M.insert_result(row)
    log.debug("Result:")
    log.debug(row)

    table.insert(M.results, row)
    M.update_results()
end

function M.remove_dups()
    -- If a venv is found both by another search AND (cwd or file) search, then keep the one found by another search.
    local seen = {}
    local filtered_results = {}

    for _, v in ipairs(M.results) do
        if not seen[v.name] then
            seen[v.name] = v
        else
            local prev_entry = seen[v.name]
            if
                (v.source == "file" or v.source == "cwd")
                and (prev_entry.source ~= "file" and prev_entry.source ~= "cwd")
            then
            -- Current item has less priority, do not add it
            elseif
                (prev_entry.source == "file" or prev_entry.source == "cwd")
                and (v.source ~= "file" and v.source ~= "cwd")
            then
                -- Previous item has less priority, replace it
                seen[v.name] = v
            end
        end
    end

    for _, entry in pairs(seen) do
        table.insert(filtered_results, entry)
    end

    M.results = filtered_results
end

function M.sort_results()
    local selected_python = path.current_python_path
    local current_file_dir = vim.fn.expand("%:p:h")

    log.debug("Calculating path similarity based on: '" .. current_file_dir .. "'")
    -- Normalize path by converting all separators to a common one (e.g., '/')
    local function normalize_path(path)
        return path:gsub("\\", "/")
    end

    -- Calculate the path similarity
    local function path_similarity(path1, path2)
        path1 = normalize_path(path1)
        path2 = normalize_path(path2)
        local segments1 = vim.split(path1, "/")
        local segments2 = vim.split(path2, "/")
        local count = 0
        for i = 1, math.min(#segments1, #segments2) do
            if segments1[i] == segments2[i] then
                count = count + 1
            else
                break
            end
        end
        return count
    end

    log.debug("Sorting results on path similarity.")
    table.sort(M.results, function(a, b)
        -- Check for 'selected_python' match
        local a_is_selected = a.path == selected_python
        local b_is_selected = b.path == selected_python
        if a_is_selected and not b_is_selected then
            return true
        elseif not a_is_selected and b_is_selected then
            return false
        end

        -- Compare based on path similarity
        local sim_a = path_similarity(a.path, current_file_dir)
        local sim_b = path_similarity(b.path, current_file_dir)
        if sim_a ~= sim_b then
            return sim_a > sim_b
        end

        -- Fallback to alphabetical sort
        return a.name > b.name
    end)
end

function M.update_results()
    M.picker.update_results(M.results)
end

function M.open(in_progress)
    if not in_progress then
        M.sort_results()
    end

    M.picker.open(M.results)
end

function M.setup()
    local picker = config.user_settings.options.picker
    if picker == "telescope" then
        M.picker = require("venv-selector.pickers.telescope")
    elseif picker == "fzf-lua" then
        M.picker = require("venv-selector.pickers.fzf_lua")
    else
        -- TODO: error
    end
end

return M
