import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {decodeCache,luaStrings,PdeArchive,sha256} from './pde-format.mjs';
import {cacheHeader,cacheChecksum,rekeyCache,encodeCache} from './cache-format.mjs';
import {readStaticMesh,writeStaticMesh,avatarStarBlendMode} from './scene-mesh.mjs';
import {embedOriginal} from './lua-chunk.mjs';
import {sceneMinimap} from './scene-minimap.mjs';
import {remapShaderSamplers} from './shader-samplers.mjs';

const [mode,source='C:/Game/DaChongFeng/finalcombat_cache',target='C:/Game/AvatarStar/AvatarStar.pde',stage='.tmpbuild/finalcombat-maps/import']=process.argv.slice(2);
if(!['prepare','pack'].includes(mode))throw Error('Usage: node client-patches/import-finalcombat-maps.mjs prepare|pack [source-cache] [target-pde] [stage]');
fs.mkdirSync(stage,{recursive:true});
const json=(f,v)=>fs.writeFileSync(f,JSON.stringify(v,null,2)+'\n');
function walk(dir,prefix=''){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name),prefix+e.name+'/'):[prefix+e.name]);}
const manifestFile=path.join(stage,'manifest.json');
if(mode==='pack'){
  const manifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
  if(fs.statSync(target).size!==manifest.originalSize)throw Error('Target PDE changed; prepare again');
  const result=spawnSync(process.execPath,[path.resolve('client-patches/rebuild-finalcombat-pde.mjs'),target,stage,path.join(stage,'rebuild')],{stdio:'inherit'});
  if(result.error||result.status!==0)throw result.error??Error('PDEPack rebuild failed');
  process.exit(0);
}
const files=walk(source),sourceIndex=new Map(files.map(p=>[p.toLowerCase(),p]));
const archive=new PdeArchive(target),entries=archive.entries(),targetIndex=new Map(entries.map(e=>[e.path.toLowerCase(),e]));
const resources=new Map(),copied=new Map(),warnings=[];
function save(p,bytes){const f=path.join(stage,'resources',p);fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,bytes);resources.set(p,f);}
function sourceFile(p){return sourceIndex.get(p.replace(/^\//,'').toLowerCase());}
function sourceBytes(p){const f=sourceFile(p);if(!f)throw Error('Missing source resource: '+p);return fs.readFileSync(path.join(source,f));}
function getTarget(p){const e=targetIndex.get(p.toLowerCase());if(!e)throw Error('Missing target resource: '+p);return archive.data(e);}
function compile(text,name){const f=path.resolve(stage,'lua',name+'.lua'),o=f+'c';fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,text);
  const r=spawnSync(path.resolve('tools/unpdec/Release/Lua/luac.exe'),['-o',o,f],{encoding:'utf8'});if(r.status!==0)throw Error('Lua compilation failed: '+r.stderr+r.stdout);const b=fs.readFileSync(o);luaStrings(b);return b;}
function decompile(p){const raw=sourceBytes(p),b=decodeCache(raw),f=path.resolve(stage,'source-lua',path.basename(p).replace('.lua.cache','.luac'));fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,b);
  const r=spawnSync(path.resolve('tools/Lua/unluac.exe'),[f],{encoding:'utf8'});if(r.status!==0)throw Error('Lua decompilation failed: '+p);return fs.readFileSync(f.replace(/c$/,''),'utf8');}
function copyTexture(p){p=p.toLowerCase().replace(/^\//,'');const key=p+'.cache';if(copied.has(key))return copied.get(key);
  const dest='mesh/scene/finalcombat/assets/'+p.replace(/^mesh\//,'');const bytes=sourceBytes(key),header=cacheHeader(bytes);
  if(![0x201,0x202,0x203].includes(header.type)||header.version!==1)throw Error('Unsupported texture '+p);
  save(dest+'.cache',rekeyCache(bytes,'/'+dest));copied.set(key,'/'+dest);return '/'+dest;
}
const shaderReports=[];
function shader(name,extension){const sourcePath=`shader/${name}.${extension}.cache`,key=sourcePath.toLowerCase();if(copied.has(key))return copied.get(key);
  // Use the original compiled shaders under private names: their constant tables
  // and DX9 bytecode have the same serialization, despite cache version 3 vs 2.
  const bytes=sourceBytes(key),full=decodeCache(bytes,false);let p=8+full.readUInt32LE(4),uniforms=[];
  const count=full.readUInt32LE(p);p+=4;for(let i=0;i<count;i++){const n=full.readUInt32LE(p);p+=4;const text=full.subarray(p,p+n).toString('utf8');p+=n;uniforms.push({name:text,reg:full.readInt32LE(p),size:full.readInt32LE(p+4)});p+=8;}
  if(p!==full.length)throw Error('Shader layout mismatch '+key);
  if(extension==='pd9'&&count===0&&name.endsWith('_lod_0')&&sourceFile(sourcePath.replace('_lod_0','_lod_1'))){
    const fallback=shader(name.replace('_lod_0','_lod_1'),extension);copied.set(key,fallback);warnings.push({shader:name,message:'Source LOD 0 is a placeholder; using its complete LOD 1 shader.'});return fallback;
  }
  const newName='fc_'+name.toLowerCase(),dest=`shader/${newName}.${extension}`;
  const nativeSamplers={ColorMap:0,LightMap:4,ShadowAOMap:15,ReflectMap:7};
  const registers=new Map(uniforms.filter(u=>u.size===-1&&nativeSamplers[u.name]!==undefined).map(u=>[u.reg,nativeSamplers[u.name]]));
  const remapped=remapShaderSamplers(full,registers);
  for(const u of uniforms)if(u.size===-1&&registers.has(u.reg))u.reg=registers.get(u.reg);
  save(dest+'.cache',encodeCache(remapped.bytes,bytes,'/'+dest,2));copied.set(key,newName);shaderReports.push({source:sourcePath,target:dest,uniforms,remappedOperands:remapped.changed});return newName;
}
const scripts=files.filter(p=>/^level\/level.*\.lua\.cache$/i.test(p)).map(p=>{const text=decompile(p);return {path:p,text,name:text.match(/AddMapName\("(.*?)"\)/)?.[1],scene:text.match(/AddMesh\("(.*?)"\)/)?.[1]};});
const sceneDirs=fs.readdirSync(path.join(source,'mesh/scene')).filter(d=>sourceFile(`mesh/scene/${d}/scene.mesh.cache`)).sort((a,b)=>(parseInt(a.replace('level',''))||9999)-(parseInt(b.replace('level',''))||9999));
const configRoot='src/AvatarStar.Server.Game/Config',catalog=JSON.parse(fs.readFileSync(configRoot+'/lobby_levels.json','utf8'));
const oldImport=catalog.levels.filter(e=>e.imported),usedCodes=new Set([...entries.filter(e=>e.type===2&&/^mesh\/scene\/level\d+$/.test(e.path)).map(e=>e.path.split('/').at(-1).toUpperCase()),...catalog.levels.filter(e=>!e.imported).map(e=>e.name)]);
for(const key of Object.keys(JSON.parse(fs.readFileSync(configRoot+'/lobby_levelinfo.json','utf8'))))if(!oldImport.some(e=>e.name===key))usedCodes.add(key);
const maps=[];let code=54,room=400023;
for(const dir of sceneDirs){
  while(usedCodes.has('LEVEL'+code))code++;
  while(catalog.levels.some(e=>!e.imported&&e.id===room))room++;
  const candidates=scripts.filter(s=>s.scene===dir+'/scene.mesh').sort((a,b)=>{const priority=s=>/_td_/.test(s.path)?0:/_cp_/.test(s.path)?1:/_knife_/.test(s.path)?2:3;return priority(a)-priority(b)||a.path.localeCompare(b.path);});
  const selected=candidates[0],text=selected?.text??'',saved=oldImport.find(e=>e.sourceScene===dir),id=saved?.id??room++,level=saved?.name??'LEVEL'+code++;
  const name=selected?.name?.replace(/\((简单|困难)\)/,'')??`大冲锋${dir.replace('level','')}号地图`;
  const map={id,code:level,sourceScene:dir,name:dir==='level52'?name+'（一）':dir==='level53'?name+'（二）':name,sourceScript:selected?.path??null,variants:candidates.map(s=>s.path)};
  if(!selected)warnings.push({scene:dir,message:'No level script; created a static team-deathmatch entrance from mesh bounds.'});
  const meshPath=`mesh/scene/${dir}/scene.mesh`,raw=sourceBytes(meshPath+'.cache'),h=cacheHeader(raw),mesh=readStaticMesh(decodeCache(raw,false),h.version);
  if(!writeStaticMesh(mesh,h.version).equals(decodeCache(raw,false)))throw Error('Lossless source mesh roundtrip failed: '+dir);
  const light=text.match(/SetLightMap\("(.*?)"\)/)?.[1];let lightTexture=light&&sourceFile('mesh/scene/'+light+'.cache')?copyTexture('mesh/scene/'+light):null;
  if(!lightTexture){const guess=files.find(p=>new RegExp(`mesh/scene/materials/(et0?${parseInt(dir.slice(5))}_lp_all|level_${dir.slice(5)}_lp)\\.dds\\.cache$`,'i').test(p));if(guess)lightTexture=copyTexture(guess.replace(/\.cache$/,''));}
  for(const primitive of mesh.primitives){primitive.blend=avatarStarBlendMode(primitive.blend);const m=primitive.material;if(!m)continue;
    m.vs=m.vs.map(n=>shader(n,'vd9'));m.ps=m.ps.map(n=>shader(n,'pd9'));
    // Placeholder LOD 0 also lacks its material bindings. Copy matching bindings
    // from the complete lower LOD when its shader is promoted to LOD 0.
    for(let lod=0;lod<m.ps.length;lod++){
      const uniforms=shaderReports.find(s=>s.target===`shader/${m.ps[lod]}.pd9`)?.uniforms??[];
      m.textures[lod]??=[];m.pu[lod]??=[];
      for(const u of uniforms){
        const slots=u.size===-1?m.textures:m.pu;
        if(!slots[lod].some(v=>v.name===u.name)){const value=slots.flat().find(v=>v.name===u.name);if(value)slots[lod].push({...value});}
        if(['FogClamper','LightMapIntensity','ShadowIntensity'].includes(u.name)&&!m.pu[lod].some(v=>v.name===u.name)){
          const values=Buffer.alloc(16);for(let c=0;c<4;c++)values.writeFloatLE(1,c*4);m.pu[lod].push({name:u.name,values});
        }
      }
    }
    for(const lod of m.textures){for(const t of lod)t.path=copyTexture(t.path);if(lightTexture&&!lod.some(t=>t.name==='LightMap'))lod.push({name:'LightMap',path:lightTexture});}
  }
  const destination=`mesh/scene/${level.toLowerCase()}`;map.mesh=destination+'/scene.mesh';map.physics=destination+'/scene.physx';
  const converted=writeStaticMesh(mesh);readStaticMesh(converted,10);save(map.mesh+'.cache',encodeCache(converted,raw,'/'+map.mesh,10));
  const physics=sourceBytes(meshPath.replace('.mesh','.physx.cache'));save(map.physics+'.cache',rekeyCache(physics,'/'+map.mesh,6));
  let mini=text.match(/AddLittleMap\("(.*?)"\)/)?.[1];
  if(!mini||!sourceFile(mini+'.cache')){const local=files.filter(p=>p.startsWith('mesh/scene/'+dir+'/')&&/map.*\.dds\.cache$/i.test(p));mini=(local.find(p=>/td_/.test(p))??local[0])?.replace(/\.cache$/,'');}
  const bounds=Array.from({length:6},(_,i)=>mesh.bounds.readFloatLE(i*4));
  const sourceInfo=text.match(/level:SetMapInfo\(([^\n]*)\)/)?.[1];
  const values=sourceInfo?sourceInfo.split(',').map(Number):[(bounds[0]+bounds[3])/2,(bounds[2]+bounds[5])/2,(bounds[3]-bounds[0])/2,(bounds[5]-bounds[2])/2];
  if(values.length!==4||!values.every(Number.isFinite)||values[2]<=0||values[3]<=0)throw Error('Invalid minimap bounds '+dir);
  map.playableBounds=[values[0]-values[2],values[1]-values[3],values[0]+values[2],values[1]+values[3]];
  // Final Combat stores minimap half extents; AvatarStar's six-argument API uses full size.
  const info=[values[0],values[1],values[2]*2,values[3]*2].join(', ');
  if(mini)map.preview=copyTexture(mini);
  else {
    const dds=sceneMinimap(mesh,info.split(',').map(Number)),template=sourceBytes('mesh/scene/materials/et01_lp_all.dds.cache'),full=Buffer.concat([decodeCache(template,false).subarray(0,8),dds]);full.writeUInt32LE(dds.length,4);
    map.preview='/'+destination+'/map_image.dds';save(destination+'/map_image.dds.cache',encodeCache(full,template,map.preview));warnings.push({scene:dir,message:'Minimap missing in source; generated from scene geometry.'});
  }
  const allowed=new Set(['SetSunDirection','SetShadowDirection','SetShadowDistance','SetShadowMapSize','SetFog','SetYFog','SetLightmapIntensity','SetAmbientIntensity','SetFar','SetNear','SetCameraPosition','SetCameraRotation','SetCharacterLight','AddDeadAABB']);
  const lines=text.split(/\r?\n/).filter(l=>allowed.has(l.match(/^level:(\w+)\(/)?.[1]));
  const intensity=text.match(/SetCharacterIntensity\((.*?)\)/)?.[1]??'1.3';
  let lua=`-- ${map.name}; source ${dir}. AvatarStar team deathmatch entrance.\nlevel:SetMapInfo(${info}, 1, 0.6)\nlevel:SetMapTexture("${map.preview.replace(/^\//,'')}")\nlevel:AddMesh("${level.toLowerCase()}/scene.mesh")\nlevel:AddPhysx("${level.toLowerCase()}/scene.mesh")\n`;
  if(!selected)lua+='level:SetSunDirection(0.4, 0.6, 0.7)\nlevel:SetShadowDirection(0.4, 1, 0.7)\nlevel:SetLightmapIntensity(1)\nlevel:SetFar(2000)\nlevel:SetNear(0.1)\n';
  lua+=lines.join('\n')+`\nlevel:SetCharacterLightIntensity(${intensity})\nlevel:SetNotifyPosHeight(3, 6)\nlevel:SetAmbienceAudio("go/ambience_2d/ambience_day")\ncg:SetStar(false)\n`;
  map.deadVolumes=[...text.matchAll(/AddDeadAABB\(Vector3\(([^)]+)\), Vector3\(([^)]+)\)\)/g)].map(m=>[...m[1].split(','),...m[2].split(',')].map(Number));
  const bytecode=compile(lua,level),scriptTemplate=getTarget('mesh/scene/level53/script.lua.cache'),scriptFull=Buffer.concat([decodeCache(scriptTemplate,false).subarray(0,8),bytecode]);
  // ScriptLua stores resource type followed by the bytecode byte count.
  scriptFull.writeUInt32LE(bytecode.length,4);map.script=destination+'/script.lua';save(map.script+'.cache',encodeCache(scriptFull,scriptTemplate,'/'+map.script));
  maps.push(map);console.log(`${level} / ${id}: ${map.name} (${dir})`);
}
const customPath='scripts/newsys/custommaps.lua',original=getTarget(customPath);
const hook=`local function original() end\nlocal function install()\nlocal maps = {\n${maps.map(m=>`{key="${m.code.toLowerCase()}", text_id="id_fc_${m.code.toLowerCase()}", name=${JSON.stringify(m.name)}, image=${JSON.stringify(m.preview)}},`).join('\n')}\n}\nlocal texts={}\nfor _,m in ipairs(maps) do\n texts[m.text_id]=m.name\n Icons.PreviewMaps[m.key]=Gui.Image(m.image,Vector4(0,0,0,0))\n Icons.PreviewMapsDisable[m.key]=Gui.Image(m.image,Vector4(0,0,0,0))\nend\nReadTextTable(texts)\nend\noriginal()\nlocal ok,err=pcall(install)\nif not ok then print("FinalCombat maps: "..tostring(err)) end\n`;
save(customPath,embedOriginal(compile(hook,'custommaps-finalcombat'),original));
const manifest={version:1,renderFix:'avatarstar-blend-flags-v1',source:path.resolve(source),target:path.resolve(target),originalSize:archive.size,preparedAt:new Date().toISOString(),maps,resources:[...resources.keys()],shaders:shaderReports,warnings,unavailableScripts:scripts.filter(s=>s.scene&&!sourceFile('mesh/scene/'+s.scene+'.cache')).map(s=>({script:s.path,missing:s.scene}))};
json(manifestFile,manifest);archive.close();console.log(JSON.stringify({maps:maps.length,resources:resources.size,warnings,unavailable:manifest.unavailableScripts}));
