(() => {
"use strict";
if (window.__FAZTUDO_INSTALL_UI__) return;
window.__FAZTUDO_INSTALL_UI__ = true;
const standalone = () => matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
let promptEvent = null, banner = null;
function helpText() {
 const ua=navigator.userAgent||"";
 if(/iPhone|iPad|iPod/i.test(ua)) return "No iPhone/iPad: use Partilhar no Safari e escolha Adicionar ao ecrã principal.";
 if(/Android/i.test(ua)) return "No Android: abra o menu ⋮ do navegador e escolha Instalar aplicação ou Adicionar ao ecrã inicial. Se não aparecer, actualize o navegador.";
 return "No computador: procure Instalar Faz Tudo Tecnologia no menu do navegador ou o ícone de instalação junto ao endereço.";
}
function help() {
 let d=document.getElementById("ft-install-help"); if(d)return;
 d=document.createElement("div");d.id="ft-install-help";d.setAttribute("role","dialog");d.setAttribute("aria-modal","true");
 d.style.cssText="position:fixed;inset:0;z-index:2147483000;background:#0009;display:grid;place-items:center;padding:18px";
 const p=document.createElement("div");p.style.cssText="max-width:420px;background:white;color:#172033;border-radius:14px;padding:22px;font:16px/1.5 system-ui";
 const h=document.createElement("h2");h.textContent="Instalar Faz Tudo Tecnologia";
 const t=document.createElement("p");t.textContent=helpText();
 const b=document.createElement("button");b.textContent="Fechar";b.style.cssText="padding:10px 18px;background:#1769aa;color:white;border:0;border-radius:8px";
 b.onclick=()=>d.remove();p.append(h,t,b);d.append(p);d.onclick=e=>{if(e.target===d)d.remove()};document.body.append(d);
}
function show() {
 if(banner||standalone())return;
 try{if(sessionStorage.getItem("ft-install-dismissed")==="1")return}catch(e){}
 banner=document.createElement("aside");banner.id="ft-install-banner";
 banner.style.cssText="position:fixed;left:12px;right:12px;bottom:12px;z-index:2147482000;display:flex;align-items:center;gap:10px;background:#14212d;color:white;padding:12px;border-radius:13px;box-shadow:0 5px 24px #0005;font:14px system-ui";
 const label=document.createElement("div");label.style.flex="1";label.textContent="Instale o Faz Tudo Tecnologia — acesso rápido pelo ecrã inicial";
 const go=document.createElement("button");go.textContent="Instalar";go.style.cssText="padding:10px 13px;border:0;border-radius:8px;background:#f4c542;color:#172033;font-weight:bold";
 go.onclick=async()=>{if(promptEvent){promptEvent.prompt();try{await promptEvent.userChoice}catch(e){}promptEvent=null;banner&&banner.remove();banner=null}else help()};
 const close=document.createElement("button");close.textContent="×";close.setAttribute("aria-label","Fechar");close.style.cssText="border:0;background:transparent;color:white;font-size:23px";
 close.onclick=()=>{banner&&banner.remove();banner=null;try{sessionStorage.setItem("ft-install-dismissed","1")}catch(e){}};
 banner.append(label,go,close);document.body.append(banner);
}
addEventListener("beforeinstallprompt",e=>{e.preventDefault();promptEvent=e;show()});
addEventListener("appinstalled",()=>{promptEvent=null;banner&&banner.remove();banner=null});
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",show,{once:true});else show();
})();