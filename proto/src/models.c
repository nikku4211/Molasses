#include <windows.h>
#include <windowsx.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <malloc.h>

#include "models.h"

const threedmodel cube = {
	{
		0x0200, 0x0200, 0x0400, 0x0400,
		0x0200, 0x0400, 0x0400, 0x0200
	},
	{
		0x0200, 0x0400, 0x0200, 0x0400,
		0x0400, 0x0200, 0x0400, 0x0200
	},
	{
		0x0200, 0x0200, 0x0200, 0x0200,
		0x0400, 0x0400, 0x0400, 0x0400
	},
	{
		0,0,1,2,
		3,3,4,6,
		7,5,4,2
	},
	{
		1,2,2,3,
		6,4,7,7,
		5,1,1,6
	}
};