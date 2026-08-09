#!/usr/bin/env python3
"""Slime-scheme: flood-fill magenta key + despill + LANCZOS + union canvas."""
from __future__ import annotations
from collections import deque
from pathlib import Path
import subprocess
import numpy as np
from PIL import Image

ROOT = Path('/tmp/mob-v2')
CANON = Path('/workspace/docs/superpowers/art-canon/monster-video')
ASSETS = Path('/workspace/midgard_outpost/assets/images/enemies')

MOB_PICKS = {
    "lunatic": (4,7,10,13,16,19),
    "wolf": (7,10,13,16,19,22),
    "mushroom": (4,7,10,13,16,19),
    "bee": (1,4,7,10,13,16),
    "crab": (4,7,10,13,16,19),
    "ghost": (1,4,7,10,13,16),
    "plant": (4,7,10,13,16,19),
    "boss_demon": (4,7,10,13,16,19),
    "boss_spider": (4,7,10,13,16,19),
    "boss_undead": (4,7,10,13,16,19),
    "boss_golem": (4,7,10,13,16,19),
}

def is_magenta(r,g,b):
    chroma=(r+b)/2.0 - g
    if r>=175 and b>=175 and g<=95 and chroma>=95: return True
    if r>=205 and b>=185 and g<=115 and chroma>=85: return True
    return False

def flood_key(img: Image.Image) -> Image.Image:
    a=np.array(img.convert('RGBA')); h,w=a.shape[:2]
    rem=np.zeros((h,w),dtype=bool)
    for y in range(h):
        row=a[y]
        for x in range(w):
            r,g,b=int(row[x,0]),int(row[x,1]),int(row[x,2])
            rem[y,x]=is_magenta(r,g,b)
    visited=np.zeros((h,w),dtype=bool); q=deque()
    for x in range(0,w,4):
        for y in (0,h-1):
            if rem[y,x]: visited[y,x]=True; q.append((x,y))
    for y in range(0,h,4):
        for x in (0,w-1):
            if rem[y,x]: visited[y,x]=True; q.append((x,y))
    while q:
        x,y=q.popleft(); a[y,x,3]=0
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx,ny=x+dx,y+dy
            if 0<=nx<w and 0<=ny<h and not visited[ny,nx] and rem[ny,nx]:
                visited[ny,nx]=True; q.append((nx,ny))
    return Image.fromarray(a)

def despill(img: Image.Image) -> Image.Image:
    a=np.array(img.convert('RGBA')).astype(np.float32)
    r,g,b,al=a[:,:,0],a[:,:,1],a[:,:,2],a[:,:,3]
    spill=np.clip((np.minimum(r,b)-g)/70.0,0,1)*(al>0)*((r>g+10)&(b>g+10))
    r2=r-spill*np.maximum(0,r-g)*0.9
    b2=b-spill*np.maximum(0,b-g)*0.9
    g2=g+spill*np.maximum(0,(r+b)/2-g)*0.12
    return Image.fromarray(np.clip(np.stack([r2,g2,b2,al],-1),0,255).astype(np.uint8))

def kill_fringe_magenta(img: Image.Image) -> Image.Image:
    a=np.array(img.convert('RGBA')); h,w=a.shape[:2]; al=a[:,:,3]
    for y in range(h):
        for x in range(w):
            if al[y,x]==0: continue
            r,g,b=int(a[y,x,0]),int(a[y,x,1]),int(a[y,x,2])
            if not (r>=200 and b>=190 and g<=70 and ((r+b)/2-g)>=150): continue
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)):
                nx,ny=x+dx,y+dy
                if 0<=nx<w and 0<=ny<h and al[ny,nx]==0:
                    a[y,x,3]=0; break
    return Image.fromarray(a)

def keep_largest(img: Image.Image) -> Image.Image:
    a=np.array(img); h,w=a.shape[:2]; solid=a[:,:,3]>16
    visited=np.zeros((h,w),dtype=bool); best=None; best_n=0
    for y in range(h):
        for x in range(w):
            if visited[y,x] or not solid[y,x]: continue
            q=deque([(x,y)]); visited[y,x]=True; comp=[]
            while q:
                cx,cy=q.popleft(); comp.append((cx,cy))
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx,ny=cx+dx,cy+dy
                    if 0<=nx<w and 0<=ny<h and not visited[ny,nx] and solid[ny,nx]:
                        visited[ny,nx]=True; q.append((nx,ny))
            if len(comp)>best_n: best_n=len(comp); best=comp
    out=np.zeros_like(a)
    if best:
        for x,y in best: out[y,x]=a[y,x]
    return Image.fromarray(out)

