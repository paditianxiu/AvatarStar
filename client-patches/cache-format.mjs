import {decodeCache} from './pde-format.mjs';

// PDE resource caches use QuickLZ and an uncomplemented CRC32 seeded by the resource path.
const table=Array.from({length:256},(_,i)=>{let c=i;for(let j=0;j<8;j++)c=c&1?0xedb88320^(c>>>1):c>>>1;return c>>>0;});
export function crc32(bytes,seed=0){let c=seed;for(const b of bytes)c=table[(c^b)&255]^(c>>>8);return c>>>0;}
const seed=crc32(Buffer.from('crc_key'));
export function cacheHeader(bytes){
  if(bytes.length<25||bytes.readUInt16LE(4)!==2)throw Error('Invalid cache header');
  let base=12;const count=bytes.readUInt32LE(8);
  for(let i=0;i<count;i++){if(base+4>bytes.length)throw Error('Truncated dependencies');base+=4+bytes.readUInt32LE(base)+8;}
  if(base+12>bytes.length||base+12+bytes.readUInt32LE(base)!==bytes.length)throw Error('Cache size mismatch');
  return {base,type:bytes.readUInt32LE(0),version:bytes.readUInt16LE(6)};
}
export function cacheChecksum(bytes,resource){const {base}=cacheHeader(bytes);return crc32(bytes.subarray(base+12),crc32(Buffer.from(resource),seed));}
export function rekeyCache(bytes,resource,version){
  const result=Buffer.from(bytes),h=cacheHeader(result);
  if(version!==undefined)result.writeUInt16LE(version,6);
  result.writeUInt32LE(cacheChecksum(result,resource),h.base+4);return result;
}
export function encodeCache(fullPayload,template,resource,version){
  const h=cacheHeader(template), q=Buffer.alloc(9+fullPayload.length);
  // QuickLZ level 3, long size fields, literal (uncompressed) payload.
  q[0]=0x6e;q.writeUInt32LE(q.length,1);q.writeUInt32LE(fullPayload.length,5);fullPayload.copy(q,9);
  const out=Buffer.alloc(24+q.length);template.copy(out,0,0,8);out.writeUInt32LE(0,8);
  out.writeUInt16LE(version??h.version,6);out.writeUInt32LE(q.length,12);out.writeUInt32LE(1,20);q.copy(out,24);
  out.writeUInt32LE(cacheChecksum(out,resource),16);
  if(!decodeCache(out,false).equals(fullPayload))throw Error('Cache encode roundtrip failed');return out;
}
