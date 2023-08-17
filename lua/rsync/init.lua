local M = {}

local loaded = false

M.config = {
    max_concurrent_jobs = 1,
    on_update = nil,
    sync_up_on_write = false
}

local setup_commands = function ()
    vim.api.nvim_create_user_command("SyncDown", function (opts)
        local helpers = require("rsync.helpers")
        local config = helpers.get_config()
        config.delete = opts.args == "delete"
        M.sync_down(config)
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncUp", function (opts)
        local helpers = require("rsync.helpers")
        local config = helpers.get_config()
        config.delete = opts.args == "delete"
        M.sync_up(config)
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncStop", function ()
        M.sync_stop()
    end)
end

local setup_autocmds = function ()
    local group = vim.api.nvim_create_augroup("RsyncAutocmds", {
        clear = true
    })
    vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function ()
            if M.config.sync_up_on_write then
                local helpers = require("rsync.helpers")
                local config = helpers.get_config()
                if config and config.host and config.user and config.path then
                    M.sync_up(config)
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

M.sync_down = function (config)
    if not config or not config.host or not config.user or not config.path then
        local notifications = require("rsync.notifications")
        notifications.error("invalid config")
        return
    end
    local helpers = require("rsync.helpers")
    config.src = helpers.config_to_remote(config)
    config.dest = vim.loop.cwd() .. helpers.get_separator()
    local Job = require("rsync.job")
    Job(config):start()
end

M.sync_up = function (config)
    if not config or not config.host or not config.user or not config.path then
        local notifications = require("rsync.notifications")
        notifications.error("invalid config")
        return
    end
    local helpers = require("rsync.helpers")
    config.src = vim.loop.cwd() .. helpers.get_separator()
    config.dest = helpers.config_to_remote(config)
    local Job = require("rsync.job")
    Job(config):start()
end

M.sync_stop = function ()
    local Job = require("rsync.job")
    if Job.current then
        Job.current:stop()
    end
end

return M
