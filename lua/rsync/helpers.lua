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
        return
    end
    return config
end

M.config_to_remote = function (config)
    return string.format("%s@%s:%s", config.user, config.host, config.path)
end

return M
