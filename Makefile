# Settings
# --------

build_dir:=.build
defn_dir:=$(build_dir)/defn
k_submodule:=$(build_dir)/k
pandoc_tangle_submodule:=$(build_dir)/pandoc-tangle
k_bin:=$(k_submodule)/k-distribution/target/release/k/bin
tangler:=$(pandoc_tangle_submodule)/tangle.lua

LUA_PATH=$(pandoc_tangle_submodule)/?.lua;;
export LUA_PATH

.PHONY: all clean \
        deps ocaml-deps haskell-deps \
        defn defn-imp defn-imp-ocaml defn-imp-java defn-fun defn-fun-ocaml defn-fun-java \
        build build-imp build-imp-ocaml build-imp-java build-fun build-fun-ocaml build-fun-java \
        test test-imp test-fun

all: build

clean:
	rm -rf $(build_dir)
	git submodule update --init --recursive

# Build Dependencies (K Submodule)
# --------------------------------

deps: $(k_submodule)/make.timestamp $(pandoc_tangle_submodule)/make.timestamp ocaml-deps

$(k_submodule)/make.timestamp:
	git submodule update --init --recursive
	cd $(k_submodule) && mvn package -DskipTests -Dllvm.backend.skip
	touch $(k_submodule)/make.timestamp

$(pandoc_tangle_submodule)/make.timestamp:
	git submodule update --init -- $(pandoc_tangle_submodule)
	touch $(pandoc_tangle_submodule)/make.timestamp

ocaml-deps:
	eval $$(opam config env) \
	    opam install --yes mlgmp zarith uuidm

# Building Definition
# -------------------

imp_defn_dir:=$(defn_dir)/imp
imp_krun_files:=imp.k
imp_kcompile_files:=kat-imp.k kat.k imp.k

imp_ocaml_dir:=$(imp_defn_dir)/ocaml
imp_ocaml_defn:=$(patsubst %, $(imp_ocaml_dir)/%, $(imp_krun_files))
imp_ocaml_kompiled:=$(imp_ocaml_dir)/imp-kompiled/interpreter

imp_java_dir:=$(imp_defn_dir)/java
imp_java_defn:=$(patsubst %, $(imp_java_dir)/%, $(imp_kcompile_files))
imp_java_kompiled:=$(imp_java_dir)/kat-imp-kompiled/compiled.txt

fun_defn_dir:=$(defn_dir)/fun
fun_krun_files:=fun.k
fun_kcompile_files:=kat-fun.k kat.k fun.k

fun_ocaml_dir:=$(fun_defn_dir)/ocaml
fun_ocaml_defn:=$(patsubst %, $(fun_ocaml_dir)/%, $(fun_krun_files))
fun_ocaml_kompiled:=$(fun_ocaml_dir)/fun-kompiled/interpreter

fun_java_dir:=$(fun_defn_dir)/java
fun_java_defn:=$(patsubst %, $(fun_java_dir)/%, $(fun_kcompile_files))
fun_java_kompiled:=$(fun_java_dir)/kat-fun-kompiled/compiled.txt

# Tangle definition from *.md files

krun_tangler:='.k,.krun'
kcompile_tangler:='.k,.kcompile'

defn: defn-imp defn-fun
defn-imp: defn-imp-ocaml defn-imp-java
defn-fun: defn-fun-ocaml defn-fun-java

defn-imp-ocaml: $(imp_ocaml_defn)
defn-imp-java: $(imp_java_defn)
defn-fun-ocaml: $(fun_ocaml_defn)
defn-fun-java: $(fun_java_defn)

$(imp_ocaml_dir)/%.k: %.md $(pandoc_tangle_submodule)/make.timestamp
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to markdown --lua-filter=$(tangler) --metadata=code:$(krun_tangler) $< > $@

$(imp_java_dir)/%.k: %.md $(pandoc_tangle_submodule)/make.timestamp
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to markdown --lua-filter=$(tangler) --metadata=code:$(kcompile_tangler) $< > $@

$(fun_ocaml_dir)/%.k: %.md $(pandoc_tangle_submodule)/make.timestamp
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to markdown --lua-filter=$(tangler) --metadata=code:$(krun_tangler) $< > $@

$(fun_java_dir)/%.k: %.md $(pandoc_tangle_submodule)/make.timestamp
	@echo "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to markdown --lua-filter=$(tangler) --metadata=code:$(kcompile_tangler) $< > $@

# Build definitions

build: build-imp build-fun
build-imp: build-imp-ocaml build-imp-java
build-fun: build-fun-ocaml build-fun-java

build-imp-ocaml: $(imp_ocaml_kompiled)
build-imp-java: $(imp_java_kompiled)
build-fun-ocaml: $(fun_ocaml_kompiled)
build-fun-java: $(fun_java_kompiled)

$(imp_ocaml_kompiled): $(imp_ocaml_defn)
	@echo "== kompile: $@"
	eval $$(opam config env)                              \
	    $(k_bin)/kompile -O3 --non-strict --backend ocaml \
	    --directory $(imp_ocaml_dir) -I $(imp_ocaml_dir)  \
	    --main-module IMP --syntax-module IMP $<

$(imp_java_kompiled): $(imp_java_defn)
	@echo "== kompile: $@"
	$(k_bin)/kompile --backend java                                \
	    --directory $(imp_java_dir) -I $(imp_java_dir)             \
	    --main-module IMP-ANALYSIS --syntax-module IMP-ANALYSIS $<

$(fun_ocaml_kompiled): $(fun_ocaml_defn)
	@echo "== kompile: $@"
	eval $$(opam config env)                                     \
	    $(k_bin)/kompile -O3 --non-strict --backend ocaml        \
	    --directory $(fun_ocaml_dir) -I $(fun_ocaml_dir)         \
	    --main-module FUN-UNTYPED --syntax-module FUN-UNTYPED $<

$(fun_java_kompiled): $(fun_java_defn)
	@echo "== kompile: $@"
	$(k_bin)/kompile --backend java                                \
	    --directory $(fun_java_dir) -I $(fun_java_dir)             \
	    --main-module FUN-ANALYSIS --syntax-module FUN-ANALYSIS $<

# Testing
# -------

test_dir:=tests
test_imp_files:=$(wildcard $(test_dir)/imp/*.strat)
test_fun_files:=$(wildcard $(test_dir)/fun/*.strat)

TEST=./kat test

test: test-imp test-fun
test-imp: $(test_imp_files:=.test)
test-fun: $(test_fun_files:=.test)

%.strat.test:
	$(TEST) $*
