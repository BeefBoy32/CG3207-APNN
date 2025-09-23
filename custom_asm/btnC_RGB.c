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

    // Colors (24-bit RGB)
    unsigned int red   = 0x00FF00;
    unsigned int green = 0x0000FF;
    unsigned int blue  = 0xFF0000;

    unsigned int color = red; // start with Red

    // Turn on OLED in 24-bit mode
    *OLED_CTRL_ADDR = 0x21;

    // Draw initial Red screen
    for (int y = 0; y < 64; y++) 
    {
        *OLED_ROW_ADDR = y;
        for (int x = 0; x < 96; x++) 
        {
            *OLED_COL_ADDR = x;
            *OLED_DATA_ADDR = color;
        }
    }

    while (1) 
    {
        // Poll center button (bit1 of PB)
        if ((*PB_ADDR & 0x2) != 0) 
        {
            // Cycle to next color using if-else
            if (color == red)
                color = green;
            else if (color == green)
                color = blue;
            else
                color = red;

            // Fill screen with new color
            for (int y = 0; y < 64; y++) 
            {
                *OLED_ROW_ADDR = y;
                for (int x = 0; x < 96; x++) 
                {
                    *OLED_COL_ADDR = x;
                    *OLED_DATA_ADDR = color;
                }
            }

            // Simple debounce: wait until button released
            while ((*PB_ADDR & 0x2) != 0);
        }
    }

    return 0;
}
