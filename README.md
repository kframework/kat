K Analysis Toolset
==================

This repository uses the K Strategy Language to build a suite of tools for program analysis.

Installing/Building
-------------------

### System Dependencies

The following are needed for building/running KAT:

-   [Pandoc >= 1.17](https://pandoc.org) is used to generate the `*.k` files from the `*.md` files.
-   GNU [Bison](https://www.gnu.org/software/bison/), [Flex](https://github.com/westes/flex), and [Autoconf](http://www.gnu.org/software/autoconf/).
-   GNU [libmpfr](http://www.mpfr.org/) and [libtool](https://www.gnu.org/software/libtool/).
-   Java 8 JDK (eg. [OpenJDK](http://openjdk.java.net/))
-   [Opam](https://opam.ocaml.org/doc/Install.html), **important**: Ubuntu users prior to 15.04 **must** build from source, as the Ubuntu install for 14.10 and prior is broken.
    `opam repository` also requires `rsync`.
-   [Z3](https://github.com/Z3Prover/z3) automated first-order theorem prover.

On Ubuntu >= 15.04 (for example):

```sh
sudo apt-get install make gcc maven openjdk-8-jdk flex opam pkg-config libmpfr-dev autoconf libtool pandoc zlib1g-dev z3 libz3-dev
```

On ArchLinux:

```sh
sudo pacman -S  base-devel rsync opam pandoc jre8-openjdk mpfr maven z3
```

On OSX, using [Homebrew](https://brew.sh/), after installing the command line tools package:

```sh
brew tap caskroom/cask caskroom/version
brew cask install java8
brew install automake libtool gmp mpfr pkg-config pandoc maven opam z3
```

### Installing/Building

After installing the above dependencies, the following command will build submodule dependencies and then KEVM:

```sh
make deps
make build
```

This Repository
---------------

-   [kat.md] defines the strategy language used, as well as the analysis algorithms implemented in that language.
-   [imp.md] defines the IMP language (modified to work well with stratagies).
-   [kat-imp.md] hooks KAT up to IMP, providing the needed definitions.
