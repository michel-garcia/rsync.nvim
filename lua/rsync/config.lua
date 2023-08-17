local M = {}
M.__index = M

M.sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

M.get = function ()
    local filename = table.concat({ vim.loop.cwd(), ".rsync.lua" }, M.sep)
    local ok, config = pcall(dofile, filename)
    if ok then
        return setmetatable(config, M)
    end
end

M.get_remote_path = function (self)
    return string.format("%s@%s:%s", self.user, self.host, self.path)
end

return M
