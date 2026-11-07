import fs from 'node:fs';
import path from 'node:path';
import {decodeCache} from './pde-format.mjs';
import {encodeCache,rekeyCache,cacheHeader,cacheChecksum} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {readActorMesh,writeActorMesh,useNativeWeaponVertexShader} from './actor-mesh.mjs';
import {syncShaderSamplerReflection} from './shader-samplers.mjs';
import {appendResources} from './pde-batch.mjs';

const input=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const stage=path.resolve(process.argv[3]??'.tmpbuild/finalcombat-actors/shop-icons');
const installed=path.resolve(process.argv[4]??'C:/Game/AvatarStar/AvatarStar_actors.pde');
const manifestFile=path.join(input,'manifest.json'),manifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
const candidate=path.join(stage,'AvatarStar_actors.pde');
if(fs.existsSync(candidate))throw Error('Choose a new repair output directory');
fs.mkdirSync(stage,{recursive:true});fs.copyFileSync(manifestFile,path.join(stage,'manifest.before.json'));
const replacements=new Map(),modelPaths=new Set(),shaderPaths=new Set();
const stats={icons:0,models:0,vertexShaders:0,unusedIndices:0,pixelShaders:0,samplerBindings:0};
function write(p,b){
 const h=cacheHeader(b),raw=decodeCache(b,false);
 if(!decodeCacheNative(b,false,{fill:0xcd}).equals(raw)||cacheChecksum(b,'/'+p.slice(0,-6))!==b.readUInt32LE(h.base+4))throw Error('Invalid cache '+p);
 const out=path.join(stage,'resources',p);fs.mkdirSync(path.dirname(out),{recursive:true});fs.writeFileSync(out,b);replacements.set(p,out);
}
for(const w of manifest.weapons){
 const p='ui/skinf/lobby/'+w.resource+'.tga',b=fs.readFileSync(path.join(input,'resources',w.icon.slice(1)+'.cache'));
 write(p+'.cache',rekeyCache(b,'/'+p));w.shopIcon='/'+p;stats.icons++;
 w.models.forEach(m=>modelPaths.add(m.path+'.cache'));
}
for(const p of modelPaths){
 const b=fs.readFileSync(path.join(input,'resources',p)),mesh=readActorMesh(decodeCache(b,false),10),changed=useNativeWeaponVertexShader(mesh);
 for(const part of mesh.primitives)for(const ps of part.material?.ps??[])if(ps.startsWith('fca_'))shaderPaths.add('shader/'+ps+'.pd9.cache');
 if(!changed.shaders)continue;
 write(p,encodeCache(writeActorMesh(mesh),b,'/'+p.slice(0,-6),10));
 stats.models++;stats.vertexShaders+=changed.shaders;stats.unusedIndices+=changed.unusedIndices;
}
for(const p of shaderPaths){
 const b=fs.readFileSync(path.join(input,'resources',p)),result=syncShaderSamplerReflection(decodeCache(b,false));
 if(!result.changed)continue;
 write(p,encodeCache(result.bytes,b,'/'+p.slice(0,-6)));stats.pixelShaders++;stats.samplerBindings+=result.changed;
}
fs.copyFileSync(installed,candidate);
const pack=appendResources(candidate,replacements);
for(const [p,source] of replacements)for(const folder of ['resources','all-resources']){
 const root=path.join(input,folder);if(folder==='all-resources'&&!fs.existsSync(root))continue;
 const dest=path.join(root,p);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(source,dest);
}
manifest.resources=[...new Set([...manifest.resources,...replacements.keys()])];
manifest.shopTextureRepair={at:new Date().toISOString(),...stats};
fs.writeFileSync(manifestFile,JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync(path.join(stage,'repair-verification.json'),JSON.stringify({...stats,pack},null,2)+'\n');
console.log({...stats,bytes:pack.newSize,candidate});