def process_frame(img: Image.Image, max_edge=160) -> Image.Image:
    im=flood_key(img); im=despill(im); im=kill_fringe_magenta(im); im=keep_largest(im)
    bbox=im.getbbox()
    if bbox:
        x0,y0,x1,y1=bbox
        im=im.crop((max(0,x0-2),max(0,y0-2),min(im.width,x1+2),min(im.height,y1+2)))
    w,h=im.size; scale=max_edge/max(w,h)
    if abs(scale-1)>1e-6:
        im=im.resize((max(1,int(w*scale)),max(1,int(h*scale))), Image.Resampling.LANCZOS)
    arr=np.array(im); arr[:,:,3]=np.where(arr[:,:,3]<12,0,arr[:,:,3])
    for y,x in ((0,0),(0,-1),(-1,0),(-1,-1)): arr[y,x,3]=0
    return Image.fromarray(arr)

def union_bottom(frames):
    bboxes=[f.getbbox() for f in frames]
    cw=max(x1-x0 for x0,y0,x1,y1 in bboxes)
    ch=max(y1-y0 for x0,y0,x1,y1 in bboxes)
    out=[]
    for f,(x0,y0,x1,y1) in zip(frames,bboxes):
        crop=f.crop((x0,y0,x1,y1))
        canvas=Image.new('RGBA',(cw,ch),(0,0,0,0))
        canvas.paste(crop, ((cw-crop.width)//2, ch-crop.height), crop)
        arr=np.array(canvas)
        for y,x in ((0,0),(0,-1),(-1,0),(-1,-1)): arr[y,x,3]=0
        out.append(Image.fromarray(arr))
    return out

def extract(mob):
    vid=ROOT/f'{mob}.mp4'
    frames_dir=ROOT/'frames'/mob
    frames_dir.mkdir(parents=True, exist_ok=True)
    if len(list(frames_dir.glob('f_*.png')))<20:
        for p in frames_dir.glob('f_*.png'): p.unlink()
        subprocess.check_call(['ffmpeg','-y','-i',str(vid),'-vf','fps=8',str(frames_dir/'f_%03d.png')],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return frames_dir

def process_mob(mob):
    frames_dir=extract(mob)
    picks=MOB_PICKS[mob]
    srcs=[]
    for n in picks:
        p=frames_dir/f'f_{n:03d}.png'
        if not p.exists():
            # clamp to available
            avail=sorted(frames_dir.glob('f_*.png'))
            p=avail[min(n-1, len(avail)-1)]
        srcs.append(p)
    frames=[process_frame(Image.open(p),160) for p in srcs]
    frames=union_bottom(frames)
    (CANON/mob).mkdir(parents=True, exist_ok=True)
    (ASSETS/mob).mkdir(parents=True, exist_ok=True)
    for i,f in enumerate(frames):
        f.save(CANON/mob/f'walk_{i}.png')
        f.save(ASSETS/mob/f'walk_{i}.png')
    frames[0].save(ASSETS/f'{mob}.png')
    a=np.array(frames[0]); solid=a[:,:,3]>20; rgb=a[:,:,:3].astype(float)
    pink=solid&(rgb[:,:,0]>180)&(rgb[:,:,2]>140)&(rgb[:,:,1]<140)
    print(f'{mob}: {frames[0].size} pink%={100*pink.sum()/max(1,solid.sum()):.3f} solid%={100*solid.mean():.1f}')
    frames[0].save(ROOT/f'preview-{mob}.png')

if __name__=='__main__':
    import sys
    mobs=sys.argv[1:] or [p.stem for p in ROOT.glob('*.mp4')]
    for mob in mobs:
        if mob in MOB_PICKS and (ROOT/f'{mob}.mp4').exists():
            print('==', mob)
            process_mob(mob)
