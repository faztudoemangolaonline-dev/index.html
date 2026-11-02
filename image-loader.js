(function(){
"use strict";
const cache=new Map();
const fallback="data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 16 9%22%3E%3Crect width=%2216%22 height=%229%22 fill=%22%23edf4fb%22/%3E%3C/svg%3E";
async function loadChunk(file){if(!cache.has(file))cache.set(file,fetch("./"+file,{cache:"force-cache"}).then(r=>{if(!r.ok)throw new Error("Falha ao carregar imagens");return r.json();}));return cache.get(file);}
async function reveal(img){if(img.dataset.loaded==="1")return;img.dataset.loaded="1";try{const data=await loadChunk(img.dataset.imageChunk);const uri=data[img.dataset.imageKey];if(uri)img.src=uri;else img.src=fallback;}catch(e){img.src=fallback;img.alt=(img.alt||"Imagem")+" — imagem temporariamente indisponível";}}
function start(){const imgs=[...document.querySelectorAll("img[data-image-key]")];if(!imgs.length)return;if("IntersectionObserver"in window){const io=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){io.unobserve(entry.target);reveal(entry.target);}}),{rootMargin:"500px 0px"});imgs.forEach(img=>io.observe(img));}else imgs.forEach(reveal);}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",start,{once:true});else start();
})();