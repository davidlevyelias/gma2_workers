local Workers = require("gma2-workers")

local ROOT_HANDLE = 1
local POOL_INDEX = 14
local WORKER_COUNT = 12 -- Desired concurrent workers

local function iterateRange(poolHandle, startIdx, endIdx)
    local found = 0
    for i = startIdx, endIdx do
        local child = gma.show.getobj.child(poolHandle, i)
        if child then
            local _ = gma.show.getobj.label(child)
            found = found + 1
        end
    end
    return found
end

local function workerRange(poolHandle, startIdx, endIdx)
    if not poolHandle then return 0 end
    return iterateRange(poolHandle, startIdx, endIdx)
end

local function Start()
    gma.echo("[Await Example] === Listing Pool Items ===")

    local poolHandle = gma.show.getobj.child(ROOT_HANDLE, POOL_INDEX)
    if not poolHandle then
        gma.echo("[Await Example] No pool handle. Check POOL_INDEX.")
        return
    end

    local poolSize = gma.show.getobj.amount(poolHandle)
    gma.echo(string.format("[Await Example] Pool reports %d slots.", poolSize))

    local chunkSize = math.ceil(poolSize / WORKER_COUNT)
    local tasks = {}

    for startIdx = 1, poolSize, chunkSize do
        local endIdx = math.min(startIdx + chunkSize - 1, poolSize)
        table.insert(tasks, {
            func = workerRange,
            args = { poolHandle, startIdx, endIdx }
        })
    end

    local t0 = os.clock()
    local response = Workers.RunSync({
        tasks = tasks,
        mode = "timer",
        workers = WORKER_COUNT
    })
    local totalDuration = os.clock() - t0

    local totalFound = 0
    for _, result in pairs(response.result) do
        if result.success and type(result.data) == "number" then
            totalFound = totalFound + result.data
        end
    end

    gma.echo(string.format(
        "[Await Example] Found %d items via %d workers in %.3fs (RunSync took %.3fs).",
        totalFound,
        response.workerCount,
        response.duration,
        totalDuration
    ))
end

return Start
