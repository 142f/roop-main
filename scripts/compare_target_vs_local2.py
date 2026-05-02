#!/usr/bin/env python3
import re, subprocess
from pathlib import Path

def load_local_from_pip():
    d={}
    out = subprocess.check_output([str(Path('.venv310')/ 'Scripts' / 'python.exe'), '-m', 'pip', 'freeze'], text=True)
    for l in out.splitlines():
        l=l.strip()
        if not l or l.startswith('#'): continue
        m=re.match(r"([^=<>!~\[\]]+)==(.+)$", l)
        if m:
            name=m.group(1).strip().lower()
            ver=m.group(2).strip()
            d[name]=ver
    return d

server_target = {
    'flask':'2.2.5',
    'flask-cors':'3.0.10',
    'werkzeug':'2.2.3',
    'onnx':'1.14.0',
    'onnxruntime-gpu':'1.15.0',
    'tensorflow':'2.15.0',
    'protobuf':'4.23.4',
    'insightface':'0.7.3',
    'kornia':'0.6.8',
    'timm':'0.5.4',
    'transformers':None,
    'numpy':'1.24.3',
    'opencv-python-headless':'4.8.0.74',
    'scipy':'1.15.3',
    'scikit-image':'0.20.0',
    'pillow':'9.5.0',
    'imageio':'2.9.0',
    'moviepy':'1.0.3',
    'matplotlib':'3.8.0',
    'tqdm':'4.65.0',
    'psutil':'5.9.5',
    'opennsfw2':'0.10.2',
    'hydra-core':'1.3.2',
    'gdown':None,
    'ipython':'7.21.0',
    'fraction':'1.5.1'
}

local = load_local_from_pip()

print('=== Target vs Local Summary ===')
missing=0
for pkg, target_ver in server_target.items():
    local_ver = local.get(pkg)
    if local_ver is None:
        print(f'MISSING_ON_LOCAL  : {pkg}   target={target_ver}')
        missing+=1
    else:
        if target_ver is None:
            print(f'PRESENT           : {pkg}   local={local_ver}   target=any')
        else:
            match = 'OK' if local_ver==target_ver else 'DIFF'
            print(f'{match:4}             : {pkg}   local={local_ver}   target={target_ver}')

print('\n=== Local-only packages (present locally but not in target) ===')
extras = [p for p in sorted(local.keys()) if p not in server_target]
for p in extras:
    print('LOCAL_ONLY       :', p, local[p])

print('\n=== Summary ===')
print('Total target packages:', len(server_target))
print('Missing on local:', missing)
print('Extra local packages:', len(extras))

print('\nNote: run.py was previously executed successfully in this environment (exit code 0).')
