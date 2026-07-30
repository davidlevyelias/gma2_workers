local Dispatcher = require("src.dispatcher")

---@class GMA2WorkersInfo
---@field name string
---@field version string
---@field author string

---@class GMA2WorkersModule
---@field info GMA2WorkersInfo
local gma2Workers = {}

gma2Workers.info = {
    name = "gma2_workers",
    version = "1.1.2",
    author = "David Levy Elias",
}

local function ensureConfig(config, caller)
    if type(config) ~= "table" then
        error(string.format("%s expects a config table", caller), 2)
    end
    return config
end

---@param config {tasks: WorkerTask[], onComplete: fun(response: WorkerResponse), mode?: WorkerMode, workers?: integer}
function gma2Workers.RunAsync(config)
    Dispatcher.runAsync(ensureConfig(config, "gma2Workers.RunAsync"))
end

---@param config {tasks: WorkerTask[], mode?: WorkerMode, workers?: integer}
---@return WorkerResponse|nil
function gma2Workers.RunSync(config)
    return Dispatcher.runSync(ensureConfig(config, "gma2Workers.RunSync"))
end

gma2Workers.Dispatch = gma2Workers.RunSync

return gma2Workers