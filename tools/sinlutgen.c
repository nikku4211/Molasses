// Example sine lut generator
#include <stdio.h>
#include <math.h>

#define M_PI 3.1415926535f
#define SIN_SIZE 128
#define SIN_FP 7

int main(int argc, char *argv[])
{
    int ii;
		FILE *fp;
		if (argc > 1)
			fp = fopen(argv[1], "w");
		else {
			printf("please specify a file\n");
			return 1;
		}
    unsigned short hw;

    fprintf(fp, ";\n; Sine lut; %d entries, %d fixeds\n;\n\n", 
        SIN_SIZE+32, SIN_FP);
    fprintf(fp, ".segment \"ABS0DATA\"\n.align $100\nsinlut:\n");
    for(ii=0; ii<SIN_SIZE+32; ii++)
    {
        hw= (unsigned short)(sin(ii*2*M_PI/SIN_SIZE)*(1<<SIN_FP));
        if(ii%8 == 0)
            fputs("\n.word ", fp);
				if (ii%8 == 7)
					fprintf(fp, "$%04X", hw);
				else
					fprintf(fp, "$%04X, ", hw);
    }
    //fputs("\n};\n", fp);

    fclose(fp);
    return 0;
}