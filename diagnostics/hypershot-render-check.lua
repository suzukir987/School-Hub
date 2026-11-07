local Trace=(function()
-- Full startup diagnostic for the exact published build. Console output only.
-- Private bytes still pass the original key/proof/hash checks. No keys, URLs,
-- response bodies or arbitrary exception messages are written to the console.
local Trace={Build='hypershot-full-startup-trace-20261107-v1'}
Trace.PublishedUrl='https://raw.githubusercontent.com/suzukir987/School-Hub/63bf183c9f3ac8d014a797e222b8eea6c99bf281/bootstrap.lua'
Trace.PublishedBytes=6782547
Trace.ApiNeedle='return function(options)return Runtime.Start(Common,Modules,options)end'
Trace.ApiReplacement=[=[return function(options)
 options=options or{}
 local emit=options.SchoolHubStartupTrace
 if type(emit)~='function'then return Runtime.Start(Common,Modules,options)end
 local function around(stage,fn,...)
  emit(stage..':before')
  local values=table.pack(pcall(fn,...))
  if not values[1]then emit(stage..':error');error(values[2],0)end
  emit(stage..':after')
  return(table.unpack or unpack)(values,2,values.n)
 end
 local create=Modules.Digest.Create
 Modules.Digest.Create=function(...)
  local digest,backend=around('digest-provider',create,...)
  emit('digest-backend:'..tostring(backend))
  return function(value,...)
   if type(value)=='string'and #value>=262144 then return around('hash-large-'..#value,digest,value,...)end
   return digest(value,...)
  end,backend
 end
 local prepare=Modules.NativeStartup.Prepare
 Modules.NativeStartup.Prepare=function(...)
  local tx=around('native-prepare',prepare,...)
  if type(tx)=='table'and type(tx.Commit)=='function'then
   local commit=tx.Commit
   tx.Commit=function(...)return around('native-commit',commit,...)end
  end
  return tx
 end
 return around('public-runtime',Runtime.Start,function(...)return around('public-common',Common,...)end,Modules,options)
end]=]
local function pack(...)return{n=select('#',...),...}end
local function first(...)for i=1,select('#',...)do local v=select(i,...);if type(v)=='function'then return v end end end
function Trace.Patch(source)
 assert(type(source)=='string'and #source==Trace.PublishedBytes,'Unexpected published bootstrap size')
 local at=source:find(Trace.ApiNeedle,1,true)
 assert(at and not source:find(Trace.ApiNeedle,at+#Trace.ApiNeedle,true),'Unexpected published bootstrap entry')
 local ending='\nreturn start()\n';assert(source:sub(-#ending)==ending,'Unexpected published bootstrap ending')
 source=source:sub(1,at-1)..Trace.ApiReplacement..source:sub(at+#Trace.ApiNeedle)
 return source:sub(1,-#ending-1)..'\nreturn start\n'
end
function Trace.Run(options)
 options=options or{}
 local env=options.env or _G
 if not options.env and type(getgenv)=='function'then local ok,v=pcall(getgenv);if ok and type(v)=='table'then env=v end end
 local previous=env.SchoolHubHypershotFullStartupTrace
 if type(previous)=='table'and previous.running then return nil,'already-running'end
 local report={build=Trace.Build,running=true,stage='initial',sequence=0,completed=false};env.SchoolHubHypershotFullStartupTrace=report
 local output=options.print or print
 local wait=options.wait or(task and task.wait)
 local function mark(stage)
  report.stage=stage;report.sequence=report.sequence+1
  if type(output)=='function'then pcall(output,'[School Hub Trace] '..report.sequence..' STAGE='..stage)end
  -- Only before potentially failing operations. Never change thread identity.
  if stage:sub(-7)==':before'and type(wait)=='function'then pcall(wait,.35)end
 end
 local function around(stage,fn,...)
  mark(stage..':before');local values=pack(pcall(fn,...))
  if not values[1]then mark(stage..':error');error(values[2],0)end
  mark(stage..':after');return(table.unpack or unpack)(values,2,values.n)
 end
 local function execute()
  mark('build:'..Trace.Build)
  mark(options.isolateRender and'mode:render-off'or'mode:full-trace')
  if options.enforcePlace~=false then
   assert(game.GameId==5995470825,'Open Hypershot before this diagnostic')
  end
  local fetch=options.fetch or function(url)return game:HttpGet(url)end
  local compiler=options.compile or loadstring;assert(type(compiler)=='function','Compiler unavailable')
  local source=around('public-download',fetch,Trace.PublishedUrl)
  source=Trace.Patch(source)
  local chunk=around('public-compile',compiler,source,'@SchoolHubFullStartupTrace');source=nil
  assert(type(chunk)=='function','Published bootstrap could not compile')
  local start=around('public-evaluate',chunk);chunk=nil
  assert(type(start)=='function','Published bootstrap API unavailable')
  local synTable=type(env.syn)=='table'and env.syn or{}
  local httpTable=type(env.http)=='table'and env.http or{}
  local nativeRequest=options.request or first(env.request,request,env.http_request,http_request,env.syn_request,syn_request,synTable.request,httpTable.request)
  local downloads=0
  local runtimeOptions={env=env,SchoolHubStartupTrace=mark}
  if nativeRequest then runtimeOptions.request=function(spec)
   local label='request'
   if type(spec)=='table'then
    if spec.Method=='GET'then downloads=downloads+1;label=downloads%2==1 and'download-common'or'download-game'
    elseif type(spec.Url)=='string'and spec.Url:find('/api/hub/session',1,true)then downloads=0;label='authentication'
    elseif type(spec.Url)=='string'and spec.Url:find('/api/hub/started',1,true)then
     -- Diagnostic runs never fabricate or submit a successful-start receipt.
     mark('startup-receipt-skipped');return{StatusCode=503,Body='Diagnostic receipt disabled.'}
    end
   end
   return around(label,nativeRequest,spec)
  end end
  runtimeOptions.compile=function(body,name)
   local kind=name=='School Hub common'and'private-common'or'private-game'
   local fn,why=around('compile-'..kind,compiler,body,name)
   if type(fn)~='function'then return fn,why end
   return function(...)
    local factory=around('evaluate-'..kind,fn,...)
    if type(factory)~='function'then return factory end
    return function(...)
     local value=around('instantiate-'..kind,factory,...)
     if kind=='private-game'and type(value)=='table'and type(value.launch)=='function'then
      local launch=value.launch
      value.launch=function(...)
       local values=pack(around('game-start',launch,...))
       if options.isolateRender then
        mark('hypershot-render-disabling')
        game:GetService('RunService'):UnbindFromRenderStep('SchoolHubHypershotRender')
        mark('hypershot-render-disabled')
        report.renderDisabled=true
       end
       return(table.unpack or unpack)(values,1,values.n)
      end
     end
     return value
    end
   end
  end
  local handle,reason=around('loader-start',start,runtimeOptions)
  if not handle then mark('loader-refused');return nil,reason end
  report.handle=handle;mark('loader-returned')
  local schedule=options.delay or(task and task.delay)
  if type(schedule)=='function'then
   for _,seconds in ipairs({2,5,10,20})do pcall(schedule,seconds,function()
    local ok,status=pcall(handle.Status)
    if ok and type(status)=='table'and status.started then
     mark('hub-alive-'..seconds..'s')
     if seconds==20 then report.completed=true;mark('trace-completed')end
    elseif ok and type(status)=='table'and status.recoveryRequired then mark('startup-recovery-required')end
   end)end
  end
  return handle,reason
 end
 local values=pack(pcall(execute));report.running=false
 if not values[1]then mark('diagnostic-error');return nil,'Diagnostic stopped; send the final STAGE lines.'end
 return(table.unpack or unpack)(values,2,values.n)
end
return Trace

end)()
return Trace.Run({isolateRender=true})
