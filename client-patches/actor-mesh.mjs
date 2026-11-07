// Actor meshes share material serialization with scene meshes, and carry a
// named bone palette and per-bone bounds for skinned vertices.
export function readActorMesh(bytes,version){
 if(![8,10].includes(version)||bytes.readUInt32LE(0)!==0x100)throw Error('Unsupported actor mesh version');
 let p=4;const take=n=>{if(n<0||p+n>bytes.length)throw Error('Truncated actor mesh');const b=bytes.subarray(p,p+n);p+=n;return b;};
 const u=()=>take(4).readUInt32LE(),count=()=>{const n=u();if(n>2e6)throw Error('Invalid mesh count');return n;};
 const str=()=>{const n=u();if(n>255)throw Error('Invalid mesh string');return take(n).toString('utf8');};
 const strings=()=>Array.from({length:count()},str),uniforms=()=>Array.from({length:count()},()=>Array.from({length:count()},()=>({name:str(),values:take(count()*4)})));
 const type=u();if(![1,2].includes(type))throw Error('Unsupported actor mesh type');
 const bones=type===2?strings():[],bounds=take(type===2?count()*24:24),primitives=[];
 for(let i=0,n=count();i<n;i++){
  const faces=count(),vertices=count(),layer=u(),cull=u(),blend=u(),visible=take(1)[0],extra=version===10?take(4):Buffer.alloc(4),vb=take(count()),ib=take(count());
  const stride=type===2?64:52;if(vb.length!==vertices*stride||ib.length!==faces*12)throw Error(`Invalid actor buffers: ${type}/${vertices}/${vb.length}`);
  let material=null;if(take(1)[0])material={vs:strings(),ps:strings(),vu:uniforms(),pu:uniforms(),textures:Array.from({length:count()},()=>Array.from({length:count()},()=>({name:str(),path:str()})))};
  primitives.push({faces,vertices,layer,cull,blend,visible,extra,vb,ib,material,collision:u()});
 }
 const physics=take(count()*4);if(p!==bytes.length)throw Error(`Actor mesh tail mismatch ${p}/${bytes.length}`);
 return {type,bones,bounds,primitives,physics};
}
export function writeActorMesh(mesh,version=10){
 const parts=[],u=n=>{const b=Buffer.alloc(4);b.writeUInt32LE(n);parts.push(b);},str=s=>{const b=Buffer.from(s);if(b.length>255)throw Error('Mesh string too long');u(b.length);parts.push(b);};
 const strings=a=>{u(a.length);a.forEach(str);},uniforms=a=>{u(a.length);for(const lod of a){u(lod.length);for(const v of lod){str(v.name);u(v.values.length/4);parts.push(v.values);}}};
 u(0x100);u(mesh.type);if(mesh.type===2){strings(mesh.bones);u(mesh.bounds.length/24);}parts.push(mesh.bounds);u(mesh.primitives.length);
 for(const x of mesh.primitives){for(const n of [x.faces,x.vertices,x.layer,x.cull,x.blend])u(n);parts.push(Buffer.from([x.visible]));if(version===10)parts.push(x.extra);
  u(x.vb.length);parts.push(x.vb);u(x.ib.length);parts.push(x.ib);parts.push(Buffer.from([x.material?1:0]));
  if(x.material){const m=x.material;strings(m.vs);strings(m.ps);uniforms(m.vu);uniforms(m.pu);u(m.textures.length);for(const lod of m.textures){u(lod.length);for(const t of lod){str(t.name);str(t.path);}}}u(x.collision);
 }u(mesh.physics.length/4);parts.push(mesh.physics);return Buffer.concat(parts);
}

export function useNativeWeaponVertexShader(mesh){
 let shaders=0,unusedIndices=0;
 for(const primitive of mesh.primitives){
  if(!primitive.material||!primitive.material.vs.includes('default_weapon_vs'))continue;
  if(mesh.type!==2)throw Error('Weapon shader requires a skinned vertex buffer');
  primitive.material.vs=primitive.material.vs.map(n=>{if(n!=='default_weapon_vs')return n;shaders++;return 'default_skined_vs';});
  // The weighted skin shader reads all four palette entries, including those
  // with zero weight. Source weapon meshes used 255 as the unused sentinel.
  primitive.vb=Buffer.from(primitive.vb);
  for(let p=0;p<primitive.vb.length;p+=64)for(let i=0;i<4;i++){
   if(primitive.vb.readFloatLE(p+40+4*i)===0&&primitive.vb[p+36+i]>=mesh.bones.length){primitive.vb[p+36+i]=0;unusedIndices++;}
  }
 }
 return {shaders,unusedIndices};
}

export function readSkeleton(bytes){
 let p=0;const u=()=>{const n=bytes.readUInt32LE(p);p+=4;return n;};if(u()!==0x600)throw Error('Unsupported skeleton');
 const n=u();if(n>4096)throw Error('Invalid bone count');const bones=[];
 for(let i=0;i<n;i++){const parent=u()|0,len=u();if(len>255||parent>=i||parent< -1)throw Error('Invalid skeleton hierarchy');const name=bytes.subarray(p,p+len).toString('utf8');p+=len;bones.push({name,parent});}
 if(u()!==n||bytes.length-p!==n*28)throw Error('Invalid skeleton poses');
 for(const b of bones){b.position=Array.from({length:3},(_,i)=>bytes.readFloatLE(p+i*4));b.rotation=Array.from({length:4},(_,i)=>bytes.readFloatLE(p+12+i*4));p+=28;}
 return bones;
}

export function readAnimation(bytes){
 let p=0;const u=()=>{if(p+4>bytes.length)throw Error('Truncated animation');const n=bytes.readUInt32LE(p);p+=4;return n;};
 if(u()!==0x500)throw Error('Unsupported animation');const count=u();if(count>4096)throw Error('Invalid animation joint count');const tracks=[];
 for(let i=0;i<count;i++){const size=u();if(size>255||p+size>bytes.length)throw Error('Invalid animation name');const name=bytes.subarray(p,p+size).toString('utf8');p+=size;const frames=u(),length=u();if(!frames||length!==frames*7||p+length*4>bytes.length)throw Error('Invalid animation frames');const data=bytes.subarray(p,p+length*4);p+=length*4;tracks.push({name,frames,data});}
 if(p!==bytes.length)throw Error('Animation tail mismatch');return tracks;
}
