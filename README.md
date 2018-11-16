# FpChip8
![main](https://user-images.githubusercontent.com/12776674/48627579-0dc53c80-e99c-11e8-8dc6-31e29ab74202.jpg)

FpChip8 is a FPGA implementation of the CHIP-8 with VHDL.
It provides full support of the chip and includes 34 games which can be played using a keypad or on the board directly.

Originally implemented on Altera DE1 Board, FpChip8 can be easily ported into other boards or FPGA systems without extra work.
All files are well documented and outlined for the easy understanding and portability, made considering the graphical RTL
visualization since the beginning.

![screen](https://user-images.githubusercontent.com/12776674/48627914-005c8200-e99d-11e8-9be7-c6c0bee9ce8c.jpg)

This implementation uses buzzer outputting audio at 250 Hz square wave, uses a 4x4 keypad for controlling the 16 CHIP-8 buttons,
the four press keys for picking which game to play, reeset/load and changing screen color. Output is VGA at 640x480, but the
internal CHIP-8 resolution is 64x32 and a VGA scaler is used for that. It also means that CHIP-8 video output can be easily
adapted to HDMI or other video output method, including LED matrixes.

If you're getting started with FPGAs and VHDL, CHIP-8 is definitely a good guide for doing your first full project!

A video with some gameplay is available at https://youtu.be/cncZqL_IjYM
