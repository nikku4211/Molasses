// Stupid identity lut generator
#include <stdio.h>

#define ID_SIZE 256

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

    fprintf(fp, ";\n; Identity lut; %d entries, all ints\n;\n\n", 
        ID_SIZE);
    fprintf(fp, ".segment \"ABS0DATA\"\n.align $100\nidlut:\n");
    for(ii=0; ii<ID_SIZE; ii++)
    {
        hw=ii;
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