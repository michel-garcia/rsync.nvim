local M = {}

local loaded = false

local sep = vim.loop.os_uname().sysname == "Windows" and "\\" or "/"

local errors = {
    [1] = "Syntax or usage error",
    [2] = "Protocol incompatibility",
    [3] = "Errors selecting input/output files, dirs",
    [4] = "Requested action not supported",
    [5] = "Error starting client-server protocol",
    [6] = "Daemon unable to append to log-file",
    [10] = "Error in socket I/O",
    [11] = "Error in file I/O",
    [12] = "Error in rsync protocol data stream",
    [13] = "Errors with program diagnostics",
    [14] = "Errors in IPC code",
    [20] = "Received SIGUSR1 or SIGINT",
    [21] = "Some error returned bt waitpid()",
    [22] = "Error allocating core memory buffers",
    [23] = "Partial transfer due to error",
    [24] = "Partial transfer due to vanished source files",
    [25] = "The --max-delete limit stopped deletions",
    [30] = "Timeout in data send/receive",
    [35] = "Timeout waiting for daemon connection"
}

local bail = function (message, level)
    vim.notify(string.format("Rsync: %s", message), level)
end

local get_config = function ()
    local filename = table.concat({
        vim.loop.cwd(), ".rsync.lua"
    }, sep)
    local ok, config = pcall(dofile, filename)
    if not ok then
        bail("missing or invalid config", "error")
        return
    end
    if not config.host then
        bail("missing 'host' in config", "error")
        return
    end
    if not config.user then
        bail("missing 'user' in config", "error")
        return
    end
    if not config.path then
        bail("missing 'path' in config", "error")
        return
    end
    return config
end

local config_to_remote = function (config)
    return string.format("%s@%s:%s", config.user, config.host, config.path)
end

local sync = function (src, dest, config)
    if vim.fn.executable("rsync") ~= 1 then
        bail("rsync is not a valid executable", "error")
        return
    end
    if M.current.job_id then
        local statuses = vim.fn.jobwait({ M.current.job_id }, 10000)
        if statuses[1] < 0 then
            bail("job in progress", "warn")
            return
        end
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
    local cmd = string.format(
        "rsync %s %s %s", table.concat(opts, " "), src, dest
    )
    if config.pass then
        if vim.fn.executable("sshpass") ~= 1 then
            bail("sshpass is not a valid executable", "error")
            return
        end
        cmd = string.format("sshpass -p '%s' %s", config.pass, cmd)
    end
    M.current.job_id = vim.fn.jobstart(cmd, {
        capture_stdout = true,
        on_exit = function (_, code)
            M.current.job_id = nil
            if code == 0 then
                bail("job complete!")
                return
            end
            local error = errors[code] or "Unknown error"
            bail(error, "error")
        end,
        on_stdout = function (_, data)
            for _, line in ipairs(data) do
                if line ~= "" then
                    local percentage = line:match("(%d+)%%")
                    if percentage ~= nil then
                        M.current.status.percentage = tonumber(percentage)
                    end
                end
            end
        end
    })
end

M.current = {
    job_id = nil,
    status = {
        percentage = 0
    }
}

M.setup = function ()
    if loaded then
        return
    end
    loaded = true
    vim.api.nvim_create_user_command("SyncDown", function (opts)
        local delete = opts.args == "delete"
        M.sync_down(delete)
    end, { nargs = "?" })
    vim.api.nvim_create_user_command("SyncUp", function (opts)
        local delete = opts.args == "delete"
        M.sync_up(delete)
    end, { nargs = "?" })
end

M.sync_down = function (delete)
    local config = get_config()
    if not config then
        return
    end
    local src = config_to_remote(config)
    local dest = vim.loop.cwd() .. sep
    config.delete = delete or false
    sync(src, dest, config)
end

M.sync_up = function (delete)
    local config = get_config()
    if not config then
        return
    end
    local src = vim.loop.cwd() .. sep
    local dest = config_to_remote(config)
    config.delete = delete or false
    sync(src, dest, config)
end

return M
