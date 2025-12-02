local Workers = require("gma2-workers")

local TASK_COUNT = 12
local WORKER_LIMIT = 3

local function mockTask(taskId)
    local function task()
        local workerSlot = ((taskId - 1) % WORKER_LIMIT) + 1
        gma.echo(string.format("[Limited Demo] Worker %d processing task %d", workerSlot, taskId))
        gma.sleep(0.05)
        return string.format("Task %d done", taskId)
    end
    return task
end

local function Start()
    gma.echo("[Limited Demo] === Limited Worker Count Demo ===")
    gma.echo(string.format("[Limited Demo] Tasks: %d | Workers: %d", TASK_COUNT, WORKER_LIMIT))

    local tasks = {}
    for i = 1, TASK_COUNT do
        table.insert(tasks, {
            func = mockTask(i)
        })
    end

    Workers.RunAsync({
        tasks = tasks,
        mode = "timer",
        workers = WORKER_LIMIT,
        onComplete = function(response)
            gma.echo(string.format("[Limited Demo] Completed in %.3fs", response.duration))
        end
    })
end

return Start
