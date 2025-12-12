G5OPT = ./build/ECE565-X86/gem5.opt
LOG = scripts/log.out

all: build sweep

.PHONY: build
build:
	scons USE_HDF5=0 -j 8 $(G5OPT)

.PHONY: sweep
sweep:
	@nohup python3 scripts/run_spec_sweep.py --sweep scripts/victim_config.json --max-workers 6 --reps 1 > $(LOG) 2>&1 &
