local events = require("rsync.events")

local M = {}
M.current = nil
M.__index = M

M.id = 0
M.config = {
    exclude = {
        ".rsync.*"
    },
    include = {}
}
M.status = "starting"
M.percentage = 0

M.new = function (config)
    local self = setmetatable({}, M)
    self.config = vim.tbl_deep_extend("force", M.config, config)
    return self
end

M.prepare = function (self)
    local opts = {
        "--archive",
        "--info=progress2",
        "--verbose"
    }
    if self.config.delete then
        table.insert(opts, "--delete")
    end
    for _, pattern in ipairs(self.config.exclude) do
        local opt = string.format("--exclude %s", pattern)
        table.insert(opts, opt)
    end
    for _, pattern in ipairs(self.config.include) do
        local opt = string.format("--include %s", pattern)
        table.insert(opts, opt)
    end
    if self.config.port then
        local opt = string.format("--rsh='ssh -p %s'", self.config.port)
        table.insert(opts, opt)
    end
    local args = table.concat(opts, " ")
    self.cmd = string.format(
        "rsync %s %s %s", args, self.config.src, self.config.dest
    )
    if self.config.pass then
        self.cmd = string.format(
            "sshpass -p '%s' %s", self.config.pass, self.cmd
        )
    end
    return true
end

M.start = function (self)
    local opts = {
        capture_stdout = true,
        on_exit = function (_, code)
            self:on_exit(code)
        end,
        on_stdout = function (_, data)
            self:on_stdout(data)
        end
    }
    if not self:prepare() then
        return false
    end
    self.id = vim.fn.jobstart(self.cmd, opts)
    local active = self.id > 0
    if active then
        M.current = self
    end
    return active
end

M.stop = function (self)
    self.status = "stopping"
    return vim.fn.jobstop(self.id)
end

M.on_exit = function (self, code)
    self.code = code
    self.status = self.status == "stopping" and "stopped" or "completed"
    M.current = nil
    if code ~= 0 then
        return events.error(self)
    end
    events.complete(self)
end

M.on_stdout = function (self, data)
    self.status = "syncing"
    for _, line in ipairs(data) do
        if line ~= "" then
            local percentage = line:match("(%d+)%%")
            if percentage ~= nil then
                self.percentage = tonumber(percentage)
                events.progress(self)
            end
        end
    end
end

return setmetatable(M, {
    __call = function (_, ...)
        return M.new(...)
    end
})
