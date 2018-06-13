# Settings
# --------

build_dir:=.build
defn_dir:=$(build_dir)/defn
imp_dir:=$(defn_dir)/imp
simple_dir:=$(defn_dir)/simple

k_submodule:=$(build_dir)/k
k_bin:=$(k_submodule)/k-distribution/target/release/k/bin
kompile:=$(k_bin)/kompile
krun:=$(k_bin)/krun

pandoc_tangle_submodule:=$(build_dir)/pandoc-tangle
tangler:=$(pandoc_tangle_submodule)/tangle.lua
LUA_PATH:=$(pandoc_tangle_submodule)/?.lua;;
export LUA_PATH

test_dir:=tests

.PHONY: build build-krun build-kompile build-krun-imp build-kompile-imp build-krun-simple \
		defn defn-krun defn-kompile defn-krun-imp defn-kompile-imp defn-krun-simple example-files \
		deps ocaml-deps \
		test-bimc test-sbc test

all: build

clean:
	rm -rf $(build_dir)

# Dependencies
# ------------

deps: $(k_submodule)/make.timestamp $(pandoc_tangle_submodule)/make.timestamp ocaml-deps

$(k_submodule)/make.timestamp:
	git submodule update --init -- $(k_submodule)
	cd $(k_submodule) \
		&& mvn package -q -DskipTests
	touch $(k_submodule)/make.timestamp

$(pandoc_tangle_submodule)/make.timestamp:
	git submodule update --init -- $(pandoc_tangle_submodule)
	touch $(pandoc_tangle_submodule)/make.timestamp

ocaml-deps:
	opam init --quiet --no-setup
	opam repository add k "$(k_submodule)/k-distribution/target/release/k/lib/opam" \
	    || opam repository set-url k "$(k_submodule)/k-distribution/target/release/k/lib/opam"
	opam update
	opam switch 4.03.0+k
	eval $$(opam config env) \
	    opam install --yes mlgmp zarith uuidm ocaml-protoc rlp yojson hex ocp-ocamlres

# Build definition
# ----------------

imp_kcompile_dir:=$(defn_dir)/imp/kcompile
imp_krun_dir:=$(defn_dir)/imp/krun
simple_krun_dir:=$(defn_dir)/simple/krun
imp_kcompile_files:=$(patsubst %, $(imp_kcompile_dir)/%, kat-imp.k kat.k imp.k)
imp_krun_files:=$(patsubst %, $(imp_krun_dir)/%, imp.k)
simple_krun_files:=$(patsubst %, $(simple_krun_dir)/%, simple.k)

# Tangle *.k files

defn: defn-kcompile-imp defn-krun-imp defn-krun-simple

defn-kcompile-imp: $(imp_kcompile_files)
defn-krun-imp: $(imp_krun_files)
defn-krun-simple: $(simple_krun_files)

$(imp_kcompile_dir)/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:'.k,.kcompile' $< > $@

$(imp_krun_dir)/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:'.k,.krun' $< > $@

$(simple_krun_dir)/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:'.k,.krun' $< > $@

# Backends (for running and compiling)

build: build-kcompile-imp build-krun-imp build-krun-simple

build-kcompile-imp: $(imp_kcompile_dir)/kat-imp-kompiled/timestamp
build-krun-imp: $(imp_krun_dir)/imp-kompiled/interpreter

$(imp_dir)/kcompile/kat-imp-kompiled/timestamp: $(imp_kcompile_files)
	@echo "== kompile: $@"
	$(kompile) --main-module IMP-ANALYSIS --backend java \
			   --syntax-module IMP-ANALYSIS $< --directory $(defn_dir)/kcompile

$(imp_dir)/krun/imp-kompiled/interpreter: $(imp_krun_files)
	@echo "== kompile: $@"
	eval $$(opam config env) \
		$(kompile) --main-module IMP --backend ocaml \
				   --syntax-module IMP $< --directory $(defn_dir)/krun

build-krun-simple: $(simple_krun_dir)/simple-kompiled/interpreter

$(simple_dir)/krun/simple-kompiled/interpreter: $(simple_krun_files)
	@echo "== kompile: $@"
	eval $$(opam config env) \
		$(kompile) --main-module SIMPLE --backend ocaml \
				   --syntax-module SIMPLE $< --directory $(defn_dir)/krun

# Testing
# -------

test_files:=$(wildcard $(test_dir)/*.imp)

TEST=./kat test

test: $(test_files:=.test)

$(test_dir)/%.imp.test:
	$(TEST) $(test_dir)/$*.imp $(test_dir)/$*.strat

$(test_dir)/%.expected:
	mkdir -p $@

# SBC Benchmarking
# ----------------

sbced_files:=$(wildcard $(test_dir)/sbced/*.k)

$(test_dir)/sbced/%/diff.runtime: $(test_dir)/sbced/%/original.runtime $(test_dir)/sbced/%/compiled.runtime
	git diff --no-index --ignore-space-change $^ || true

$(test_dir)/sbced/%/original.runtime: $(defn_dir)/krun/imp-kompiled/interpreter $(test_dir)/%.imp
	eval $$(opam config env) ; \
		time ( $(krun) --directory $(defn_dir)/krun $(test_dir)/$*.imp &>$@ ) &>> $@

$(test_dir)/sbced/%/compiled-kompiled/interpreter: $(test_dir)/sbced/%/compiled.k
	eval $$(opam config env) ; \
		$(kompile) --backend ocaml --main-module COMPILED --syntax-module COMPILED $< --directory $(test_dir)/sbced/$*

$(test_dir)/sbced/%/compiled.runtime: $(test_dir)/sbced/%/compiled-kompiled/interpreter $(test_dir)/%.imp
	eval $$(opam config env) ; \
		time ( $(krun) --directory tests/sbced/$* -cN=10000 &>$@ ) &>> $@
