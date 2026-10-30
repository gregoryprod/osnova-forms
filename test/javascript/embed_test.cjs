const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const source=fs.readFileSync('public/embed.js','utf8');
function browser(fetch, storage = new Map()) {
  const store={getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v),removeItem:k=>storage.delete(k)};
  const context={window:{},document:{referrer:'',querySelector:()=>null},location:{href:'https://osnova-mind.ru/?utm_source=test'},sessionStorage:store,crypto:require('node:crypto').webcrypto,URL,AbortSignal,fetch};
  vm.runInNewContext(source,context);
  return context.window.OsnovaIntake;
}
test('network retry and page reload preserve UUID; success starts new submission', async()=>{
  const bodies=[]; let fail=true; const storage=new Map();
  const fetch=async(u,o)=>{bodies.push(JSON.parse(o.body));if(fail)throw Error('offline');return{ok:true,json:async()=>({ok:true,id:'test'})};};
  const data={answers:[],name:'Test',contact:'@example_test',consent:true};
  await assert.rejects(browser(fetch,storage).submit(data));
  fail=false;
  const api=browser(fetch,storage);
  await api.submit(data); await api.submit(data);
  assert.equal(bodies[0].client_submission_id,bodies[1].client_submission_id);
  assert.notEqual(bodies[1].client_submission_id,bodies[2].client_submission_id);
  assert.equal(bodies[1].utm.utm_source,'test');
});
test('server rejection preserves retry UUID',async()=>{
 const ids=[];let good=false;
 const api=browser(async(u,o)=>{ids.push(JSON.parse(o.body).client_submission_id);return {ok:good,json:async()=>({ok:true})};});
 await assert.rejects(api.submit({name:'Test'})); good=true;
 await api.submit({name:'Test'}); assert.equal(ids[0],ids[1]);
});
