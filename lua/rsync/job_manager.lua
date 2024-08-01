local M = {}
M.jobs = {}

M.add = function (job)
    M.jobs[job.id] = job
end

M.remove = function (job_id)
    M.jobs[job_id] = nil
end

M.stop_all = function ()
    for _, job in M.jobs do
        job:stop()
    end
end

return M
