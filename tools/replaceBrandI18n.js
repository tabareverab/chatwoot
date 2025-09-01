const fs = require('fs'), path = require('path');
const BRAND = 'O Chat';
const roots = [
  'app/javascript/dashboard/i18n/locale',
  'app/javascript/widget/i18n/locale',
];
function x(v){ if(typeof v==='string') return v.replaceAll('Chatwoot', BRAND);
  if(Array.isArray(v)) return v.map(x);
  if(v&&typeof v==='object'){ for (const k of Object.keys(v)) v[k]=x(v[k]); }
  return v; }
for (const root of roots){
  if (!fs.existsSync(root)) continue;
  for (const f of fs.readdirSync(root)){
    if (!f.endsWith('.json')) continue;
    const p = path.join(root,f);
    const src = fs.readFileSync(p,'utf8');
    try{
      const out = x(JSON.parse(src));
      fs.writeFileSync(p, JSON.stringify(out,null,2)+'\n','utf8');
      console.log('[OK]', p);
    } catch(e){ console.error('[SKIP]', p, e.message); }
  }
}
