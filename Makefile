# Settings
# --------

build_dir:=$(CURDIR)/.build
defn_dir:=$(build_dir)/defn

k_submodule:=$(build_dir)/k
k_bin:=$(k_submodule)/k-distribution/target/release/k/bin

pandoc_tangle_submodule:=$(build_dir)/pandoc-tangle
tangler:=$(pandoc_tangle_submodule)/tangle.lua
LUA_PATH:=$(pandoc_tangle_submodule)/?.lua;;
export LUA_PATH

test_dir:=tests

.PHONY: build deps defn example-files \
		test-bimc test-sbc test

all: build

clean:
	rm -rf $(build_dir)

# Build definition
# ----------------

# Tangle *.k files

k_files:=kat-imp.k imp.k kat.k
defn_files:=$(patsubst %, $(defn_dir)/%, $(k_files))

defn: $(defn_files)

$(defn_dir)/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:.k $< > $@

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

build: $(defn_dir)/imp-analysis-kompiled/timestamp

$(defn_dir)/imp-analysis-kompiled/timestamp: $(defn_files)
	@echo "== kompile: $@"
	$(k_bin)/kompile --debug --main-module IMP-ANALYSIS --backend java \
					 --syntax-module IMP-ANALYSIS $< --directory $(defn_dir) --transition 'lookup assignment'

# Testing
# -------

example_dir:=tests/examples
example_files:=$(wildcard $(example_dir)/*.imp)

TEST=./kat test

test: test-bimc test-sbc

test-bimc:
	$(TEST) tests/examples/straight-line-1.imp    tests/examples/straight-line-1-bimc1.out      'step-with skip ; bimc 2 (bexp? x <= 7)'
	$(TEST) tests/examples/straight-line-1.imp    tests/examples/straight-line-1-bimc2.out      'step-with skip ; bimc 3 (bexp? x <= 7)'
	$(TEST) tests/examples/straight-line-2.imp    tests/examples/straight-line-2-bimc1.out      'step-with skip ; bimc 2 (bexp? x <= 7)'
	$(TEST) tests/examples/straight-line-2.imp    tests/examples/straight-line-2-bimc2.out      'step-with skip ; bimc 3 (bexp? x <= 7)'
	$(TEST) tests/examples/straight-line-2.imp    tests/examples/straight-line-2-bimc3.out      'step-with skip ; bimc 500 (bexp? x <= 7)'
	$(TEST) tests/examples/sum.imp                tests/examples/sum-bimc1.out                  'step-with skip ; bimc 500 (bexp? s <= 32)'
	$(TEST) tests/examples/sum.imp                tests/examples/sum-bimc2.out                  'step-with skip ; bimc 41 (bexp? s <= 32)'
	$(TEST) tests/examples/sum.imp                tests/examples/sum-bimc3.out                  'step-with skip ; bimc 40 (bexp? s <= 32)'
	$(TEST) tests/examples/inf-div-bad.imp        tests/examples/inf-div-bad-bimc.out           'bimc 5000 (not div-zero-error?)'
	$(TEST) tests/examples/inf-div-good.imp       tests/examples/inf-div-good-bimc.out          'bimc 5000 (not div-zero-error?)'
	$(TEST) tests/examples/collatz.imp            tests/examples/collatz-bimc.out               'step-with skip ; bimc 5000 (bexp? n <= 1000)'
	$(TEST) tests/examples/collatz-all.imp        tests/examples/collatz-all-bimc.out           'step-with skip ; bimc 5000 (bexp? n <= 1000)'
	$(TEST) tests/examples/krazy-loop-correct.imp tests/examples/krazy-loop-correct-bimc.out    'bimc 5000 (not div-zero-error?)'
	$(TEST) tests/examples/krazy-loop-incorrect   tests/examples/krazy-loop-incorrect-bimc1.out 'bimc 5000 (not div-zero-error?)'
	$(TEST) tests/examples/krazy-loop-incorrect   tests/examples/krazy-loop-incorrect-bimc2.out 'bimc 1384 (not div-zero-error?)'

test-sbc: $(example_files:=.testsbc)

$(example_dir)/%.imp.testsbc:
	$(TEST) $(example_dir)/$*.imp $(example_dir)/sbc/$* 'compile'
