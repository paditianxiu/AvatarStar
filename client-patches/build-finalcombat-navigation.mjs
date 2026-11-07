import fs from 'node:fs';import path from 'node:path';import zlib from 'node:zlib';
import {decodeCache,sha256} from './pde-format.mjs';
import {bake} from './build-ai-navigation.mjs';
const [stage='.tmpbuild/finalcombat-maps/import',output='src/AvatarStar.Server.Game/Config/AiNavigation']=process.argv.slice(2);
const manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8')),report=[];
fs.mkdirSync(output,{recursive:true});
export function collisionTriangles(bytes){
  const b=decodeCache(bytes,false);if(b.readUInt32LE(0)!==0x700)throw Error('Invalid collision resource');
  const count=b.readUInt32LE(4),triangles=[];let offset=8;
  for(let actor=0;actor<count;actor++){
    const size=b.readUInt32LE(offset);offset+=4;const c=b.subarray(offset,offset+size);offset+=size;
    const mode=b.readUInt32LE(offset),attrs=b.readUInt32LE(offset+4);offset+=8+attrs*12;
    if(!size)continue;
    if(c.subarray(0,8).toString('hex')!=='4e5853014d455348'||c.readUInt32LE(8)!==1)throw Error('Unsupported cooked physics');
    const flags=c.readUInt32LE(12),vertices=c.readUInt32LE(28),faces=c.readUInt32LE(32),width=flags&8?1:flags&16?2:4,indices=36+vertices*12;
    if(indices+faces*3*width>c.length||attrs!==faces)throw Error('Invalid physics indices');
    // Team barriers do not belong to a shared navigation graph.
    if(mode>=5)continue;
    for(let f=0;f<faces;f++){const t=[];for(let k=0;k<3;k++){const i=c.readUIntLE(indices+(f*3+k)*width,width);if(i>=vertices)throw Error('Vertex out of range');for(let ax=0;ax<3;ax++)t.push(c.readFloatLE(36+i*12+ax*4));}if(!t.every(Number.isFinite))throw Error('Nonfinite geometry');triangles.push(t);}
  }
  if(offset!==b.length)throw Error('Collision resource trailing bytes');return triangles;
}
for(const map of manifest.maps){
  const bytes=fs.readFileSync(path.join(stage,'resources',map.physics+'.cache')),hash=sha256(bytes),file=path.join(output,map.code+'.json.gz'),stamp=path.join(stage,map.code+'.nav.json');
  const regionHash=sha256(Buffer.from(JSON.stringify([map.deadVolumes,map.playableBounds])));
  if(fs.existsSync(file)&&fs.existsSync(stamp)){const old=JSON.parse(fs.readFileSync(stamp,'utf8'));if(old.physics===hash&&old.regionHash===regionHash){report.push(old);console.log(map.code+' navigation already verified');continue;}}
  console.log('Baking '+map.code+' '+map.name);const triangles=collisionTriangles(bytes),nodes=bake(triangles,map.deadVolumes,map.playableBounds);
  if(nodes.length<30)throw Error(map.code+' has no usable connected floor');
  fs.writeFileSync(file,zlib.gzipSync(JSON.stringify({version:1,cellSize:1,nodes,triangles}),{level:9}));
  const r={level:map.code,nodes:nodes.length,triangles:triangles.length,physics:hash,regionHash};report.push(r);fs.writeFileSync(stamp,JSON.stringify(r));console.log(JSON.stringify(r));
}
fs.writeFileSync(path.join(output,'finalcombat-sources.json'),JSON.stringify(report,null,2)+'\n');
