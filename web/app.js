'use strict';
const $=id=>document.getElementById(id);
const names={cash:'Nakit',kp:'KP',gold:'Altın',gp:'GP'};
const number=n=>new Intl.NumberFormat('tr-TR').format(n);
let snapshot={players:[],logs:[]},selectedId=null,controlData={controls:[]},toastTimer;
function el(tag,text,className){const node=document.createElement(tag);if(text!==undefined)node.textContent=text;if(className)node.className=className;return node;}
function toast(message,error=false){$('toast').textContent=message;$('toast').hidden=false;$('toast').style.background=error?'#4b2929':'#2e3b34';clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,5500);}
async function request(path,payload){const options=payload?{method:'POST',headers:{'Content-Type':'application/json','X-Admin-Token':snapshot.token},body:JSON.stringify(payload)}:{};const res=await fetch(path,options);const data=await res.json();if(!res.ok)throw new Error(data.error||'İstek tamamlanamadı.');return data;}
async function refresh(){snapshot=await request('/api/state');if(!snapshot.players.some(p=>p.id===selectedId))selectedId=snapshot.players[0]?.id||null;renderAdmin();}
function renderAdmin(){
 $('playerCount').textContent=snapshot.players.length;
 $('players').replaceChildren();
 if(!snapshot.players.length)$('players').append(el('p','Başlamak için ilk test oyuncunu oluştur.','empty'));
 for(const p of snapshot.players){const button=el('button',undefined,'player'+(p.id===selectedId?' selected':''));button.type='button';button.setAttribute('aria-pressed',String(p.id===selectedId));button.append(el('span',p.name.slice(0,2).toLocaleUpperCase('tr-TR'),'avatar'));const text=el('span',p.name);text.append(el('small','#'+p.id.slice(0,8)));button.append(text);button.onclick=()=>{selectedId=p.id;renderAdmin();};$('players').append(button);}
 const player=snapshot.players.find(p=>p.id===selectedId);
 $('selectedName').textContent=player?.name||'Oyuncu seç';$('selectedId').textContent=player?'#'+player.id.slice(0,8):'—';$('grantButton').disabled=!player;
 $('balances').replaceChildren(...Object.entries(names).map(([key,label])=>{const card=el('div',undefined,'balance');card.append(el('span',label.toLocaleUpperCase('tr-TR')),el('strong',player?number(player[key]):'—'));return card;}));
 $('history').replaceChildren();
 if(!snapshot.logs.length){const row=el('tr');const cell=el('td','Henüz işlem yok. İlk bakiye eklemen burada görünecek.','empty');cell.colSpan=5;row.append(cell);$('history').append(row);}
 for(const log of snapshot.logs){const row=el('tr');for(const [i,text]of[log.name,`+${number(log.amount)} ${names[log.currency]}`,`${number(log.balance_after)} ${names[log.currency]}`,log.reason,new Date(log.created_at).toLocaleString('tr-TR')].entries())row.append(el('td',text,i===1?'positive':undefined));$('history').append(row);}
}
$('playerForm').onsubmit=async event=>{event.preventDefault();const button=event.currentTarget.querySelector('button');button.disabled=true;try{const result=await request('/api/players',{name:$('playerName').value});selectedId=result.id;$('playerName').value='';await refresh();toast('Test oyuncusu oluşturuldu.');}catch(e){toast(e.message,true);}finally{button.disabled=false;}};
let pendingGrant=null;
$('grantForm').onsubmit=async event=>{event.preventDefault();if(!selectedId)return;const button=$('grantButton');button.disabled=true;const draft={playerId:selectedId,currency:$('currency').value,amount:Number($('amount').value),reason:$('reason').value};const signature=JSON.stringify(draft);if(pendingGrant?.signature!==signature)pendingGrant={signature,payload:{...draft,requestId:crypto.randomUUID()}};try{await request('/api/grants',pendingGrant.payload);await refresh();pendingGrant=null;toast('Bakiye eklendi ve işlem kaydedildi.');}catch(e){toast(e.message,true);}finally{button.disabled=!selectedId;}};
function renderControls(){const query=$('controlSearch').value.toLocaleLowerCase('tr-TR');const list=controlData.controls.filter(c=>(!$('onlyBound').checked||c.bindings.length)&&JSON.stringify(c).toLocaleLowerCase('tr-TR').includes(query));$('controlRows').replaceChildren();for(const c of list){const row=el('tr');const name=el('td',c.label);name.append(el('small',`${c.action} · ${c.id}`));row.append(name,el('td',c.bindings.map(b=>b.key).join(', ')||'—'),el('td',c.mobile),el('td',c.status));$('controlRows').append(row);}if(!list.length){const row=el('tr');const cell=el('td','Eşleşen kontrol yok.');cell.colSpan=4;row.append(cell);$('controlRows').append(row);}}
$('controlSearch').oninput=renderControls;$('onlyBound').onchange=renderControls;

