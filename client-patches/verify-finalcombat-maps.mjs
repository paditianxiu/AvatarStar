import fs from 'node:fs';import path from 'node:path';
import {decodeCache,luaStrings,PdeArchive,sha256} from './pde-format.mjs';
import {cacheHeader,cacheChecksum} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {readStaticMesh,avatarStarBlendMode} from './scene-mesh.mjs';
import {prototypes} from './lua-chunk.mjs';
const stage=process.argv[2]??'.tmpbuild/finalcombat-maps/import',manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8'));
const a=new PdeArchive(manifest.verifiedPde),index=new Map(a.entries().map(e=>[e.path.toLowerCase(),e]));let checks=0;
function check(c,m){checks++;if(!c)throw Error(m);}
function read(p){const e=index.get(p.replace(/^\//,'').toLowerCase());check(!!e,'Missing resource: '+p);return a.data(e);}
function dependency(p){check(index.has(p.replace(/^\//,'').toLowerCase()),'Missing dependency: '+p);}
const shaders=new Map(manifest.shaders.map(s=>[s.target.replace(/^shader\//,'').replace(/\.[^.]+$/,''),s]));
for(const f of manifest.resources){const b=read(f);check(b.equals(fs.readFileSync(path.join(stage,'resources',f))),'Resource content mismatch '+f);
  if(f.endsWith('.cache')){let resource='/'+f.replace(/\.cache$/,'').replace(/\.physx$/,'.mesh');const h=cacheHeader(b);check(b.readUInt32LE(h.base+4)===cacheChecksum(b,resource),'CRC mismatch '+f);
    check(decodeCacheNative(b,false,{fill:0xcd}).equals(decodeCache(b,false)),'Native client decompression mismatch '+f);}}
const names=new Set(),ids=new Set();
for(const m of manifest.maps){check(!names.has(m.code)&&!ids.has(m.id),'Duplicate map ID');names.add(m.code);ids.add(m.id);
  check(m.code!=='LEVEL99','Reserved LEVEL99 overwritten');
  const mesh=readStaticMesh(decodeCache(read(m.mesh+'.cache'),false),10),sourceBytes=fs.readFileSync(path.join(manifest.source,'mesh/scene',m.sourceScene,'scene.mesh.cache'));
  const original=readStaticMesh(decodeCache(sourceBytes,false),cacheHeader(sourceBytes).version);
  check(mesh.primitives.length===original.primitives.length&&mesh.bounds.equals(original.bounds),'Geometry bounds/count changed');
  mesh.primitives.forEach((p,i)=>{check(p.vb.equals(original.primitives[i].vb)&&p.ib.equals(original.primitives[i].ib),'Geometry buffers changed');
    if(manifest.renderFix==='avatarstar-blend-flags-v1')check(p.blend===avatarStarBlendMode(original.primitives[i].blend),'Incorrect AvatarStar blend flags: '+m.code+'/'+i);
    if(!p.material)return;const material=p.material;
    material.vs.forEach(s=>dependency('shader/'+s+'.vd9.cache'));material.ps.forEach(s=>dependency('shader/'+s+'.pd9.cache'));
    for(let lod=0;lod<material.textures.length;lod++){const tex=material.textures[lod];for(const t of tex)dependency(t.path+'.cache');
      const expected=shaders.get(material.ps[Math.min(lod,material.ps.length-1)])?.uniforms.filter(u=>u.size===-1)??[];
      for(const u of expected)check(tex.some(t=>t.name===u.name)||['ShadowAOMap','ReflectMap'].includes(u.name),`${m.code}: missing sampler ${u.name}`);
    }
  });
  const physics=decodeCache(read(m.physics+'.cache'),false),sourcePhysics=decodeCache(fs.readFileSync(path.join(manifest.source,'mesh/scene',m.sourceScene,'scene.physx.cache')),false);
  check(physics.equals(sourcePhysics),'Collision data changed');
  const strings=luaStrings(decodeCache(read(m.script+'.cache'))).map(s=>s.text);
  check(strings.includes(m.code.toLowerCase()+'/scene.mesh')&&strings.includes('SetMapTexture'),'Missing map entrance');
  check(!strings.includes('AddLittleMap')&&!strings.includes('AddMachineGunTurretArea'),'Foreign scene API left in entrance');
  const dds=decodeCache(read(m.preview+'.cache'));check(dds.toString('ascii',0,4)==='DDS ','Invalid preview DDS');
}
const before=new PdeArchive(manifest.target),old=before.entries(),originalCustom=before.data(old.find(e=>e.path==='scripts/newsys/custommaps.lua'));
const expectedFiles=new Set([...old.filter(e=>e.type===1).map(e=>e.path.toLowerCase()),...manifest.resources.map(p=>p.toLowerCase())]);
check([...index.values()].filter(e=>e.type===1).length===expectedFiles.size,'Unexpected file count in rebuilt PDE');
for(const e of index.values())if(e.type===1)check(expectedFiles.has(e.path.toLowerCase()),'Unexpected resource '+e.path);
const patched=read('scripts/newsys/custommaps.lua'),embedded=prototypes(patched).children[0];
check(patched.subarray(embedded.start,embedded.end).equals(originalCustom.subarray(12)),'Existing CustomMaps code changed');
const replaced=new Set(manifest.resources.map(p=>p.toLowerCase()));
for(const e of old)if(e.type===1&&!replaced.has(e.path.toLowerCase())){const n=index.get(e.path.toLowerCase());
  check(n&&n.size===e.size&&a.data(n).equals(before.data(e)),'Old file content changed '+e.path);}
before.close();a.close();
// Apart from the root directory, every byte of the original PDE prefix must survive.
if(manifest.packMode!=='unpdec-full'){
const oldFd=fs.openSync(manifest.target,'r'),newFd=fs.openSync(manifest.verifiedPde,'r'),left=Buffer.alloc(4*1024*1024),right=Buffer.alloc(left.length);
try{for(let offset=8192;offset<manifest.originalSize;offset+=left.length){const n=Math.min(left.length,manifest.originalSize-offset);fs.readSync(oldFd,left,0,n,offset);fs.readSync(newFd,right,0,n,offset);check(left.subarray(0,n).equals(right.subarray(0,n)),'Original PDE prefix changed at '+offset);}}finally{fs.closeSync(oldFd);fs.closeSync(newFd);}
}
const result={checks,maps:manifest.maps.length,resources:manifest.resources.length,verifiedAt:new Date().toISOString()};fs.writeFileSync(path.join(stage,'verification.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
