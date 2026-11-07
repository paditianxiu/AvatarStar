import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {decodeCache,sha256} from './pde-format.mjs';
const stage=path.resolve(process.argv[2]??'.tmpbuild/pde-rebuild');
const manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8'));
const verify=fs.mkdtempSync(path.join(stage,'unpdec-verification-'));
const pde=path.join(verify,'AvatarStar.pde');fs.copyFileSync(manifest.verifiedPde,pde);
const logs={};
function run(exe,args,input){const name=path.basename(exe),log=path.join(verify,name+'.log'),fd=fs.openSync(log,'w');
 try {const r=spawnSync(exe,args,{cwd:verify,input,stdio:['pipe',fd,fd]});if(r.error||r.status!==0)throw r.error??Error(name+' exited '+r.status);logs[name]=log;}finally{fs.closeSync(fd);}}
run(path.resolve('tools/unpdec/Release/Unpack/FastXOR.exe'),[pde],'\n');
// UnPdeC scans its executable directory, rather than the working directory.
const unpack=path.join(verify,'UnPdeC.exe');fs.copyFileSync('tools/unpdec/Release/Unpack/UnPdeC.exe',unpack);
run(unpack,[],'Y\n\n');
function walk(dir,prefix=''){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name),prefix+e.name+'/'):[prefix+e.name]);}
const source=path.join(stage,'all-resources'),extracted=path.join(verify,'AvatarStar_cache');
const metadata=new Set(['BlockTracker.json','VfsOffsets.txt','VfsTable.hex']);
const expected=walk(source),actual=walk(extracted).filter(f=>!metadata.has(f));if(expected.length!==actual.length)throw Error('UnPdeC file count mismatch: '+actual.length+'/'+expected.length);
let checked=0;const files=[];
for(const file of expected){const left=fs.readFileSync(path.join(source,file)),right=fs.readFileSync(path.join(extracted,file));if(!left.equals(right))throw Error('UnPdeC readback mismatch: '+file);files.push({path:file,size:left.length,sha256:sha256(left)});if(++checked%5000===0)console.log('Independently verified',checked);}
let cachesChecked=0;
const compression=JSON.parse(fs.readFileSync(path.join(stage,'compression-report.json'),'utf8'));
const uncache=path.resolve('tools/unpdec/Release/Unpack/UnCache.exe'),cacheDir=path.join(verify,'cache-roundtrip');
for(const entry of compression){
 if(entry.ok===false)throw Error('Previously failed compression: '+entry.file);
 const input=path.join(cacheDir,entry.file),packed=fs.readFileSync(path.join(source,entry.file));fs.mkdirSync(path.dirname(input),{recursive:true});fs.writeFileSync(input,packed);
 run(uncache,[input],'');
 const output=input.replace(/\.lua\.cache$/,'.luac').replace(/\.cache$/,''),bytes=fs.readFileSync(output);
 if(!bytes.equals(decodeCache(packed,false))||(entry.sha256&&sha256(bytes)!==entry.sha256))throw Error('UnCache payload mismatch: '+entry.file);
 cachesChecked++;
}
const report={files:checked,caches:cachesChecked,verifiedAt:new Date().toISOString(),logs};
fs.writeFileSync(path.join(stage,'unpdec-verification.json'),JSON.stringify(report,null,2)+'\n');
fs.writeFileSync(path.join(stage,'resource-hashes.json'),JSON.stringify(files,null,2)+'\n');console.log(report);
