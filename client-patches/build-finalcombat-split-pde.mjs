import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PdeArchive,luaStrings,sha256} from './pde-format.mjs';
import {embedOriginal} from './lua-chunk.mjs';
import {appendResources} from './pde-batch.mjs';

const input=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const stage=path.resolve(process.argv[3]??'.tmpbuild/finalcombat-actors/split');
const basePde=path.resolve(process.argv[4]??'.tmpbuild/pde-native-compression/AvatarStar.rebuilt.pde');
const manifest=JSON.parse(fs.readFileSync(path.join(input,'manifest.json'),'utf8'));
const limit=0x80000000;
const run=(exe,args)=>{const r=spawnSync(exe,args,{stdio:'inherit'});if(r.error||r.status!==0)throw r.error??Error(exe+' exited '+r.status);};
if(fs.existsSync(path.join(stage,'AvatarStar.pde')))throw Error('Choose a clean output stage');
fs.mkdirSync(stage,{recursive:true});
const extra=path.join(stage,'actor-resources'),hook='scripts/newsys/custommaps.lua';
for(const file of manifest.resources.filter(p=>p!==hook)){
 const dest=path.join(extra,file);fs.mkdirSync(path.dirname(dest),{recursive:true});
 fs.copyFileSync(path.join(input,'resources',file),dest);
}
const marker='finalcombat/actors.mounted';
fs.mkdirSync(path.join(extra,'finalcombat'),{recursive:true});
fs.writeFileSync(path.join(extra,marker),'AvatarStar actor resources v1\n');
const loader=path.join(stage,'mount-actor-pack.luac');
run(path.resolve('tools/unpdec/Release/Lua/luac.exe'),['-o',loader,'client-patches/mount-actor-pack.lua']);
const code=embedOriginal(fs.readFileSync(loader),fs.readFileSync(path.join(input,'resources',hook)));
luaStrings(code);
const replacement=path.join(stage,'custommaps.luac');fs.writeFileSync(replacement,code);
const main=path.join(stage,'AvatarStar.pde'),actors=path.join(stage,'AvatarStar_actors.pde');
fs.copyFileSync(basePde,main);
const mainPatch=appendResources(main,new Map([[hook,replacement]]));
if(fs.statSync(main).size>=limit)throw Error('Main archive exceeds native signed seek limit');
console.log('Main archive ready',fs.statSync(main).size);
const adapter=path.resolve('.tmpbuild/pde-rebuild/pack-adapter/bin/Release/net8.0/PackAdapter.dll');
run('dotnet',[adapter,'pack',extra,actors]);
if(fs.statSync(actors).size>=limit)throw Error('Actor archive exceeds native signed seek limit');

// Verify the union against the already validated complete build. The only
// changed original resource is the startup hook that mounts the second archive.
const a=new PdeArchive(main),b=new PdeArchive(actors),index=new Map();
for(const archive of [a,b])for(const entry of archive.entries().filter(e=>e.type===1)){
 if(index.has(entry.path.toLowerCase()))throw Error('Duplicate resource between split archives: '+entry.path);
 for(const block of archive.blocks(entry.block,entry.size))if(archive.real(block)+4096>limit)throw Error('Unreachable native file block');
 index.set(entry.path.toLowerCase(),{archive,entry});
}
let checked=0;
const walk=(dir,prefix='')=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name),prefix+e.name+'/'):[prefix+e.name]);
const complete=path.join(input,'all-resources'),all=walk(complete);
for(const file of all){const item=index.get(file.toLowerCase());if(!item)throw Error('Missing split resource '+file);
 const expected=file===hook?code:fs.readFileSync(path.join(complete,file));
 if(!item.archive.data(item.entry).equals(expected))throw Error('Split resource mismatch '+file);
 if(++checked%5000===0)console.log('Verified split resources',checked);
}
if(index.size!==all.length+1)throw Error('Unexpected split archive inventory');
a.close();b.close();
const report={version:1,nativeSeekLimit:limit,cards:manifest.cards.length,weapons:manifest.weapons.length,verifiedAt:new Date().toISOString(),files:checked,marker,
 main:{path:main,bytes:fs.statSync(main).size},actors:{path:actors,bytes:fs.statSync(actors).size},hookSha256:sha256(code),mainPatch};
fs.writeFileSync(path.join(stage,'split-verification.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({files:checked,main:report.main,actors:report.actors}));
