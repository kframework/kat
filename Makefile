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

bimc_files:=straight-line-1.imp \
			straight-line-2.imp \
			sum.imp \
			inf-div-bad.imp \
			inf-div-good.imp \
			collatz.imp \
			collatz-all.imp \
			krazy-loop-correct.imp \
			krazy-loop-incorrect.imp

test-bimc: $(patsubst %, $(example_dir)/%, $(bimc_files:=.testbimc))

$(example_dir)/straight-line-1.imp.testbimc:
	$(TEST) $(example_dir)/straight-line-1.imp      $(example_dir)/bimc/straight-line-1-1      'step-with skip ; step ; bimc 1 (bexp? x <= 7)'
	$(TEST) $(example_dir)/straight-line-1.imp      $(example_dir)/bimc/straight-line-1-2      'step-with skip ; step ; bimc 2 (bexp? x <= 7)'

$(example_dir)/straight-line-2.imp.testbimc:
	$(TEST) $(example_dir)/straight-line-2.imp      $(example_dir)/bimc/straight-line-2-1      'step-with skip ; step ; bimc 1 (bexp? x <= 7)'
	$(TEST) $(example_dir)/straight-line-2.imp      $(example_dir)/bimc/straight-line-2-2      'step-with skip ; step ; bimc 2 (bexp? x <= 7)'
	$(TEST) $(example_dir)/straight-line-2.imp      $(example_dir)/bimc/straight-line-2-3      'step-with skip ; step ; bimc 500 (bexp? x <= 7)'

$(example_dir)/sum.imp.testbimc:
	$(TEST) $(example_dir)/sum.imp                  $(example_dir)/bimc/sum-1                  'step-with skip ; bimc 500 (bexp? s <= 32)'
	$(TEST) $(example_dir)/sum.imp                  $(example_dir)/bimc/sum-2                  'step-with skip ; bimc 41 (bexp? s <= 32)'
	$(TEST) $(example_dir)/sum.imp                  $(example_dir)/bimc/sum-3                  'step-with skip ; bimc 40 (bexp? s <= 32)'

$(example_dir)/inf-div-bad.imp.testbimc:
	$(TEST) $(example_dir)/inf-div-bad.imp          $(example_dir)/bimc/inf-div-bad-1          'bimc 5000 (not div-zero-error?)'

$(example_dir)/inf-div-good.imp.testbimc:
	$(TEST) $(example_dir)/inf-div-good.imp         $(example_dir)/bimc/inf-div-good-1         'bimc 5000 (not div-zero-error?)'

$(example_dir)/collatz.imp.testbimc:
	$(TEST) $(example_dir)/collatz.imp              $(example_dir)/bimc/collatz-1              'step-with skip ; bimc 5000 (bexp? n <= 1000)'

$(example_dir)/collatz-all.imp.testbimc:
	$(TEST) $(example_dir)/collatz-all.imp          $(example_dir)/bimc/collatz-all-1          'step-with skip ; bimc 5000 (bexp? n <= 1000)'

$(example_dir)/krazy-loop-correct.imp.testbimc:
	$(TEST) $(example_dir)/krazy-loop-correct.imp   $(example_dir)/bimc/krazy-loop-correct-1   'bimc 5000 (not div-zero-error?)'

$(example_dir)/krazy-loop-incorrect.imp.testbimc:
	$(TEST) $(example_dir)/krazy-loop-incorrect.imp $(example_dir)/bimc/krazy-loop-incorrect-1 'bimc 5000 (not div-zero-error?)'
	$(TEST) $(example_dir)/krazy-loop-incorrect.imp $(example_dir)/bimc/krazy-loop-incorrect-2 'bimc 1384 (not div-zero-error?)'

test-sbc: $(example_files:=.testsbc)

$(example_dir)/%.imp.testsbc:
	$(TEST) $(example_dir)/$*.imp $(example_dir)/sbc/$* 'compile'
