// DOOZ File Manager
const {$,api,openModal,closeModal}=window.DOOZ;
let cwd='/',currentFile='';

async function fmLoad(path){
    cwd=path;
    const parts=path.split('/').filter(Boolean);
    let bc='<a href="#" onclick="fmLoad(\'/\');return false">~</a>';
    parts.forEach((p,i)=>{
        const fp='/'+parts.slice(0,i+1).join('/');
        bc+=` / <a href="#" onclick="fmLoad('${fp}');return false">${p}</a>`;
    });
    $('fm-path').innerHTML=bc;
    
    const r=await api('files',{path});
    let h='';
    if(path!=='/'){
        const pr=path.split('/').slice(0,-1).join('/')||'/';
        h+=`<div class="fm-item" ondblclick="fmLoad('${pr}')"><div class="fm-icon dir">⬆</div><div class="fm-info"><div class="fm-name">..</div></div></div>`;
    }
    const files=(r.files||[]).sort((a,b)=>(b.type==='dir')-(a.type==='dir')||a.name.localeCompare(b.name));
    const icons={sh:'⚡',py:'🐍',js:'📜',c:'©',txt:'📝',conf:'⚙',gz:'📦',tar:'📦',dat:'🔑'};
    files.forEach(f=>{
        const fp=path==='/'?'/'+f.name:path+'/'+f.name;
        const isDir=f.type==='dir';
        const ext=f.name.split('.').pop().toLowerCase();
        h+=`<div class="fm-item" ondblclick="${isDir?`fmLoad('${fp}')`:`fmView('${fp}')`}"><div class="fm-icon ${isDir?'dir':''}">${isDir?'📁':(icons[ext]||'📄')}</div><div class="fm-info"><div class="fm-name">${f.name}</div><div class="fm-meta">${f.perm||''} • ${f.size||''}</div></div></div>`;
    });
    $('fm-list').innerHTML=h||'Empty';
}

function fmUp(){fmLoad(cwd.split('/').slice(0,-1).join('/')||'/');}
function fmRefresh(){fmLoad(cwd);}

async function fmView(path){
    currentFile=path;
    $('modal-view-title').textContent=path.split('/').pop();
    const r=await api('read',{path});
    $('modal-view-content').textContent=r.content||'(empty/binary)';
    openModal('modal-view');
}

async function fmEdit(path){
    currentFile=path||currentFile;
    $('modal-edit-title').textContent='Edit: '+currentFile.split('/').pop();
    const r=await api('read',{path:currentFile});
    $('modal-edit-content').value=r.content||'';
    closeModal('modal-view');
    openModal('modal-edit');
}

async function fmSaveEdit(){
    await api('write',{path:currentFile,content:$('modal-edit-content').value});
    closeModal('modal-edit');
    fmRefresh();
}

function fmNewFile(){
    $('modal-new-name').value='';
    $('modal-new-content').value='';
    openModal('modal-new');
}

function fmNewDir(){
    const n=prompt('Folder name:');
    if(n)api('mkdir',{path:cwd+'/'+n}).then(fmRefresh);
}

async function fmSaveNew(){
    const n=$('modal-new-name').value.trim();
    if(!n)return;
    await api('write',{path:cwd+'/'+n,content:$('modal-new-content').value});
    closeModal('modal-new');
    fmRefresh();
}

window.load_files=()=>fmLoad(cwd);
window.fmLoad=fmLoad;
window.fmUp=fmUp;
window.fmRefresh=fmRefresh;
window.fmView=fmView;
window.fmEdit=fmEdit;
window.fmSaveEdit=fmSaveEdit;
window.fmNewFile=fmNewFile;
window.fmNewDir=fmNewDir;
window.fmSaveNew=fmSaveNew;
