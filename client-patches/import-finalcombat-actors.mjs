import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {decodeCache,luaStrings,sha256} from './pde-format.mjs';
import {cacheHeader,encodeCache,rekeyCache} from './cache-format.mjs';
import {decodeCacheNative} from './cache-native.mjs';
import {readActorMesh,writeActorMesh,readSkeleton,useNativeWeaponVertexShader} from './actor-mesh.mjs';
import {retargetSkin} from './retarget-skin.mjs';
import {avatarStarBlendMode} from './scene-mesh.mjs';
import {remapShaderSamplers} from './shader-samplers.mjs';
import {embedOriginal} from './lua-chunk.mjs';

const stage=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const source='C:/Game/DaChongFeng/finalcombat_cache',native='.tmpbuild/pde-native-compression/all-resources';
const readJson=f=>JSON.parse(fs.readFileSync(f,'utf8').replace(/^\uFEFF/,''));
const walk=(dir,prefix='')=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name),prefix+e.name+'/'):[prefix+e.name]);
const index=new Map(walk(source).map(p=>[p.toLowerCase(),p])),nativeFiles=walk(native),nativeIndex=new Map(nativeFiles.map(p=>[p.toLowerCase(),p]));
const inventory=readJson('.tmpbuild/finalcombat-actors/research/inventory.json');
const resources=new Set(),dependencies=[],warnings=[],excluded=[],shaders=[],cards=[],weapons=[],textures=new Map(),meshes=new Map(),animations=new Map();
const canonical=p=>p.replace(/^\//,'').toLowerCase();
function fromSource(p){const file=index.get(canonical(p));if(!file)throw Error('Missing source '+p);return fs.readFileSync(path.join(source,file));}
function fromNative(p){const file=nativeIndex.get(canonical(p));if(!file)throw Error('Missing native '+p);return fs.readFileSync(path.join(native,file));}
function save(p,b){p=canonical(p);const file=path.join(stage,'resources',p);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,b);resources.add(p);return p;}
function cache(p,raw,template,version){save(p+'.cache',encodeCache(raw,template,'/'+p,version));return '/'+p;}
function copyCache(src,dest,version){const b=fromSource(src+'.cache');let converted=rekeyCache(b,'/'+dest,version);if(!decodeCacheNative(converted,false,{fill:0xcd}).equals(decodeCache(b,false)))converted=encodeCache(decodeCache(b,false),b,'/'+dest,version);save(dest+'.cache',converted);return '/'+dest;}
function compile(text,virtual){const f=path.join(stage,'lua',virtual),o=f+'c';fs.mkdirSync(path.dirname(f),{recursive:true});fs.writeFileSync(f,text);const r=spawnSync(path.resolve('tools/unpdec/Release/Lua/luac.exe'),['-o',o,f],{encoding:'utf8'});if(r.status!==0)throw Error('Lua compile: '+r.stdout+r.stderr);let b=fs.readFileSync(o);const old=b.readUInt32LE(12),name=Buffer.from('@/'+virtual+'\0'),size=Buffer.alloc(4);size.writeUInt32LE(name.length);b=Buffer.concat([b.subarray(0,12),size,name,b.subarray(16+old)]);luaStrings(b);return b;}
function nativeLua(resource){const f=path.join(stage,'templates',resource+'.luac');fs.mkdirSync(path.dirname(f),{recursive:true});if(!fs.existsSync(f.slice(0,-1))){fs.writeFileSync(f,decodeCache(fromNative('weapon/'+resource+'.lua.cache')));const r=spawnSync(path.resolve('tools/Lua/unluac.exe'),[f]);if(r.status!==0)throw Error('Decompile '+resource);}return fs.readFileSync(f.slice(0,-1),'utf8');}
function texture(p){p=canonical(p);if(textures.has(p))return textures.get(p);const target='finalcombat/assets/'+p,b=fromSource(p+'.cache'),h=cacheHeader(b);if(h.version!==1||![0x201,0x202,0x203].includes(h.type))throw Error('Texture format '+p);const result=copyCache(p,target);textures.set(p,result);return result;}
function uniforms(raw){let p=8+raw.readUInt32LE(4),n=raw.readUInt32LE(p);p+=4;const list=[];for(let i=0;i<n;i++){const l=raw.readUInt32LE(p);p+=4;const name=raw.subarray(p,p+l).toString();p+=l;list.push({name,reg:raw.readInt32LE(p),size:raw.readInt32LE(p+4)});p+=8;}if(p!==raw.length)throw Error('Shader layout');return list;}
const samplerMap=new Map();
const samplerAliases={UVMap:'Decal_Color_Map'};
function renameShaderUniforms(raw){const end=8+raw.readUInt32LE(4),list=uniforms(raw),pieces=[raw.subarray(0,end)],count=Buffer.alloc(4);count.writeUInt32LE(list.length);pieces.push(count);for(const u of list){const name=Buffer.from(samplerAliases[u.name]??u.name),n=Buffer.alloc(4),v=Buffer.alloc(8);n.writeUInt32LE(name.length);v.writeInt32LE(u.reg);v.writeInt32LE(u.size,4);pieces.push(n,name,v);}return Buffer.concat(pieces);}
for(const file of nativeFiles.filter(f=>/^shader\/.*\.pd9.cache$/i.test(f)))for(const u of uniforms(decodeCache(fromNative(file),false)))if(u.size===-1){const old=samplerMap.get(u.name);if(old!==undefined&&old!==u.reg)throw Error('Conflicting native sampler '+u.name);samplerMap.set(u.name,u.reg);}
function shader(name,ext){
 if(ext==='vd9'&&['default_skined_vs','default_weapon_vs','default_static_vs'].includes(name))return name;
 const dest='shader/fca_'+name.toLowerCase()+'.'+ext;if(resources.has(dest+'.cache'))return 'fca_'+name.toLowerCase();
 const b=fromSource('shader/'+name+'.'+ext+'.cache'),raw=renameShaderUniforms(decodeCache(b,false)),u=uniforms(raw);
 if(ext==='pd9'&&!u.length&&name.endsWith('_lod_0')&&index.has('shader/'+name.replace('_lod_0','_lod_1')+'.pd9.cache'))return shader(name.replace('_lod_0','_lod_1'),ext);
 const registers=new Map();for(const v of u.filter(x=>x.size===-1)){if(!samplerMap.has(v.name))throw Error('Unknown native sampler '+v.name);registers.set(v.reg,samplerMap.get(v.name));}
 const remapped=remapShaderSamplers(raw,registers);cache(dest,remapped.bytes,b,2);shaders.push({path:dest,source:name,uniforms:uniforms(remapped.bytes)});return 'fca_'+name.toLowerCase();
}
function material(mesh){for(const p of mesh.primitives){const m=p.material;if(!m){p.blend=0;continue;}p.blend=avatarStarBlendMode(p.blend);m.vs=m.vs.map(n=>shader(n,'vd9'));m.ps=m.ps.map(n=>shader(n,'pd9'));for(const lod of m.textures)for(const t of lod){t.name=samplerAliases[t.name]??t.name;t.path=texture(t.path);}}}
function mesh(src,dest,bones){const key=src+'|'+(bones?'character':'weapon');if(meshes.has(key)&&meshes.get(key).path===dest)return meshes.get(key);
 const b=fromSource(src+'.cache'),h=cacheHeader(b),raw=decodeCache(b,false),m=readActorMesh(raw,h.version);if(!writeActorMesh(m,h.version).equals(raw))throw Error('Mesh roundtrip '+src);
 let retarget=null;if(bones)retarget=retargetSkin(m,bones,targetBones);material(m);
 // Native third-person/shop weapons use the normal skinned vertex pipeline.
 // The source game's weapon VS additionally requires WeaponRot (c31..c34),
 // which this client does not supply on its regular weapon rendering path.
 if(!bones)useNativeWeaponVertexShader(m);
 // Two float4 constants per dual quaternion, beginning at c64; DX9 has c0..c255.
 if(m.bones.length>96)throw Error('Shader bone palette exceeds 96: '+src);
 const bytes=writeActorMesh(m);readActorMesh(bytes,10);cache(dest,bytes,b,10);
 const record={source:src,path:dest,bones:m.bones,vertices:m.primitives.reduce((s,p)=>s+p.vertices,0),retarget};meshes.set(key,record);return record;
}
const targetBones=readSkeleton(decodeCache(fromNative('skeleton/basemodel.skel.cache'),false));
const jobs={leader:'突击兵',officelady:'狙击手',butcher:'机枪手',fireman:'火箭兵',firebat:'火焰兵',nurse:'护士',engineer:'工程兵'};
const series={body:'经典',baroque:'巴洛克',celestial:'天神',newyear:'新年',steampunk:'蒸汽朋克',classics:'经典',darkmetal:'暗黑金属',newoutfit:'新装',halloween:'万圣节',christmas:'圣诞',summer:'夏日',pirate:'海盗',chinese:'中国风',western:'西部',military:'军装',beach:'海滩',lunar:'新春',space:'太空',sakura:'樱花',snow:'冰雪',wedding:'婚礼',school:'校园',spring:'春日',superhero:'超级英雄'};
function variantName(name){const key=name.replace(/[0-9_]+$/,'');return (series[key]??name)+(series[key]?(name.match(/\d+$/)?.[0]??''):'');}
// Avatar strings are the common path used by shop, storage, lobby and in-game players.
// Keep each mesh's bone palette separate, as in the source character.
const checkpoint=path.join(stage,'costumes.json');
if(process.argv.includes('--reuse-costumes')&&fs.existsSync(checkpoint)){
 const c=readJson(checkpoint);cards.push(...c.cards);excluded.push(...c.excluded);shaders.push(...c.shaders);c.resources.forEach(p=>resources.add(p));for(const [k,v] of c.textures)textures.set(k,v);for(const [k,v] of c.meshes)meshes.set(k,v);
}else{
for(const c of inventory.characters.filter(c=>/^character\/(leader|officelady|butcher|fireman|firebat|nurse|engineer)_[01]\//.test(c.file)&&/SetMesh\("body"/.test(c.text)).sort((a,b)=>a.file.localeCompare(b.file))){
 const [,job,team,variant]=c.file.match(/^character\/(\w+)_([01])\/(.*?)\.lua.cache$/),key='fca_'+job+'_'+team+'_'+variant;
 const parts=[...c.text.matchAll(/SetMesh\("([^"]+)", "([^"]+)", (?:true|false), 0\)/g)];if(parts.length!==2)throw Error('Incomplete costume '+c.file);
 const missingParts=parts.filter(p=>!index.has(canonical('mesh/character/thirdperson/'+p[2]+'.cache'))).map(p=>p[2]);
 if(missingParts.length){excluded.push({source:c.file,reason:'source costume meshes are absent',missing:missingParts});continue;}
 const skel=c.text.match(/third_person_skeleton = "([^"]+)"/)?.[1]??inventory.characters.find(x=>x.file===`character/${job}_${team}/all.lua.cache`)?.text.match(/third_person_skeleton = "([^"]+)"/)?.[1];
 const bones=readSkeleton(decodeCache(fromSource(skel+'.cache'),false)),avatar=Object.fromEntries(['skin','eye','mouth','nose','ear','beard','hair','helmet','underwear','outerwear','trousers','glove','shoes','decal','movable','immobile','immobileUp','immobileDown'].map(k=>[k,'']));
 avatar.skin="{'fca_hidden_skin',1,-1,0,255,255,255,0,0,0,0,0,0}";
 const models=[];for(let i=0;i<parts.length;i++){const [,part,p]=parts[i],slot=i===0?'helmet':'hair',id=i===0?8:7,name=key+'_'+part+'_lod0',dest=`mesh/character/thirdperson/avatar/head/${slot}/mesh_${name}.mesh`;models.push(mesh('mesh/character/thirdperson/'+p,dest,bones));avatar[slot]=`{'${name}',${id},0,0,255,255,255,255,255,255,255,255,255}`;}
 cards.push({sid:320000+cards.length,resource:'',display:'id_'+key,name:'大冲锋·'+jobs[job]+'·'+variantName(variant)+(team==='0'?'（红）':'（蓝）'),source:c.file,sourceSkeleton:skel,models,avatar});
 if(cards.length%50===0)console.log('Prepared costumes',cards.length);
}
// The engine uses alpha-cutout shaders for the underlying body/head. Empty face
// slots already select its built-in transparent onecolor_a texture.
for(const suffix of ['c','m']){const template=fromNative('mesh/character/thirdperson/avatar/basemodel/tex_onecolor_a_'+suffix+'.dds.cache');cache('mesh/character/thirdperson/avatar/skin/tex_fca_hidden_skin_'+suffix+'.dds',decodeCache(template,false),template);}
fs.writeFileSync(checkpoint,JSON.stringify({cards,excluded,shaders,resources:[...resources],textures:[...textures],meshes:[...meshes]}));
}

const config=readJson('src/AvatarStar.Server.Game/Resources/shop_config.json');
const baseItems=Object.values(config.shop.categories).flatMap(c=>c.items).filter(i=>i.type===2);
const animationClass={sniperrifle:'sniperrifle_01',minigun:'machinegun_01',automachinegun:'machinegun_01',rocketlauncher:'rpg_01',flamethrower:'sprayer_01',grenade:'grenade_01',pistol:'pistol_01',deserteagle:'pistol_01',shotgun:'shotgun_01',scattergun:'shotgun_01',spas:'shotgun_01',rspas:'shotgun_01',m1014:'shotgun_01',jokershotgun:'shotgun_01',airgun:'shotgun_01',syringegun:'smg_01',laser:'sprayer_01',transfusionbomb:'sprayer_01'};
const melee=new Set(['bonesaw','captainhook','clamp','fireaxe','kukri','spontoon','sword','taser']);
function weaponClass(name,anim){if(melee.has(anim)||/\/strider\.lua/.test(name))return 'knives_01';if(animationClass[anim])return animationClass[anim];if(/^sniper01/.test(anim))return 'sniperrifle_01';if(/^fatman01/.test(anim))return 'machinegun_01';if(/^rocket01/.test(anim))return 'rpg_01';if(/^firebat01/.test(anim))return 'sprayer_01';if(/^(engineer02|fatman02|rocket02)/.test(anim))return 'shotgun_01';if(/^(medic03|engineer03)/.test(anim))return 'pistol_01';if(/^(medic04|engineer04)/.test(anim))return 'grenade_01';if(/05001$/.test(anim))return 'knives_01';return 'smg_01';}
function animationSet(anim,base){const id='fca_'+base.replace(/_01$/,'')+'_'+anim.toLowerCase();if(animations.has(id))return id;
 const nativePrefix='animation/character/thirdperson/male/'+base+'/',charFiles=nativeFiles.filter(f=>f.toLowerCase().startsWith(nativePrefix));if(!charFiles.length)throw Error('Missing character animations '+base);
 for(const f of charFiles){const dest=f.replace(nativePrefix,'animation/character/thirdperson/male/'+id+'/');save(dest,rekeyCache(fromNative(f),'/'+dest.replace(/\.cache$/,'')));}
 const candidates=[...index.keys()].filter(f=>f.startsWith('animation/prop/thirdperson/')&&f.includes('/'+anim.toLowerCase()+'/')&&f.endsWith('.anim.cache')).sort();
 const first=candidates.find(f=>/\/idle\.anim.cache$/.test(f))??candidates[0];if(!first)throw Error('Missing weapon animations '+anim);
 const prefix=first.slice(0,first.lastIndexOf('/')+1),files=candidates.filter(f=>f.startsWith(prefix)),names=new Set();
 for(const f of files){const name=path.posix.basename(f),dest='animation/prop/thirdperson/male/'+id+'/'+name;copyCache(f.slice(0,-6),dest.slice(0,-6));names.add(name);}
 const idle=files.find(f=>/\/idle\.anim.cache$/.test(f))??first;
 for(const name of ['idle','idlemenu','weaponidle','change','shoot','reload'])if(!names.has(name+'.anim.cache'))copyCache(idle.slice(0,-6),`animation/prop/thirdperson/male/${id}/${name}.anim`);
 animations.set(id,{source:prefix,base,charFiles:charFiles.length,propFiles:files.length});return id;
}
function iconFrom(text,field){const line=text.match(new RegExp('weapon\\.'+field+' = texture\\(([^\\n]+)\\)'))?.[1];if(!line)return null;const quoted=[...line.matchAll(/"([^"]*)"/g)].map(m=>m[1]);const p=quoted.join('zh_cn');if(index.has(canonical(p)+'.cache'))return texture(p);const suffix=quoted.at(-1)?.toLowerCase();const found=[...index.keys()].find(f=>f.endsWith(suffix+'.cache'));if(found)return texture(found.slice(0,-6));return null;}
const knownNames={ak47:'AK47',aug:'AUG',mk18:'MK18',pistol:'手枪',deserteagle:'沙漠之鹰',flamethrower:'火焰喷射器',minigun:'加特林机枪',shotgun:'霰弹枪',m1014:'M1014',rspas:'R-SPAS',spas:'SPAS',kukri:'弯刀',sword:'长剑',fireaxe:'消防斧',bonesaw:'骨锯',grenade:'手雷',laser:'激光枪',syringegun:'注射枪',broadsword:'阔剑',clamp:'工程钳',shovel:'工兵铲'};
const jobWeapon={striker:'突击',sniper:'狙击',fatman:'重装',rocket:'火箭',firebat:'火焰',medic:'医疗',engineer:'工程'};
for(const w of [...inventory.weapons].sort((a,b)=>a.file.localeCompare(b.file))){
 const name=w.file.split('/')[1],anim=w.text.match(/animation_set = "([^"]+)"/)?.[1]?.toLowerCase();
 if(/bullet|^boss|^cell|^tankweapon|^proprole|^fueltank$|^aad$|^c4$|^yamaha|^automachinegun$/.test(name)||!anim||/weapon\.(?:bg_tower_mesh|bandjoint)\s*=/.test(w.text)){excluded.push({source:w.file,reason:'projectile, NPC, deployable or no animation set'});continue;}
 if(!/\.(?:kill_icon|fire_particle|sound_name)/.test(w.text)){excluded.push({source:w.file,reason:'not a standalone usable weapon'});continue;}
 const selected=new Map();for(const match of w.text.matchAll(/weapon:SetMesh(Color)?\("([^"]+)", "([^"]+)"(?:, (\d+))?\)/g)){const [,color,key,p,lod='0']=match;if(lod!=='0')continue;selected.set(key,color?p+'_n_lod0.mesh':p);}
 if(!selected.size){excluded.push({source:w.file,reason:'no base mesh'});continue;}
 const missingModels=[...selected.values()].filter(p=>!index.has(canonical('mesh/prop/weapon/'+p+'.cache')));
 if(missingModels.length){excluded.push({source:w.file,reason:'source weapon meshes are absent',missing:missingModels});continue;}
 const key='fca_'+name,base=weaponClass(w.file,anim),template=baseItems.find(x=>x.resource===base);if(!template)throw Error('Missing shop template '+base);
 const skel=w.text.match(/skeleton = "([^"]+)"/)?.[1];if(!skel)throw Error('Missing skeleton '+name);
 const bones=readSkeleton(decodeCache(fromSource(skel+'.cache'),false)),boneNames=new Set(bones.map(b=>b.name)),models=[];
 // SetMesh names are relative to AvatarStar's /mesh/weapon/, whereas the
 // source game stores the same weapon parts below /mesh/prop/weapon/.
 for(const [part,p] of selected){const dest='mesh/weapon/'+key+'/'+path.posix.basename(p),record=mesh('mesh/prop/weapon/'+p,dest);if(record.bones.some(n=>!boneNames.has(n)))throw Error('Weapon mesh/skeleton mismatch '+name);models.push({...record,part});}
 const familyName=name.replace(/(?:lv|_l|l)\d+$/,''),shopIcon=['ui/zh_cn/lobbyui/ibt_icon/'+name+'.tga','ui/zh_cn/lobbyui/ibt_icon/'+familyName+'.tga'].find(p=>index.has(p+'.cache'));
 const skeleton=copyCache(canonical(skel),'skeleton/'+key+'.skel'),set=animationSet(anim,base),killIcon=iconFrom(w.text,'kill_icon'),icon=iconFrom(w.text,'icon')??(shopIcon?texture(shopIcon):killIcon);
 if(!icon)throw Error('Missing shop icon '+name);
 // Tip.GetIcon and IconsF.GetLobbySlotIcon derive this path from item.resource;
 // they do not read weapon.icon from the weapon definition.
 const shopIconPath='ui/skinf/lobby/'+key+'.tga';
 save(shopIconPath+'.cache',rekeyCache(fs.readFileSync(path.join(stage,'resources',icon.slice(1)+'.cache')),'/'+shopIconPath));
 let text=nativeLua(base).split(/\r?\n/).filter(l=>!/^weapon:(?:SetMesh|SetMeshWithLevel)/.test(l)&&!/^weapon\.(?:skeleton|animation_set|icon|kill_icon|name) =/.test(l)).join('\n')+'\n';
 text+=models.map(m=>`weapon:SetMesh(${JSON.stringify(m.part)}, ${JSON.stringify(m.path.replace('mesh/weapon/',''))})`).join('\n')+'\n';
 text+=`weapon.skeleton = ${JSON.stringify(skeleton)}\nweapon.animation_set = ${JSON.stringify(set)}\nweapon.name = ${JSON.stringify(key)}\nweapon.icon = texture(${JSON.stringify(icon)})\n`;
 if(killIcon)text+=`weapon.kill_icon = texture(${JSON.stringify(killIcon)})\n`;else warnings.push({source:w.file,message:'Source has no kill icon; native weapon category icon retained.'});
 if(!killIcon){const line=nativeLua(base).split(/\r?\n/).find(l=>/^weapon.kill_icon =/.test(l));if(line)text+=line+'\n';}
 const virtual='weapon/'+key+'.lua',code=compile(text,virtual),raw=Buffer.alloc(8+code.length);raw.writeUInt32LE(0xA01);raw.writeUInt32LE(code.length,4);code.copy(raw,8);cache(virtual,raw,fromNative('weapon/'+base+'.lua.cache'));
 let label=knownNames[name];if(!label){const group=Object.keys(jobWeapon).find(k=>name.startsWith(k));label=group?jobWeapon[group]+'武器 '+name.slice(group.length):name.toUpperCase();}
 weapons.push({sid:220000+weapons.length,resource:key,name:'大冲锋·'+label,display:'id_'+key,source:w.file,base,subtype:template.subtype,skeleton,animationSet:set,models,icon,shopIcon:'/'+shopIconPath,killIcon});
 if(weapons.length%50===0)console.log('Prepared weapons',weapons.length);
}
const texts=Object.fromEntries([...cards,...weapons].map(c=>[c.display,c.name]));
texts.id_finalcombat_card_description='大冲锋角色造型卡，可在造型卡界面装备。';texts.id_finalcombat_weapon_description='大冲锋移植武器，使用对应枪种的战斗属性。';
const hook='local function original() end\nlocal function install()\nReadTextTable({\n'+Object.entries(texts).map(([k,v])=>`[${JSON.stringify(k)}]=${JSON.stringify(v)},`).join('\n')+'\n})\nend\noriginal()\ninstall()\n';
const textScript='scripts/newsys/custommaps.lua';save(textScript,embedOriginal(compile(hook,textScript),fromNative(textScript)));
const manifest={version:1,source,baseline:path.resolve(native),generatedAt:new Date().toISOString(),cards,weapons,excluded,warnings,meshes:[...meshes.values()],shaders,animations:[...animations].map(([id,v])=>({id,...v})),resources:[...resources],texts};
fs.writeFileSync(path.join(stage,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');console.log(JSON.stringify({cards:cards.length,weapons:weapons.length,resources:resources.size,excluded:excluded.length,warnings}));
