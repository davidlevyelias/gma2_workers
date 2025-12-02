local Dispatcher = require("src.dispatcher")
local gma2Workers = {}

local function ensureConfig(config, caller)
    if type(config) ~= "table" then
        error(string.format("%s expects a config table", caller), 2)
    end
    return config
end

---@param config {tasks: WorkerTask[], onComplete: fun(response: WorkerResponse), mode?: WorkerMode}
function gma2Workers.RunAsync(config)
    Dispatcher.runAsync(ensureConfig(config, "gma2Workers.RunAsync"))
end

---@param config {tasks: WorkerTask[], mode?: WorkerMode}
---@return WorkerResponse|nil
function gma2Workers.RunSync(config)
    return Dispatcher.runSync(ensureConfig(config, "gma2Workers.RunSync"))
end

return gma2Workers