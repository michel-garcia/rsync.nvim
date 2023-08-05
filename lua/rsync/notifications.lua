local M = {}

M.notify = function (message, level)
    vim.notify(string.format("Rsync: %s", message), level)
end

M.success = function (message)
    M.notify(message)
end

M.warn = function (message)
    M.notify(message, "warn")
end

M.error = function (message)
    M.notify(message, "error")
end

return M
