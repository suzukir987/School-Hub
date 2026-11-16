-- School Hub: exact approved bootstrap, one native scheduler handoff.
local source = game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/849419de4518149ff8acd57263d5ad1e85dd59f3/bootstrap.lua")
local start, reason = loadstring(source)
assert(type(start) == "function", reason or "School Hub bootstrap could not be compiled.")
task.defer(start)
