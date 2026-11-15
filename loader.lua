-- School Hub: exact approved bootstrap, one native scheduler handoff.
local source = game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/8ec4114984f06a7222d1f9ec37901be9d7a05a66/bootstrap.lua")
local start, reason = loadstring(source)
assert(type(start) == "function", reason or "School Hub bootstrap could not be compiled.")
task.defer(start)
