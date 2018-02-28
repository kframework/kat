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

.PHONY: build deps ocaml-deps defn example-files

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
	opam install --yes mlgmp zarith uuidm

# OCAML Backend

build: $(defn_dir)/imp-kat-kompiled/interpreter deps

$(defn_dir)/imp-kat-kompiled/interpreter: $(defn_files)
	@echo "== kompile: $@"
	eval $$(opam config env) \
	$(k_bin)/kompile --debug --gen-ml-only -O3 --non-strict \
					 --main-module IMP-ANALYSIS --syntax-module IMP-ANALYSIS $< --directory $(defn_dir) ; \
	ocamlfind opt -c $(defn_dir)/imp-kat-kompiled/constants.ml -package gmp -package zarith ; \
	ocamlfind opt -c -I $(defn_dir)/imp-kat-kompiled ; \
	ocamlfind opt -a -o $(defn_dir)/semantics.cmxa ; \
	ocamlfind remove imp-kat-semantics-plugin ; \
	ocamlfind install imp-kat-semantics-plugin META $(defn_dir)/semantics.cmxa $(defn_dir)/semantics.a ; \
	$(k_bin)/kompile --debug --packages imp-kat-semantics-plugin -O3 --non-strict \
					 --main-module IMP-ANALYSIS --syntax-module IMP-ANALYSIS $< --directory $(defn_dir) ; \
	cd $(defn_dir)/imp-kat-kompiled \
		&& ocamlfind opt -o interpreter \
			-package gmp -package dynlink -package zarith -package str -package uuidm -package unix -package imp-kat-semantics-plugin \
			-linkpkg -inline 20 -nodynlink -O3 -linkall \
			constants.cmx prelude.cmx plugin.cmx parser.cmx lexer.cmx run.cmx interpreter.ml

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
