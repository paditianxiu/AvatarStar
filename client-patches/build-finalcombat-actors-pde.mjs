import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PdeArchive,decodeCache,sha256} from './pde-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {cacheHeader,rekeyCache} from './cache-format.mjs';

const stage=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import'),manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8'));
const run=(exe,args)=>{const r=spawnSync(exe,args,{stdio:'inherit'});if(r.error||r.status!==0)throw r.error??Error(exe+' exited '+r.status);};
const source=path.join(stage,'all-resources'),resources=path.join(stage,'resources'),compress=path.join(stage,'compression');fs.mkdirSync(compress,{recursive:true});
run(process.execPath,['client-patches/build-unpdec-adapter.mjs']);
const adapter=path.resolve('.tmpbuild/pde-rebuild/pack-adapter/bin/Release/net8.0/PackAdapter.dll'),jobs=[];
for(const file of manifest.resources.filter(p=>p.endsWith('.cache'))){const b=fs.readFileSync(path.join(resources,file)),raw=decodeCache(b,false),h=cacheHeader(b);if(b[h.base+12]===0x6e){const input=path.join(compress,jobs.length+'.raw'),output=path.join(compress,jobs.length+'.qlz');fs.writeFileSync(input,raw);jobs.push({file,input,output,sha256:sha256(raw)});}else if(!decodeCacheNative(b,false,{fill:0xcd}).equals(raw))throw Error('Source compression is incompatible: '+file);}
fs.writeFileSync(path.join(compress,'jobs.json'),JSON.stringify(jobs));run('dotnet',[adapter,'compress-list',path.join(compress,'jobs.json'),path.join(compress,'complete.txt')]);
const report=[];
for(const job of jobs){const raw=fs.readFileSync(job.input),data=fs.readFileSync(job.output),file=path.join(resources,job.file),template=fs.readFileSync(file),b=Buffer.alloc(33+data.length);template.copy(b,0,0,8);b.writeUInt32LE(data.length+9,12);b.writeUInt32LE(1,20);b[24]=0x6f;b.writeUInt32LE(data.length+9,25);b.writeUInt32LE(raw.length,29);data.copy(b,33);
 if(!decodeCache(b,false).equals(raw)||!decodeCacheNative(b,false,{fill:0xcd}).equals(raw))throw Error('Native compression failed '+job.file);
 fs.writeFileSync(file,rekeyCache(b,'/'+job.file.replace(/\.cache$/,'')));report.push({file:job.file,raw:raw.length,compressed:b.length,sha256:job.sha256});
}
fs.writeFileSync(path.join(stage,'compression-report.json'),JSON.stringify(report,null,2)+'\n');
// Pack exactly the recorded native baseline plus this manifest, never stale outputs.
if(fs.existsSync(source))throw Error('Output already exists; choose a clean build stage');
fs.cpSync(manifest.baseline,source,{recursive:true});
for(const file of manifest.resources){const dest=path.join(source,file);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join(resources,file),dest);}
manifest.verifiedPde=path.join(stage,'AvatarStar.pde');run('dotnet',[adapter,'pack',source,manifest.verifiedPde]);
if(fs.statSync(manifest.verifiedPde).size>=0x80000000)throw Error('PDE exceeds the native signed 2 GiB seek limit; use build-finalcombat-split-pde.mjs');
fs.writeFileSync(path.join(stage,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const pde=new PdeArchive(manifest.verifiedPde),entries=pde.entries();let checked=0;
for(const e of entries.filter(e=>e.type===1)){const expected=fs.readFileSync(path.join(source,e.path));if(!pde.data(e).equals(expected))throw Error('Packed readback mismatch '+e.path);checked++;}
pde.close();fs.writeFileSync(path.join(stage,'pack-verification.json'),JSON.stringify({files:checked,bytes:fs.statSync(manifest.verifiedPde).size,compressedCaches:report.length,verifiedAt:new Date().toISOString()},null,2)+'\n');console.log('Packed and verified',checked,'files');
