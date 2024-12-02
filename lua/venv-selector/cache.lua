local config = require("venv-selector.config")
local log = require("venv-selector.logger")

local M = {}

function M.setup()
    if not config.cache.enabled then
        log.debug("Cache disabled")
        return
    end

    M.cache_file = vim.fn.stdpath("cache") .. "/venv_selector.json"
    log.debug("Cache file is " .. M.cache_file)
end

function M.save(python_path, venv_type)
    if not M.cache_file then
        return
    end

    local venv_cache = {
        [vim.fn.getcwd()] = {
            value = python_path,
            type = venv_type,
        },
    }

    -- if cache file exists and is not empty, read it and merge it with the new cache
    if vim.fn.filereadable(M.cache_file) == 1 then
        local cached_file = vim.fn.readfile(M.cache_file)
        if cached_file ~= nil and cached_file[1] ~= nil then
            local cached_json = vim.fn.json_decode(cached_file[1])
            venv_cache = vim.tbl_deep_extend("force", cached_json, venv_cache)
        end
    end

    local venv_cache_json = vim.fn.json_encode(venv_cache)
    vim.fn.writefile({ venv_cache_json }, M.cache_file)
    log.debug("Wrote cache content: ", venv_cache_json)
end

function M.retrieve()
    if not M.cache_file then
        return
    end

    if vim.fn.filereadable(M.cache_file) == 1 then
        local cache_file_content = vim.fn.readfile(M.cache_file)
        log.debug("Read cache content: ", cache_file_content)

        if cache_file_content ~= nil and cache_file_content[1] ~= nil then
            local venv_cache = vim.fn.json_decode(cache_file_content[1])
            local cached_venv = venv_cache and venv_cache[vim.fn.getcwd()]
            if cached_venv ~= nil then
                local venv = require("venv-selector.venv")

                log.debug("Activating venv `" .. cached_venv.value .. "` from cache.")
                venv.activate(cached_venv.value, cached_venv.type, false)
                return
            end
        end
    end
end

return M
