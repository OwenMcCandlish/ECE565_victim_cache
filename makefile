CPU_MODEL="WIB_O3CPU"
BENCHMARK="lbm_s"

.PHONY: build sim debug

empty_:
	echo "NOP"

build:
	scons-3 USE_HDF5=0 -j 10 ./build/ECE565-X86/gem5.opt

sim-victim:
	build/ECE565-X86/gem5.opt configs/spec/spec_victim_cache_config.py --cpu-type=X86MinorCPU --benchmark=$(BENCHMARK) --enable-fast-forward --caches --enable-victim-cache

sim-no-victim:
	build/ECE565-X86/gem5.opt configs/spec/spec_victim_cache_config.py --cpu-type=X86MinorCPU --benchmark=$(BENCHMARK) --enable-fast-forward --caches

debug:
	# Can also print to file with --debug-file
	DEBUG_FLAG="WIB"
	./build/ECE565-X86/gem5.opt configs/spec/spec_se_project_config.py --debug-flags=$(DEBUG_FLAG) --cpu-type=$(CPU_MODEL) -b $(BENCHMARK) --caches --l2cache --enable-fast-forward

