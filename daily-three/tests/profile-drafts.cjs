const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const source=fs.readFileSync('dist/app.js','utf8');
const helpers=source.slice(source.indexOf('const profileDraftMemory='),source.indexOf('function profileFields('));
const screens=source.slice(source.indexOf('function profileFields('),source.indexOf('function todayScreen('));
const storage=new Map();let blocked=false;
const fields={first_name:'Draft',last_name:'Student',major:'Finance',year:'Third year',instagram:'@draft',linkedin:'https://www.linkedin.com/in/draft',consent:'on'};
function context(id='student-a'){
 const c=vm.createContext({Map,Date,JSON,String,localStorage:{getItem(k){if(blocked)throw Error('Storage unavailable');return storage.get(k)||null},setItem(k,v){if(blocked)throw Error('Storage unavailable');storage.set(k,v)},removeItem(k){if(blocked)throw Error('Storage unavailable');storage.delete(k)}},FormData:class{get(k){return fields[k]||null}},user:{id,email:'draft@calpoly.edu'},profile:null,isAdmin:false,years:['First year','Third year'],esc:v=>String(v??'').replaceAll('&','&amp;').replaceAll('"','&quot;').replaceAll('<','&lt;'),$:()=>({})});
 vm.runInContext(helpers+screens,c);return c;
}
let c=context();vm.runInContext('saveProfileDraft()',c);
assert.equal(JSON.parse(storage.get('kinnect-profile-draft-student-a')).fields.linkedin,fields.linkedin);
c=context();assert.equal(vm.runInContext('readProfileDraft().fields.first_name',c),'Draft');assert.match(vm.runInContext('profileScreen()',c),/name="consent" checked required/);assert.match(vm.runInContext('profileScreen()',c),/value="Finance"/);
assert.equal(vm.runInContext('readProfileDraft()',context('student-b')),null);
const stored=JSON.parse(storage.get('kinnect-profile-draft-student-a'));stored.updatedAt=Date.now()-86400001;storage.set('kinnect-profile-draft-student-a',JSON.stringify(stored));assert.equal(vm.runInContext('readProfileDraft()',context()),null);
c=context();vm.runInContext('saveProfileDraft();clearProfileDraft()',c);assert.equal(storage.has('kinnect-profile-draft-student-a'),false);
blocked=true;c=context();vm.runInContext('saveProfileDraft()',c);assert.equal(vm.runInContext('readProfileDraft().fields.major',c),'Finance');vm.runInContext('clearProfileDraft()',c);assert.equal(vm.runInContext('readProfileDraft()',c),null);blocked=false;
let visibility,boots=0,saves=0;const d=vm.createContext({window:{addEventListener(){}},document:{hidden:false,addEventListener(type,fn){visibility=fn}},user:{id:'student-a'},busy:false,view:'onboarding',saveProfileDraft(){saves++},boot(){boots++}});
vm.runInContext(source.slice(source.indexOf("window.addEventListener?.('pagehide'"),source.lastIndexOf('\nboot();')),d);visibility();assert.equal(boots,0);d.document.hidden=true;visibility();assert.equal(saves,1);d.document.hidden=false;d.view='profile';visibility();assert.equal(boots,0);d.view='today';visibility();assert.equal(boots,1);
console.log('Profile draft checks passed: refresh restoration, field and consent retention, account isolation, expiry, cleanup, blocked storage fallback, and safe tab switching.');
