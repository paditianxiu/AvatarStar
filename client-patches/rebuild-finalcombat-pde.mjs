import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PdeArchive,decodeCache,luaStrings,sha256} from './pde-format.mjs';
import {cacheHeader,encodeCache,rekeyCache} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {embedOriginal} from './lua-chunk.mjs';

const [baseline,importStage='.tmpbuild/finalcombat-maps/import',stage='.tmpbuild/pde-rebuild']=process.argv.slice(2);
if(!baseline)throw Error('Usage: node client-patches/rebuild-finalcombat-pde.mjs <pre-import.pde> [import-stage] [output-stage]');
const manifest=JSON.parse(fs.readFileSync(path.join(importStage,'manifest.json'),'utf8'));
if(fs.statSync(baseline).size!==manifest.originalSize)throw Error('Use the complete pre-import backup as the baseline');
const source=path.resolve(stage,'all-resources'),resources=path.resolve(stage,'resources');
if(fs.existsSync(source))throw Error('Use a fresh output stage to avoid packing stale files');
fs.mkdirSync(source,{recursive:true});
function run(exe,args){const r=spawnSync(exe,args,{stdio:'inherit'});if(r.error||r.status!==0)throw r.error??Error(exe+' exited '+r.status);}
run(process.execPath,['client-patches/build-unpdec-adapter.mjs']);
const adapter=path.resolve('.tmpbuild/pde-rebuild/pack-adapter/bin/Release/net8.0/PackAdapter.dll');
const archive=new PdeArchive(baseline),entries=archive.entries();
let extracted=0;
for(const e of entries){const file=path.join(source,e.path);if(e.type===2)fs.mkdirSync(file,{recursive:true});else {fs.writeFileSync(file,archive.data(e));if(++extracted%5000===0)console.log('Extracted',extracted);}}
// Import work directories can contain obsolete outputs from earlier prepare
// runs (including reserved LEVEL99). Only copy the manifest's exact inventory.
for(const file of manifest.resources){const out=path.join(resources,file);fs.mkdirSync(path.dirname(out),{recursive:true});fs.copyFileSync(path.join(importStage,'resources',file),out);}
function compile(name,virtual){
 const lua=path.resolve(importStage,'lua',name+'.lua'),out=path.resolve(stage,'lua',name+'.luac');fs.mkdirSync(path.dirname(out),{recursive:true});
 run(path.resolve('tools/unpdec/Release/Lua/luac.exe'),['-o',out,lua]);
 let bytes=fs.readFileSync(out);
 // Same virtual source-path operation as PDELuac. Do not compile decompiled
 // original UI scripts: retain their exact prototypes with embedOriginal.
 const oldLength=bytes.readUInt32LE(12),nameBytes=Buffer.from('@/'.concat(virtual,'\0')),length=Buffer.alloc(4);length.writeUInt32LE(nameBytes.length);
 bytes=Buffer.concat([bytes.subarray(0,12),length,nameBytes,bytes.subarray(16+oldLength)]);luaStrings(bytes);fs.writeFileSync(out,bytes);return bytes;
}
for(const m of manifest.maps){
 const file=path.join(resources,m.script+'.cache'),template=fs.readFileSync(file),code=compile(m.code,m.script),full=Buffer.alloc(8+code.length);
 full.writeUInt32LE(0xA01);full.writeUInt32LE(code.length,4);code.copy(full,8);fs.writeFileSync(file,encodeCache(full,template,'/'+m.script));
}
const custom='scripts/newsys/custommaps.lua';
fs.writeFileSync(path.join(resources,custom),embedOriginal(compile('custommaps-finalcombat',custom),archive.data(entries.find(e=>e.path===custom))));
archive.close();
const compressed=[];
for(const file of manifest.resources){
 if(!file.endsWith('.cache'))continue;
 const cache=fs.readFileSync(path.join(resources,file)),header=cacheHeader(cache);if(cache[header.base+12]!==0x6e)continue;
 const raw=decodeCache(cache,false),input=path.resolve(stage,'compression-input.bin'),output=path.resolve(stage,'compression-output.bin');fs.writeFileSync(input,raw);
 run('dotnet',[adapter,'compress',input,output]);
 const data=fs.readFileSync(output),b=Buffer.alloc(33+data.length);cache.copy(b,0,0,8);b.writeUInt32LE(9+data.length,12);b.writeUInt32LE(1,20);b[24]=0x6f;b.writeUInt32LE(9+data.length,25);b.writeUInt32LE(raw.length,29);data.copy(b,33);
 if(!raw.equals(decodeCache(b,false)))throw Error('Compressed payload mismatch: '+file);
 if(!raw.equals(decodeCacheNative(b,false,{fill:0xcd})))throw Error('Client decoder mismatch: '+file);
 const result=rekeyCache(b,'/'+file.replace(/\.cache$/,'').replace(/\.physx$/,'.mesh'));
 fs.writeFileSync(path.join(resources,file),result);compressed.push({file,raw:raw.length,compressed:b.length,sha256:sha256(raw)});
}
fs.cpSync(resources,source,{recursive:true});
manifest.target=path.resolve(baseline);manifest.verifiedPde=path.resolve(stage,'AvatarStar.rebuilt.pde');manifest.packMode='unpdec-full';manifest.nativeCompression='quicklz-distance-at-least-3';manifest.rebuiltAt=new Date().toISOString();
fs.writeFileSync(path.join(stage,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');fs.writeFileSync(path.join(stage,'compression-report.json'),JSON.stringify(compressed,null,2)+'\n');
run('dotnet',[adapter,'pack',source,manifest.verifiedPde]);
if(fs.statSync(manifest.verifiedPde).size>=0x80000000)throw Error('Rebuilt archive exceeds the conservative 2 GiB compatibility limit');
run(process.execPath,['client-patches/verify-finalcombat-maps.mjs',stage]);
run(process.execPath,['client-patches/verify-unpdec-pde.mjs',stage]);
console.log('Verified PDE: '+manifest.verifiedPde);
