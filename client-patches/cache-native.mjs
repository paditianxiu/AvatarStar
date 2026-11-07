import {cacheHeader} from './cache-format.mjs';

// AvatarStar client 1.4.0.65795, decoder at 0x4F9980: match copies read/write
// DWORDs while advancing three bytes. Unlike a bytewise decoder, this requires
// a match distance of at least three to avoid reading unwritten output bytes.
export function decodeCacheNative(bytes,stripHeader=true,{fill=0,onMatch}={}){
  const {base}=cacheHeader(bytes),q=bytes.subarray(base+12),long=(q[0]&2)!==0,header=long?9:3;
  const length=long?q.readUInt32LE(5):q[2];
  if(length>100_000_000)throw Error('Invalid native cache output size');
  if(!(q[0]&1)){const raw=q.subarray(header,header+length);if(raw.length!==length)throw Error('Truncated native cache');return stripHeader?raw.subarray(8):raw;}
  const source=Buffer.alloc(q.length-header+16);q.copy(source,0,header);
  const output=Buffer.alloc(length+16,fill),shifts=[4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0];
  let input=0,out=0,bits=1;
  while(out<length){
    if(bits===1){bits=source.readUInt32LE(input);input+=4;}
    if(!bits||input>q.length-header)throw Error('Invalid native cache control word');
    const value=source.readUInt32LE(input);
    if(bits&1){
      let offset,count,used;
      if(!(value&3)){offset=(value>>>2)&63;count=3;used=1;}
      else if(!(value&2)){offset=(value>>>2)&16383;count=3;used=2;}
      else if(!(value&1)){offset=(value>>>6)&1023;count=((value>>>2)&15)+3;used=2;}
      else if((value&127)===3){offset=value>>>15;count=((value>>>7)&255)+3;used=4;}
      else{offset=(value>>>7)&131071;count=((value>>>2)&31)+2;used=3;}
      if(!offset||offset>out||out+count>length)throw Error('Invalid native cache backreference');
      onMatch?.({offset,count,out});
      for(let n=0;n<count;n+=3)output.writeUInt32LE(output.readUInt32LE(out+n-offset),out+n);
      out+=count;input+=used;bits>>>=1;
    }else{
      if(out>=length-11)break;
      output.writeUInt32LE(value,out);const count=shifts[bits&15];out+=count;input+=count;bits>>>=count;
    }
  }
  while(out<length){if(bits===1){input+=4;bits=0x80000000;}if(input>=q.length-header)throw Error('Truncated native cache tail');output[out++]=source[input++];bits>>>=1;}
  return output.subarray(stripHeader?8:0,length);
}
