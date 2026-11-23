-- School Hub: exact approved bootstrap, one native scheduler handoff.
local source = game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/a7a8d1dbea29bc52b242191b2d4a0bf5799e56cf/bootstrap.lua")
local start, reason = loadstring(source)
assert(type(start) == "function", reason or "School Hub bootstrap could not be compiled.")
task.defer(start)
