import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';

// Reuse the supplied PDEPack implementation without starting its WPF window.
const root=path.resolve('.tmpbuild/pde-rebuild/pack-adapter');
fs.mkdirSync(root,{recursive:true});
const source=fs.readFileSync('tools/unpdec/Src/PDEPack/MainWindow.xaml.cs','utf8').replace(/^\uFEFF+/, '');
const start=source.indexOf('        private void PackDirectory(');
if(start<0)throw Error('PDEPack entry point not found');
const constants=source.match(/private const (?:uint|int) \w+ = [^;]+;/g);
if(constants?.length!==3)throw Error('Unexpected PDEPack constants');
const core='using System;\nusing System.IO;\nusing System.Collections.Generic;\nnamespace PDEPack { public class MainWindow {\n'+constants.join('\n')+'\n'+source.slice(start).replace('private void PackDirectory(', 'public void PackDirectory(');
const openArchive='using var fs = new FileStream(outputPath, FileMode.Create, FileAccess.ReadWrite, FileShare.None);';
if(!core.includes(openArchive))throw Error('Unexpected PDEPack allocation layout');
// AvatarStar passes a signed LONG to SetFilePointer with no high DWORD. The
// generic packer supports larger archives, but this client cannot read them.
fs.writeFileSync(path.join(root,'PackCore.cs'),core.replace(openArchive,
 'if (fileSize >= 0x80000000UL) throw new InvalidDataException("AvatarStar archive exceeds native signed 2 GiB seek limit; split resources into separate PDE files.");\n            '+openArchive));
const compressor=fs.readFileSync('tools/unpdec/Src/ReCache/Services/Compressor.cs','utf8');
const compressStart=compressor.indexOf('    public static byte[] Compress('),compressEnd=compressor.indexOf('    private static (int offset, int length) FindBestMatch(');
if(compressStart<0||compressEnd<compressStart)throw Error('Unexpected ReCache compressor layout');
const byteCheck='if (data[i] != data[position])',search=compressor.slice(compressEnd);
if(search.split(byteCheck).length!==3)throw Error('Unexpected ReCache match search layout');
// The client copies matches in DWORDs at three-byte increments. Both the coarse
// and fine searches must exclude distances 1 and 2; UnCache's bytewise decoder
// accepts those distances and therefore cannot detect this incompatibility.
const nativeSearch=search.replaceAll(byteCheck,'if (position - i < 3 || data[i] != data[position])');
fs.writeFileSync(path.join(root,'Compressor.cs'),compressor.slice(0,compressStart)+fs.readFileSync('client-patches/unpdec-compressor-body.cs','utf8')+'\n'+nativeSearch);
fs.writeFileSync(path.join(root,'PackAdapter.csproj'),`<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net8.0</TargetFramework><ImplicitUsings>enable</ImplicitUsings><Nullable>enable</Nullable></PropertyGroup></Project>\n`);
fs.writeFileSync(path.join(root,'Program.cs'),`if(args.Length!=3) throw new ArgumentException("pack|compress|compress-list <input> <output>");
if(args[0]=="pack") new PDEPack.MainWindow().PackDirectory(args[1],args[2]);
else if(args[0]=="compress") {
 ReCache.Services.Compressor.EnableLogging(false);
 File.WriteAllBytes(args[2],ReCache.Services.Compressor.Compress(File.ReadAllBytes(args[1])));
} else if(args[0]=="compress-list") {
 ReCache.Services.Compressor.EnableLogging(false);
 var list=System.Text.Json.JsonSerializer.Deserialize<List<Dictionary<string,string>>>(File.ReadAllText(args[1]))!;
 int count=0;foreach(var item in list){File.WriteAllBytes(item["output"],ReCache.Services.Compressor.Compress(File.ReadAllBytes(item["input"])));if(++count%25==0)Console.WriteLine($"Compressed {count}/{list.Count}");}
 File.WriteAllText(args[2],$"{count}");
} else throw new ArgumentException("Unknown mode");
Console.WriteLine($"{args[0]} completed: {new FileInfo(args[2]).Length} bytes");\n`);
const r=spawnSync('dotnet',['build',path.join(root,'PackAdapter.csproj'),'-c','Release','--nologo','-v','quiet'],{stdio:'inherit'});
if(r.status!==0)throw Error('Could not build unpdec adapter');
console.log(path.join(root,'bin/Release/net8.0/PackAdapter.dll'));
