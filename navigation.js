/* Navegação responsiva sem barra duplicada — Faz Tudo Tecnologia */
(function(){
"use strict";
if(window.__FAZTUDO_NAV_V3__)return;window.__FAZTUDO_NAV_V3__=true;
function init(){
 const header=document.querySelector("body>header");
 const nav=header&&header.querySelector("nav");
 if(!header||!nav)return;
 nav.setAttribute("aria-label","Navegação principal");
 nav.id=nav.id||"faztudo-main-nav";
 if(!header.querySelector("[data-ft-menu-toggle]")){
  const button=document.createElement("button");button.type="button";button.dataset.ftMenuToggle="1";
  button.textContent="☰ Menu";button.setAttribute("aria-controls",nav.id);button.setAttribute("aria-expanded","false");
  button.style.cssText="display:none;padding:9px 13px;border:1px solid #1769aa;border-radius:8px;background:#1769aa;color:#fff;font-weight:700";
  button.addEventListener("click",()=>{const open=button.getAttribute("aria-expanded")!=="true";button.setAttribute("aria-expanded",String(open));nav.classList.toggle("ftt-menu-open",open);});
  header.querySelector(".nav")?.appendChild(button);
  const style=document.createElement("style");style.id="ftt-mobile-nav-style";
  style.textContent="@media(max-width:780px){header .nav{position:relative}header [data-ft-menu-toggle]{display:inline-block!important}header nav:not(.ftt-menu-open){display:none!important}header nav.ftt-menu-open{display:flex!important;flex-direction:column;align-items:flex-start;width:100%;padding:12px 0}header nav.ftt-menu-open a{padding:7px 0}}";
  document.head.appendChild(style);
 }
 nav.addEventListener("click",e=>{if(e.target.closest("a")&&window.matchMedia("(max-width:780px)").matches){nav.classList.remove("ftt-menu-open");header.querySelector("[data-ft-menu-toggle]")?.setAttribute("aria-expanded","false");}});
}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",init,{once:true});else init();
})();