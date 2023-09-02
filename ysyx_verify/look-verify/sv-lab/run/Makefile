
NOVAS	:= /eda/tools/snps/verdi/R-2020.12/share/PLI/VCS/LINUX64
EXTRA	:= -P ${NOVAS}/novas.tab \
		${NOVAS}/pli.a

RTL_FLIST := -f ./lab.f \

TB_FLIST  := -f ./tb.f \
 
SIM_TOOL	:= vcs
WAVE_TOOL	:= verdi
WAVE_FILE	:= top_tb.fsdb

# sim options
SIM_OPTIONS := 	-full64 -debug_access+all +v2k -sverilog -timescale=1ns/1ns \
				-debug_access+r+w+nomemcbk -debug_region+cell +vpi \
				${EXTRA} \
				-kdb \
				+error+500 \
				+notimingcheck \
				+nospecify \
				+delay_mode_distributed \
				+vcs+flush+all \
				+lint=TFIPC-L \
				-CFLAGS -DVCS \
				+incdir+../sv-lab/mcdf \
				+incdir+../sv-lab \

comp:
	$(SIM_TOOL) $(SIM_OPTIONS) $(TB_FLIST) $(RTL_FLIST) -top tb1 -l compile.log 

sim:
	./simv l vcs.log

wave:
	$(WAVE_TOOL) $(TB_FLIST) $(RTL_FLIST) -ssf $(WAVE_FILE)

.PHONY: clean
clean: 
	rm -rf ...
