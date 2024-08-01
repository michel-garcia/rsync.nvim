local JobManager = require("rsync.job_manager")

local M = {}
M.__index = M

M.src = nil
M.dest = nil
M.opts = {
    delete = false,
    exclude = {},
    include = {},
    pass = nil,
    port = nil
}
M.exited = false
M.failed = false
M.notification = nil
M.spinner = {
    frames = {
	    "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷",
    },
    index = 0
}

M.new = function (src, dest, opts)
    local self = setmetatable({}, M)
    vim.validate({
        src = { src, "string" },
        dest = { dest, "string" },
        opts = { opts, "table" },
        delete = { opts.delete or false, "boolean" },
        exclude = { opts.exclude or {}, "table" },
        include = { opts.include or {}, "table" },
        pass = { opts.pass or nil, "string" },
        port = { opts.port or 0, "number" }
    })
    self.src = src
    self.dest = dest
    self.opts = vim.tbl_deep_extend("force", M.opts, opts or M.opts)
    return self
end

M.get_cmd = function (self)
    local opts = {
        "--archive",
        "--exclude .rsync.lua",
        "--info=progress2",
        "--mkpath",
        "--no-inc-recursive"
    }
    if self.opts.delete then
        table.insert(opts, "--delete")
    end
    for _, pattern in ipairs(self.opts.exclude) do
        local opt = string.format("--exclude %s", vim.fn.escape(pattern, " \\"))
        table.insert(opts, opt)
    end
    for _, pattern in ipairs(self.opts.include) do
        local opt = string.format("--include %s", vim.fn.escape(pattern, " \\"))
        table.insert(opts, opt)
    end
    if self.opts.port then
        local opt = string.format("--rsh='ssh -p %s'", self.opts.port)
        table.insert(opts, opt)
    end
    local args = table.concat(opts, " ")
    local cmd = string.format("rsync %s %s %s", args, self.src, self.dest)
    if not self.opts.pass then
        return cmd
    end
    return string.format("sshpass -p '%s' %s", self.opts.pass, cmd)
end

M.start = function (self)
    self.notification = vim.notify("Starting...", vim.log.levels.INFO, {
        timeout = false,
        title = "Rsync"
    })
    self:update()
    local cmd = self:get_cmd()
    self.exited = false
    self.failed = false
    self.id = vim.fn.jobstart(cmd, {
        capture_stdout = true,
        on_stderr = function (_, data)
            self.failed = true
            self:on_stderr(data)
        end,
        on_stdout = function (_, data)
            self:on_stdout(data)
        end,
        on_exit = function (_, code)
            self.exited = true
            self:on_exit(code)
        end
    })
    JobManager.add(self)
    local ok = self.id > 0
    if not ok then
        self.failed = true
        vim.notify("Unable to start job.", vim.log.levels.ERROR, {
            replace = self.notification,
            timeout = 3500,
            title = "Rsync"
        })
    end
    return ok
end

M.stop = function (self)
    vim.fn.jobstop(self.id)
end

M.on_stderr = function (self, data)
    if self.exited then
        return
    end
    local content = table.concat(data)
    if content:len() == 0 then
        return
    end
    self.notification = vim.notify(content, vim.log.levels.ERROR, {
        icon = "",
        replace = self.notification,
        timeout = 7500,
        title = "Rsync"
    })
end

M.on_stdout = function (self, data)
    if self.exited then
        return
    end
    local content = table.concat(data)
    if content:len() == 0 then
        return
    end
    self.percentage = content:match("(%d+)%%")
end

M.on_exit = function (self, code)
    JobManager.remove(self.id)
    if code ~= 0 then
        return
    end
    self.notification = vim.notify("Sync complete!", vim.log.levels.INFO, {
        icon = "",
        replace = self.notification,
        timeout = 3500,
        title = "Rsync"
    })
end

M.update = function (self)
    if self.exited or self.failed then
        return
    end
    self.spinner.index = (self.spinner.index + 1) % #self.spinner.frames
    local message = self.percentage and string.format("Syncing: %s%%", self.percentage) or "Starting..."
    self.notification = vim.notify(message, vim.log.levels.INFO, {
        icon = self.spinner.frames[self.spinner.index],
        replace = self.notification,
        timeout = false,
        title = "Rsync"
    })
    vim.defer_fn(function ()
        self:update()
    end, 100)
end

return setmetatable(M, {
    __call = function (_, ...)
        return M.new(...)
    end
})
