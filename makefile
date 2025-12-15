PY = python3.12
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

	@nohup $(PY) scripts/run_spec_sweep.py --sweep scripts/victim_config.json --max-workers 20 --reps 1 --resume > $(LOG) 2>&1 &

.PHONY: sweep_force
sweep_force:
	@nohup $(PY) scripts/run_spec_sweep.py --sweep scripts/victim_config.json --max-workers 20 --reps 1 > $(LOG) 2>&1 &

.PHONY: check
check:
	@ps -ef | grep "bowles7" | grep "gem5" | grep -v "grep"

.PHONY: data
data:
	@python3.12 scripts/parse_all_stats_to_json.py --out-root out --collect-dir ../pas/vc/data/

.PHONY: graphs
graphs:
	python3.12 ../scripts/g5charts.py ipcbar -o ../pas/vc/ipc.png ../pas/vc/data/*.json

.PHONY: csv
csv:
	python3.12 ../scripts/g5getdata.py --json-dir ../pas/vc/data --out-csv ../pas/vc/vc.csv --include-id-cols  --mode auto --metric ipc=ipc --metric dc_a=dcache.overallAccesses --metric dc_m=dcache.overallMisses --metric ic_a=icache.overallAccesses --metric ic_m=icache.overallMisses --metric l2_a=l2.overallAccesses --metric l2_m=l2.overallMisses
