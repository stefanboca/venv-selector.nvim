local config = require("venv-selector.config")
local gui = require("venv-selector.gui")
local workspace = require("venv-selector.workspace")
local path = require("venv-selector.path")
local utils = require("venv-selector.utils")
local log = require("venv-selector.logger")

local uv = vim.uv or vim.loop

local function is_workspace_search(str)
    return string.find(str, "$WORKSPACE_PATH") ~= nil
end

local function is_cwd_search(str)
    return string.find(str, "$CWD") ~= nil
end

local function is_filepath_search(str)
    return string.find(str, "$FILE_DIR") ~= nil
end

local M = {}

local function interactive_search_patterns(opts)
    if opts ~= nil and #opts.args > 0 then
        local patterns = {
            interactive = {
                command = opts.args:gsub("%$CWD", vim.fn.getcwd()),
            },
        }
        log.debug("Interactive patterns replaces previous pattern settings: ", patterns)
        return patterns
    end

    return nil
end

local function run_search(opts)
    if M.search_in_progress == true then
        log.info("Not starting new search because previous search is still running.")
        return
    end

    local jobs = {}
    local job_count = 0
    local results = {}
    local search_patterns = interactive_search_patterns(opts) or config.search.patterns
    local cwd = vim.fn.getcwd()

    local function on_event(job_id, data, event)
        local callback = jobs[job_id].on_result_callback or config.search.on_result_callback

        if event == "stdout" and data then
            local search = jobs[job_id]

            if not results[job_id] then
                results[job_id] = {}
            end
            for _, line in ipairs(data) do
                if line ~= "" and line ~= nil then
                    local rv = {}
                    rv.path = line
                    rv.name = line
                    rv.icon = ""
                    rv.type = search.type or "venv"
                    rv.source = search.name

                    if callback then
                        log.debug(
                            "Calling on_result_callback() callback function with line '"
                                .. line
                                .. "' and source '"
                                .. rv.source
                                .. "'"
                        )
                        rv.name = callback(line, rv.source)
                    end

                    gui.insert_result(rv)
                end
            end
        elseif event == "stderr" and data then
            if data and #data > 0 then
                for _, line in ipairs(data) do
                    if line ~= "" then
                        log.debug(line)
                    end
                end
            end
        elseif event == "exit" then
            job_count = job_count - 1
            if job_count == 0 then
                log.info("Searching finished.")
                gui.remove_dups()
                gui.sort_results()
                gui.update_results()
                M.search_in_progress = false
            end
        end
    end

    local function start_search_job(job_name, search, count)
        local job = path.expand(search.execute_command)

        log.debug("Starting '" .. job_name .. "': '" .. job .. "'")
        M.search_in_progress = true

        -- Special for windows to run the command without a shell (translate the command to a lua table before sending to jobstart)
        if uv.os_uname().sysname == "Windows_NT" then
            job = utils.split_string(job)
        end

        local job_id = vim.fn.jobstart(job, {
            stdout_buffered = true,
            stderr_buffered = true,
            on_stdout = on_event,
            on_stderr = on_event,
            on_exit = on_event,
        })
        search.name = job_name
        jobs[job_id] = search
        count = count + 1

        local function stop_job()
            local running = vim.fn.jobwait({ job_id }, 0)[1] == -1
            if running then
                vim.fn.jobstop(job_id)
                log.notify_warning(
                    "Search with name '"
                        .. jobs[job_id].name
                        .. "' took more than "
                        .. config.search.timeout_ms
                        .. " milliseconds and was stopped. Avoid using VenvSelect in your $HOME directory since it searches all hidden files by default."
                )
            end
        end

        -- Start a timer to terminate the job after 5 seconds
        local timer = assert(uv.new_timer())
        timer:start(
            config.search.timeout_ms,
            0,
            vim.schedule_wrap(function()
                stop_job()
                timer:stop()
                timer:close()
            end)
        )

        return count
    end

    local current_dir = path.get_current_file_directory()

    -- Start search jobs from config
    for job_name, pattern in pairs(search_patterns) do
        if pattern ~= false then -- Can be set to false by user to not search path
            pattern.execute_command = pattern.command:gsub("$FD", config.search.fd_binary)

            -- search has $WORKSPACE_PATH inside - dont start it unless the lsp has discovered workspace folders
            if is_workspace_search(pattern.command) then
                local workspace_folders = workspace.list_folders()
                for _, workspace_path in pairs(workspace_folders) do
                    pattern.execute_command = pattern.execute_command:gsub("$WORKSPACE_PATH", workspace_path)
                    job_count = start_search_job(job_name, pattern, job_count)
                end
                -- search has $CWD inside
            elseif is_cwd_search(pattern.command) then
                pattern.execute_command = pattern.execute_command:gsub("$CWD", cwd)
                job_count = start_search_job(job_name, pattern, job_count)
                -- search has $FILE_DIR inside
            elseif is_filepath_search(pattern.command) then
                if current_dir ~= nil then
                    pattern.execute_command = pattern.execute_command:gsub("$FILE_DIR", current_dir)
                    job_count = start_search_job(job_name, pattern, job_count)
                end
            else
                -- search has no keywords inside
                job_count = start_search_job(job_name, pattern, job_count)
            end
        end
    end
end

function M.New(opts)
    if utils.table_has_content(gui.results) == false then
        run_search(opts)
    end
end

return M
