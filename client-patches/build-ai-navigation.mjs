import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import {fileURLToPath} from 'node:url';
import { decodeCache, sha256 } from './pde-format.mjs';

// PhysX 2.x cooked triangle meshes: preserve geometry, discard SDK acceleration data.
export function trianglesFromCache(bytes) {
  const b = decodeCache(bytes);
  if (b.subarray(4, 12).toString('hex') !== '4e5853014d455348' || b.readUInt32LE(12) !== 1)
    throw new Error('Unsupported PhysX mesh');
  const flags = b.readUInt32LE(16), vertices = b.readUInt32LE(32), faces = b.readUInt32LE(36);
  const width = flags & 8 ? 1 : flags & 16 ? 2 : 4;
  const indices = 40 + vertices * 12;
  if (vertices > 2000000 || faces > 2000000 || indices + faces * 3 * width > b.length) throw new Error('Invalid mesh size');
  const result = [];
  for (let f = 0; f < faces; f++) {
    const tri = [];
    for (let k = 0; k < 3; k++) {
      const index = b.readUIntLE(indices + (f * 3 + k) * width, width);
      if (index >= vertices) throw new Error('Invalid mesh index');
      for (let axis = 0; axis < 3; axis++) tri.push(b.readFloatLE(40 + index * 12 + axis * 4));
    }
    if (tri.every(Number.isFinite)) result.push(tri);
  }
  return result;
}

function cross(a,b) { return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]; }
function sub(a,b) { return a.map((v,i)=>v-b[i]); }
function dot(a,b) { return a.reduce((n,v,i)=>n+v*b[i],0); }
function intersection(origin, delta, t) {
  const ex=t[3]-t[0],ey=t[4]-t[1],ez=t[5]-t[2],fx=t[6]-t[0],fy=t[7]-t[1],fz=t[8]-t[2];
  const px=delta[1]*fz-delta[2]*fy,py=delta[2]*fx-delta[0]*fz,pz=delta[0]*fy-delta[1]*fx;
  const det=ex*px+ey*py+ez*pz;if(Math.abs(det)<1e-8)return null;
  const sx=origin[0]-t[0],sy=origin[1]-t[1],sz=origin[2]-t[2],u=(sx*px+sy*py+sz*pz)/det;
  if(u<-.00001||u>1.00001)return null;
  const qx=sy*ez-sz*ey,qy=sz*ex-sx*ez,qz=sx*ey-sy*ex,v=(delta[0]*qx+delta[1]*qy+delta[2]*qz)/det;
  if(v<-.00001||u+v>1.00001)return null;
  const d=(fx*qx+fy*qy+fz*qz)/det;return d>=0&&d<=1?d:null;
}

