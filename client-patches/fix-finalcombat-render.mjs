import fs from 'node:fs';import path from 'node:path';import {spawnSync} from 'node:child_process';
import {decodeCache,sha256} from './pde-format.mjs';
import {cacheHeader,encodeCache,rekeyCache} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {readStaticMesh,writeStaticMesh,avatarStarBlendMode} from './scene-mesh.mjs';

const [previous='.tmpbuild/pde-rebuild',stage='.tmpbuild/pde-render/fixed']=process.argv.slice(2);
if(fs.existsSync(stage))throw Error('Use a fresh render-fix stage');
fs.mkdirSync(stage,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(previous,'manifest.json'),'utf8'));
const resources=path.join(stage,'resources'),all=path.join(stage,'all-resources');
function run(exe,args){const r=spawnSync(exe,args,{stdio:'inherit'});if(r.error||r.status!==0)throw r.error??Error(exe+' exited '+r.status);}
run(process.execPath,['client-patches/build-unpdec-adapter.mjs']);
const adapter=path.resolve('.tmpbuild/pde-rebuild/pack-adapter/bin/Release/net8.0/PackAdapter.dll');
fs.cpSync(path.join(previous,'all-resources'),all,{recursive:true});
for(const file of manifest.resources){const dest=path.join(resources,file);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join(previous,'resources',file),dest);}
const compression=JSON.parse(fs.readFileSync(path.join(previous,'compression-report.json'),'utf8')),changes=[];
for(const map of manifest.maps){
 const relative=map.mesh+'.cache',file=path.join(resources,relative),cache=fs.readFileSync(file),mesh=readStaticMesh(decodeCache(cache,false),10);
 const source=fs.readFileSync(path.join(manifest.source,'mesh/scene',map.sourceScene,'scene.mesh.cache')),original=readStaticMesh(decodeCache(source,false),cacheHeader(source).version);
 if(mesh.primitives.length!==original.primitives.length)throw Error('Primitive count changed: '+map.code);
 const modes={};
 mesh.primitives.forEach((p,i)=>{
  const before=original.primitives[i],expected=avatarStarBlendMode(before.blend);
  if(!p.vb.equals(before.vb)||!p.ib.equals(before.ib))throw Error('Geometry changed: '+map.code);
  if(p.blend!==before.blend&&p.blend!==expected)throw Error('Unexpected existing blend value: '+map.code);
  p.blend=expected;modes[before.blend+' -> '+expected]=(modes[before.blend+' -> '+expected]??0)+1;
 });
 fs.writeFileSync(file,encodeCache(writeStaticMesh(mesh),cache,'/'+map.mesh,10));
 changes.push({map:map.code,primitives:mesh.primitives.length,modes});console.log(map.code,modes);
}
// Recompress the complete converted inventory. Old stages also contain shaders
// and Lua packed with distance-1/2 matches which the client cannot decode.
for(const entry of compression){
 const relative=entry.file,file=path.join(resources,relative),cache=fs.readFileSync(file),raw=decodeCache(cache,false);
 const input=path.resolve(stage,'compression-input.bin'),output=path.resolve(stage,'compression-output.bin');fs.writeFileSync(input,raw);
 run('dotnet',[adapter,'compress',input,output]);
 const data=fs.readFileSync(output),packed=Buffer.alloc(33+data.length);cache.copy(packed,0,0,8);packed.writeUInt32LE(9+data.length,12);packed.writeUInt32LE(1,20);packed[24]=0x6f;packed.writeUInt32LE(9+data.length,25);packed.writeUInt32LE(raw.length,29);data.copy(packed,33);
 if(!decodeCache(packed,false).equals(raw)||!decodeCacheNative(packed,false,{fill:0xcd}).equals(raw))throw Error('Client compression mismatch: '+relative);
 const result=rekeyCache(packed,'/'+relative.replace(/\.cache$/,'').replace(/\.physx$/,'.mesh'));fs.writeFileSync(file,result);
 Object.assign(entry,{raw:raw.length,compressed:packed.length,sha256:sha256(raw),ok:true});
}
for(const relative of manifest.resources){
 const file=path.join(resources,relative),bytes=fs.readFileSync(file);
 if(relative.endsWith('.cache')&&!decodeCacheNative(bytes,false,{fill:0xcd}).equals(decodeCache(bytes,false)))throw Error('Preserved cache is incompatible: '+relative);
 fs.copyFileSync(file,path.join(all,relative));
}
manifest.renderFix='avatarstar-blend-flags-v1';manifest.nativeCompression='quicklz-distance-at-least-3';manifest.verifiedPde=path.resolve(stage,'AvatarStar.rebuilt.pde');manifest.rebuiltAt=new Date().toISOString();
fs.writeFileSync(path.join(stage,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');fs.writeFileSync(path.join(stage,'compression-report.json'),JSON.stringify(compression,null,2)+'\n');fs.writeFileSync(path.join(stage,'render-fix.json'),JSON.stringify(changes,null,2)+'\n');
run('dotnet',[adapter,'pack',all,manifest.verifiedPde]);
if(fs.statSync(manifest.verifiedPde).size>=0x80000000)throw Error('PDE exceeds compatibility size limit');
run(process.execPath,['client-patches/verify-finalcombat-maps.mjs',stage]);
run(process.execPath,['client-patches/verify-unpdec-pde.mjs',stage]);
console.log('Verified render fix: '+manifest.verifiedPde);
