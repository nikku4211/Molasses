# made by Nikku4211 in 2024
title = MolassesProto
version = 0.01

# Compiler
CC = gcc
WIND = windres

# Include and Library paths
# INCS = -IC:\MinGW_SDL\include\SDL2
# LIBS = -LC:\MinGW_SDL\lib

# Compiler and Linker Flags
CFLAGS = -std=c99 -Wall -v
LFLAGS = -lgdi32
# -lSDL2main -lSDL2
WFLAGS =

# Source files
SOURCES := src
SRC_C := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))

# Windres files
WRES := rcs
RC_C := $(foreach dir,$(WRES),$(notdir $(wildcard $(dir)/*.rc)))

# Resource files
RESOURCES := res

# Object files
OBJECTS := obj
OBJ_C := $(SRC_C:%.c=$(OBJECTS)/%.o) $(RC_C:%.rc=$(OBJECTS)/%.o)

# C Executables and source files mapping
BUILD = $(title).exe

# Targets
all: clean $(BUILD)

# Rule to clean up object files and executables
clean:
	rm -f $(OBJ_C) $(BUILD)
	
# Rule to clean up executables
clean_build:
	rm -f $(BUILD)

# Generic rule to compile .c files into .o files
$(OBJECTS)/%.o: $(SOURCES)/%.c
	$(CC) $(CFLAGS) -c $< -o $@
	
$(OBJECTS)/%.o: $(WRES)/%.rc
	$(WIND) $< $(WFLAGS) $@

# Rule to build each executable
$(BUILD): $(OBJ_C)
	$(CC) $^ $(CFLAGS) $(LFLAGS) -o $@