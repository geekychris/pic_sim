# Build a PIC18F452 image with MPLAB XC8.
# Override the compiler location with: make XC8_DIR=/Applications/microchip/xc8/v3.10

XC8_DIR ?= $(lastword $(sort $(wildcard /Applications/microchip/xc8/v*)))
CC      := $(XC8_DIR)/bin/xc8-cc
DEVICE  := 18F452

# XC8 v3+ takes device definitions from a Device Family Pack (DFP)
DFP_DIR ?= $(lastword $(sort $(wildcard $(HOME)/.mchp_packs/Microchip/PIC18Fxxxx_DFP/*)))/xc8

TARGET  := build/pic_sim
SRCS    := $(wildcard src/*.c)

CFLAGS  := -mcpu=$(DEVICE) -mdfp="$(DFP_DIR)" -O0 -gdwarf-3 -std=c99 -Wall \
           -mwarn=-3 -msummary=-psect,-class,+mem,-hex,-file

.PHONY: all clean info

all: $(TARGET).elf

$(TARGET).elf: $(SRCS) | build
	"$(CC)" $(CFLAGS) -o $@ $(SRCS)

build:
	mkdir -p build

clean:
	rm -rf build

info:
	@echo "XC8_DIR = $(XC8_DIR)"
	@echo "DFP_DIR = $(DFP_DIR)"
	@"$(CC)" --version
