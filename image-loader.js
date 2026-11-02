(function(){
"use strict";
const cache=new Map();
const fallback="data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 16 9%22%3E%3Crect width=%2216%22 height=%229%22 fill=%22%23edf4fb%22/%3E%3C/svg%3E";
async function loadChunk(file, originalOnly=false){
  const key=file+(originalOnly?"::original":"::preferred");
  if(!cache.has(key)) cache.set(key,(async()=>{
    const match=file.match(/^image-assets-([0-9]+)[.]json$/);
    if(!originalOnly && match){
      try {
        const optimized=await fetch("./image-assets-webp-"+match[1]+".json",{cache:"force-cache"});
        if(optimized.ok) return await optimized.json();
      } catch(_) {}
    }
    const original=await fetch("./"+file,{cache:"force-cache"});
    if(!original.ok) throw new Error("Falha ao carregar imagens");
    return original.json();
  })());
  return cache.get(key);
}
async function reveal(img){
  if(img.dataset.loaded==="1")return;
  img.dataset.loaded="1";
  try{
    const file=img.dataset.imageChunk;
    const key=img.dataset.imageKey;
    const data=await loadChunk(file);
    const uri=data[key];
    if(uri && /^data:image\\/webp/i.test(uri)){
      img.onerror=async()=>{
        img.onerror=null;
        try{
          const original=await loadChunk(file,true);
          img.src=original[key]||fallback;
        }catch(_){img.src=fallback;}
      };
    }
    img.src=uri||fallback;
  }catch(e){
    img.src=fallback;
    img.alt=(img.alt||"Imagem")+" — imagem temporariamente indisponível";
  }
}
function start(){const imgs=[...document.querySelectorAll("img[data-image-key]")];if(!imgs.length)return;if("IntersectionObserver"in window){const io=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){io.unobserve(entry.target);reveal(entry.target);}}),{rootMargin:"500px 0px"});imgs.forEach(img=>io.observe(img));}else imgs.forEach(reveal);}
if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",start,{once:true});else start();
})();