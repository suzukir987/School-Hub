-- School Hub: bounded Hypershot compatibility probe; no license/device data.
-- No gameplay functions, purchases, remote calls, hooks or captured code.
local env=_G
if type(getgenv)=="function"then local ok,value=pcall(getgenv);if ok and type(value)=="table"then env=value end end
if type(env.SchoolHubHypershotStartupProbe)=="table"and env.SchoolHubHypershotStartupProbe.running then
    warn("School Hub: startup check is already running.");return
end
local file="school_hub_hypershot_startup_probe.json"
local report={format=1,build="hypershot-startup-probe-20261107-v2",running=true,completed=false,stage="initial",calls={},capabilities={}}
env.SchoolHubHypershotStartupProbe=report
local http=game:GetService("HttpService")
local write=env.writefile or writefile
local function clean(value)return tostring(value):gsub("[%c]"," "):sub(1,160)end
local output=print
local function console(message)
    if type(output)=="function"then pcall(output,"[School Hub Probe] "..message)end
end
local function save(stage)
    report.stage=stage
    console("STAGE="..stage)
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
    console("CALL="..name.." RESULT="..(ok and "OK ("..type(value)..")"or "ERROR: "..clean(value)))
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
    if not ok or type(list)~="table"then
        if ok then report.inventoryError="getloadedmodules returned "..type(list)..", expected table"end
        return
    end
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
local status="COMPLETED"
if report.unsupportedPlace then status="UNSUPPORTED_PLACE"
elseif report.missing then status="MISSING_API: "..report.missing
elseif report.error or report.inventoryError then status="ERROR"end
for _,entry in ipairs(report.calls)do if not entry.ok and status=="COMPLETED"then status="CALL_ERROR"end end
local found,cached,required=0,0,0
local absent,uncached={},{}
for name,module in pairs(report.modules or {})do
    if module.found then found=found+1 else absent[#absent+1]=name end
    if module.cached then cached=cached+1 elseif module.found then uncached[#uncached+1]=name end
    if module.ok then required=required+1 end
end
table.sort(absent);table.sort(uncached)
console("===== RESULT BEGIN =====")
console("BUILD="..report.build)
console("EXECUTOR="..(report.executor or "unknown"))
console("STATUS="..status)
local last=report.calls[#report.calls]
console("LAST_CALL="..(last and last.name or "none").." OK="..(last and tostring(last.ok)or "n/a"))
console("INVENTORY="..tostring(report.loadedModuleCount or 0).." FOUND="..found.." CACHED="..cached.." REQUIRE_OK="..required)
if report.error then console("ERROR="..report.error)end
if report.inventoryError then console("ERROR="..report.inventoryError)end
for _,entry in ipairs(report.calls)do if not entry.ok then console("FAILED_CALL="..entry.name.." ERROR="..(entry.error or "unknown"))end end
if #absent>0 then console("NOT_FOUND="..table.concat(absent,","))end
if #uncached>0 then console("NOT_CACHED="..table.concat(uncached,","))end
console("===== RESULT END =====")
return report
