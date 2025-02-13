#pragma once

#define EXTRA_DATA_OFFSET       0

#define MENU_ABOUT              1
#define MENU_NEWGAME             2
#define MENU_SETTINGS						3
#define MENU_QUIT								4
#define MENU_SCALE_BASE	5
#define MENU_SCALE_2X	MENU_SCALE_BASE+1
#define MENU_SCALE_3X	MENU_SCALE_BASE+2
#define MENU_SCALE_4X	MENU_SCALE_BASE+3

#define MENU_FULLSCREEN	9

#define GenericMenu		101
#define GenericIcon		201

#define game_name "MolassesProto"

#define game_res_width 128
#define game_res_height 56
#define game_bpp 32
#define game_drawing_area_mem_size ((game_res_height+64) * game_res_width * (game_bpp / 8))

typedef struct game_bitmap {
	BITMAPINFO bitmap_info;
	void* memory;
} game_bitmap;

typedef struct pixel32 {
	unsigned char blue;
	unsigned char green;
	unsigned char red;
	unsigned char alpha;
} pixel32;

typedef struct performance_data {
	unsigned int total_frames_rendered;
	float raw_fps_average;
	float cooked_fps_average;
	LARGE_INTEGER perf_freq;
	BOOL display_debug;
} performance_data;

#define calculate_avg_fps_after_x_frames 60

#define pix_to_subpix(n) ((n) << 8)
#define subpix_to_pix(n) ((n) >> 8)

#define M_PI 3.1415926535f
#define SIN_SIZE 128
#define SIN_FP 7

typedef struct threedPoint {
	short x;
	short y;
	short z;
} threedPoint;

typedef struct twodPoint {
	unsigned short x;
	unsigned short y;
} twodPoint;

typedef struct threedmodel {
	short x[8];
	short y[8];
	short z[8];
	unsigned char edge1[12];
	unsigned char edge2[12];
} threedmodel;

BOOL WINAPI WinAbout( HWND window_handle, UINT msg, WPARAM wparam, LPARAM lparam );

void initTrig();

void initThreed();

void threedStuff();

void playerInput();

void frameGraphics();