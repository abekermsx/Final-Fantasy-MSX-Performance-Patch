# Final Fantasy MSX Performance Patch
## About
Improves the performance of Final Fantasy MSX by removing the framerate limiter and replacing some routines with optimized code.

This patch was tested with a diskimage of the game with CRC32 checksum `4CFD3A9E`, it will probably work with other versions as well. It's also compatible with `Final Fantasy MSX2: English Translation`!

## Patching
There are three methods to patch the game.

### Patching the original game using IPS
The easiest way to patch the original game disk is using the supplied IPS file. The patch can be applied with any patcher that supports the IPS file format, e.g. `Lunar Patcher`.

### Patching the original game by assembling code
The original game disk can also be patched by assembling the file `ffmsxpp-disk.asm` using the assembler `sjasmplus`.
It requires a diskimage with the name `ff.dsk` in the `data` directory and a directory `out`.
The diskimage can then be patched with the command `sjasmplus.exe --syntax=Fa --longptr ffmsxpp-disk.asm`. This will generate a diskimage `ffmsxpp.dsk` in the `out` directory.

### Patching individual files
If you used the tool `Final Fantasy MSX2: Say DOS Tool` to dump files from the original game disk it's possible to patch the individual files.
It requires a directory `data` with in it all the files dumped with the `Final Fantasy MSX2: Say DOS Tool` and a directory `out`. 
The files can then be patched with the command `sjasmplus.exe --syntax=Fa --longptr ffmsxpp-files.asm`. The following files will be patched:
```
data/files/sectors/0002.bin
data/files/sectors/0003.bin
data/files/files/BATTLE.COM
data/files/files/MAIN.COM
data/files/files/SMAP.COM
data/files/files/STARTUP.COM
```
The patched files will be outputted the `out` directory. Overwrite the original files and use the `Final Fantasy MSX2: Say DOS Tool` to generate a new diskimage.

## Links
- `Final Fantasy MSX2: English Translation` : https://github.com/romh-acking/final-fantasy-msx2-en
- `Final Fantasy MSX2: Say DOS Tool` : https://github.com/romh-acking/final-fantasy-msx2-say-dos-tool
- `Final Fantasy MSX2: (De)Compressor Tool` : https://github.com/romh-acking/final-fantasy-msx2-de-compressor
- `Lunar Patcher` : https://www.romhacking.net/utilities/240/
- `sjasmplus` : https://github.com/z00m128/sjasmplus
