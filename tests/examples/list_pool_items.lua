local Workers = require("gma2-workers")

local ROOT_HANDLE = 1 -- Constant entry point used by gma.show.getobj.* helpers
local POOL_INDEX = 14 -- Example pool (change to match the pool you want to benchmark)
local WORKER_COUNT = 20 -- Adjust to taste


local function iterateRangeDirect(poolHandle, startIdx, endIdx)
    local found = 0
    for i = startIdx, endIdx do
        local child = gma.show.getobj.child(poolHandle, i)
        if child then
            local _ = gma.show.getobj.label(child) -- mimic user data fetch
            gma.feedback(string.format("[Direct] Found item at index %d", i))
            found = found + 1
        end
    end
    return found
end


local function workerScanPool(poolHandle, startIdx, endIdx)
    if not poolHandle then return 0 end
    return iterateRangeDirect(poolHandle, startIdx, endIdx)
end

local function benchmarkDirect()
    local poolHandle = gma.show.getobj.child(ROOT_HANDLE, POOL_INDEX)
    if not poolHandle then
        gma.echo("[Pool Benchmark] Pool handle not found. Adjust POOL_INDEX.")
        return nil, nil
    end

    local poolSize = gma.show.getobj.amount(poolHandle)

    gma.echo(string.format("[Pool Benchmark] Direct scan over %d reported slots.", poolSize))

    local t0 = os.clock()
    local found = iterateRangeDirect(poolHandle, 1, poolSize)
    local duration = os.clock() - t0

    gma.echo(string.format("[Pool Benchmark] Direct iteration: found %d entries in %.3fs.", found, duration))
    return found, duration, poolHandle, poolSize
end

local function benchmarkWorkers(poolHandle, poolSize, baselineDuration)
    local tasks = {}
    local chunkSize = math.ceil(poolSize / WORKER_COUNT)

    for startIdx = 1, poolSize, chunkSize do
        local endIdx = math.min(startIdx + chunkSize - 1, poolSize)
        table.insert(tasks, {
            func = workerScanPool,
            args = { poolHandle, startIdx, endIdx }
        })
    end

    gma.echo(string.format(
        "[Pool Benchmark] Spawning %d workers (%d-slot chunks) in timer mode...",
        #tasks,
        chunkSize
    ))

    Workers.RunAsync({
        tasks = tasks,
        mode = "timer",
        onComplete = function(response)
            local totalFound = 0
            for _, result in pairs(response.result) do
                if result.success and type(result.data) == "number" then
                    totalFound = totalFound + result.data
                end
            end

            local speedup = baselineDuration and baselineDuration / response.duration or 0
            gma.echo(string.format(
                "[Pool Benchmark] Worker iteration (%d workers): found %d entries in %.3fs (%.2fx speed-up).",
                response.workerCount,
                totalFound,
                response.duration,
                speedup
            ))
        end
    })
end

local function Start()
    gma.echo("[Pool Benchmark] === Listing Pool Items Benchmark ===")

    local _, baselineDuration, poolHandle, poolSize = benchmarkDirect()
    if poolHandle and poolSize then
        benchmarkWorkers(poolHandle, poolSize, baselineDuration)
    end
end

return Start