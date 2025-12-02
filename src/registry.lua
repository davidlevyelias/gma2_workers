---@class WorkerTask
---@field func fun(...: any): any
---@field args table?

---@class WorkerResult
---@field success boolean
---@field data any

---@class WorkerResponse
---@field duration number
---@field workerCount integer
---@field jobId string
---@field result table<integer, WorkerResult>

---@alias WorkerMode "timer"|"cmd"

---@class WorkerJob
---@field tasks WorkerTask[]
---@field onComplete fun(response: WorkerResponse)?
---@field results table<integer, WorkerResult>
---@field totalTasks integer
---@field workerThreads integer
---@field startTime number
---@field mode WorkerMode
---@field alias string?
---@field awaiting boolean
---@field finalResponse WorkerResponse?
---@field completed boolean?
---@field nextTaskIndex integer
---@field completedTasks integer

---@type table<string, WorkerJob>
local activeJobs = {}

local Utils = require("src.utils")

local Registry = {}

---@param tasks WorkerTask[]
---@param mode WorkerMode
---@param onComplete fun(response: WorkerResponse)?
---@param awaiting boolean
---@param workerThreads integer
function Registry.createJob(tasks, mode, onComplete, awaiting, workerThreads)
    local jobId = Utils.generateJobId()
    local job = {
        tasks = tasks,
        onComplete = onComplete,
        results = {},
        totalTasks = #tasks,
        workerThreads = workerThreads,
        startTime = os.clock(),
        mode = mode,
        alias = nil,
        awaiting = awaiting or false,
        finalResponse = nil,
        completed = false,
        nextTaskIndex = 1,
        completedTasks = 0
    }

    activeJobs[jobId] = job
    return jobId, job
end

---@param jobId string
---@return WorkerJob|nil
function Registry.get(jobId)
    return activeJobs[jobId]
end

---@param jobId string
---@param alias string
function Registry.setAlias(jobId, alias)
    local job = activeJobs[jobId]
    if job then
        job.alias = alias
    end
end

---@param jobId string
function Registry.remove(jobId)
    activeJobs[jobId] = nil
end

return Registry
