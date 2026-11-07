import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PdeArchive, luaStrings, sha256} from './pde-format.mjs';
import {prototypes, embedOriginal} from './lua-chunk.mjs';

const resource = 'scripts/lobby/playgame.lua';
const marker = 'AS_ROOM_AI_V2';
const [mode, filename, stage = '.tmpbuild/room-ai/client-patch'] = process.argv.slice(2);
if (!filename || !['prepare','apply','rollback'].includes(mode))
  throw new Error('Usage: node client-patches/install-room-ai.mjs prepare|apply|rollback <AvatarStar.pde> [stage-directory]');

function encodedWrite(fd, key, offset, bytes) {
  const encrypted = Buffer.from(bytes);
  for(let i=0;i<encrypted.length;i++) encrypted[i] ^= key[(offset+i)%4096];
  if(fs.writeSync(fd,encrypted,0,encrypted.length,offset)!==encrypted.length) throw new Error('Short PDE write');
}
function replaceEntry(file, bytes, expectedHash) {
  const archive = new PdeArchive(file);
  const entry = archive.entries().find(e=>e.path===resource);
  if(!entry || sha256(archive.data(entry))!==expectedHash) throw new Error('Original resource changed; prepare again');
  const previous = archive.read(entry.directoryOffset+120,8);
  const group = Math.ceil(archive.size/0x401000);
  const firstBlock = group*1024;
  const count=Math.ceil(bytes.length/4096);
  if(count>=1024) throw new Error('Replacement exceeds one allocation group');
  const key=archive.key, oldSize=archive.size;
  archive.close();
  const fd=fs.openSync(file,'r+');
  try {
    // New allocation only; existing scripts and collision data are never overwritten.
    const end=(group*0x401000)+4096+count*4096;
    const zeros=Buffer.alloc(1024*1024);
    for(let offset=oldSize;offset<end;offset+=zeros.length)
      encodedWrite(fd,key,offset,zeros.subarray(0,Math.min(zeros.length,end-offset)));
    for(let i=0;i<count;i++) {
      const fat=Buffer.alloc(4);fat.writeUInt32LE((0x80000000|(i===count-1?0:firstBlock+i+1))>>>0);
      encodedWrite(fd,key,group*0x401000+i*4,fat);
      encodedWrite(fd,key,group*0x401000+4096+i*4096,bytes.subarray(i*4096,(i+1)*4096));
    }
    fs.fsyncSync(fd);
    const next=Buffer.alloc(8);next.writeUInt32LE(firstBlock);next.writeUInt32LE(bytes.length,4);
    encodedWrite(fd,key,entry.directoryOffset+120,next);fs.fsyncSync(fd);
    return {directoryOffset:entry.directoryOffset,previous:previous.toString('hex'),next:next.toString('hex'),oldSize};
  } finally {fs.closeSync(fd);}
}
function verify(file, bytes, inventory) {
  const archive=new PdeArchive(file);
  try {
    const entries=archive.entries();
    if(entries.length!==inventory.length)throw new Error('Archive directory count changed');
    for(let i=0;i<entries.length;i++) {
      const before=inventory[i],after=entries[i];
      if(before.path!==after.path)throw new Error('Archive directory order changed');
      if(after.path!==resource && (before.block!==after.block||before.size!==after.size||before.directoryOffset!==after.directoryOffset))
        throw new Error('Unrelated resource modified: '+after.path);
    }
    if(!archive.data(entries.find(e=>e.path===resource)).equals(bytes))throw new Error('PDE readback mismatch');
  }finally{archive.close();}
}

fs.mkdirSync(stage,{recursive:true});
const manifestFile=path.join(stage,'manifest.json');
if(mode==='prepare') {
  const archive=new PdeArchive(filename), inventory=archive.entries(), entry=inventory.find(e=>e.path===resource);
  if(!entry)throw new Error('Room script missing');
  const current=archive.data(entry);archive.close();
  let original=current;
  const strings=luaStrings(current);
  if(strings.some(s=>s.text==='AS_ROOM_AI_V1'))original=strings.find(s=>s.data.subarray(0,4).toString('hex')==='1b4c7561')?.data;
  if(strings.some(s=>s.text===marker)) {
    const embedded=prototypes(current).children[0];
    original=Buffer.concat([current.subarray(0,12),current.subarray(embedded.start,embedded.end)]);
  }
  if(!original)throw new Error('Previous patch has no preserved original bytecode');
  fs.writeFileSync(path.join(stage,'before.luac'),current);
  fs.writeFileSync(path.join(stage,'original.luac'),original);
  const hook=fs.readFileSync('client-patches/room-ai.lua','utf8');
  const wrapper=`local marker = "${marker}"\nlocal function original() end\nlocal function install()\n${hook}\nend\noriginal()\nlocal ok, err = pcall(install)\nif not ok then print("Room AI UI: " .. tostring(err)) end\n`;
  const source=path.resolve(stage,'playgame-ai.lua'), binary=path.resolve(stage,'playgame-ai.luac');
  fs.writeFileSync(source,wrapper);
  const compile=spawnSync(path.resolve('tools/Lua/luac.exe'),['-o',binary,source],{encoding:'utf8'});
  if(compile.status!==0)throw new Error('Lua compile failed: '+compile.stderr+compile.stdout);
  const replacement=embedOriginal(fs.readFileSync(binary),original), constants=luaStrings(replacement);
  fs.writeFileSync(binary,replacement);
  if(!constants.some(s=>s.text==='room_ai_'))throw new Error('AI hook missing');
  const testFile=path.join(stage,'verified-client.pde');
  fs.copyFileSync(filename,testFile);
  const allocation=replaceEntry(testFile,replacement,sha256(current));
  verify(testFile,replacement,inventory);
  fs.writeFileSync(manifestFile,JSON.stringify({resource,filename:path.resolve(filename),beforeHash:sha256(current),
    originalHash:sha256(original),replacementHash:sha256(replacement),inventory,allocation,verified:true},null,2));
  console.log(JSON.stringify({verified:true,resource,originalBytes:original.length,compiledBytes:replacement.length,stage}));
} else {
  const manifest=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
  if(path.resolve(filename)!==manifest.filename||!manifest.verified)throw new Error('Manifest target mismatch');
  const replacement=fs.readFileSync(path.join(stage,'playgame-ai.luac'));
  if(sha256(replacement)!==manifest.replacementHash)throw new Error('Compiled patch changed');
  if(mode==='apply') {
    manifest.applied=replaceEntry(filename,replacement,manifest.beforeHash);
    fs.writeFileSync(manifestFile,JSON.stringify(manifest,null,2));
    verify(filename,replacement,manifest.inventory);
    console.log(JSON.stringify({applied:true,resource,sha256:manifest.replacementHash,backup:path.join(stage,'before.luac')}));
  } else {
    if(!manifest.applied)throw new Error('No installed patch in this manifest');
    const archive=new PdeArchive(filename), entry=archive.entries().find(e=>e.path===resource);
    if(sha256(archive.data(entry))!==manifest.replacementHash)throw new Error('Resource changed after installation');
    const key=archive.key;archive.close();const fd=fs.openSync(filename,'r+');
    try{encodedWrite(fd,key,manifest.applied.directoryOffset+120,Buffer.from(manifest.applied.previous,'hex'));fs.fsyncSync(fd);}finally{fs.closeSync(fd);}
    console.log('Original directory pointer restored; appended blocks retained for safety.');
  }
}
