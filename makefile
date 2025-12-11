CPU_MODEL="WIB_O3CPU"
BENCHMARK="lbm_s"
.PHONY: build sim debug

empty_:
	echo "NOP"

build:
	scons-3 USE_HDF5=0 -j 10 ./build/ECE565-X86/gem5.opt

sim-victim:
	build/ECE565-X86/gem5.opt --debug-flags=Cache configs/spec/spec_victim_cache_config.py --cpu-type=X86MinorCPU --benchmark=$(BENCHMARK) --ff-instructions 100000 --sim-instructions 10000 --caches --enable-victim-cache

sim-no-victim:
	build/ECE565-X86/gem5.opt --debug-flags=Cache configs/spec/spec_victim_cache_config.py --cpu-type=X86MinorCPU --benchmark=$(BENCHMARK) --ff-instructions 100000 --sim-instructions 10000 --caches

