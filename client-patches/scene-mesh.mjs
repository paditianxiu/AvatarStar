// Final Combat v8 and AvatarStar v10 share static vertices/materials. v10 adds one
// four-byte primitive field after visibility, and changes opaque/cutout flags.
// Native AvatarStar scenes store 0 for opaque and 1 for alpha-tested foliage;
// Final Combat's Attribute.h uses 1 and 2 respectively. Other blend bits retain
// their values. Copying 1 unchanged turns buildings/terrain into cutout surfaces.
export function avatarStarBlendMode(finalCombatMode){
  if(finalCombatMode===1)return 0;
  if(finalCombatMode===2)return 1;
  if([4,8,16,32,64].includes(finalCombatMode))return finalCombatMode;
  throw Error('Unsupported Final Combat blend mode: '+finalCombatMode);
}
export function readStaticMesh(bytes,version){
  if(![8,10].includes(version)||bytes.readUInt32LE(0)!==0x100||bytes.readUInt32LE(4)!==1)throw Error('Unsupported static mesh');
  let p=8;const take=n=>{if(n<0||p+n>bytes.length)throw Error('Truncated mesh');const r=bytes.subarray(p,p+n);p+=n;return r;};
  const u=()=>take(4).readUInt32LE();const count=()=>{const n=u();if(n>2e6)throw Error('Invalid mesh count');return n;};
  const str=()=>{const n=u();if(n>255)throw Error('Invalid material name');return take(n).toString('utf8');};
  const strings=()=>Array.from({length:count()},str);
  const uniforms=()=>Array.from({length:count()},()=>Array.from({length:count()},()=>({name:str(),values:take(count()*4)})));
  const bounds=take(24),primitives=[];const n=count();
  for(let i=0;i<n;i++){
    const faces=count(),vertices=count(),layer=u(),cull=u(),blend=u(),visible=take(1)[0],extra=version===10?take(4):Buffer.alloc(4);
    const vb=take(u()),ib=take(u());if(vb.length!==vertices*52||ib.length!==faces*12)throw Error('Invalid static buffers');
    let material=null;if(take(1)[0])material={vs:strings(),ps:strings(),vu:uniforms(),pu:uniforms(),textures:Array.from({length:count()},()=>Array.from({length:count()},()=>({name:str(),path:str()})))};
    primitives.push({faces,vertices,layer,cull,blend,visible,extra,vb,ib,material,collision:u()});
  }
  const physics=take(count()*4);if(p!==bytes.length)throw Error(`Mesh tail mismatch ${p}/${bytes.length}`);
  return {bounds,primitives,physics};
}
export function writeStaticMesh(mesh,version=10){
  const parts=[];const u=n=>{const b=Buffer.alloc(4);b.writeUInt32LE(n);parts.push(b);};const str=s=>{const b=Buffer.from(s);if(b.length>255)throw Error('Material path too long');u(b.length);parts.push(b);};
  const strings=a=>{u(a.length);a.forEach(str);};
  const uniforms=a=>{u(a.length);for(const lod of a){u(lod.length);for(const v of lod){str(v.name);u(v.values.length/4);parts.push(v.values);}}};
  u(0x100);u(1);parts.push(mesh.bounds);u(mesh.primitives.length);
  for(const x of mesh.primitives){for(const n of [x.faces,x.vertices,x.layer,x.cull,x.blend])u(n);parts.push(Buffer.from([x.visible]));if(version===10)parts.push(x.extra);
    u(x.vb.length);parts.push(x.vb);u(x.ib.length);parts.push(x.ib);parts.push(Buffer.from([x.material?1:0]));
    if(x.material){const m=x.material;strings(m.vs);strings(m.ps);uniforms(m.vu);uniforms(m.pu);u(m.textures.length);for(const lod of m.textures){u(lod.length);for(const t of lod){str(t.name);str(t.path);}}}u(x.collision);
  }
  u(mesh.physics.length/4);parts.push(mesh.physics);return Buffer.concat(parts);
}
