import fs from 'node:fs';
import {PdeArchive,sha256} from './pde-format.mjs';

// Build on a disposable copy. Existing file blocks stay in place. Only the fixed
// root directory is replaced; every descendant directory is written to new blocks.
export function appendResources(filename,resources){
  const archive=new PdeArchive(filename),before=archive.entries(),key=archive.key,oldSize=archive.size;
  const root={children:new Map(),path:'',type:2,block:0,size:4096};
  const nodes=new Map([['',root]]);
  for(const e of before){const n={...e,children:e.type===2?new Map():null};nodes.set(e.path.toLowerCase(),n);const parent=e.path.slice(0,e.path.lastIndexOf('/')+1).slice(0,-1);nodes.get(parent.toLowerCase()).children.set(e.path.split('/').at(-1).toLowerCase(),n);}
  const replacements=[];
  for(const [name,file] of resources){
    if(name.startsWith('/')||name.includes('..')||name.includes('\\'))throw Error('Invalid resource path');
    const parts=name.split('/');let parent=root,prefix='';
    for(let i=0;i<parts.length;i++){
      const part=parts[i];if(Buffer.byteLength(part)>110)throw Error('Resource filename too long');
      const p=prefix+part,isFile=i===parts.length-1;let n=nodes.get(p.toLowerCase());
      if(!n){n={path:p,type:isFile?1:2,children:isFile?null:new Map()};nodes.set(p.toLowerCase(),n);parent.children.set(part.toLowerCase(),n);}
      if(n.type!==(isFile?1:2))throw Error('File/directory conflict: '+p);
      if(isFile){n.file=file;n.size=fs.statSync(file).size;replacements.push(n);}else parent=n;
      prefix=p+'/';
    }
  }
  if(root.children.size>32)throw Error('Root directory exceeds fixed block');
  let nextBlock=Math.ceil(oldSize/0x401000)*1024;
  const fats=new Map();
  function allocate(n){const count=Math.max(1,Math.ceil(n.size/4096));n.block=nextBlock;nextBlock+=count;
    for(let i=0;i<count;i++){const b=n.block+i,g=Math.floor(b/1024);if(!fats.has(g))fats.set(g,Buffer.alloc(4096));fats.get(g).writeUInt32LE((0x80000000|(i===count-1?0:b+1))>>>0,(b%1024)*4);}
  }
  for(const n of replacements)allocate(n);
  const dirs=[...nodes.values()].filter(n=>n.type===2&&n!==root);
  for(const n of dirs){n.size=Math.max(4096,Math.ceil(n.children.size*128/4096)*4096);allocate(n);}
  const end=archive.real(nextBlock-1)+4096;archive.close();
  if(end>=0x80000000)throw Error('PDE append would exceed the native signed 2 GiB seek limit');
  const fd=fs.openSync(filename,'r+');
  function write(offset,bytes){const b=Buffer.from(bytes);for(let i=0;i<b.length;i++)b[i]^=key[(offset+i)%4096];if(fs.writeSync(fd,b,0,b.length,offset)!==b.length)throw Error('Short PDE write');}
  const real=b=>(b+Math.floor(b/1024)+1)*4096;
  function data(n,b){let offset=0;while(offset<b.length){const block=n.block+offset/4096,len=Math.min(b.length-offset,(1024-block%1024)*4096);write(real(block),b.subarray(offset,offset+len));offset+=len;}}
  function directory(n){const b=Buffer.alloc(n.size);let offset=0;for(const child of n.children.values()){b[offset]=child.type;b.write(child.path.split('/').at(-1),offset+1,'utf8');b.writeUInt32LE(child.block,offset+120);b.writeUInt32LE(child.size,offset+124);offset+=128;}return b;}
  try{
    const zero=Buffer.alloc(1024*1024);for(let p=oldSize;p<end;p+=zero.length)write(p,zero.subarray(0,Math.min(zero.length,end-p)));
    for(const [group,fat] of fats)write(group*0x401000,fat);
    for(const n of replacements)data(n,fs.readFileSync(n.file));
    for(const n of dirs)data(n,directory(n));
    fs.fsyncSync(fd);write(4096,directory(root));fs.fsyncSync(fd);
  }finally{fs.closeSync(fd);}
  const check=new PdeArchive(filename);
  try{
    const after=check.entries(),index=new Map(after.map(e=>[e.path.toLowerCase(),e]));
    if(after.length!==nodes.size-1)throw Error('PDE directory inventory mismatch');
    const changed=new Set(resources.keys());
    for(const e of before)if(e.type===1&&!changed.has(e.path)){const n=index.get(e.path.toLowerCase());if(!n||n.block!==e.block||n.size!==e.size)throw Error('Unrelated resource changed: '+e.path);}
    for(const n of replacements)if(!check.data(index.get(n.path.toLowerCase())).equals(fs.readFileSync(n.file)))throw Error('PDE readback mismatch: '+n.path);
    return {beforeFiles:before.filter(e=>e.type===1).length,afterFiles:after.filter(e=>e.type===1).length,resources:replacements.map(n=>({path:n.path,size:n.size,sha256:sha256(fs.readFileSync(n.file))})),oldSize,newSize:end};
  }finally{check.close();}
}
