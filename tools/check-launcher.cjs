'use strict';
// No credentials or package dependencies. Run from a complete repository checkout.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),cp=require('node:child_process'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),read=name=>fs.readFileSync(path.join(root,name),'utf8');
const sha=value=>crypto.createHash('sha256').update(value).digest('hex'),record=JSON.parse(read('startup-profile.json'));
assert.equal(record.profile,'school-hub-startup-20261110-v1');
const bootstrap=read('bootstrap.lua'),loader=read('loader.lua');
assert.equal(sha(bootstrap),record.bootstrapSha256,'Bootstrap needs a matching reviewed startup proof');
assert.equal(sha(loader),record.loaderSha256,'Loader needs a matching reviewed entry proof');
const target=loader.match(/https:\/\/raw\.githubusercontent\.com\/suzukir987\/School-Hub\/([0-9a-f]{40})\/bootstrap\.lua/);
assert(target,'Loader target must be an immutable full commit');
const expected=`-- School Hub: exact approved bootstrap, one native scheduler handoff.
local source = game:HttpGet("https://raw.githubusercontent.com/suzukir987/School-Hub/${target[1]}/bootstrap.lua")
local start, reason = loadstring(source)
assert(type(start) == "function", reason or "School Hub bootstrap could not be compiled.")
task.defer(start)
`;
assert.equal(loader,expected,'Synchronous/mutable loader is retired');
assert.equal(target[1],record.loaderBootstrapCommit);
const pinned=cp.execFileSync('git',['show',target[1]+':bootstrap.lua'],{cwd:root,maxBuffer:20_000_000,windowsHide:true});
assert.equal(sha(pinned),record.loaderBootstrapSha256,'Pinned target differs from the approved loader target');
const begin='local start=(function(...)\n',end='\nend)()\nreturn start()\n';
assert(bootstrap.startsWith(begin)&&bootstrap.endsWith(end),'Unexpected public startup composition');
const api=bootstrap.slice(begin.length,-end.length);assert.equal(sha(api),record.apiSha256);
assert(api.includes("if stages<16 and task and type(task.wait)=='function'then stages=stages+1;task.wait()end"));
assert(api.includes("options={}for key,value in pairs(supplied)do options[key]=value end"));
assert(api.includes("local out=pack(fn(...))")&&api.includes('return unpackValues(out,1,out.n)'));
const first='local Common=(function(...)\n',last="\nend)()\n_SHNativeStage('common-cold-ready')\nlocal Modules=";
const a=api.indexOf(first),z=api.indexOf(last,a);assert(a>=0&&z>a,'Embedded common boundary missing');
const common=api.slice(a+first.length,z);assert.equal(sha(common),record.commonSha256);
assert(common.includes('__SHReadyPoolChunk=(function()return {')&&!common.includes('common-ready-pool-build'),'Prepared common profile missing or diagnostic payload');
assert(record.evidence.composed.checks>=170&&record.evidence.composed.cases>=15&&record.evidence.nativeBoundary.checks>=40&&record.evidence.loader.checks>=25,'Behavioral proof summary required');
console.log('PASS startup publication profile; immutable target, exact reviewed bytes, native boundaries and prepared common');
