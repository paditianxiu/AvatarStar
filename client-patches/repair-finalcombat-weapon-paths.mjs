import fs from 'node:fs';
import path from 'node:path';
import {decodeCache} from './pde-format.mjs';
import {rekeyCache,cacheHeader,cacheChecksum} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {appendResources} from './pde-batch.mjs';

const input=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const stage=path.resolve(process.argv[3]??'.tmpbuild/finalcombat-actors/weapon-path-fix');
const installed=path.resolve(process.argv[4]??'C:/Game/AvatarStar/AvatarStar_actors.pde');
const manifestFile=path.join(input,'manifest.json'),manifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
const candidate=path.join(stage,'AvatarStar_actors.pde');
if(fs.existsSync(candidate))throw Error('Choose a new repair output directory');
fs.mkdirSync(stage,{recursive:true});fs.copyFileSync(manifestFile,path.join(stage,'manifest.before.json'));
const replacements=new Map(),moves=new Map();
for(const w of manifest.weapons)for(const m of w.models){
 if(m.path.startsWith('mesh/prop/weapon/'))moves.set(m.path+'.cache',m.path.replace('mesh/prop/weapon/','mesh/weapon/')+'.cache');
 else if(!m.path.startsWith('mesh/weapon/'))throw Error('Unexpected weapon path '+m.path);
}
if(!moves.size)throw Error('No legacy weapon paths to repair');
for(const [oldName,newName] of moves){
 const original=fs.readFileSync(path.join(input,'resources',oldName)),fixed=rekeyCache(original,'/'+newName.slice(0,-6));
 const raw=decodeCache(original,false),h=cacheHeader(fixed);
 if(!decodeCache(fixed,false).equals(raw)||!decodeCacheNative(fixed,false,{fill:0xcd}).equals(raw)||cacheChecksum(fixed,'/'+newName.slice(0,-6))!==fixed.readUInt32LE(h.base+4))throw Error('Rekey verification failed '+newName);
 const out=path.join(stage,'resources',newName);fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,fixed);replacements.set(newName,out);
}
fs.copyFileSync(installed,candidate);
const report=appendResources(candidate,replacements);
// Keep generated inputs consistent so later rebuilds retain the correction.
for(const [oldName,newName] of moves)for(const folder of ['resources','all-resources']){
 const root=path.resolve(input,folder),oldFile=path.resolve(root,oldName),newFile=path.resolve(root,newName);
 if(!oldFile.startsWith(root+path.sep)||!newFile.startsWith(root+path.sep))throw Error('Resource path escaped generated input');
 if(folder==='all-resources'&&!fs.existsSync(root))continue;
 fs.mkdirSync(path.dirname(newFile),{recursive:true});fs.copyFileSync(replacements.get(newName),newFile);
 if(fs.existsSync(oldFile))fs.unlinkSync(oldFile);
}
for(const m of [...manifest.meshes,...manifest.weapons.flatMap(w=>w.models)])if(moves.has(m.path+'.cache'))m.path=moves.get(m.path+'.cache').slice(0,-6);
manifest.resources=manifest.resources.map(p=>moves.get(p)??p);
manifest.weaponPathRepair={at:new Date().toISOString(),models:moves.size,root:'/mesh/weapon/'};
fs.writeFileSync(manifestFile,JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync(path.join(stage,'repair-verification.json'),JSON.stringify({...report,weapons:manifest.weapons.length,models:moves.size,moves:Object.fromEntries(moves)},null,2)+'\n');
console.log({weapons:manifest.weapons.length,models:moves.size,bytes:report.newSize,candidate});
