const dialog=document.querySelector('#join-dialog');
document.querySelectorAll('[data-join]').forEach(b=>b.addEventListener('click',()=>dialog.showModal()));
document.querySelector('.close').addEventListener('click',()=>dialog.close());
document.querySelectorAll('.choice').forEach(button=>button.addEventListener('click',()=>{document.querySelectorAll('.choice').forEach(b=>b.classList.remove('selected'));button.classList.add('selected');document.querySelector('#vote-note').textContent=`You chose “${button.dataset.choice}.” Campus results are unlocked!`;}));
document.querySelector('#signup').addEventListener('submit',e=>{e.preventDefault();document.querySelector('#form-message').textContent='You’re on the list — see you soon.';e.target.reset();});
