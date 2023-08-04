local M = {}

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

M.get_error = function (code)
    return errors[code]
end

return M
