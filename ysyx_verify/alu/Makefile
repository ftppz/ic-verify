NAME = sim_alu

SIM = vcs

SIM_FALGS = -full64 +v2k -sverilog -timescale=1ns/1ns +incdir+./include -f ./filelist -o ${NAME} -l ${NAME}.log

compile:
	${SIM} ${SIM_FALGS}

run:
	./${NAME} +TESTNAME=op_test

sim:
	make compile
	make run

clean:
	rm -rf csrc *.log ${NAME} ${NAME}.* ucli.key

