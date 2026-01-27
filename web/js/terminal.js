// DOOZ Terminal
const {$,api,addLine}=window.DOOZ;

async function rs(path){
    $('term-out').innerHTML='';
    addLine('term-out','$ bash '+path,'cmd');
    const r=await api('run',{path});
    (r.output||'').split('\n').forEach(l=>addLine('term-out',l,'ok'));
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

window.load_proc=loadProc;
window.rs=rs;
window.termExec=termExec;
window.loadProc=loadProc;
