import fs from 'node:fs';
import path from 'node:path';

const stage=path.resolve(process.argv[2]??'.tmpbuild/finalcombat-actors/import');
const read=f=>JSON.parse(fs.readFileSync(f,'utf8').replace(/^\uFEFF/,''));
const manifest=read(path.join(stage,'manifest.json'));
const root='src/AvatarStar.Server.Game',shopFile=root+'/Resources/shop_config.json',cardsFile=root+'/Resources/avatar_cards.json',textsFile=root+'/Config/game_text_id_to_text.json';
const shop=read(shopFile),cards=read(cardsFile),texts=read(textsFile);
const stamp=new Date().toISOString().replace(/[:.]/g,'-'),backup=path.join(stage,'server-backup',stamp);fs.mkdirSync(backup,{recursive:true});
for(const f of [shopFile,cardsFile,textsFile])fs.copyFileSync(f,path.join(backup,path.basename(f)));
for(const c of Object.values(shop.shop.categories))c.items=c.items.filter(x=>x.importedFrom!=='finalcombat');
cards.cards=cards.cards.filter(c=>c.importedFrom!=='finalcombat');
const existing=new Set([...Object.values(shop.shop.categories).flatMap(c=>c.items),...cards.cards].map(c=>c.sid));
const claim=sid=>{if(existing.has(sid))throw Error('Existing SID collision '+sid);existing.add(sid);};
for(const w of manifest.weapons){claim(w.sid);const category=Object.values(shop.shop.categories).find(c=>c.items.some(x=>x.resource===w.base));if(!category)throw Error('Missing base category '+w.base);
 const base=category.items.find(x=>x.resource===w.base),item=structuredClone(base);Object.assign(item,{sid:w.sid,resource:w.resource,display:w.display,description:'id_finalcombat_weapon_description',occupation:-1,level:1,grade:5,quantity:1,isLimited:false,importedFrom:'finalcombat',sourceResource:w.source});
 if(item.tip&&typeof item.tip==='object')item.tip.grade=5;
 item.prices=[{...item.prices[0],priceId:1,currency:1,price:1,rebatePrice:0,sellState:2,unitType:1,unit:1,isRenew:false,isCardPrice:false,isGive:false,vipLevel:0,startDateTime:0,endDateTime:0}];category.items.push(item);
}
for(const c of manifest.cards){claim(c.sid);cards.cards.push({sid:c.sid,subtype:1,display:c.display,resource:'',description:'id_finalcombat_card_description',grade:1,avatarLevel:1,bindType:2,isSell:'N',isSys:true,designer:'msgbox_common_conditionkey_146',level:1,prices:[{priceId:1,currency:1,unitType:2,unit:100,price:1,rebatePrice:0,isGive:false,isRenew:false,isCardPrice:false}],avatar:c.avatar,importedFrom:'finalcombat',sourceResource:c.source});}
Object.assign(texts,manifest.texts);
shop.shop.lastUpdated=new Date().toISOString().slice(0,10);
for(const [f,v] of [[shopFile,shop],[cardsFile,cards],[textsFile,texts]])fs.writeFileSync(f,JSON.stringify(v,null,2)+'\n');
const catalog={version:1,cards:manifest.cards.map(({sid,name,source,display})=>({sid,name,source,display})),weapons:manifest.weapons.map(({sid,name,source,resource,subtype,base})=>({sid,name,source,resource,subtype,base})),excluded:manifest.excluded,warnings:manifest.warnings};
fs.writeFileSync(root+'/Config/finalcombat_items.json',JSON.stringify(catalog,null,2)+'\n');
console.log(JSON.stringify({cards:manifest.cards.length,weapons:manifest.weapons.length,backup}));
