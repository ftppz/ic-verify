#!/bin/csh -f

cd /home/wuwei/alu

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/eda/tools/snps/VCS/R-2020.12/linux64/bin/vcselab $* \
    -o \
    sim_alu \
    -nobanner \

cd -

