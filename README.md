## GMA2 Workers

High-Performance Parallel Processing Library for GrandMA2 Lua Engine

GMA2 Workers is a robust Orchestrator Library that brings true parallel processing to the GrandMA2 Lua engine. By leveraging `gma.timer` and `gma.cmd` injection, GMA2 Workers allows you to split heavy workloads (like parsing the entire Plugin pool or manipulating thousands of fixtures) across multiple concurrent "workers."

🚀 **Features**

- **True Concurrency:** Run heavy Lua loops without blocking the GrandMA2 UI.
- **Linear Scaling:** Proven performance gains. A task that takes **155s** with 1 worker takes **~8s** with 19 workers.
- **Zero Global Pollution:** Smart cleanup mechanisms ensure your `_G` namespace stays clean.
- **Two Execution Modes:**
    - `timer` (Default): High-performance, low-overhead using native timer interrupts.
    - `cmd`: Robust, isolated execution using the command line pipeline.
- **Async or Await:** Call `RunAsync` with an `onComplete` callback, or `RunSync` to block until all workers finish and immediately receive the response.
- **Lua 5.3 Compatible:** Ready for standard Lua environments.

🧱 **Project Structure**

- `init.lua`: Public entry-point returned by `require("gma2-workers")`.
- `src/utils.lua`: Deterministic helpers (IDs, alias names, counters).
- `src/registry.lua`: In-memory tracking of active jobs/workers (also hosts the shared annotations).
- `src/executor.lua`: Runs worker functions and resolves callbacks.
- `src/dispatcher.lua`: Orchestrates `gma.timer`/`gma.cmd` scheduling.

📦 **Installation**

1. Download the entire `gma2-workers` folder (keep the name so `require` can resolve nested modules) or download a pre-packaged release file.
2. Place the folder in your GrandMA2 plugin directory:

   - **PC:** `C:\ProgramData\MA Lighting Technologies\grandma\gma2_V_3.x.x\plugins\`
   - **Console:** `/gma2/plugins/`

3. Import it into your plugin script using `local gma2workers = require("gma2-workers")` (or rename the folder and update the require path accordingly).

⚡ **Quick Start**

1.  **Require the Library**
    `local gma2workers = require("gma2-workers")`

2.  **Define a "Pure" Function**
    **Crucial:** The function you want to run in parallel must be "Pure". It cannot access local variables defined outside of itself (Upvalues). It must rely only on the arguments passed to it or global MA functions.

    ```LUA
    -- Good: Self-contained
    local function heavyTask(index, itemsToProcess)
        local result = 0
        for i = 1, itemsToProcess do
            result = math.sin(i) * math.cos(i) -- Burn CPU
        end
        return "Worker " .. index .. " finished " .. itemsToProcess .. " items."
    end
    ```

3.  **Run the Job**

    ```LUA
    local function Start()
    -- Create a list of tasks
    local myTasks = {}

        -- Split work into 10 chunks
        for i = 1, 10 do
            table.insert(myTasks, {
                func = heavyTask,
                args = {i, 50000} -- Arguments passed to the function
            })
        end

        -- Run it
        gma2workers.RunAsync({
            tasks = myTasks,
            mode = "timer", -- Optional: "timer" (default) or "cmd"
            onComplete = function(response)
                gma.echo("Job done in " .. response.duration .. "s")

                -- Access results
                for workerId, output in pairs(response.result) do
                    gma.echo(output.data)
                end
            end
        })

        -- Or block and get the response immediately
        local response = gma2workers.RunSync({
            tasks = myTasks,
            mode = "timer"
        })
        gma.echo("Await mode duration: " .. response.duration .. "s")
    end
    return Start
    ```

📊 **Benchmarks**

Does it actually work? Yes.

We tested a CPU-intensive trigonometric loop (1 Million Operations) on GrandMA2 onPC. The results show near-perfect linear scaling up to ~20 threads.

| Workers | Duration (s) | Performance   |
| ------- | ------------ | ------------- |
| 1       | 155.5s       | 1x (Baseline) |
| 2       | 77.7s        | 2x Faster     |
| 4       | 38.9s        | 4x Faster     |
| 10      | 15.5s        | 10x Faster    |
| 19      | 8.1s         | 19x Faster    |

_Note: Performance plateaus after ~20 workers due to internal engine overhead._

📚 **API Reference**

### `gma2workers.RunAsync(config)`
Fire-and-forget execution that completes via callback.

#### Parameters: `config` (Table)

| Key          | Type     | Description                                                           |
| ------------ | -------- | --------------------------------------------------------------------- |
| `tasks`      | Table    | An array of task objects: `{ {func=ref, args={...}}, ... }`           |
| `onComplete` | Function | **Required**. Called once all workers finish. Receives `response`.        |
| `mode`       | String   | `"timer"` (Default) or `"cmd"`.                                       |

### `gma2workers.RunSync(config)`
Blocking execution that returns the response table directly.

| Key          | Type   | Description                                                 |
| ------------ | ------ | ----------------------------------------------------------- |
| `tasks`      | Table  | Same task array as above.                                   |
| `mode`       | String | Optional execution mode (`"timer"` default, or `"cmd"`). | 

`RunSync` returns the same response object that `onComplete` would receive:

> **Note:** `gma2workers.Dispatch` remains available for backward compatibility and is now an alias for `RunSync`.

```LUA
{
    duration = 8.123, -- Total time in seconds
    workerCount = 19, -- Number of workers used
    jobId = "Job_...", -- Internal ID
    result = { -- Table of returns from workers
        [1] = { success = true, data = "..." },
        [2] = { success = false, data = "Error: ..." },
        ...
    }
}
```

⚠️ **Important Considerations**

**The "Upvalue" Limitation**

Because of how Lua closures work across threads/timers in MA2, your worker functions cannot see local variables defined outside of them.

**This will FAIL:**

```LUA
local multiplier = 50 -- Local variable
local function badWorker(val)
return val * multiplier -- ERROR: Cannot see 'multiplier'
end
```

**This works:**

```LUA
-- Pass everything via arguments
local function goodWorker(val, mult)
return val * mult
end
```

**Race Conditions**

gma2workers allows parallel execution. If multiple workers try to write to the same global variable (e.g., `_G.myCounter = _G.myCounter + 1`) at the same time, data will be lost.

- **Solution:** Return data from the worker function instead of writing to globals. gma2workers collects all returns safely for you.


📝 **License**
Distributed under the MIT License. See `LICENSE` for more information.
Developed by David Levy Elias - Lighting Designer & Programmer.
