const root = document.getElementById('root');
const want = document.getElementById('want');
const unit = document.getElementById('unit');
const total = document.getElementById('total');
const accept = document.getElementById('accept');
const decline = document.getElementById('decline');

function openUI(offer){
  want.textContent = `${offer.amt}x ${offer.label}`;
  unit.textContent = `$${offer.unit} / ea`;
  total.textContent = `$${offer.payout}`;
  root.classList.remove('hidden');
}

function closeUI(){
  root.classList.add('hidden');
}

function post(name, data={}){
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: {'Content-Type':'application/json; charset=UTF-8'},
    body: JSON.stringify(data)
  }).catch(()=>{});
}

accept.addEventListener('click', ()=> post('cdg_corner_accept'));
decline.addEventListener('click', ()=> post('cdg_corner_decline'));

window.addEventListener('message', (event)=>{
  const data = event.data;
  if (!data || !data.action) return;
  if (data.action === 'open') openUI(data.offer);
  if (data.action === 'close') closeUI();
});

window.addEventListener('keydown', (e)=>{
  if (root.classList.contains('hidden')) return;
  if (e.key === 'Escape') { post('cdg_corner_decline'); return; }
  if (e.key.toLowerCase() === 'e') { post('cdg_corner_accept'); return; }
  if (e.key === 'Backspace') { post('cdg_corner_decline'); }
});
