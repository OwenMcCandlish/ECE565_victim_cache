G5OPT = ./build/ECE565-X86/gem5.opt

all: build sweep

.PHONY: build
build:
	scons USE_HDF5=0 -j 8 $(G5OPT)

.PHONY: sweep
sweep:
	python3 scripts/run_spec_sweep.py --sweep scripts/victim_config.json --max-workers 6 --reps 1
