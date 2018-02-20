# Settings

build_dir:=.build
defn_dir:=$(build_dir)/defn

.PHONY: build deps ocaml-deps defn

all: build

clean:
	rm -rf $(build_dir)

# Tangle from *.md files
# ----------------------

# Tangle *.k files

k_files:=imp-kat.k imp.k kat.k
defn_files:=$(patsubst %, $(defn_dir)/%, $(k_files))

defn: $(defn_files)

$(defn_dir)/kat.k: KAT.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to tangle.lua --metadata=code:kat $< > $@

$(defn_dir)/imp-kat.k: KAT-IMP.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to tangle.lua --metadata=code:imp-kat $< > $@

$(defn_dir)/imp.k: KAT-IMP.md
	@echo >&2 "==  tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to tangle.lua --metadata=code:imp-lang $< > $@

# Build interpreters
# ------------------

# Dependencies

k_submodule:=$(build_dir)/k
k_bin:=$(k_submodule)/k-distribution/target/release/k/bin

deps: $(k_submodule)/make.timestamp ocaml-deps

$(k_submodule)/make.timestamp:
	git submodule update --init -- $(k_submodule)
	cd $(k_submodule) \
		&& mvn package -q -DskipTests
	touch $(k_submodule)/make.timestamp

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
    # kompile --debug --main-module IMP-ANALYSIS --syntax-module IMP-ANALYSIS imp-kat.k || exit 1

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
