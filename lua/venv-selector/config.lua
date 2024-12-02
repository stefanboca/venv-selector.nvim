local hooks = require("venv-selector.hooks")

local uv = vim.uv or vim.loop

local M = {}

local default_patterns = {
    ["Linux"] = {
        virtualenvs = {
            command = "$FD 'python$' ~/.virtualenvs --color never",
        },
        hatch = {
            command = "$FD 'python$' ~/.local/share/hatch --color never -E '*-build*'",
        },
        poetry = {
            command = "$FD '/bin/python$' ~/.cache/pypoetry/virtualenvs --full-path",
        },
        pyenv = {
            command = "$FD '/bin/python$' ~/.pyenv/versions --full-path --color never -E pkgs/ -E envs/ -L",
        },
        pipenv = {
            command = "$FD '/bin/python$' ~/.local/share/virtualenvs --full-path --color never",
        },
        anaconda_envs = {
            command = "$FD 'bin/python$' ~/.conda/envs --full-path --color never",
            type = "anaconda",
        },
        anaconda_base = {
            command = "$FD '/python$' /opt/anaconda/bin --full-path --color never",
            type = "anaconda",
        },
        miniconda_envs = {
            command = "$FD 'bin/python$' ~/miniconda3/envs --full-path --color never",
            type = "anaconda",
        },
        miniconda_base = {
            command = "$FD '/python$' ~/miniconda3/bin --full-path --color never",
            type = "anaconda",
        },
        pipx = {
            command = "$FD '/bin/python$' ~/.local/share/pipx/venvs ~/.local/pipx/venvs --full-path --color never",
        },
        cwd = {
            command = "$FD '/bin/python$' $CWD --full-path --color never -HI -a -L -E /proc -E .git/ -E .wine/ -E .steam/ -E Steam/ -E site-packages/",
        },
        workspace = {
            command = "$FD '/bin/python$' $WORKSPACE_PATH --full-path --color never -E /proc -HI -a -L",
        },
        file = {
            command = "$FD '/bin/python$' $FILE_DIR --full-path --color never -E /proc -HI -a -L",
        },
    },
    ["Darwin"] = {
        virtualenvs = {
            command = "$FD 'python$' ~/.virtualenvs --color never",
        },
        hatch = {
            command = "$FD 'python$' ~/Library/Application\\\\ Support/hatch/env/virtual --color never -E '*-build*'",
        },
        poetry = {
            command = "$FD '/bin/python$' ~/Library/Caches/pypoetry/virtualenvs --full-path",
        },
        pyenv = {
            command = "$FD '/bin/python$' ~/.pyenv/versions --full-path --color never -E pkgs/ -E envs/ -L",
        },
        pipenv = {
            command = "$FD '/bin/python$' ~/.local/share/virtualenvs --full-path --color never",
        },
        anaconda_envs = {
            command = "$FD 'bin/python$' ~/.conda/envs --full-path --color never",
            type = "anaconda",
        },
        anaconda_base = {
            command = "$FD '/python$' /opt/anaconda/bin --full-path --color never",
            type = "anaconda",
        },
        miniconda_envs = {
            command = "$FD 'bin/python$' ~/miniconda3/envs --full-path --color never",
            type = "anaconda",
        },
        miniconda_base = {
            command = "$FD '/python$' ~/miniconda3/bin --full-path --color never",
            type = "anaconda",
        },
        pipx = {
            command = "$FD '/bin/python$' ~/.local/share/pipx/venvs ~/.local/pipx/venvs --full-path --color never",
        },
        cwd = {
            command = "$FD '/bin/python$' $CWD --full-path --color never -HI -a -L -E /proc -E .git/ -E .wine/ -E .steam/ -E Steam/ -E site-packages/",
        },
        workspace = {
            command = "$FD '/bin/python$' $WORKSPACE_PATH --full-path --color never -E /proc -HI -a -L",
        },
        file = {
            command = "$FD '/bin/python$' $FILE_DIR --full-path --color never -E /proc -HI -a -L",
        },
    },
    -- NOTE: For windows searches, we convert the string below to a lua table before running it, so the execution doesnt use a shell that needs
    -- a lot of escaping of the strings to get right.
    ["Windows_NT"] = {
        hatch = {
            command = "$FD python.exe $HOME/AppData/Local/hatch/env/virtual --full-path --color never",
        },
        poetry = {
            command = "$FD python.exe$ $HOME/AppData/Local/pypoetry/Cache/virtualenvs --full-path --color never",
        },
        pyenv = {
            command = "$FD python.exe$ $HOME/.pyenv/pyenv-win/versions $HOME/.pyenv-win-venv/envs -E Lib",
        },
        pipenv = {
            command = "$FD python.exe$ $HOME/.virtualenvs --full-path --color never",
        },
        anaconda_envs = {
            command = "$FD python.exe$ $HOME/anaconda3/envs --full-path -a -E Lib",
            type = "anaconda",
        },
        anaconda_base = {
            command = "$FD anaconda3//python.exe $HOME/anaconda3 --full-path -a --color never",
            type = "anaconda",
        },
        miniconda_envs = {
            command = "$FD python.exe$ $HOME/miniconda3/envs --full-path -a -E Lib",
            type = "anaconda",
        },
        miniconda_base = {
            command = "$FD miniconda3//python.exe $HOME/miniconda3 --full-path -a --color never",
            type = "anaconda",
        },
        pipx = {
            command = "$FD Scripts//python.exe$ $HOME/pipx/venvs --full-path -a --color never",
        },
        cwd = {
            command = "$FD Scripts//python.exe$ $CWD --full-path --color never -HI -a -L",
        },
        workspace = {
            command = "$FD Scripts//python.exe$ $WORKSPACE_PATH --full-path --color never -HI -a -L",
        },
        file = {
            command = "$FD Scripts//python.exe$ $FILE_DIR --full-path --color never -HI -a -L",
        },
    },
}

