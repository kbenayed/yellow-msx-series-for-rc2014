#ifndef __ARGUMENTS
#define __ARGUMENTS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern const char *pFossilBaudRates[12];
#define fossil_rate_to_string(f) pFossilBaudRates[f & 0xF]

void process_cli_arguments(const int argc, const char **argv);

#endif
