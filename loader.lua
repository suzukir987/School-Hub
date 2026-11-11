-- School Hub: exact approved bootstrap, one native scheduler handoff.
local source = game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/17a2c8482cf40708907d6298dac94eb7d2b8afed/bootstrap.lua")
local start, reason = loadstring(source)
assert(type(start) == "function", reason or "School Hub bootstrap could not be compiled.")
task.defer(start)
