CODEDIRS=./src/grammar ./src/grammar/rolls
INCDIRS=./src/grammar

CC=cc
OPT=-O3 -std=c99 -Wall -Wextra -Werror -pedantic -Wcast-align \
	-Wcast-qual -Wdisabled-optimization -Winit-self \
	-Wmissing-declarations -Wmissing-include-dirs \
	-Wredundant-decls -Wshadow -Wsign-conversion \
	-Wundef -Wno-unused -Wformat=2 \
        -ffast-math


USE_SECURE_RANDOM=0
ifeq ($(USE_SECURE_RANDOM), 1) 
# @echo "Using Fast, but Cryptographically insecure random fn"
ARC4RANDOM:=-lbsd `pkg-config --libs libbsd`
else 
# @echo "Using Cryptographically Secure, but slow random fn"
ARC4RANDOM:=
endif

# YACC/LEX fails for the following, so disabled:
# -Wswitch-default  -Wstrict-overflow=5

# EMCC fails for the following, so disabled:
# -Wlogical-op

# add flags and the include paths
DEFS=-DUSE_SECURE_RANDOM=${USE_SECURE_RANDOM}

CFLAGS=$(foreach D,$(INCDIRS),-I$(D)) $(OPT) $(DEFS)

# add flags to build for shared library and add include paths
SHAREDCFLAGS=-fPIC -c $(foreach D,$(INCDIRS),-I$(D)) $(ARC4RANDOM) $(DEFS)

# generate list of c files and remove y.tab.c from src/grammar directory
CFILES=$(foreach D,$(CODEDIRS),$(wildcard $(D)/*.c)) build/lex.yy.c build/y.tab.c
CFILES:=$(filter-out ./src/grammar/y.tab.c, $(CFILES))

# list out object files from the above c files. Replace their path with build/
OBJECTS=$(addprefix build/,$(notdir $(patsubst %.c,%.o,$(CFILES))))


all: clean yacc lex compile shared
	echo "== Build Complete =="

yacc:
	mkdir -p build
	bison -d src/grammar/dice.yacc --debug --verbose | true 
        cat y.output
	mv y.tab.c build/y.tab.c
	mv y.tab.h build/y.tab.h
	mv y.output build/y.output | true	# Only present with verbose
lex:
	flex src/grammar/dice.lex
	mv lex.yy.c build/lex.yy.c

# Executable
compile:
	$(CC) $(CFLAGS) $(CFILES) $(ARC4RANDOM)

# Shared Lib
shared: $(OBJECTS)
	$(CC) -shared -o build/dice.so $^ $(ARC4RANDOM)

# Linux
	mv ./a.out build/dice | true
# Windows
	mv ./a.exe build/dice | true

# hardcode for y.tab.o
build/y.tab.o: 
	$(CC) $(SHAREDCFLAGS) -c build/y.tab.c -o $@

build/lex.yy.o:
	$(CC) $(SHAREDCFLAGS) -c build/lex.yy.c -o $@  

# for /grammar/rolls hardcode
build/condition_checking.o:
	$(CC) $(SHAREDCFLAGS) -c src/grammar/rolls/condition_checking.c -o $@

# for /grammar/rolls hardcode
build/sided_dice.o:
	$(CC) $(SHAREDCFLAGS) -c src/grammar/rolls/sided_dice.c -o $@

# for rest, wildcard
build/%.o:src/grammar/%.c
	$(CC) $(SHAREDCFLAGS) -c -o $@ $^

test_no_pip : python
	python3 -m pytest tests/python/ -xs

test : pip
	python3 -m pytest tests/python/ -xs

include src/python/target.mk
include src/js/target.mk
include src/go/target.mk
include src/perl/target.mk
include src/swig/target.mk

clean: perl_clean python_clean clean_js
	rm -rf build
	rm src/grammar/test_dice.yacc | true
