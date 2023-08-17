local M = {}

local loaded = false

M.config = {
    max_concurrent_jobs = 1,
    on_update = nil,
    sync_up_on_write = false
}

local setup_commands = function ()
    vim.api.nvim_create_user_command("SyncDown", function (opts)
        local delete = opts.args == "delete"
        M.sync_down(delete)
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncUp", function (opts)
        local delete = opts.args == "delete"
        M.sync_up(delete)
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncCurDown", function ()
        M.sync_current_down()
    end, {})
    vim.api.nvim_create_user_command("SyncCurUp", function ()
        M.sync_current_up()
    end, {})
    vim.api.nvim_create_user_command("SyncStop", function ()
        M.sync_stop()
    end, {})
end

local setup_autocmds = function ()
    local group = vim.api.nvim_create_augroup("RsyncAutocmds", {
        clear = true
    })
    vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function ()
            if M.config.sync_up_on_write then
                local Config = require("rsync.config")
                local config = Config.get()
                if config then
                    M.sync_current_up()
                end
            end
        end,
        group = group
    })
end

M.setup = function (config)
    if loaded then
        return
    end
    loaded = true
    M.config = vim.tbl_extend("force", M.config, config or {})
    setup_commands()
    setup_autocmds()
end

M.sync_down = function (delete)
    local Config = require("rsync.config")
    local config = Config.get()
    if not config then
        local notifications = require("rsync.notifications")
        notifications.error("invalid config")
        return
    end
    config.src = config:get_remote_path() .. Config.sep
    config.dest = vim.loop.cwd() .. Config.sep
    config.delete = delete
    local Job = require("rsync.job")
    if Job.current then
        Job.current:stop()
    end
    Job(config):start()
end

M.sync_up = function (delete)
    local Config = require("rsync.config")
    local config = Config.get()
    if not config or not config.host or not config.user or not config.path then
        local notifications = require("rsync.notifications")
        notifications.error("invalid config")
        return
    end
    config.src = vim.loop.cwd() .. Config.sep
    config.dest = config:get_remote_path() .. Config.sep
    config.delete = delete
    local Job = require("rsync.job")
    if Job.current then
        Job.current:stop()
    end
    Job(config):start()
end

M.sync_current_down = function ()
    local Config = require("rsync.config")
    local config = Config.get()
    if not config then
        return
    end
    local path = vim.fn.expand("%:.")
    local stat = vim.loop.fs_stat(path)
    if not stat or stat.type ~= "file" then
        return
    end
    local remote_path = config:get_remote_path()
    if not remote_path then
        return
    end
    config.src = table.concat({ remote_path, path }, Config.sep)
    config.dest = table.concat({ vim.loop.cwd(), path }, Config.sep)
    local Job = require("rsync.job")
    if Job.current then
        Job.current:stop()
    end
    Job(config):start()
end

M.sync_current_up = function ()
    local Config = require("rsync.config")
    local config = Config.get()
    if not config then
        return
    end
    local path = vim.fn.expand("%:.")
    local stat = vim.loop.fs_stat(path)
    if not stat or stat.type ~= "file" then
        return
    end
    local remote_path = config:get_remote_path()
    if not remote_path then
        return
    end
    config.src = table.concat({ vim.loop.cwd(), path }, Config.sep)
    config.dest = table.concat({ remote_path, path }, Config.sep)
    local Job = require("rsync.job")
    if Job.current then
        Job.current:stop()
    end
    Job(config):start()
end

M.sync_stop = function ()
    local Job = require("rsync.job")
    if Job.current then
        Job.current:stop()
    end
end

return M
