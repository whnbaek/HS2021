#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>

#define SIZE 5 // 4 -> 5

int main(int argc, char** argv)
{
  int i;

  int foo = open("/dev/mem", O_RDWR);
  int *fpga_bram = mmap(NULL, SIZE * sizeof(int), PROT_READ|PROT_WRITE, MAP_SHARED, foo, 0x40000000);
  int *fpga_ip   = mmap(NULL, sizeof(int), PROT_READ|PROT_WRITE, MAP_SHARED, foo, 0x43C00000);

  // initialize memory
  for (i = 0; i < SIZE; i++)
    *(fpga_bram + i) = (i * 2 + 1); // i * 2 -> i * 2 + 1
  for (i = SIZE; i < SIZE * 2; i++)
    *(fpga_bram + i) = 1; 

  printf("%-10s%-10s\n", "addr", "FPGA(hex)");
  for (i = 0; i < SIZE * 2; i++)
    printf("%-10d%-10X\n", i, *(fpga_bram + i));

  // run ip
  *(fpga_ip) = 0x4444; // 0x5555 -> 0x4444
  while (*fpga_ip == 0x4444); // 0x5555 -> 0x4444
  printf("%-10s%-10X\n", "fpga_ip", *fpga_ip); // newly added

  printf("%-10s%-10s\n", "addr", "FPGA(hex)");
  for (i = 0; i < SIZE * 2; i++)
    printf("%-10d%-10X\n", i, *(fpga_bram + i));

  return 0;
}

