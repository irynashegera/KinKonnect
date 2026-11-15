const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const code=fs.readFileSync('dist/app.js','utf8');
async function scenario(changed){
 const app={innerHTML:''},store=new Map(),sessions=new Map([['kinnect-welcome-student-1','seen']]),calls=[];
 const profile={id:'student-1',first_name:'Test',last_name:'Student',major:'Business',year:'Third year',instagram:null,linkedin:null};
 const fields=Object.fromEntries(['first_name','last_name','major','year','instagram','linkedin'].map(k=>[k,String(profile[k]||'')]));if(changed)fields.major='Edited major';store.set('kinnect-profile-draft-student-1',JSON.stringify({fields,updatedAt:Date.parse('2026-11-15T10:59:00Z'),consent:false}));
 const questions=[1,2,3].map(n=>({id:String(n),question_text:'Sunday '+n,option_a:'A',option_b:'B'})),answers=questions.map(q=>({question_id:q.id,choice:0}));
 const db={auth:{getSession:async()=>({data:{session:{}}}),getUser:async()=>({data:{user:{id:'student-1',email:'test@calpoly.edu',email_confirmed_at:'2026-11-14'}}})},from(table){const data={profiles:profile,questions,answers}[table],chain={select(){return chain},eq(){return chain},order(){return chain},maybeSingle:async()=>({data}),then(a,b){return Promise.resolve({data}).then(a,b)}};return chain},rpc:async(name,args)=>{calls.push({name,args});return {data:name==='is_kinnect_admin'?false:name==='campus_results'?[{question_text:'Saturday saved question',option_a:'A',option_b:'B',votes_a:8,votes_b:3,my_choice:0}]:null,error:null}}};
 class FixedDate extends Date{constructor(...args){super(...(args.length?args:['2026-11-15T11:00:00Z']))}static now(){return Date.parse('2026-11-15T11:00:00Z')}}
 const storage=m=>({getItem:k=>m.get(k)||null,setItem:(k,v)=>m.set(k,v),removeItem:k=>m.delete(k)});
 const ctx=vm.createContext({window:{supabase:{createClient:()=>db},scrollTo(){}},document:{querySelector:s=>s==='#app'?app:null,querySelectorAll:()=>[],addEventListener(){}},localStorage:storage(store),sessionStorage:storage(sessions),location:{hash:'',pathname:'/',origin:'https://kinnect.test'},history:{replaceState(){}},Date:FixedDate,Intl,URL,URLSearchParams,Promise,Map,setTimeout,clearTimeout,setInterval:()=>0});
 vm.runInContext(code,ctx);await vm.runInContext('boot()',ctx);await vm.runInContext("navigate('today')",ctx);
 assert.match(app.innerHTML,/Saturday saved question/);assert.match(app.innerHTML,/Saturday, Nov 14/);assert.doesNotMatch(app.innerHTML,/There wasn’t a question set/);assert(calls.some(c=>c.name==='campus_results'&&c.args.target_date==='2026-11-14'));
 if(changed)assert.equal(JSON.parse(store.get('kinnect-profile-draft-student-1')).fields.major,'Edited major');else assert.equal(store.has('kinnect-profile-draft-student-1'),false);
 vm.runInContext("pastResults=[]",ctx);await vm.runInContext("navigate('today')",ctx);assert.match(app.innerHTML,/Saturday saved question/);
}
(async()=>{await scenario(false);await scenario(true);console.log('Results regression passed: Saturday’s actual query loads after profile navigation, unchanged drafts clear, edited drafts survive, returning to Today refreshes results.');})().catch(e=>{console.error(e);process.exit(1)});
