local notifications = require("rsync.notifications")

local M = {}

M.get_separator = function ()
    return vim.loop.os_uname().sysname == "Windows" and "\\" or "/"
end

M.get_config = function ()
    local sep = M.get_separator()
    local filename = table.concat({
        vim.loop.cwd(), ".rsync.lua"
    }, sep)
    local ok, config = pcall(dofile, filename)
    if not ok then
        notifications.error("missing or invalid config")
        return
    end
    if not config.host then
        notifications.error("missing 'host' in config")
        return
    end
    if not config.user then
        notifications.error("missing 'user' in config")
        return
    end
    if not config.path then
        notifications.error("missing 'path' in config")
        return
    end
    return config
end

M.config_to_remote = function (config)
    return string.format("%s@%s:%s", config.user, config.host, config.path)
end

return M
