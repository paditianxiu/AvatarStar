// Orthographic geometry preview for source maps whose minimap texture is absent.
export function sceneMinimap(mesh,info,size=256){
  const [cx,cz,w,h]=info,rgba=Buffer.alloc(size*size*4),depth=new Float32Array(size*size).fill(-Infinity);
  for(let i=0;i<size*size;i++){rgba[i*4]=35;rgba[i*4+1]=29;rgba[i*4+2]=24;rgba[i*4+3]=255;}
  for(const p of mesh.primitives)for(let t=0;t<p.faces;t++){
    const v=[];for(let k=0;k<3;k++){const offset=p.ib.readUInt32LE((t*3+k)*4)*52;if(offset+12>p.vb.length)throw Error('Minimap vertex out of bounds');v.push([(p.vb.readFloatLE(offset)-cx)/w*size+size/2,p.vb.readFloatLE(offset+4),size/2-(p.vb.readFloatLE(offset+8)-cz)/h*size]);}
    const [[ax,ay,az],[bx,by,bz],[cx1,cy,cz1]]=v,area=(bz-cz1)*(ax-cx1)+(cx1-bx)*(az-cz1);if(Math.abs(area)<.01)continue;
    for(let y=Math.max(0,Math.floor(Math.min(az,bz,cz1)));y<=Math.min(size-1,Math.ceil(Math.max(az,bz,cz1)));y++)
    for(let x=Math.max(0,Math.floor(Math.min(ax,bx,cx1)));x<=Math.min(size-1,Math.ceil(Math.max(ax,bx,cx1)));x++){
      const u=((bz-cz1)*(x-cx1)+(cx1-bx)*(y-cz1))/area,vv=((cz1-az)*(x-cx1)+(ax-cx1)*(y-cz1))/area,ww=1-u-vv;if(u<0||vv<0||ww<0)continue;
      const d=u*ay+vv*by+ww*cy,i=y*size+x;if(d<depth[i])continue;depth[i]=d;
      const shade=Math.max(65,Math.min(220,110+d*3));rgba[i*4]=shade*.8;rgba[i*4+1]=shade;rgba[i*4+2]=shade*.9;
    }
  }
  const header=Buffer.alloc(128);header.write('DDS ');header.writeUInt32LE(124,4);header.writeUInt32LE(0x100f,8);header.writeUInt32LE(size,12);header.writeUInt32LE(size,16);header.writeUInt32LE(size*4,20);
  header.writeUInt32LE(32,76);header.writeUInt32LE(0x41,80);header.writeUInt32LE(32,88);header.writeUInt32LE(0xff0000,92);header.writeUInt32LE(0xff00,96);header.writeUInt32LE(0xff,100);header.writeUInt32LE(0xff000000,104);header.writeUInt32LE(0x1000,108);
  return Buffer.concat([header,rgba]);
}
