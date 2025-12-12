G5OPT = ./build/ECE565-X86/gem5.opt
LOG = scripts/log.out
BENCHMARK="lbm_s"

all: build sweep

.PHONY: build
build:
	scons-3 USE_HDF5=0 -j 8 $(G5OPT)

.PHONY: sweep
sweep:
	@nohup python3 scripts/run_spec_sweep.py --sweep scripts/victim_config.json --max-workers 6 --reps 1 > $(LOG) 2>&1 &

.PHONY: sim-victim
sim-victim:
	build/ECE565-X86/gem5.opt configs/spec/spec_victim_cache_config.py --cpu-type=X86MinorCPU --benchmark=$(BENCHMARK) --ff-instructions 100000 --sim-instructions 10000 --caches --enable-victim-cache

.PHONY: sim-no-victim
sim-no-victim:
	build/ECE565-X86/gem5.opt configs/spec/spec_victim_cache_config.py --cpu-type=X86MinorCPU --benchmark=$(BENCHMARK) --ff-instructions 100000 --sim-instructions 10000 --caches --disable-victim-cache

