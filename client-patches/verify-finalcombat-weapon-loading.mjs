import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PdeArchive,decodeCache} from './pde-format.mjs';
import {cacheHeader,cacheChecksum} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';

// Execute the packed weapon chunks with the matching Lua VM. Resolve SetMesh
// through the client's /mesh/weapon/ root, independently of the import manifest.
const stage=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const packed=process.argv[3],vm=path.resolve(process.argv[4]??'.tmpbuild/finalcombat-actors/black-screen/lua.exe');
const manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8'));
const output=path.join(stage,'weapon-loading');fs.mkdirSync(output,{recursive:true});
const archive=packed?new PdeArchive(packed):null;
const index=archive?new Map(archive.entries().filter(e=>e.type===1).map(e=>[e.path.toLowerCase(),e])):null;
const walk=(dir,prefix='')=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name),prefix+e.name+'/'):[prefix+e.name]);
const available=new Set([...walk(manifest.baseline),...(index?index.keys():walk(path.join(stage,'resources')))].map(p=>'/'+p.toLowerCase()));
// Native HUD icons can live in the language pack rather than the main archive.
for(const name of fs.readdirSync('C:/Game/AvatarStar').filter(n=>/^AvatarStar_[a-z]{2}_[a-z]{2}\.pde$/.test(n))){
 const language=new PdeArchive('C:/Game/AvatarStar/'+name);
 try{for(const e of language.entries())if(e.type===1)available.add('/'+e.path.toLowerCase());}finally{language.close();}
}
function read(p){const e=index?.get(p);return e?archive.data(e):fs.readFileSync(path.join(index?manifest.baseline:stage+'/resources',p));}
const quote=s=>JSON.stringify(s.replaceAll('\\','/'));
try{
 const lines=['local available = {',...Array.from(available,p=>`[${quote(p)}]=true,`),'}',
  'local function requireResource(p) assert(available[string.lower(p)..".cache"], "Missing client resource: "..p) end',
  // Missing optional icons in native templates already return null in game.
  // Imported textures are required; this test focuses on weapon assembly.
  'function texture(p) if string.find(p,"^/finalcombat/") then requireResource(p) end return available[string.lower(p)..".cache"] and p or nil end',
  'local weapons, parts = 0, 0'];
 for(const w of manifest.weapons){
  const p='weapon/'+w.resource+'.lua.cache',bytes=read(p),h=cacheHeader(bytes),raw=decodeCache(bytes,false);
  if(cacheChecksum(bytes,'/'+p.slice(0,-6))!==bytes.readUInt32LE(h.base+4)||!decodeCacheNative(bytes,false,{fill:0xcd}).equals(raw))throw Error('Invalid weapon cache '+p);
  const chunk=path.join(output,w.resource+'.luac');fs.writeFileSync(chunk,raw.subarray(8));
  lines.push('do local count = 0',
   'weapon = {SetMesh = function(self, part, mesh) requireResource("/mesh/weapon/"..mesh); count=count+1 end}',
   `assert(loadfile(${quote(chunk)}))()`,
   'requireResource(weapon.skeleton)',
   `assert(weapon.name==${quote(w.resource)} and count==${w.models.length}, "Weapon assembly mismatch")`,
   'parts=parts+count; weapons=weapons+1 end');
 }
 lines.push('print("Weapon scripts: "..weapons.."; resolved model parts: "..parts)');
 const harness=path.join(output,'check-loading.lua');fs.writeFileSync(harness,lines.join('\n')+'\n');
 const result=spawnSync(vm,[harness],{encoding:'utf8'});
 if(result.error||result.status!==0)throw result.error??Error(result.stdout+result.stderr);
 const report={weapons:manifest.weapons.length,parts:manifest.weapons.reduce((n,w)=>n+w.models.length,0),pack:packed??null,verifiedAt:new Date().toISOString(),output:result.stdout.trim()};
 fs.writeFileSync(path.join(output,'verification.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}finally{archive?.close();}
