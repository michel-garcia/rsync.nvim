local M = {}
M.config = {}

local loaded = false

M.setup = function (config)
    if loaded then
        return
    end
    loaded = true
    M.config = vim.tbl_deep_extend("force", {
        sync_up_on_write = false
    }, config or {})
    M.setup_commands()
    M.setup_autocmds()
end

M.setup_commands = function ()
    vim.api.nvim_create_user_command("SyncDown", function (opts)
        if vim.fn.empty(opts.args) == 1 then
            M.sync_down(false)
            return
        elseif opts.args == "current" then
            M.sync_current_down()
            return
        elseif opts.args == "delete" then
            M.sync_down(true)
            return
        end
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncUp", function (opts)
        if vim.fn.empty(opts.args) == 1 then
            M.sync_up(false)
            return
        elseif opts.args == "current" then
            M.sync_current_up()
            return
        elseif opts.args == "delete" then
            M.sync_up(true)
            return
        end
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncStop", function ()
        M.sync_stop()
    end, {})
end

M.setup_autocmds = function ()
    local group = vim.api.nvim_create_augroup("RsyncAutocmds", {
        clear = true
    })
    vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function ()
            if M.config.sync_up_on_write then
                M.sync_current_up()
            end
        end,
        group = group
    })
end

M.sync_down = function (delete)
    local config = M.get_config()
    if not config then
        return
    end
    local src = M.get_remote_path(config)
    local dest = M.get_root()
    M.sync(src, dest, config, delete)
end

M.sync_up = function (delete)
    local config = M.get_config()
    if not config then
        return
    end
    local src = M.get_root()
    local dest = M.get_remote_path(config)
    M.sync(src, dest, config, delete)
end

M.sync_current_down = function ()
    local config = M.get_config()
    if not config then
        return
    end
    local path = vim.api.nvim_buf_get_name(0)
    local filename = vim.fs.basename(path)
    if filename == ".rsync.lua" or vim.tbl_contains(config.exclude or {}, filename) then
        return
    end
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= "file" then
        return
    end
    local remote_path = M.get_remote_path(config)
    local abs_path = vim.fn.fnamemodify(path, ":p")
    local root = M.get_root()
    if not root then
        return
    end
    local fragment = string.gsub(abs_path, root, "")
    local src = vim.fs.joinpath(remote_path, fragment)
    local dest = vim.fs.normalize(path)
    M.sync(src, dest, config)
end

M.sync_current_up = function ()
    local config = M.get_config()
    if not config then
        return
    end
    local path = vim.api.nvim_buf_get_name(0)
    local filename = vim.fs.basename(path)
    if filename == ".rsync.lua" or vim.tbl_contains(config.exclude or {}, filename) then
        return
    end
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= "file" then
        return
    end
    local root = M.get_root()
    if not root then
        return
    end
    local src = vim.fs.normalize(path)
    local abs_path = vim.fn.fnamemodify(path, ":p")
    local fragment = string.gsub(abs_path, root, "")
    local remote_path = M.get_remote_path(config)
    local dest = vim.fs.joinpath(remote_path, fragment)
    M.sync(src, dest, config)
end

M.sync = function (src, dest, config, delete)
    local Job = require("rsync.job")
    local job = Job(src, dest, {
        delete = delete,
        disable_mkpath = config.disable_mkpath,
        exclude = config.exclude,
        include = config.include,
        pass = config.pass,
        port = config.port
    })
    job:start()
end

M.sync_stop = function ()
    local JobManager = require("rsync.job_manager")
    JobManager.stop_all()
end

M.get_root = function ()
    local path = vim.fs.root(0, {
        ".rsync.lua"
    })
    if not path then
        return
    end
    return string.format("%s/", path)
end

M.get_config = function ()
    local root = M.get_root()
    if not root then
        return
    end
    local path = vim.fs.joinpath(root, ".rsync.lua")
    local ok, config = pcall(dofile, path)
    if not ok then
        vim.notify("Invalid rsync config", vim.log.levels.ERROR)
        return
    end
    config.path = vim.fs.normalize(config.path)
    vim.validate({
        host = { config.host, "string" },
        user = { config.user, "string" },
        pass = { config.pass or nil, "string" },
        port = { config.port or 0, "number" },
        path = { config.path, "string" },
        exclude = { config.exclude or {}, "table" },
        include = { config.include or {}, "table" },
        disable_mkpath = { config.disable_mkpath or false, "boolean" }
    })
    return config
end

M.get_remote_path = function (config)
    return string.format("%s@%s:%s/", config.user, config.host, config.path)
end

return M
