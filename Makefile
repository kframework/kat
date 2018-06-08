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

.PHONY: build build-krun build-kompile deps ocaml-deps \
		defn defn-krun defn-kompile example-files \
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

# Tangle *.k files

k_files:=kat-imp.k imp.k kat.k
kcompile_files:=$(patsubst %, $(defn_dir)/kcompile/%, $(k_files))
krun_files:=$(defn_dir)/krun/imp.k

defn: defn-kcompile defn-krun

defn-kcompile: $(kcompile_files)
defn-krun: $(krun_files)

$(defn_dir)/kcompile/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:'.k,.kcompile' $< > $@

$(defn_dir)/krun/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(tangler)" --metadata=code:'.k,.krun' $< > $@

# Java Backend

build: build-kcompile build-krun

build-kcompile: $(defn_dir)/kcompile/kat-imp-kompiled/timestamp
build-krun: $(defn_dir)/krun/imp-kompiled/interpreter

$(defn_dir)/kcompile/kat-imp-kompiled/timestamp: $(kcompile_files)
	@echo "== kompile: $@"
	$(kompile) --main-module IMP-ANALYSIS --backend java \
				 --syntax-module IMP-ANALYSIS $< --directory $(defn_dir)/kcompile

$(defn_dir)/krun/imp-kompiled/interpreter: $(krun_files)
	@echo "== kompile: $@"
	eval $$(opam config env) \
		$(kompile) --main-module IMP --backend ocaml \
					 --syntax-module IMP $< --directory $(defn_dir)/krun

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
