local M = {}
M.__index = M

M.sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

M.get = function ()
    local filename = table.concat({ vim.loop.cwd(), ".rsync.lua" }, M.sep)
    local ok, config = pcall(dofile, filename)
    if not ok or not config then
        return false
    end
    return setmetatable(config, M)
end

M.get_remote_path = function (self)
    if not self.host then
        local notifications = require("rsync.notifications")
        notifications.error("missing host")
        return false
    end
    if not self.user then
        local notifications = require("rsync.notifications")
        notifications.error("missing user")
        return false
    end
    if not self.path then
        local notifications = require("rsync.notifications")
        notifications.error("missing path")
        return false
    end
    return string.format("%s@%s:%s", self.user, self.host, self.path)
end

return M
