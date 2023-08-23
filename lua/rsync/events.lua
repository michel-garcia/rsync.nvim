local M = {}

local prev = nil

M.progress = function (job)
    local message = string.format("Syncing: %s%%", job.percentage)
    local opts = {
        timeout = false,
        title = "Rsync",
        replace = prev
    }
    prev = vim.notify(message, "info", opts)
end

M.complete = function (job)
    local opts = {
        timeout = 3500,
        title = "Rsync",
        replace = prev
    }
    local message = "Sync complete!"
    vim.notify(message, "success", opts)
end

M.error = function (job)
    local opts = {
        title = "Rsync",
        replace = prev
    }
    local Errors = require("rsync.errors")
    local error = Errors.get_error(job.code)
    local message = string.format("Rsync error: %s", error)
    vim.notify(message, "error", opts)
end

return M
