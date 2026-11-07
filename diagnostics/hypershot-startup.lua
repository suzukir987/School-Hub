-- School Hub: bounded Hypershot compatibility probe; no license/device data.
-- No gameplay functions, purchases, remote calls, hooks or captured code.
local env=_G
if type(getgenv)=="function"then local ok,value=pcall(getgenv);if ok and type(value)=="table"then env=value end end
if type(env.SchoolHubHypershotStartupProbe)=="table"and env.SchoolHubHypershotStartupProbe.running then
    warn("School Hub: startup check is already running.");return
end
local file="school_hub_hypershot_startup_probe.json"
local report={format=1,build="hypershot-startup-probe-20261107-v1",running=true,completed=false,stage="initial",calls={},capabilities={}}
env.SchoolHubHypershotStartupProbe=report
local http=game:GetService("HttpService")
local write=env.writefile or writefile
local function clean(value)return tostring(value):gsub("[%c]"," "):sub(1,160)end
local function save(stage)
    report.stage=stage
    if type(write)=="function"then
        local ok,body=pcall(http.JSONEncode,http,report)
        if ok and type(body)=="string"and #body<=30000 then
            local saved=pcall(write,file,body);report.fileWritten=saved
        end
    end
end
local builtins={getloadedmodules=getloadedmodules,identifyexecutor=identifyexecutor,getexecutorname=getexecutorname,
    request=request,http_request=http_request,readfile=readfile,writefile=writefile,getconnections=getconnections,
    gethui=gethui,loadstring=loadstring,getconstants=debug and debug.getconstants}
local function cap(name)return type(env[name])=="function"and env[name]or type(builtins[name])=="function"and builtins[name]or nil end
local function call(name,fn,...)
    save("before:"..name)
    local ok,value=pcall(fn,...)
    report.calls[#report.calls+1]={name=name,ok=ok,resultType=type(value),error=not ok and clean(value)or nil}
    save("after:"..name)
    return ok,value
end
local function run()
    report.placeId=tostring(game.PlaceId);report.universeId=tostring(game.GameId)
    for name in pairs(builtins)do report.capabilities[name]=cap(name)~=nil end
    for _,name in ipairs({"getloadedmodules","identifyexecutor","getexecutorname","request","http_request","readfile","writefile","getconnections","gethui","loadstring","getconstants"})do
        report.capabilities[name]=cap(name)~=nil
    end
    local identify=cap("identifyexecutor")or cap("getexecutorname")
    if identify then local ok,name=call("executor-name",identify);if ok then report.executor=clean(name)end end
    local places={[17516596118]=true,[86696142930150]=true,[92980558919575]=true,[97804379417079]=true,
        [100040622766961]=true,[105357751512007]=true,[108428559529058]=true,[110169684430399]=true,
        [122181485177067]=true,[128220027114734]=true,[131008473296170]=true,[134474332601640]=true}
    if game.GameId~=5995470825 or not places[game.PlaceId]then
        report.unsupportedPlace=true;return
    end
    local loadedModules=cap("getloadedmodules")
    if not loadedModules then report.missing="getloadedmodules";return end
    local ok,list=call("getloadedmodules",loadedModules)
    if not ok or type(list)~="table"then return end
    local loaded,count={},0
    for _,module in pairs(list)do count=count+1;if count>50000 then report.inventoryTruncated=true;break end;loaded[module]=true end
    report.loadedModuleCount=count
    local storage=game:GetService("ReplicatedStorage")
    local players=game:GetService("Players");local player=players.LocalPlayer
    local gui=player and player:FindFirstChildOfClass("PlayerGui")
    local paths={
        {"entities",storage,"Entity.EntityClient"},{"prediction",storage,"Entity.EntityPrediction"},
        {"shot",storage,"Entity.ShotClient"},{"weaponSim",storage,"Entity.WeaponSim"},
        {"trace",storage,"Entity.ShotTrace"},{"hitboxes",storage,"Entity.Hitboxes"},
        {"config",storage,"Entity.EntityConfig"},{"movement",storage,"Entity.MovementSim"},
        {"characters",storage,"Modules.ClientCharacters"},{"global",storage,"Modules.GlobalStuff"},
        {"network",storage,"Modules.NetworkModule2"},{"controller",gui,"ControllerGUI.NewMainLocal.Controller"},
        {"action",gui,"FirstPersonGUI.ActionHandler"},{"fpShared",gui,"FirstPersonGUI.ActionHandler.Shared"},
        {"menuShared",gui,"MenuUI.MenuLocal.Shared"},{"dailyPage",gui,"MenuUI.MenuLocal.DailyRewardPage"},
        {"playtimePage",gui,"MenuUI.MenuLocal.PlaytimeRewardPage"},{"questPage",gui,"MenuUI.MenuLocal.QuestsPage"},
        {"achievementPage",gui,"MenuUI.MenuLocal.AchievementFTUEPage"},{"eventPage",gui,"MenuUI.MenuLocal.ClassicEventPage"},
        {"battlepassPage",gui,"MenuUI.MenuLocal.BattlepassPage"},
    }
    report.modules={}
    for _,entry in ipairs(paths)do
        local name,node=entry[1],entry[2]
        for part in entry[3]:gmatch("[^.]+")do node=node and node:FindFirstChild(part);if not node then break end end
        local cached=node and node:IsA("ModuleScript")and loaded[node]==true or false
        report.modules[name]={found=node~=nil,cached=cached}
        -- Never require a module absent from the executor's already-loaded inventory.
        if cached then
            local got,value=call("cached-require:"..name,require,node)
            report.modules[name].ok=got;report.modules[name].resultType=type(value)
        end
    end
end
save("initial")
local ok,why=pcall(run)
if not ok then report.error=clean(why)end
report.running=false;report.completed=true;report.success=ok
save("done")
print("School Hub startup check: Done. Send "..file)
if type(write)~="function"then print(http:JSONEncode(report))end
return report
