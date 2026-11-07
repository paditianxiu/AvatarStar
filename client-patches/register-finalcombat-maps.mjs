import fs from 'node:fs';import path from 'node:path';
const stage=process.argv[2]??'.tmpbuild/finalcombat-maps/import',manifest=JSON.parse(fs.readFileSync(path.join(stage,'manifest.json'),'utf8'));
const root='src/AvatarStar.Server.Game/Config',file=root+'/lobby_levels.json',data=JSON.parse(fs.readFileSync(file,'utf8')),info=JSON.parse(fs.readFileSync(root+'/lobby_levelinfo.json','utf8'));
const old=data.levels.filter(e=>!e.imported);for(const m of manifest.maps){
  if(old.some(e=>e.id===m.id||e.name===m.code))throw Error('Map ID collision: '+m.code);
  if(!fs.existsSync(root+'/AiNavigation/'+m.code+'.json.gz'))throw Error('Missing navigation: '+m.code);
  const key='id_fc_'+m.code.toLowerCase();old.push({id:m.id,name:m.code,gameType:4,showName:key,description:key,difficulty:0,group:0,imported:true,sourceScene:m.sourceScene});info[m.code]=key;
}
data.levels=old;data.source=data.source.replace(/ \+ Final Combat imported scenes.*$/,'')+' + Final Combat imported scenes (50)';
const write=(p,v)=>fs.writeFileSync(p,(JSON.stringify(v,null,2)+'\n').replaceAll('\n','\r\n'));
write(file,data);write(root+'/lobby_levelinfo.json',info);
write(root+'/finalcombat_maps.json',{source:manifest.source,maps:manifest.maps.map(({id,code,sourceScene,name,sourceScript,variants,playableBounds,deadVolumes})=>({id,code,sourceScene,name,sourceScript,variants,playableBounds,deadVolumes})),unavailableScripts:manifest.unavailableScripts});
console.log(JSON.stringify({added:manifest.maps.length,total:old.length,first:manifest.maps[0].code,last:manifest.maps.at(-1).code}));
