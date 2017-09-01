#!/bin/bash
./plot_test.r $1 $2
montage -geometry 1024x1024 -tile 1x2 vdadaily_$2.png vda_$2.png ao_$2.png && rm vdadaily_$2.png vda_$2.png
