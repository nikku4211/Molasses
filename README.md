# Molasses
 A 3D renderer for the SNES' S-CPU.

## Dependencies
- [LibSFX](https://github.com/Optiroc/libSFX)
- [Python](https://www.python.org/)
 - [Pillow](https://pypi.org/project/pillow/) is a requirement for `romusage.py`
  - If you're on MSYS2, install `mingw-w64-python-pillow` and run the MinGW-W64 MSYS2 console.
- [GCC](https://gcc.gnu.org/)
 - Binary builds for Windows x64 are provided, but if you use Linux and you don't feel like compiling the C code of the LUT generators, [Wine](https://www.winehq.org/) is recommended.
- [SNESMOD](https://github.com/mukunda-/snesmod/tree/main/smconv)
 - Again, a binary build for SMConv for Windows x64 is provided, but if you are on Linux and don't want to compile Go code, use Wine to run the provided .exe.

## Building
For Windows users, [MSYS2](https://www.msys2.org/) is recommended to build the game.

Build LibSFX somewhere and change the path `libsfx_dir` in the `makefile` points to where your build of LibSFX is.

LibSFX is a SNES library with plenty of macros I personally find useful, and it even includes useful tools.
The LibSFX tools used by this project include:
- SuperFamiConv
- SuperFamiCheck

LibSFX also comes with CA65, which is a popular assembler for homebrew on multiple 65xx-based consoles, including the SNES.
This project uses it.

- If you're on MSYS2, install the `mingw-w64-x86_64-python` and `gcc` packages.

- If you're on Linux, build SNESMOD, then replace the path `SNESMOD` points to in the `makefile` to the path your build of SNESMOD SMConv is and replace `smconv.exe` with the Linux executeable. Also replace the `.exe` in the filenames of the LUT generators in the `makefile` with whatever executeable format your OS uses.

After all that, just run `make` in the command line. If you see some alignment warnings, that's normal, and the game will still build.

## Licence
This code is under the Boost Software Licence 1.0, a permissive licence.

Music is copyrighted by Nikku4211. Test image contains a photo of and taken by LGR.