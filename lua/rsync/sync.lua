local rsync = require("rsync")
local notifications = require("rsync.notifications")

local M = {}

local jobs = setmetatable({}, {
    __index = {
        count = function (t)
            local count = 0
            for _ in pairs(t) do
                count = count + 1
            end
            return count
        end,
        add = function (t, job)
            t[job.id] = job
        end,
        get = function (t, id)
            return t[id]
        end,
        remove = function (t, job)
            t[job.id] = nil
        end
    }
})

M.get_jobs = function ()
    return jobs
end

M.exec = function (config)
    if vim.fn.executable("rsync") ~= 1 then
        notifications.error("rsync is not a valid executable")
        return
    end
    if not config.src or not config.dest then
        notifications.error("missing path in command")
        return
    end
    if jobs:count() == rsync.config.max_concurrent_jobs then
        notifications.warn("job limit reached")
        return
    end
    local opts = { "-av", "--info=progress2" }
    if config.delete then
        table.insert(opts, "--delete")
    end
    if not config.exclude then
        config.exclude = {}
    end
    table.insert(config.exclude, ".rsync.*")
    if config.exclude then
        for _, pattern in ipairs(config.exclude) do
            local opt = string.format("--exclude %s", pattern)
            table.insert(opts, opt)
        end
    end
    if config.include then
        for _, pattern in ipairs(config.include) do
            local opt = string.format("--include %s", pattern)
            table.insert(opts, opt)
        end
    end
    if config.port then
        local opt = string.format("-e 'ssh -p %s'", config.port)
        table.insert(opts, opt)
    end
    local cmd = string.format(
        "rsync %s %s %s", table.concat(opts, " "), config.src, config.dest
    )
    if config.pass then
        if vim.fn.executable("sshpass") ~= 1 then
            notifications.error("sshpass is not a valid executable")
            return
        end
        cmd = string.format("sshpass -p '%s' %s", config.pass, cmd)
    end
    local job_id = vim.fn.jobstart(cmd, {
        capture_stdout = true,
        on_exit = function (job_id, code)
            local job = jobs:get(job_id)
            job.status = "complete"
            if rsync.config.on_update then
                rsync.config.on_update(job)
            end
            jobs:remove(job)
            if code == 0 then
                notifications.success("job complete!")
                return
            end
            local errors = require("rsync.errors")
            local error = errors.get_error(code) or "Unknown error"
            notifications.error(error)
        end,
        on_stdout = function (job_id, data)
            local job = jobs:get(job_id)
            job.status = "syncing"
            if rsync.config.on_update then
                rsync.config.on_update(job)
            end
            for _, line in ipairs(data) do
                if line ~= "" then
                    local percentage = line:match("(%d+)%%")
                    if percentage ~= nil then
                        job.percentage = tonumber(percentage)
                        if rsync.config.on_update then
                            rsync.config.on_update(job)
                        end
                    end
                end
            end
        end
    })
    local job = {
        id = job_id,
        status = "starting",
        percentage = 0
    }
    jobs:add(job)
    if rsync.config.on_update then
        rsync.config.on_update(job)
    end
end

M.stop = function (job_id)
    vim.fn.jobstop(job_id)
    local job = jobs:get(job_id)
    job.status = "stopped"
    if rsync.config.on_update then
        rsync.config.on_update(job)
    end
    jobs:remove(job)
    notifications.success("job stopped")
end

return M
