import fs from 'node:fs';
import path from 'node:path';
import {decodeCache,luaStrings} from './pde-format.mjs';
import {cacheHeader,cacheChecksum} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {readActorMesh,writeActorMesh,readSkeleton} from './actor-mesh.mjs';
import {retargetSkin} from './retarget-skin.mjs';
import {syncShaderSamplerReflection} from './shader-samplers.mjs';

const stage=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import'),manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8'));
const base=manifest.baseline,resource=path.join(stage,'resources');let checks=0,caches=0,vertices=0;
const check=(condition,message)=>{checks++;if(!condition)throw Error(message);};
function file(p){p=p.replace(/^\//,'').toLowerCase();const f=path.join(resource,p);return fs.existsSync(f)?f:path.join(base,p);}
function exists(p){check(fs.existsSync(file(p)), 'Missing dependency '+p);}
const nativeBones=readSkeleton(decodeCache(fs.readFileSync(file('skeleton/basemodel.skel.cache')),false)),names=new Set(nativeBones.map(b=>b.name));
for(const p of manifest.resources){const bytes=fs.readFileSync(file(p));if(!p.endsWith('.cache')){luaStrings(bytes);continue;}
 const h=cacheHeader(bytes),raw=decodeCache(bytes,false);check(decodeCacheNative(bytes,false,{fill:0xcd}).equals(raw),'Native cache mismatch '+p);check(cacheChecksum(bytes,'/'+p.slice(0,-6))===bytes.readUInt32LE(h.base+4),'Cache CRC '+p);caches++;
 if(p.endsWith('.lua.cache'))luaStrings(raw.subarray(8));
 if(!p.endsWith('.mesh.cache'))continue;
 const mesh=readActorMesh(raw,10);check(writeActorMesh(mesh).equals(raw),'Mesh serialization '+p);
 if(p.includes('/avatar/head/'))check(mesh.bones.every(n=>names.has(n)),'Native skeleton bone names '+p);
 for(const prim of mesh.primitives){check(prim.ib.every((v,i)=>i%4!==0||prim.ib.readUInt32LE(i)<prim.vertices),'Triangle indices '+p);const stride=mesh.type===2?64:52;
  for(let i=0;i<prim.vb.length;i+=stride){vertices++;for(let k=0;k<3;k++)check(Number.isFinite(prim.vb.readFloatLE(i+k*4)),'Vertex position '+p);
   if(mesh.type===2){let weight=0;for(let k=0;k<4;k++){const w=prim.vb.readFloatLE(i+40+k*4);check(Number.isFinite(w)&&w>=0,'Bone weight '+p);if(w>0)check(prim.vb[i+36+k]<mesh.bones.length,'Bone index '+p);weight+=w;}check(Math.abs(weight-1)<.025,'Normalized weights '+p);}
  }
 const m=prim.material;if(!m)continue;
 if(p.startsWith('mesh/weapon/')){
  check(!m.vs.includes('default_weapon_vs'),'Native weapon vertex shader contract '+p);
  for(const name of m.ps){const shader=decodeCache(fs.readFileSync(file('shader/'+name+'.pd9.cache')),false);check(syncShaderSamplerReflection(shader).changed===0,'Consistent D3DX sampler reflection '+name);}
 }
 m.vs.forEach(n=>exists('shader/'+n+'.vd9.cache'));m.ps.forEach(n=>exists('shader/'+n+'.pd9.cache'));m.textures.flat().forEach(t=>exists(t.path+'.cache'));
 }
}
for(const w of manifest.weapons){
 exists('weapon/'+w.resource+'.lua.cache');exists(w.skeleton+'.cache');exists(w.icon+'.cache');if(w.killIcon)exists(w.killIcon+'.cache');
 exists('ui/skinf/lobby/'+w.resource+'.tga.cache');
 // Engine SetMesh is rooted at /mesh/weapon/, not the source game's prop path.
 for(const model of w.models){check(model.path.startsWith('mesh/weapon/'),'Client weapon model root '+model.path);exists(model.path+'.cache');}
 for(const name of ['idle','idlemenu','change','shoot','reload'])exists(`animation/prop/thirdperson/male/${w.animationSet}/${name}.anim.cache`);
 // Melee uses stdshoot1/2/3 and has no reload. Check the complete native
 // animation contract for this weapon class, including its movement states.
 const nativeDir=path.join(base,'animation/character/thirdperson/male',w.base);
 const required=fs.readdirSync(nativeDir).filter(p=>p.endsWith('.anim.cache'));
 check(required.length>0,'Native animation contract '+w.base);
 for(const name of required)exists(`animation/character/thirdperson/male/${w.animationSet}/${name}`);
}
// Identity rig conversion is independent of the source game's proportions.
const identity=readActorMesh(decodeCache(fs.readFileSync(file('mesh/character/thirdperson/avatar/basemodel/body01.mesh.cache')),false),10),before=identity.primitives.map(p=>Buffer.from(p.vb));retargetSkin(identity,nativeBones,nativeBones);
identity.primitives.forEach((p,j)=>{for(let v=0;v<p.vb.length;v+=64)for(let i=0;i<3;i++)check(Math.abs(p.vb.readFloatLE(v+4*i)-before[j].readFloatLE(v+4*i))<1e-5,'Identity retarget preserves geometry');});
const report={checks,caches,vertices,cards:manifest.cards.length,weapons:manifest.weapons.length,verifiedAt:new Date().toISOString()};fs.writeFileSync(path.join(stage,'actor-verification.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
