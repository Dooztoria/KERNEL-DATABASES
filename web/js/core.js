// DOOZ Core - Base functions
const $=id=>document.getElementById(id);
const api=async(e,d)=>{
    try{
        const r=await fetch('/api/'+e,{
            method:'POST',
            headers:{'Content-Type':'application/json'},
            body:JSON.stringify(d||{})
        });
        return r.json();
    }catch(x){return{error:x.message}}
};

function nav(p){
    document.querySelectorAll('.page').forEach(x=>x.classList.remove('on'));
    document.querySelectorAll('.nav-item').forEach(x=>x.classList.remove('on'));
    $('p-'+p)?.classList.add('on');
    document.querySelector('.nav-item[data-p="'+p+'"]')?.classList.add('on');
    
    // Trigger page-specific loaders
    if(typeof window['load_'+p]==='function')window['load_'+p]();
}

function openModal(id){$(id).classList.add('on');}
function closeModal(id){$(id).classList.remove('on');}

function addLine(el,t,c){
    const d=document.createElement('div');
    d.className='ln '+(c||'');
    d.textContent=t;
    $(el).appendChild(d);
    $(el).scrollTop=1e9;
}

// Session Timer
let sessionRemaining=7200;
async function updateSessionTimer(){
    const r=await api('timer');
    if(r.remaining!==undefined)sessionRemaining=r.remaining;
}

function renderTimer(){
    const mins=Math.floor(sessionRemaining/60);
    const secs=sessionRemaining%60;
    const el=$('session-timer');
    if(el){
        el.textContent=`${String(mins).padStart(2,'0')}:${String(secs).padStart(2,'0')}`;
        el.className='session-timer'+(sessionRemaining<300?' danger':sessionRemaining<900?' warning':'');
    }
    if(sessionRemaining>0)sessionRemaining--;
    if(sessionRemaining<=0){
        document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:#ef4444;font-size:20px;flex-direction:column"><div style="font-size:48px;margin-bottom:20px">⏱</div>SESSION EXPIRED</div>';
    }
}

// Export for other modules
window.DOOZ={$,api,nav,openModal,closeModal,addLine,updateSessionTimer,renderTimer};
