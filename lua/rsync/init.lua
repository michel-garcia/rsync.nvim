local M = {}

local loaded = false

M.config = {
    max_concurrent_jobs = 1,
    on_update = nil
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
    vim.api.nvim_create_user_command("SyncStop", function (opts)
        if M.config.max_concurrent_jobs == 1 then
            return M.sync_stop_all()
        end
        M.sync_stop(opts.args)
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncStopAll", function ()
        M.sync_stop_all()
    end, {})
end

M.setup = function (config)
    if loaded then
        return
    end
    loaded = true
    M.config = vim.tbl_extend("force", M.config, config or {})
    setup_commands()
end

M.sync_down = function (delete)
    local helpers = require("rsync.helpers")
    local config = helpers.get_config()
    if not config then
        return
    end
    local src = helpers.config_to_remote(config)
    local dest = vim.loop.cwd() .. helpers.get_separator()
    config.delete = delete or false
    local sync = require("rsync.sync")
    sync.exec(src, dest, config)
end

M.sync_up = function (delete)
    local helpers = require("rsync.helpers")
    local config = helpers.get_config()
    if not config then
        return
    end
    local src = vim.loop.cwd() .. helpers.get_separator()
    local dest = helpers.config_to_remote(config)
    config.delete = delete or false
    local sync = require("rsync.sync")
    sync.exec(src, dest, config)
end

M.sync_stop = function (job_id)
    local sync = require("rsync.sync")
    sync.stop(job_id)
end

M.sync_stop_all = function ()
    local sync = require("rsync.sync")
    local jobs = sync.get_jobs()
    for _, job in ipairs(jobs) do
        sync.stop(job.id)
    end
end

return M
