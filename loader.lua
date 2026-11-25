-- School Hub: exact approved bootstrap, one native scheduler handoff.
local source = game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/3492c246a4c2bc56899b73e8dca5beeec5741910/bootstrap.lua")
local start, reason = loadstring(source)
assert(type(start) == "function", reason or "School Hub bootstrap could not be compiled.")
task.defer(start)
