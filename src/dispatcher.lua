local Registry = require("src.registry")
local Executor = require("src.executor")
local Utils = require("src.utils")

local Dispatcher = {}

---@param jobId string
---@param workerCount integer
local function dispatchTimerWorkers(jobId, workerCount)
    for workerId = 1, workerCount do
        local wrapper = function()
            Executor.run(jobId)
        end
        gma.timer(wrapper, 0, 1)
    end
end

---@param jobId string
---@param workerCount integer
local function dispatchCmdWorkers(jobId, workerCount)
    local aliasName = Utils.generateAliasName("Exec_")
    _G[aliasName] = function()
        Executor.run(jobId)
    end
    Registry.setAlias(jobId, aliasName)

    for workerId = 1, workerCount do
        gma.cmd(string.format('LUA "%s()"', aliasName))
    end
end

---@param jobId string
---@param workerCount integer
---@param mode WorkerMode
local function startWorkers(jobId, workerCount, mode)
    if mode == "timer" then
        dispatchTimerWorkers(jobId, workerCount)
    elseif mode == "cmd" then
        dispatchCmdWorkers(jobId, workerCount)
    else
        gma.echo(string.format("GMA2 Workers: Unknown mode '%s'", tostring(mode)))
    end
end

---@param config {tasks: WorkerTask[], onComplete?: fun(response: WorkerResponse), mode?: WorkerMode, workers?: integer}
---@param awaiting boolean
---@return WorkerResponse|nil
local function dispatchInternal(config, awaiting)
    local tasks = config.tasks or {}
    local mode = config.mode or "timer"
    local onComplete = awaiting and nil or config.onComplete
    local taskCount = #tasks

    if taskCount == 0 then
        return nil
    end

    local workerThreads = taskCount
    local requestedWorkers = tonumber(config.workers)
    if requestedWorkers and requestedWorkers > 0 then
        workerThreads = math.min(taskCount, math.floor(requestedWorkers))
    end

    if workerThreads < 1 then
        workerThreads = 1
    end

    if (not awaiting) and type(onComplete) ~= "function" then
        gma.echo("GMA2 Workers: RunAsync requires an onComplete callback")
        return nil
    end

    local jobId, job = Registry.createJob(tasks, mode, onComplete, awaiting, workerThreads)

    gma.echo(string.format("GMA2 Workers: Spawning %d workers for %d tasks (Mode: %s)", workerThreads, taskCount, mode))

    startWorkers(jobId, workerThreads, mode)

    gma.sleep(0.01)

    if awaiting then
        while not job.completed do
            gma.sleep(0.01)
        end

        local response = job.finalResponse
        Registry.remove(jobId)
        return response
    end

    return nil
end

---@param config {tasks: WorkerTask[], onComplete: fun(response: WorkerResponse), mode?: WorkerMode, workers?: integer}
function Dispatcher.runAsync(config)
    dispatchInternal(config, false)
end

---@param config {tasks: WorkerTask[], mode?: WorkerMode, workers?: integer}
---@return WorkerResponse|nil
function Dispatcher.runSync(config)
    return dispatchInternal(config, true)
end

return Dispatcher
