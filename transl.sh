#!/bin/sh

sed -e 's/\.\/a/C++/' -e 's/\.\/ctrh/Citron (opt,comp,heap=512M)/' -e 's/\.\/ctrx/Citron (opt,comp)/' -e 's/\.\/ctru/Citron (unopt,comp)/' -e 's/ctr/Citron (jit)/' -e 's/\.\/hask/Haskell/' -e 's/\.\///' -e 's/rustx/Rust/' -e 's/pypy3/Python (PyPy)/' $1 | sed -re 's/\b(.)/\u\1/g'
