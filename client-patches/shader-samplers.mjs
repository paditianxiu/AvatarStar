// D3DX reads sampler registers from the CTAB comment, while the cache carries
// a second reflection table. Keep both consistent with the actual operands.
export function syncShaderSamplerReflection(fullPayload){
  const b=Buffer.from(fullPayload),end=8+b.readUInt32LE(4),samplers=new Map();
  let p=end,count=b.readUInt32LE(p);p+=4;
  for(let i=0;i<count;i++){const len=b.readUInt32LE(p);p+=4;const name=b.subarray(p,p+len).toString();p+=len;const reg=b.readInt32LE(p),size=b.readInt32LE(p+4);p+=8;if(size===-1)samplers.set(name,reg);}
  if(p!==b.length)throw Error('Shader reflection tail mismatch');
  p=12;let changed=0;
  while(p<end){const token=b.readUInt32LE(p),op=token&0xffff;if(op===0xffff)break;
    if(op!==0xfffe){p+=4+((token>>>24)&15)*4;continue;}
    const next=p+4+((token>>>16)&0x7fff)*4;
    if(next>end)throw Error('Truncated shader comment');
    if(b.toString('ascii',p+4,p+8)==='CTAB'){
      const base=p+8,n=b.readUInt32LE(base+12),info=base+b.readUInt32LE(base+16);
      if(info+n*20>next)throw Error('Invalid shader constant table');
      for(let i=0;i<n;i++){const entry=info+i*20;if(b.readUInt16LE(entry+4)!==3)continue;
        const start=base+b.readUInt32LE(entry),stop=b.indexOf(0,start);if(start<base||stop<start||stop>=next)throw Error('Invalid constant name');
        const name=b.toString('utf8',start,stop),reg=samplers.get(name==='UVMap'?'Decal_Color_Map':name);
        if(reg===undefined)continue;
        if(reg<0||reg>15)throw Error('Invalid reflected sampler');
        if(b.readUInt16LE(entry+6)!==reg){b.writeUInt16LE(reg,entry+6);changed++;}
      }
    }
    p=next;
  }
  return {bytes:b,changed};
}

// DX9 SM2/SM3 parameter tokens encode sampler registers independently of
// instructions. Change operands and both reflection tables together.
export function remapShaderSamplers(fullPayload,registers){
  const b=Buffer.from(fullPayload),codeSize=b.readUInt32LE(4),end=8+codeSize;
  if(end>b.length||codeSize%4||((b.readUInt32LE(8)>>>8)&255)<2)throw Error('Unsupported shader bytecode');
  let p=12,changed=0;
  while(p<end){
    const token=b.readUInt32LE(p),opcode=token&0xffff;
    if(opcode===0xffff){p+=4;break;}
    if(opcode===0xfffe){p+=4+((token>>>16)&0x7fff)*4;continue;}
    const length=(token>>>24)&15;if(!length&&![0,28,29,39,42,43,44].includes(opcode))throw Error('Invalid shader instruction length');
    if(p+4+length*4>end)throw Error('Truncated shader instruction');
    for(let i=1;i<=length;i++){
      // DEF/DEFI/DEFB carry immediate constants after their destination register.
      if([81,48,47].includes(opcode)&&i>1)continue;
      const offset=p+i*4,operand=b.readUInt32LE(offset),type=((operand>>>28)&7)|((operand>>>8)&24);
      if((operand&0x80000000)&&type===10&&registers.has(operand&0x7ff)){
        const reg=registers.get(operand&0x7ff);if(reg<0||reg>15)throw Error('Invalid sampler register');
        b.writeUInt32LE(((operand&~0x7ff)|reg)>>>0,offset);changed++;
      }
    }
    p+=4+length*4;
  }
  if(p!==end)throw Error('Shader bytecode tail mismatch');
  let count=b.readUInt32LE(p);p+=4;
  for(let i=0;i<count;i++){const n=b.readUInt32LE(p);p+=4+n;const reg=b.readInt32LE(p),size=b.readInt32LE(p+4);if(size===-1&&registers.has(reg))b.writeInt32LE(registers.get(reg),p);p+=8;}
  if(p!==b.length)throw Error('Shader reflection tail mismatch');
  const reflected=syncShaderSamplerReflection(b);return {bytes:reflected.bytes,changed,reflectionChanged:reflected.changed};
}
