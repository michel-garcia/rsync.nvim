local Manager = require("rsync.manager")

local M = {}
M.__index = M

M.src = nil
M.dest = nil
M.opts = {
    delete = false,
    exclude = {},
    include = {},
    pass = nil,
    port = nil,
}
M.started = false
M.percentage = nil
M.failed = false
M.completed = false
M.last_error_message = nil

M.new = function(src, dest, opts)
    local self = setmetatable({}, M)
    vim.validate({
        src = {
            src,
            "string",
        },
        dest = {
            dest,
            "string",
        },
        opts = {
            opts,
            "table",
        },
        delete = {
            opts.delete or false,
            "boolean",
        },
        disable_mkpath = {
            opts.disable_mkpath or false,
            "boolean",
        },
        exclude = {
            opts.exclude or {},
            "table",
        },
        include = {
            opts.include or {},
            "table",
        },
        on_update = {
            opts.on_update,
            "function",
        },
        pass = {
            opts.pass or nil,
            {
                "string",
                "nil",
            },
        },
        port = {
            opts.port or 0,
            "number",
        },
    })
    self.src = src
    self.dest = dest
    self.opts = vim.tbl_deep_extend("force", M.opts, opts or M.opts)
    return self
end

M.get_cmd = function(self)
    local opts = {
        "--archive",
        "--exclude .rsync.lua",
        "--info=progress2",
        "--no-inc-recursive",
    }
    if not self.opts.disable_mkpath then
        table.insert(opts, "--mkpath")
    end
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

M.start = function(self)
    self.started = false
    self.percentage = nil
    self.failed = false
    self.completed = false
    self.last_error_message = nil
    self:update()
    local cmd = self:get_cmd()
    self.id = vim.fn.jobstart(cmd, {
        capture_stdout = true,
        on_stderr = function(_, data)
            self:on_stderr(data)
        end,
        on_stdout = function(_, data)
            self:on_stdout(data)
        end,
        on_exit = function(_, code)
            self:on_exit(code)
        end,
    })
    Manager.add(self)
    local ok = self.id > 0
    if not ok then
        self.failed = true
        self:update()
    end
    self.started = true
    return ok
end

M.stop = function(self)
    vim.fn.jobstop(self.id)
end

M.on_stderr = function(self, data)
    if self.completed then
        return
    end
    local content = table.concat(data)
    if content:len() == 0 then
        return
    end
    self.failed = true
    self.last_error_message = content
    self:update()
end

M.on_stdout = function(self, data)
    if self.completed then
        return
    end
    local content = table.concat(data)
    if content:len() == 0 then
        return
    end
    self.percentage = content:match("(%d+)%%")
    self:update()
end

M.on_exit = function(self, code)
    Manager.remove(self.id)
    if code ~= 0 then
        return
    end
    self.completed = true
    self:update()
end

M.update = function(self)
    pcall(self.opts.on_update, {
        job = self,
        level = not self.failed and vim.log.levels.INFO or vim.log.levels.ERROR,
    })
end

M.status = function(self)
    if self.completed then
        return "Sync complete!"
    end
    if self.failed then
        return self.last_error_message
    end
    if self.percentage ~= nil then
        return string.format("Syncing: %s%%...", self.percentage)
    end
    return "Starting..."
end

return setmetatable(M, {
    __call = function(_, ...)
        return M.new(...)
    end,
})
