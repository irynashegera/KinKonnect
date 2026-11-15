import {readFile,mkdir,writeFile} from 'node:fs/promises';
const assets={};
for(const [name,type] of [['index.html','text/html; charset=utf-8'],['app.js','text/javascript; charset=utf-8'],['admin.js','text/javascript; charset=utf-8'],['style.css','text/css; charset=utf-8'],['vendor/supabase.js','text/javascript; charset=utf-8']])assets['/'+name]={type,body:await readFile(new URL('../dist/'+name,import.meta.url),'utf8')};
const source=await readFile(new URL('../worker/index.js',import.meta.url),'utf8');
await mkdir(new URL('../dist/server/',import.meta.url),{recursive:true});
await writeFile(new URL('../dist/server/index.js',import.meta.url),'const ASSETS='+JSON.stringify(assets)+';\n'+source);
console.log('Built Worker with five bundled static assets.');