export function bake(triangles, deadVolumes = [], playableBounds = [-120, -120, 120, 120]) {
  const buckets=new Map();
  for(const t of triangles){
    const xs=[t[0],t[3],t[6]],zs=[t[2],t[5],t[8]];
    for(let x=Math.max(-128,Math.floor(Math.min(...xs)/2));x<=Math.min(128,Math.floor(Math.max(...xs)/2));x++)
      for(let z=Math.max(-128,Math.floor(Math.min(...zs)/2));z<=Math.min(128,Math.floor(Math.max(...zs)/2));z++){
        const key=x+','+z; if(!buckets.has(key))buckets.set(key,[]);buckets.get(key).push(t);
      }
  }
  function candidates(a,b){const found=new Set();for(let x=Math.floor(Math.min(a[0],b[0])/2);x<=Math.floor(Math.max(a[0],b[0])/2);x++)
    for(let z=Math.floor(Math.min(a[2],b[2])/2);z<=Math.floor(Math.max(a[2],b[2])/2);z++)
      for(const t of buckets.get(x+','+z)||[])found.add(t);return found;}
  function clear(a,b){const d=sub(b,a);for(const t of candidates(a,b)){const v=intersection(a,d,t);if(v!==null&&v>.001&&v<.999)return false;}return true;}
  function corridor(a,b){
    const dx=b[0]-a[0],dz=b[2]-a[2],len=Math.hypot(dx,dz)||1;
    for(const side of [-.35,0,.35])for(const h of [.8,1.65]){
      const off=[dz/len*side,h,-dx/len*side];if(!clear(a.map((v,i)=>v+off[i]),b.map((v,i)=>v+off[i])))return false;
    }
    return true;
  }
  const nodes=[],cells=new Map();
  const all=triangles.flat(), xs=all.filter((_,i)=>i%3===0),zs=all.filter((_,i)=>i%3===2);
  const bounds=v=>v.reduce((a,x)=>[Math.min(a[0],x),Math.max(a[1],x)],[Infinity,-Infinity]);
  const [minX,maxX]=bounds(xs),[minZ,maxZ]=bounds(zs);
  for(let x=Math.max(-120,Math.ceil(minX));x<=Math.min(120,Math.floor(maxX));x++)for(let z=Math.max(-120,Math.ceil(minZ));z<=Math.min(120,Math.floor(maxZ));z++){
    if(x<playableBounds[0]||z<playableBounds[1]||x>playableBounds[2]||z>playableBounds[3])continue;
    const floors=[];
    for(const t of buckets.get(Math.floor(x/2)+','+Math.floor(z/2))||[]){
      const normal=cross(sub(t.slice(3,6),t.slice(0,3)),sub(t.slice(6,9),t.slice(0,3)));
      if(Math.abs(normal[1])<Math.hypot(...normal)*.65)continue;
      const hit=intersection([x,120,z],[0,-240,0],t);if(hit===null)continue;
      const y=120-hit*240;if(floors.some(v=>Math.abs(v-y)<.2))continue;
      if(deadVolumes.some(v=>x>=v[0]&&x<=v[3]&&y+.2>=v[1]&&y+.2<=v[4]&&z>=v[2]&&z<=v[5]))continue;
      const p=[x,y+.03,z];
      if(!clear([x,y+.08,z],[x,y+1.9,z]))continue;
      let free=true;for(let i=0;i<8;i++)for(const h of [.65,1.5]){
        if(!clear([x,y+h,z],[x+Math.cos(i*Math.PI/4)*.4,y+h,z+Math.sin(i*Math.PI/4)*.4]))free=false;
      }
      if(free)floors.push(y);
    }
    for(const y of floors){const index=nodes.length;nodes.push({p:[x,Math.round((y+.04)*1000)/1000,z],n:[]});
      const key=x+','+z;if(!cells.has(key))cells.set(key,[]);cells.get(key).push(index);}
  }
  for(let id=0;id<nodes.length;id++){
    const a=nodes[id];for(let dx=-1;dx<=1;dx++)for(let dz=-1;dz<=1;dz++){
      if(!dx&&!dz)continue;
      for(const j of cells.get((a.p[0]+dx)+','+(a.p[2]+dz))||[]){
        if(j<=id)continue;const b=nodes[j];if(Math.abs(a.p[1]-b.p[1])>.65||!corridor(a.p,b.p))continue;
        a.n.push(j);b.n.push(id);
      }
    }
  }
  // Isolated ledges/decoration cannot host bots. Keep substantial connected floors, including storeys.
  const keep=new Set(),seen=new Set();
  for(let i=0;i<nodes.length;i++)if(!seen.has(i)){
    const group=[i];seen.add(i);for(let k=0;k<group.length;k++)for(const n of nodes[group[k]].n)if(!seen.has(n)){seen.add(n);group.push(n);}
    if(group.length>=30)for(const n of group)keep.add(n);
  }
  const order=[...keep].sort((a,b)=>a-b),remap=new Map(order.map((id,i)=>[id,i]));
  return order.map(id=>[...nodes[id].p,...nodes[id].n.filter(n=>keep.has(n)).map(n=>remap.get(n))]);
}

if(process.argv[1]&&path.resolve(process.argv[1])===path.resolve(fileURLToPath(import.meta.url))){
  const unpack=process.argv[2]||'tools/Unpack/AvatarStar';
  const output=process.argv[3]||'src/AvatarStar.Server.Game/Config/AiNavigation';fs.mkdirSync(output,{recursive:true});
  const report=[];
  const filter=(process.argv[4]||'level50,level51,level52,level53').split(',');
  for(const directory of fs.readdirSync(path.join(unpack,'mesh/scene')).filter(n=>/^level\d+$/.test(n)&&(!filter||filter.includes(n))).sort((a,b)=>Number(b.slice(5))-Number(a.slice(5)))){
    console.log('Baking '+directory);
    const files=fs.readdirSync(path.join(unpack,'mesh/scene',directory)).filter(n=>n.endsWith('.physx.cache')&&!/flag|pointmesh|allow_|gate|door/i.test(n));
    if(!files.length)continue;
    const triangles=[],sources=[];
    for(const file of files){const bytes=fs.readFileSync(path.join(unpack,'mesh/scene',directory,file));try{for(const t of trianglesFromCache(bytes))triangles.push(t);sources.push({file,sha256:sha256(bytes)});}catch(e){console.log(directory+'/'+file+': '+e.message);}}
    if(!triangles.length)continue;
    const nodes=bake(triangles);if(nodes.length<30)continue;
    fs.writeFileSync(path.join(output,directory.toUpperCase()+'.json.gz'),zlib.gzipSync(JSON.stringify({version:1,cellSize:1,nodes,triangles}),{level:9}));
    report.push({level:directory.toUpperCase(),nodes:nodes.length,triangles:triangles.length,sources});
    console.log(directory+': '+nodes.length+' nodes / '+triangles.length+' triangles');
  }
  fs.writeFileSync(path.join(output,'sources.json'),JSON.stringify(report,null,2));
}
