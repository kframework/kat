# Settings

build_dir:=$(CURDIR)/.build
defn_dir:=$(build_dir)/defn

k_submodule:=$(build_dir)/k
k_bin:=$(k_submodule)/k-distribution/target/release/k/bin

pandoc_tangle_submodule:=$(build_dir)/pandoc-tangle
tangler:=$(pandoc_tangle_submodule)/tangle.lua
LUA_PATH:=$(pandoc_tangle_submodule)/?.lua;;
export LUA_PATH

test_dir:=tests

.PHONY: build deps defn example-files

all: build

clean:
	rm -rf $(build_dir)

# Build definition
# ----------------

# Tangle *.k files

k_files:=imp-kat.k imp.k kat.k
defn_files:=$(patsubst %, $(defn_dir)/%, $(k_files))

defn: $(defn_files)

$(defn_dir)/kat.k: KAT.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:.kat $< > $@

$(defn_dir)/imp-kat.k: KAT-IMP.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:.imp-kat $< > $@

$(defn_dir)/imp.k: KAT-IMP.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:.imp-lang $< > $@

# Dependencies

deps: $(k_submodule)/make.timestamp $(pandoc_tangle_submodule)/make.timestamp

$(k_submodule)/make.timestamp:
	git submodule update --init -- $(k_submodule)
	cd $(k_submodule) \
		&& mvn package -q -DskipTests
	touch $(k_submodule)/make.timestamp

$(pandoc_tangle_submodule)/make.timestamp:
	git submodule update --init -- $(pandoc_tangle_submodule)
	touch $(pandoc_tangle_submodule)/make.timestamp

# Java Backend

build: .build/java/imp-analysis-kompiled/timestamp

.build/java/imp-analysis-kompiled/timestamp: $(defn_files)
	@echo "== kompile: $@"
	$(k_bin)/kompile --debug --main-module IMP-ANALYSIS --backend java \
					 --syntax-module IMP-ANALYSIS $< --directory .build/java

# Testing
# -------

# Tangle examples

example_files:=straight-line-1.imp straight-line-2.imp \
               dead-if.imp \
               inf-div-bad.imp inf-div-good.imp \
               sum.imp sum-plus.imp \
               collatz.imp collatz-all.imp \
               krazy-loop-correct.imp krazy-loop-incorrect.imp

example-files: $(patsubst %, $(test_dir)/examples/%, $(example_files))

$(test_dir)/examples/%.imp: KAT-IMP-examples.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:.$* $< > $@

# Tangle test scripts

test_scripts:=straight-line-2-bimc1.sh straight-line-2-bimc2.sh straight-line-2-bimc3.sh \
              inf-div-bad-bimc.sh inf-div-good-bimc.sh \
              sum-bimc1.sh sum-bimc2.sh sum-bimc3.sh \
              collatz-bimc.sh collatz-all-bimc.sh \
              krazy-loop-correct-bimc.sh krazy-loop-incorrect-bimc1.sh krazy-loop-incorrect-bimc2.sh \
              straight-line-1-sbc.sh straight-line-2-sbc.sh \
              dead-if-sbc.sh \
              sum-sbc.sh sum-plus-sbc.sh \
              collatz-sbc.sh collatz-all-sbc.sh \
              krazy-loop-incorrect-sbc.sh krazy-loop-correct-sbc.sh

test-script: $(test_dir)/examples/run-tests.sh

$(test_dir)/examples/run-tests.sh: KAT-IMP-examples.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:".sh.test" KAT-IMP-examples.md > $@
	chmod u+x $@
