local Registry = require("src.registry")

local Executor = {}

---@param job WorkerJob
---@param taskIndex integer
local function buildTaskResult(job, taskIndex, success, payload)
    job.results[taskIndex] = {
        success = success,
        data = payload
    }

    job.completedTasks = job.completedTasks + 1
end

---@param jobId string
---@param job WorkerJob
local function finalizeJob(jobId, job)
    if job.completed then
        return
    end

    if job.mode == "cmd" and job.alias then
        _G[job.alias] = nil
    end

    local response = {
        result = job.results,
        duration = os.clock() - job.startTime,
        workerCount = job.workerThreads,
        jobId = jobId
    }

    if job.awaiting then
        job.finalResponse = response
        job.completed = true
    else
        job.completed = true
        if job.onComplete then
            pcall(job.onComplete, response)
        end
        Registry.remove(jobId)
    end
end

---@param job WorkerJob
---@return integer?, WorkerTask?
local function fetchNextTask(job)
    local index = job.nextTaskIndex
    if index > job.totalTasks then
        return nil, nil
    end

    job.nextTaskIndex = index + 1
    return index, job.tasks[index]
end

---@param jobId string
---@param workerLabel integer?
function Executor.run(jobId, workerLabel)
    local job = Registry.get(jobId)
    if not job or job.completed then return end

    while true do
        local taskIndex, task = fetchNextTask(job)
        if not taskIndex or not task then
            break
        end

        local args = task.args or {}
        local status, res = pcall(task.func, table.unpack(args))

        if status then
            buildTaskResult(job, taskIndex, true, res)
        else
            buildTaskResult(job, taskIndex, false, "Error: " .. tostring(res))
        end

        if job.completedTasks >= job.totalTasks then
            finalizeJob(jobId, job)
            break
        end
    end

    if job.completedTasks >= job.totalTasks then
        finalizeJob(jobId, job)
    end
end

return Executor
