# CHIP-8 ROMs

This folder contains all CHIP-8 ROMs builtin inside **c8_prog_rom.vhd**. If you want to add or remove ROMs from the project, use this folder and then run the romtb utility or compile.bat if you're using Windows.

Use the OUT.vhd file to update the files **c8_prog_rom.vhd** and **c8_progfull.vhd**. **c8_programmer.vhd** is also available if you want to keep only a single ROM in the project. Regardless, if you port it to a system that has SD card support, it's strongly recommended to keep the Chip-8 ROMs there since you will be saving tons of block RAM space, assuming you're using a small sized FPGA.

**NOTICE: None of the below games are owned nor made by me. Please let me know if you are one of the authors and would like to credited for you work!**