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
pandoc:=pandoc --from markdown --to markdown --lua-filter "$(tangler)"

test_dir:=tests
test_output:=.build/logs

.PHONY: deps deps-k deps-ocaml deps-tangle \
        defn  defn-imp  defn-imp-kcompile  defn-imp-krun  defn-fun  defn-fun-krun  defn-fun-kcompile \
        build build-imp build-imp-kcompile build-imp-krun build-fun build-fun-krun build-fun-kcompile \
        test test-imp test-fun

all: build

clean:
	rm -rf $(build_dir)

# Dependencies
# ------------

deps: deps-k deps-ocaml deps-tangle
deps-k: $(k_submodule)/make.timestamp
deps-tangle: $(pandoc_tangle_submodule)/make.timestamp

$(k_submodule)/make.timestamp:
	git submodule update --init -- $(k_submodule)
	cd $(k_submodule) && mvn package -q -DskipTests -Dllvm.backend.skip
	touch $(k_submodule)/make.timestamp

$(pandoc_tangle_submodule)/make.timestamp:
	git submodule update --init -- $(pandoc_tangle_submodule)
	touch $(pandoc_tangle_submodule)/make.timestamp

deps-ocaml:
	eval $$(opam config env) \
	    opam install --yes mlgmp zarith uuidm ocaml-protoc rlp yojson hex ocp-ocamlres

# Build definition
# ----------------

imp_dir=$(defn_dir)/imp
imp_kcompile_files:=$(patsubst %, $(imp_dir)/kcompile/%, kat-imp.k kat.k imp.k)
imp_krun_files:=$(patsubst %, $(imp_dir)/krun/%, imp.k)

fun_dir=$(defn_dir)/fun
fun_kcompile_files:=$(patsubst %, $(fun_dir)/kcompile/%, kat-fun.k kat.k fun.k)
fun_krun_files:=$(patsubst %, $(fun_dir)/krun/%, fun.k)

defn: defn-imp defn-fun

defn-imp: defn-imp-kcompile defn-imp-krun
defn-imp-kcompile: $(imp_kcompile_files)
defn-imp-krun:     $(imp_krun_files)

$(imp_dir)/kcompile/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	$(pandoc) --metadata=code:'.k,.kcompile' $< > $@

$(imp_dir)/krun/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	$(pandoc) --metadata=code:'.k,.krun' $< > $@

defn-fun: defn-fun-kcompile defn-fun-krun
defn-fun-kcompile: $(fun_kcompile_files)
defn-fun-krun:     $(fun_krun_files)

$(fun_dir)/kcompile/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	$(pandoc) --metadata=code:'.k,.kcompile' $< > $@

$(fun_dir)/krun/%.k: %.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	$(pandoc) --metadata=code:'.k,.krun' $< > $@

# Backends (for running and compiling)

build: build-imp build-fun

build-imp: build-imp-kcompile build-imp-krun
build-imp-kcompile: $(imp_dir)/kcompile/kat-imp-kompiled/timestamp
build-imp-krun:     $(imp_dir)/krun/imp-kompiled/interpreter

$(imp_dir)/kcompile/kat-imp-kompiled/timestamp: $(imp_kcompile_files)
	@echo "== kompile: $@"
	$(kompile) --main-module IMP-ANALYSIS --backend java \
	           --syntax-module IMP-ANALYSIS $< --directory $(imp_dir)/kcompile

$(imp_dir)/krun/imp-kompiled/interpreter: $(imp_krun_files)
	@echo "== kompile: $@"
	eval $$(opam config env) \
	    $(kompile) --main-module IMP --backend ocaml --non-strict -O3 \
	                 --syntax-module IMP $< --directory $(imp_dir)/krun

build-fun: build-fun-kcompile build-fun-krun
build-fun-kcompile: $(fun_dir)/kcompile/kat-fun-kompiled/timestamp
build-fun-krun:     $(fun_dir)/krun/fun-kompiled/interpreter

$(fun_dir)/kcompile/kat-fun-kompiled/timestamp: $(fun_kcompile_files)
	@echo "== kompile: $@"
	$(kompile) --main-module FUN-ANALYSIS --backend java \
	           --syntax-module FUN-UNTYPED-SYNTAX $< --directory $(fun_dir)/kcompile

$(fun_dir)/krun/fun-kompiled/interpreter: $(fun_krun_files)
	@echo "== kompile: $@"
	eval $$(opam config env) \
	    $(kompile) --main-module FUN-UNTYPED --backend ocaml --non-strict -O3 \
	               --syntax-module FUN-UNTYPED-SYNTAX $< --directory $(fun_dir)/krun

# Testing
# -------

test_imp_files:=$(wildcard $(test_dir)/imp/*.strat)
test_fun_files:=$(wildcard $(test_dir)/fun/*.strat)

TEST=./kat test

test: test-imp test-fun
test-imp: $(test_imp_files:=.test)
test-fun: $(test_fun_files:=.test)

%.strat.test:
	$(TEST) $*
