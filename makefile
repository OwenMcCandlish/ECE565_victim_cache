PY = python3.12
G5OPT = ./build/ECE565-X86/gem5.opt
LOG = scripts/log.out

all: build sweep

.PHONY: build
build:
	scons-3 USE_HDF5=0 -j 8 $(G5OPT)

.PHONY: sweep
sweep:
	@nohup $(PY) scripts/run_spec_sweep.py --sweep scripts/victim_config.json --max-workers 20 --reps 1 --resume > $(LOG) 2>&1 &

.PHONY: check
check:
	@ps -ef | grep "bowles7" | grep "gem5" | grep -v "grep"

.PHONY: data
data:
	@python3.12 scripts/parse_all_stats_to_json.py --out-root out --collect-dir ../pas/vc/data/

.PHONY: graphs
graphs:
	python3.12 ../scripts/g5charts.py ipcbar -o ../pas/vc/ipc.png ../pas/vc/data/*.json
