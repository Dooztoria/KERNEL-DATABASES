// DOOZ Dashboard
const {$,api}=window.DOOZ;
let sysData={};

async function loadDashboard(){
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
        if($('cfg-info'))$('cfg-info').textContent=JSON.stringify(d,null,2);
    }catch(e){}
    checkGsAlert();
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

function startLiveStats(){
    async function update(){
        const r=await api('exec',{cmd:"cat /proc/loadavg 2>/dev/null|awk '{print $1}';free 2>/dev/null|awk '/Mem:/{if($2>0)print int($3*100/$2);else print 0}';df / 2>/dev/null|tail -1|awk '{gsub(/%/,\"\");print $5}'"});
        const[load,mem,disk]=(r.output||'0\n0\n0').trim().split('\n');
        if($('live-stats')){
            $('live-stats').innerHTML=`
                <div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:10px"><span>CPU</span><span>${load}</span></div></div>
                <div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:10px"><span>MEM</span><span>${mem}%</span></div><div class="stat-bar"><i style="width:${mem}%;background:${mem>80?'var(--red)':'var(--green)'}"></i></div></div>
                <div><div style="display:flex;justify-content:space-between;font-size:10px"><span>DISK</span><span>${disk}%</span></div><div class="stat-bar"><i style="width:${disk}%;background:${disk>80?'var(--red)':'var(--green)'}"></i></div></div>`;
        }
    }
    update();setInterval(update,5000);
}

window.load_dash=loadDashboard;
window.loadDashboard=loadDashboard;
window.startLiveStats=startLiveStats;
