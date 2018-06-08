# Settings
# --------

build_dir:=.build
defn_dir:=$(build_dir)/defn

k_submodule:=$(build_dir)/k
k_bin:=$(k_submodule)/k-distribution/target/release/k/bin
kompile:=$(k_bin)/kompile
krun:=$(k_bin)/krun

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
					 --syntax-module IMP-ANALYSIS $< --directory $(defn_dir)

# Testing
# -------

test_files:=$(wildcard $(test_dir)/*.imp)

TEST=./kat test

test: $(test_files:=.test)

$(test_dir)/%.imp.test:
	$(TEST) $(test_dir)/$*.imp $(test_dir)/$*.strat

$(test_dir)/%.expected:
	mkdir -p $@
