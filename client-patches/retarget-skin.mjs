const add=(a,b)=>a.map((x,i)=>x+b[i]),sub=(a,b)=>a.map((x,i)=>x-b[i]),mul=(a,s)=>a.map(x=>x*s),length=a=>Math.hypot(...a);
const normal=a=>mul(a,1/(length(a)||1));
const dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
function align(a,b){a=normal(a);b=normal(b);const d=dot(a,b);if(d<-.999999){const axis=normal(Math.abs(a[0])<.9?[0,-a[2],a[1]]:[-a[1],a[0],0]);return [...axis,0];}const q=[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0],1+d],n=Math.hypot(...q);return q.map(v=>v/n);}
const conjugate=q=>[-q[0],-q[1],-q[2],q[3]];
export function quaternion(a,b){const [x,y,z,w]=a,[X,Y,Z,W]=b;return [w*X+x*W+y*Z-z*Y,w*Y-x*Z+y*W+z*X,w*Z+x*Y-y*X+z*W,w*W-x*X-y*Y-z*Z];}
export function rotate(v,q){return quaternion(quaternion(q,[...v,0]),conjugate(q)).slice(0,3);}
export function modelPose(bones){return bones.reduce((out,b)=>{const parent=out[b.parent];out.push(parent?{position:add(parent.position,rotate(b.position,parent.rotation)),rotation:quaternion(parent.rotation,b.rotation)}:{position:b.position,rotation:b.rotation});return out;},[]);}
function half(h){const s=h&0x8000?-1:1,e=(h>>>10)&31,m=h&1023;return s*(e===0?2**-14*m/1024:e===31?(m?NaN:Infinity):2**(e-15)*(1+m/1024));}
function toHalf(n){if(!Number.isFinite(n))throw Error('Non-finite vertex normal');const sign=n<0?0x8000:0;n=Math.abs(n);if(n<2**-14)return sign|Math.round(n*2**24);let e=Math.floor(Math.log2(n)),m=Math.round((n/2**e-1)*1024);if(m===1024){m=0;e++;}return sign|((e+15)<<10)|m;}

export function retargetSkin(mesh,sourceBones,targetBones){
 if(mesh.type!==2)throw Error('Expected skinned character mesh');
 const sourcePose=modelPose(sourceBones),targetPose=modelPose(targetBones),sourceNames=new Map(sourceBones.map((b,i)=>[b.name.toLowerCase(),i])),targetNames=new Map(targetBones.map((b,i)=>[b.name.toLowerCase(),i]));
 const sourceHeight=Math.max(...sourcePose.map(p=>p.position[1])),targetHeight=Math.max(...targetPose.map(p=>p.position[1])),scale=targetHeight/sourceHeight;
 if(!(scale>.15&&scale<3))throw Error('Unsupported character proportions');
 const changes=[],palette=mesh.bones.map(name=>{
  const original=sourceNames.get(name.toLowerCase());if(original===undefined)throw Error('Source mesh bone missing from skeleton: '+name);
  let sourceId=original;while(sourceId>=0&&!targetNames.has(sourceBones[sourceId].name.toLowerCase()))sourceId=sourceBones[sourceId].parent;
  if(sourceId<0)throw Error('Cannot map source bone: '+name);
  const targetId=targetNames.get(sourceBones[sourceId].name.toLowerCase());
  const source=sourcePose[sourceId],target=targetPose[targetId];
  // Bone coordinate frames differ between the two artists' rigs (e.g. a leg is
  // identity in FC and rotated ~90 degrees in AS). Match anatomical directions
  // in model space, not those arbitrary local axes, or limbs and faces twist.
  const child=sourceBones.map((b,i)=>({b,i})).filter(({b})=>b.parent===sourceId&&targetNames.has(b.name.toLowerCase())&&!/hat|weapon|ik|^ui$|^face$|^shoulder/.test(b.name.toLowerCase())).sort((a,b)=>length(b.b.position)-length(a.b.position))[0];
  let axis=null,ratio=scale,rotation=[0,0,0,1];
  if(child){const nativeChild=targetNames.get(child.b.name.toLowerCase());const a=length(child.b.position),b=length(sub(targetPose[nativeChild].position,target.position));
   if(a>.015&&b>.015){axis=normal(sub(sourcePose[child.i].position,source.position));ratio=Math.max(.15,Math.min(3,b/a));rotation=align(axis,sub(targetPose[nativeChild].position,target.position));}}
  if(sourceId!==original)changes.push({from:name,to:targetBones[targetId].name});
  return {source,target,name:targetBones[targetId].name,axis,ratio,rotation};
 });
 const names=[...new Set(palette.map(p=>p.name))],boneMap=new Map(names.map((n,i)=>[n,i]));
 const boxes=names.map(()=>({min:[Infinity,Infinity,Infinity],max:[-Infinity,-Infinity,-Infinity]}));
 for(const primitive of mesh.primitives){const vb=Buffer.from(primitive.vb);primitive.vb=vb;
  for(let p=0;p<vb.length;p+=64){const position=[0,1,2].map(i=>vb.readFloatLE(p+4*i)),directions=[12,20,28].map(offset=>[0,1,2].map(i=>half(vb.readUInt16LE(p+offset+2*i))));let result=[0,0,0],normals=directions.map(()=>[0,0,0]),weights=new Map(),total=0;
   for(let i=0;i<4;i++){const weight=vb.readFloatLE(p+40+4*i);if(weight<=1e-7)continue;if(!Number.isFinite(weight)||weight<0)throw Error('Invalid bone weight');
    const binding=palette[vb[p+36+i]];if(!binding)throw Error('Invalid skin bone index');
    const offset=sub(position,binding.source.position);let local=mul(offset,scale);
    if(binding.axis)local=add(local,mul(binding.axis,dot(offset,binding.axis)*(binding.ratio-scale)));
    result=add(result,mul(add(binding.target.position,rotate(local,binding.rotation)),weight));
    for(let k=0;k<3;k++){let localN=mul(directions[k],1/scale);if(binding.axis)localN=add(localN,mul(binding.axis,dot(directions[k],binding.axis)*(1/binding.ratio-1/scale)));normals[k]=add(normals[k],mul(rotate(localN,binding.rotation),weight));}
    const id=boneMap.get(binding.name);weights.set(id,(weights.get(id)??0)+weight);total+=weight;
   }
   if(Math.abs(total-1)>.02)throw Error('Non-normalized character weights: '+total);
   result=mul(result,1/total);result.forEach((v,i)=>{if(!Number.isFinite(v))throw Error('Invalid retargeted vertex');vb.writeFloatLE(v,p+i*4);});
   normals.forEach((v,k)=>normal(v).forEach((c,i)=>vb.writeUInt16LE(toHalf(c),p+[12,20,28][k]+2*i)));
   const entries=[...weights];for(let i=0;i<4;i++){vb[p+36+i]=entries[i]?.[0]??0;vb.writeFloatLE((entries[i]?.[1]??0)/total,p+40+4*i);}
   for(const [id] of entries)result.forEach((v,k)=>{boxes[id].min[k]=Math.min(boxes[id].min[k],v);boxes[id].max[k]=Math.max(boxes[id].max[k],v);});
  }
 }
 mesh.bones=names;mesh.bounds=Buffer.alloc(names.length*24);boxes.forEach((b,i)=>[...b.min,...b.max].forEach((v,j)=>mesh.bounds.writeFloatLE(Number.isFinite(v)?v:0,i*24+j*4)));
 return {scale,mappedBones:names.length,collapsedBones:changes};
}
