// DOOZ Main - Entry Point
async function init(){
    // Setup navigation
    document.querySelectorAll('.nav-item[data-p]').forEach(n=>n.onclick=()=>nav(n.dataset.p));
    
    // Timer
    await DOOZ.updateSessionTimer();
    setInterval(DOOZ.renderTimer,1000);
    setInterval(DOOZ.updateSessionTimer,60000);
    
    // Load dashboard
    loadDashboard();
    startLiveStats();
    fmLoad('/');
    initMethodCards();
}

async function pull(){await DOOZ.api('pull');location.reload();}
async function nuke(){if(!confirm('⚠️ DESTRUCT ALL?'))return;await DOOZ.api('destruct');document.body.innerHTML='<div style="display:flex;height:100vh;align-items:center;justify-content:center;background:#000;color:var(--red);font-size:24px">💀 DESTROYED</div>';}

window.pull=pull;
window.nuke=nuke;
init();