local config = {
    sysname = nil,
    cache = {
        enabled = true,
        file = "~/.cache/venv-selector/venvs2.json",
    },
    search = {
        fd_binary = nil,
        enable_default_patterns = true,
        timeout_ms = 5000,
        patterns = {},
    },
    select = {
        picker = "auto",
        show_search_type = true,
        on_result_callback = nil,
        active_venv_color = "#00FF00",
        telescope = {
            filter_type = "substring",
        },
    },
    activate = {
        notify = false,
        require_lsp_activation = true,
        set_env_vars = true,
        activate_in_terminal = true,
        hooks = { hooks.basedpyright_hook, hooks.pyright_hook, hooks.pylance_hook, hooks.pylsp_hook },
        on_activate_callback = nil,
    },
    debug = false,
}

function M.setup_picker()
    local log = require("venv-selector.logger")

    local telescope_installed, _ = pcall(require, "telescope")

    if config.select.picker == "auto" then
        if telescope_installed then
            config.select.picker = "telescope"
            return
        else
            log.notify_error("Could not automatically select picker. Manually set opts.select.picker")
        end
    elseif config.select.picker == "telescope" and not telescope_installed then
        log.notify_error(
            "Picker was set to '"
                .. config.select.picker
                .. "', but '"
                .. config.select.picker
                .. "' is not a installed."
        )
    else
        log.notify_error(
            "Picker was set to '"
                .. config.select.picker
                .. "', but '"
                .. config.select.picker
                .. "' is not a valid option."
        )
    end
end

function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

    local log = require("venv-selector.logger")
    -- set up logging ASAP
    log.setup()

    if not config.sysname then
        config.sysname = uv.os_uname().sysname
    end

    if not config.search.fd_binary then
        for _, cmd in ipairs({ "fd", "fdfind", "fd_find" }) do
            if vim.fn.executable(cmd) == 1 then
                config.search.fd_binary = cmd
                break
            end
        end
    end
    if not config.search.fd_binary then
        log.notify_error(
            "Cannot find fd on your system. If its installed under a different name, set opts.search.fd_binary."
        )
    end

    if config.search.enable_default_patterns then
        config.search.patterns = vim.tbl_extend(
            "force",
            default_patterns[config.sysname] or default_patterns["Linux"],
            config.search.patterns
        )
    end

    M.setup_picker()
end

return setmetatable(M, {
    __index = function(_, k)
        return config[k]
    end,
})