// Game adapters subscribe to window.addEventListener('wrb:input', event => ...).
// A command can be held by more than one finger/key; releasing one source preserves the other.
const held=new Map(),logLines=[],lastHeld=new Map();let activeView='admin',yaw=0,pitch=0,lookPointer=null,lookLast=null,stickPointer=null,stickRect=null;
function emit(detail){const input={...detail,time:performance.now()};window.dispatchEvent(new CustomEvent('wrb:input',{detail:input}));if(detail.phase!=='change'){logLines.unshift(`${detail.phase.padEnd(7)} ${detail.action}${detail.value?` ${JSON.stringify(detail.value)}`:''}`);logLines.length=Math.min(12,logLines.length);$('eventLog').textContent=logLines.join('\n');}}
function command(action,source,down){if(!held.has(action))held.set(action,new Set());const sources=held.get(action),wasDown=sources.size>0;if(down)sources.add(source);else sources.delete(source);const isDown=sources.size>0;if(wasDown!==isDown){emit({action,phase:isDown?'start':'end',value:isDown?1:0});lastHeld.set(action,isDown);}$('activeAction').textContent=[...held.entries()].filter(([,v])=>v.size).map(([k])=>k).join(' + ')||'Komut bekleniyor';}
function bindAction(button){const action=button.dataset.action;button.addEventListener('pointerdown',event=>{event.preventDefault();button.setPointerCapture(event.pointerId);command(action,`p${event.pointerId}`,true);button.classList.add('pressed');});for(const type of['pointerup','pointercancel','lostpointercapture'])button.addEventListener(type,event=>{command(action,`p${event.pointerId}`,false);if(!held.get(action)?.size)button.classList.remove('pressed');});}
document.querySelectorAll('[data-action]').forEach(bindAction);
function moveJoystick(event){if(event.pointerId!==stickPointer)return;const radius=stickRect.width/2;let x=(event.clientX-stickRect.left-radius)/radius,y=(event.clientY-stickRect.top-radius)/radius;const length=Math.hypot(x,y);if(length>1){x/=length;y/=length;}const dead=.12;if(Math.hypot(x,y)<dead)x=y=0;$('stick').style.transform=`translate(${x*(radius-26)}px,${y*(radius-26)}px)`;$('moveValue').textContent=`Hareket ${x.toFixed(2)} / ${(-y).toFixed(2)}`;emit({action:'Move',phase:'change',value:{x,y:-y}});for(const[a,on]of[['Forward',y<-.25],['Backward',y>.25],['StrafeLeft',x<-.25],['StrafeRight',x>.25]])command(a,'stick',on);}
$('joystick').onpointerdown=event=>{if(stickPointer!==null)return;event.preventDefault();stickPointer=event.pointerId;stickRect=$('joystick').getBoundingClientRect();$('joystick').setPointerCapture(event.pointerId);moveJoystick(event);};$('joystick').onpointermove=moveJoystick;
function releaseJoystick(event){if(event&&event.pointerId!==stickPointer)return;stickPointer=null;$('stick').style.transform='translate(0,0)';$('moveValue').textContent='Hareket 0.00 / 0.00';for(const a of['Forward','Backward','StrafeLeft','StrafeRight'])command(a,'stick',false);emit({action:'Move',phase:'change',value:{x:0,y:0}});}
for(const type of['pointerup','pointercancel','lostpointercapture'])$('joystick').addEventListener(type,releaseJoystick);
$('lookPad').onpointerdown=event=>{if(lookPointer!==null)return;event.preventDefault();lookPointer=event.pointerId;lookLast={x:event.clientX,y:event.clientY};$('lookPad').setPointerCapture(event.pointerId);};
$('lookPad').onpointermove=event=>{if(event.pointerId!==lookPointer)return;const s=Number($('sensitivity').value)*.15;const dx=(event.clientX-lookLast.x)*s,dy=(event.clientY-lookLast.y)*s;yaw=(yaw+dx)%360;pitch=Math.max(-89,Math.min(89,pitch+dy));lookLast={x:event.clientX,y:event.clientY};$('lookValue').textContent=`Bakış ${yaw.toFixed(0)}° / ${pitch.toFixed(0)}°`;emit({action:'Look',phase:'change',value:{yaw,pitch,dx,dy}});};
for(const type of['pointerup','pointercancel','lostpointercapture'])$('lookPad').addEventListener(type,event=>{if(event.pointerId===lookPointer)lookPointer=null;});
function releaseAll(){for(const[action,sources]of held)for(const source of[...sources])command(action,source,false);document.querySelectorAll('.pressed').forEach(b=>b.classList.remove('pressed'));releaseJoystick();lookPointer=null;}
window.addEventListener('blur',releaseAll);document.addEventListener('visibilitychange',()=>{if(document.hidden)releaseAll();});
const keyboard={KeyW:'Forward',KeyS:'Backward',KeyA:'StrafeLeft',KeyD:'StrafeRight',Space:'Jump',ControlLeft:'Duck',ShiftLeft:'Speed',KeyR:'Reload',Digit1:'ChangeRifle',Digit2:'ChangePistol',Digit3:'ChangeCharacter',Digit4:'ChangeGrenade',Digit5:'ChangeBomb',KeyE:'LeanRight',KeyQ:'LastWeapon',KeyT:'WolfMedicalKitUse',KeyF:'WolfSteamPackUse'};
for(const type of['keydown','keyup'])document.addEventListener(type,event=>{if(activeView!=='mobile'||/INPUT|SELECT|TEXTAREA/.test(event.target.tagName)||!keyboard[event.code])return;event.preventDefault();command(keyboard[event.code],event.code,type==='keydown');});
document.querySelectorAll('.tab').forEach(button=>button.onclick=()=>{releaseAll();activeView=button.dataset.view;document.querySelectorAll('.view').forEach(view=>view.hidden=view.id!==activeView);document.querySelectorAll('.tab').forEach(tab=>{tab.classList.toggle('active',tab===button);tab.setAttribute('aria-pressed',String(tab===button));});});
$('extraToggle').onclick=()=>{$('extras').hidden=!$('extras').hidden;$('extraToggle').setAttribute('aria-expanded',String(!$('extras').hidden));};
$('fullScreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await $('arena').requestFullscreen();}catch{toast('Bu tarayıcıda tam ekran açılamadı.',true);}};
Promise.all([refresh(),request('/controls.json').then(data=>{controlData=data;$('controlStats').textContent=`${data.controls.length} tanımlı komut · ${data.controls.filter(c=>c.bindings.length).length} atanmış komut · kaynak: autoexec.cfg`;$('scope').textContent=data.scope;renderControls();for(const c of data.controls){const button=el('button',c.label);button.dataset.action=c.action;button.title=`${c.action} (${c.id})`;bindAction(button);$('extraActions').append(button);}})]).catch(e=>toast(e.message,true));

// Audit candidates never populate assets/roster.json automatically.
let characterAudit=null;
const issueLabels={model_missing:'Model bulunamadı',model_parse_failed:'Model okunamadı',skin_or_render_style_missing:'Kaplama / görünüm dosyası eksik',animation_model_missing:'Animasyon modeli eksik',skeleton_requires_review:'İskelet farkı incelenmeli',playable_animation_missing:'Hareketli animasyon bulunamadı',counterpart_not_found:'İnsan/kurt eşi doğrulanamadı',counterpart_ambiguous:'Birden fazla eş adayı',counterpart_requires_review:'Eş adayında kontrol gerekiyor'};
function renderCharacterAudit(){
 if(!characterAudit)return;
 const query=$('characterSearch').value.toLocaleLowerCase('tr-TR'),filter=$('characterFilter').value;
 const rows=characterAudit.characters.filter(c=>(filter==='all'||(filter==='issues'&&c.issues.length)||(filter==='candidate'&&c.structuralCandidate))&&JSON.stringify(c).toLocaleLowerCase('tr-TR').includes(query));
 $('characterCount').textContent=`${rows.length} kayıt gösteriliyor · Onaylı karakter çifti: ${characterAudit.summary.approvedCharacters}`;
 $('characterRows').replaceChildren();
 for(const c of rows){const row=el('tr'),name=el('td',`${c.name} · ${c.id}`);name.append(el('small',c.model));row.append(name,el('td',c.form==='human'?'İnsan':'Kurt'),el('td',String(c.animationClipCount)),el('td',c.counterpartIds.join(', ')||'Doğrulanamadı'),el('td',c.included?'Deneme sürümünde · Pedro RE':(c.issues.map(i=>issueLabels[i]||i).join('; ')||'Yapısal aday · motor/görsel onay bekliyor')));$('characterRows').append(row);}
 if(!rows.length){const row=el('tr'),cell=el('td','Eşleşen kayıt yok.','empty');cell.colSpan=5;row.append(cell);$('characterRows').append(row);}
}
$('characterSearch').oninput=renderCharacterAudit;$('characterFilter').onchange=renderCharacterAudit;
request('/characters.json').then(data=>{characterAudit=data;$('characterStats').textContent=`${data.summary.parsedModels} model okundu · ${data.summary.modelDefinitions} varyant kaydı · ${data.summary.approvedCharacters} onaylı karakter`;$('characterScope').textContent=data.scope;renderCharacterAudit();}).catch(e=>{$('characterStats').textContent='Karakter raporu yüklenemedi.';toast(e.message,true);});

let mapCatalog=null;
function renderMaps(){
 if(!mapCatalog)return;
 const mode=$('mapMode').value,query=$('mapSearch').value.toLocaleLowerCase('tr-TR');
 const modes=new Map(mapCatalog.modes.map(m=>[m.id,m]));
 const rows=mapCatalog.maps.filter(m=>(mode==='all'||(m.allowedModeIds.includes(Number(mode))&&modes.get(Number(mode))?.mapNumbers.includes(m.number)))&&`${m.number} ${m.displayName} ${m.path}`.toLocaleLowerCase('tr-TR').includes(query));
 $('mapCount').textContent=`${rows.length} harita gösteriliyor · ${mapCatalog.maps.filter(m=>m.previewAvailable).length} haritada Godot / APK içinde gezinti önizlemesi var. Tamamlanmış özgün oyun modu: 0.`;
 $('mapRows').replaceChildren();
 for(const m of rows){const row=el('tr'),name=el('td',`${m.number} · ${m.displayName}`);name.append(el('small',m.path));row.append(name,el('td',m.allowedModeIds.map(id=>modes.get(id)?.sourceName||String(id)).join(' · ')||'Doğrulanamadı'),el('td',m.previewAvailable?'Gezinti önizlemesi var · mod kuralları bekleniyor':(m.allowedModeIds.length?'Mod eşleşmesi doğrulandı · sahne aktarımı bekleniyor':'Mod eşleşmesi bekleniyor · seçime kapalı')));$('mapRows').append(row);}
 if(!rows.length){const row=el('tr'),cell=el('td','Bu filtrede seçilmiş harita yok.','empty');cell.colSpan=3;row.append(cell);$('mapRows').append(row);}
}
$('mapMode').onchange=renderMaps;$('mapSearch').oninput=renderMaps;
request('/maps.json').then(data=>{mapCatalog=data;$('mapStats').textContent=`${data.maps.length} seçili harita · ${data.maps.filter(m=>m.allowedModeIds.length).length} doğrulanmış eşleşme · ${data.modes.length} kaynak mod / alt mod`;for(const m of data.modes){const option=el('option',m.sourceName);option.value=String(m.id);$('mapMode').append(option);}renderMaps();}).catch(e=>{$('mapStats').textContent='Mod–harita listesi yüklenemedi.';toast(e.message,true);});
