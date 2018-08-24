#!/bin/sh

sed -e 's/\.\/a/C++/' -e 's/\.\/ctrh/Citron (opt,heap=512M)/' -e 's/\.\/ctrx/Citron (opt)/' -e 's/\.\/ctru/Citron (unopt)/' -e 's/ctr/Citron (jit)/' -e 's/\.\/hask/Haskell/' -e 's/\.\///' -e 's/rustx/Rust/' $1 | sed -re 's/\b(.)/\u\1/g'
