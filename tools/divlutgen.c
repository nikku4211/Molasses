// Example division lut generator
#include <stdio.h>
#include <math.h>

#define M_PI 3.1415926535f
#define DIV_SIZE 256
#define DIV_FP 0

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
    unsigned char hw;

    fprintf(fp, ";\n; 1/x lut; %d entries, %d fixeds\n;\n\n", 
        DIV_SIZE, DIV_FP);
    fprintf(fp, ".segment \"ABS0DATA\"\n.align $100\ndivlut:\n");
    for(ii=0; ii<DIV_SIZE; ii++)
    {
				hw= (unsigned char)(ceil((float)64/ii));
        if(ii%8 == 0)
            fputs("\n.byte ", fp);
				if (ii%8 == 7)
					fprintf(fp, "$%02X", hw);
				else
					fprintf(fp, "$%02X, ", hw);
    }
    //fputs("\n};\n", fp);

    fclose(fp);
    return 0;
}