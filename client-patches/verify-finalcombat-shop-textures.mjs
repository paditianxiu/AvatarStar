import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PdeArchive,decodeCache} from './pde-format.mjs';
import {cacheHeader,cacheChecksum} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';

const input=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const packed=path.resolve(process.argv[3]??'.tmpbuild/finalcombat-actors/shop-icons/AvatarStar_actors.pde');
const output=path.resolve(process.argv[4]??'.tmpbuild/finalcombat-actors/shop-icons/verification');
const manifest=JSON.parse(fs.readFileSync(path.join(input,'manifest.json'),'utf8'));
const archive=new PdeArchive(packed),index=new Map(archive.entries().filter(e=>e.type===1).map(e=>[e.path.toLowerCase(),e]));
fs.mkdirSync(path.join(output,'images'),{recursive:true});
const quote=s=>JSON.stringify(s.replaceAll('\\','/'));
try{
 const icons=[],lines=['local available = {'];
 for(const w of manifest.weapons){
  const p='ui/skinf/lobby/'+w.resource+'.tga.cache',entry=index.get(p);
  if(!entry)throw Error('Missing shop image '+p);
  const bytes=archive.data(entry),h=cacheHeader(bytes),raw=decodeCache(bytes,false);
  if(cacheChecksum(bytes,'/'+p.slice(0,-6))!==bytes.readUInt32LE(h.base+4)||!decodeCacheNative(bytes,false,{fill:0xcd}).equals(raw))throw Error('Invalid shop image cache '+p);
  const original=decodeCache(fs.readFileSync(path.join(input,'resources',w.icon.slice(1)+'.cache')),false);
  if(!raw.equals(original))throw Error('Shop image differs from source artwork '+p);
  fs.writeFileSync(path.join(output,'images',w.resource+'.tga'),raw.subarray(8));
  lines.push(`[${quote('/'+p.slice(0,-6))}]=true,`);icons.push(w.resource);
 }
 lines.push('}',
  'Gui = {Icon = function(p) p=string.lower(p); if string.sub(p,1,1)~="/" then p="/"..p end return available[p] and p or nil end}',
  'function Vector4(...) return {...} end',
  `assert(loadfile(${quote(path.join(manifest.baseline,'scripts/sys/iconsF.lua'))}))()`);
 // Execute the original compiled icon lookup, including its path construction.
 for(const name of icons)lines.push(`assert(IconsF.GetLobbySlotIcon(${quote(name)}), ${quote('Missing shop icon '+name)})`);
 lines.push(`print("Original UI icon lookup succeeded: ${icons.length}")`);
 const harness=path.join(output,'check-icons.lua');fs.writeFileSync(harness,lines.join('\n')+'\n');
 const r=spawnSync(path.resolve('.tmpbuild/finalcombat-actors/black-screen/lua.exe'),[harness],{encoding:'utf8'});
 if(r.error||r.status!==0)throw r.error??Error(r.stdout+r.stderr);
 const report={icons:icons.length,pack:packed,verifiedAt:new Date().toISOString(),lua:r.stdout.trim()};
 fs.writeFileSync(path.join(output,'verification.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
}finally{archive.close();}
