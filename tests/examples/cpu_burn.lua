-- To be tested in GMA2 environment

local gma2Workers = require("gma2-workers")

-- The Work Unit
-- Runs exactly 'opsCount' math iterations
local function cpuBurner(workerIndex, opsCount)
    local val = 0
    for i = 1, opsCount do
        -- Perform expensive math to burn CPU
        val = math.sin(i) * math.cos(i) + math.tan(i)
    end
    return string.format("W%02d: Processed %d ops", workerIndex, opsCount)
end

local function Start()
    -- 1. INPUT: Mode
    local modeInput = gma.textinput("Mode (timer / cmd)", "timer")
    if not modeInput or (modeInput ~= "timer" and modeInput ~= "cmd") then
        gma.echo("Benchmark Cancelled: Invalid Mode")
        return
    end

    -- 2. INPUT: Workers
    local countInput = gma.textinput("Amount of Workers", "19")
    local workerCount = tonumber(countInput)
    if not workerCount or workerCount < 1 then return end

    -- 3. INPUT: Total Load
    -- User enters a multiplier. 1000 = 1,000,000 operations TOTAL.
    local multInput = gma.textinput("TOTAL Load (x1000 ops)", "100")
    local totalMult = tonumber(multInput)
    if not totalMult then return end

    -- 4. CALCULATE SPLIT
    local totalOps = totalMult * 1000
    -- Floor division to ensure integer loop counts
    local opsPerWorker = math.floor(totalOps / workerCount)

    -- Handle remainder (if 100 ops / 3 workers, someone needs to do +1)
    local remainder = totalOps % workerCount

    -- 5. BUILD TASKS
    local myTasks = {}
    for i = 1, workerCount do
        -- Distribute the remainder to the first few workers
        local myShare = opsPerWorker
        if i <= remainder then
            myShare = myShare + 1
        end

        table.insert(myTasks, {
            func = cpuBurner,
            args = { i, myShare }
        })
    end

    gma.echo("========================================")
    gma.echo(string.format("BENCHMARK: Splitting %d Total Ops across %d Workers", totalOps, workerCount))
    gma.echo(string.format("Load per Worker: ~%d ops | Mode: %s", opsPerWorker, modeInput))
    gma.echo("========================================")

    -- 6. RUN ASYNC
    gma2Workers.RunAsync({
        tasks = myTasks,
        mode = modeInput,
        onComplete = function(res)
            gma.echo("----------------------------------------")
            gma.echo(string.format("FINISHED in %.4fs", res.duration))
            gma.echo("----------------------------------------")
        end
    })
end

return Start
