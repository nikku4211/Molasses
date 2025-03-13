# Name
name		:= Molasses
debug		:= 2

# C compiler for tools
CC = gcc

sourcedir := src
resdir := data
src := $(wildcard $(sourcedir)/%.s)
tools := tools
objs := obj

PY := python

# If you use Linux, replace this with the Linux executeable.
SNESMOD := $(tools)/smconv.exe

derived_files := $(sourcedir)/sinlut.i $(sourcedir)/idlut.i \
	$(resdir)/chunktestpalette.png.tiles $(resdir)/chunktestpalette.png.palette \
	$(resdir)/game_music $(sourcedir)/models.i

$(resdir)/chunktestpalette.png.palette: palette_flags = -v --colors 256 -R
$(resdir)/chunktestpalette.png.tiles: tiles_flags = -v -B 8 -M snes_mode7 -D -F -R -p $(resdir)/chunktestpalette.png.palette

#$(resdir)/chunktest.png.pbm: map_flags = -v -M snes_mode7 -p $(resdir)/chunktestpalette.png.palette \
#	-t $(resdir)/chunktestpalette.png.tiles

# Include libSFX.make
libsfx_dir	:= ../libSFX
include $(libsfx_dir)/libSFX.make

run_args := $(rom)

itlisto := $(foreach dir,$(resdir),$(wildcard $(dir)/*.it))

# Alternate derived files filter
$(filter %.pbm,$(derived_files)) : %.pbm : %
	$(superfamiconv) map $(map_flags) --in-image $* --out-data $@
	
$(resdir)/game_music: $(itlisto)
	$(SNESMOD) -v -s $(itlisto) -h -o $@

# Replace .exe with whatever executable format your OS uses
$(sourcedir)/sinlut.i: $(tools)/sinlutgen.exe
	$< $@
	
$(tools)/sinlutgen.exe: $(tools)/sinlutgen.c
	$(CC) -o $@ $<

$(sourcedir)/divlut.i: $(tools)/divlutgen.exe
	$< $@
	
$(tools)/divlutgen.exe: $(tools)/divlutgen.c
	$(CC) -o $@ $<
	
$(sourcedir)/idlut.i: $(tools)/idlutgen.exe
	$< $@
	
$(tools)/idlutgen.exe: $(tools)/idlutgen.c
	$(CC) -o $@ $<
	
$(sourcedir)/models.i: $(objs)/CubeGuy.obj
	$(PY) $(tools)/wavefront2mol.py $< $@ cube 2
	
.PHONY: romused

romused: $(rom)
	$(PY) $(tools)/romusage.py $<