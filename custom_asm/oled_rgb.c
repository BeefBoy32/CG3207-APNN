#define MMIO_BASE       0xFFFFF0000

// OLED registers
#define OLED_COL_OFF    0x20 // WO
#define OLED_ROW_OFF    0x24 // WO
#define OLED_DATA_OFF   0x28 // WO
#define OLED_CTRL_OFF   0x2C // WO

// Pushbutton register
#define PB_BASE         0xFFFF0068  // RO

int main() 
{
    volatile unsigned int* OLED_ROW_ADDR  = (unsigned int*) (MMIO_BASE + OLED_ROW_OFF);
    volatile unsigned int* OLED_COL_ADDR  = (unsigned int*) (MMIO_BASE + OLED_COL_OFF);
    volatile unsigned int* OLED_DATA_ADDR = (unsigned int*) (MMIO_BASE + OLED_DATA_OFF);
    volatile unsigned int* OLED_CTRL_ADDR = (unsigned int*) (MMIO_BASE + OLED_CTRL_OFF);

    volatile unsigned int* PB_ADDR        = (unsigned int*) (PB_BASE);

    unsigned char r = 0xFF;
    unsigned char g = 0x00;
    unsigned char b = 0x00;

    // 0 = R, 1 = G, 2 = B
    int selected_channel = 0; 

    // Step size
    unsigned char step = 0x10; // increment/decrement by 16

    // Turn on OLED in 24-bit mode
    *OLED_CTRL_ADDR = 0x21;

    while (1) 
    {
        unsigned int color = (r << 16) | (g << 8) | b;

        // Fill screen with current color
        for (int y = 0; y < 64; y++) 
        {
            *OLED_ROW_ADDR = y;
            for (int x = 0; x < 96; x++) 
            {
                *OLED_COL_ADDR = x;
                *OLED_DATA_ADDR = color;
            }
        }

        unsigned int pb = *PB_ADDR & 0x7; // only bits [2:0]

        // Center button toggles channel
        if ((pb & 0x2) == 0x2) 
        {
            if (selected_channel == 0)
                selected_channel = 1;
            else if (selected_channel == 1)
                selected_channel = 2;
            else if (selected_channel == 2)
                selected_channel = 0;

            // Wait until release (debounce)
            while ((*PB_ADDR & 0x2) == 0x2);
        }

        // Left button increases value
        if ((pb & 0x1) == 0x1) 
        {
            if (selected_channel == 0 && r != 0xFF) 
            {
                r = r + step;
                if (r == 0x00) r = 0xFF; // wrap-around prevention
            }
            else if (selected_channel == 1 && g != 0xFF) 
            {
                g = g + step;
                if (g == 0x00) g = 0xFF;
            }
            else if (selected_channel == 2 && b != 0xFF) 
            {
                b = b + step;
                if (b == 0x00) b = 0xFF;
            }
            while ((*PB_ADDR & 0x1) == 0x1);
        }

        // Right button decreases value
        if ((pb & 0x4) == 0x4) 
        {
            if (selected_channel == 0 && r != 0x00) 
            {
                r = r - step;
                if (r == 0xFF) r = 0x00; // wrap-around prevention
            }
            else if (selected_channel == 1 && g != 0x00) 
            {
                g = g - step;
                if (g == 0xFF) g = 0x00;
            }
            else if (selected_channel == 2 && b != 0x00) 
            {
                b = b - step;
                if (b == 0xFF) b = 0x00;
            }
            while ((*PB_ADDR & 0x4) == 0x4);
        }
    }

    return 0;
}
