// This client uses Lua 5.2-alpha prototypes behind a Lua 5.1 header.
// Keep native bytecode intact; only splice an independently compiled function.
export function prototypes(bytes) {
  if(bytes.subarray(0,12).toString('hex')!=='1b4c75615100010404040800')throw new Error('Unexpected Lua header');
  let offset=12;
  const u32=()=>{const n=bytes.readUInt32LE(offset);offset+=4;return n;};
  const string=()=>{const n=u32();offset+=n;};
  function read(){
    const start=offset;string();offset+=12;
    const codeCount=u32();offset+=codeCount*4;
    const constants=u32();
    for(let i=0;i<constants;i++){
      const type=bytes[offset++];if(type===1)offset++;else if(type===3)offset+=8;else if(type===4)string();else if(type!==0)throw new Error('Invalid constant');
    }
    const children=[];const count=u32();for(let i=0;i<count;i++)children.push(read());
    const descriptors=u32();offset+=descriptors*2;
    const lines=u32();offset+=lines*4;
    const locals=u32();for(let i=0;i<locals;i++){string();offset+=8;}
    const upvalues=u32();for(let i=0;i<upvalues;i++)string();
    return {start,end:offset,children,codeCount};
  }
  const main=read();if(offset!==bytes.length)throw new Error('Lua prototype bounds mismatch');return main;
}

export function embedOriginal(wrapper, original) {
  const root=prototypes(wrapper), replacement=prototypes(original);
  if(root.children.length!==2)throw new Error('Expected original and install functions');
  const stub=root.children[0];
  const result=Buffer.concat([wrapper.subarray(0,stub.start),original.subarray(replacement.start,replacement.end),wrapper.subarray(stub.end)]);
  const embedded=prototypes(result).children[0];
  if(!result.subarray(embedded.start,embedded.end).equals(original.subarray(12)))throw new Error('Original function modified');
  return result;
}
