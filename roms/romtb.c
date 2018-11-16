/* CHIP-8 ROM Master Table Builder v1.0
 * by Vitor Vilela
 *
 * This simple tool takes a list of CHIP-8 ROMs and builds the main table for
 * inserting as FPGA ROM VHDL code for loading games without having to use a SD card.
 *
 * Currently it can support up to 64 ROMs, however total size should not exceed
 * destination FPGA internal RAM size.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int write_input(const char* file, unsigned char* array) {
    FILE* fp;

    fp = fopen(file, "rb");

    if (!fp) {
        printf("Error while opening file.\n");
        return -1;
    }

    int byte;
    int counter = 0;
    int size;

    // Get file size...
    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    if (size > 4096 - 512) {
        printf("ROM is too large to fit on CHIP-8 RAM.\n");
    }

    while ((byte = fgetc(fp)) != EOF) {
        *array++ = byte;
    }

    if (ferror(fp)) {
        printf("Unexpected I/O error at position %d\n", counter);
        return -1;
    }

    fclose(fp);

    return size;
}

void write_vhd(FILE* wr, int size, unsigned char* p) {
    int counter = 0;

    fprintf(wr, "\tsignal program : rom_t(0 to %d) := (\n\t\t", size-1);

    while (size > 0) {
        if (counter != 0) {
            fprintf(wr, ",");

            if (counter % 16 == 0) {
                fprintf(wr, "\n\t\t");
            } else {
                fprintf(wr, " ");
            }
        }

        fprintf(wr, "x\"%.2X\"", *p++);
        counter ++;
        size --;
    }

    fprintf(wr, "\n\t);\n");
}

void write_table(FILE* wr, int size, unsigned int* p) {
    int counter = 0;

    fprintf(wr, "\tsignal table : word_t(0 to %d) := (\n\t\t", size-1);

    while (size > 0) {
        if (counter != 0) {
            fprintf(wr, ",");

            if (counter % 8 == 0) {
                fprintf(wr, "\n\t\t");
            } else {
                fprintf(wr, " ");
            }
        }

        fprintf(wr, "x\"%.4X\"", *p++ & 0xffff);
        counter ++;
        size --;
    }

    fprintf(wr, "\n\t);\n");
    fclose(wr);
}

int main (int argc, const char* argv[]) {
    FILE *wr;

    if (argc <= 1) {
        printf("Usage: romtb <input 1> [input 2] [..]\n");
        return 0;
    }

    wr = fopen("OUT.vhd", "w");

    if (!wr) {
        printf("Error while opening output file 'OUT.vhd'.");
        return 1;
    }

    int i;
    unsigned int table[64];
    unsigned char buf[100000];
    unsigned char* p = buf;

    memset(table, -1, sizeof(table));

    for (i = 1; i < argc; i++) {
        int len = write_input(argv[i], p);

        if (len == -1) {
            printf("Errors occurred while processing '%s'.\n", argv[i]);
            return -1;
        }

        table[i-1] = (p - buf) & 0xffff;
        p += len;
    }

    write_vhd(wr, p - buf, buf);
    write_table(wr, 64, table);
    fclose(wr);

    return 0;
}
