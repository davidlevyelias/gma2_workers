local Registry = require("src.registry")
local Utils = require("src.utils")

local Executor = {}

---@param jobId string
---@param workerId integer
---@param success boolean
---@param payload any
local function onWorkerFinished(jobId, workerId, success, payload)
    local job = Registry.get(jobId)
    if not job then return end

    job.results[workerId] = {
        success = success,
        data = payload
    }

    local finishedCount = Utils.getTableCount(job.results)

    if finishedCount >= job.totalWorkers then
        local duration = os.clock() - job.startTime
        local response = {
            result = job.results,
            duration = duration,
            workerCount = job.totalWorkers,
            jobId = jobId
        }

        if job.mode == "cmd" and job.alias then
            _G[job.alias] = nil
        end

        if job.awaiting then
            job.finalResponse = response
            job.completed = true
        else
            if job.onComplete then
                pcall(job.onComplete, response)
            end
            Registry.remove(jobId)
        end
    end
end

---@param jobId string
---@param workerId integer
function Executor.run(jobId, workerId)
    local job = Registry.get(jobId)
    if not job then return end

    local task = job.tasks[workerId]

    if not task or not task.func then
        onWorkerFinished(jobId, workerId, false, "Error: Missing task definition")
        return
    end

    local args = task.args or {}
    local status, res = pcall(task.func, table.unpack(args))

    if status then
        onWorkerFinished(jobId, workerId, true, res)
    else
        onWorkerFinished(jobId, workerId, false, "Error: " .. tostring(res))
    end
end

return Executor
