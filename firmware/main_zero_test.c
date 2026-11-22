#include <stdint.h>

#define NTT_BASE       0x10000000u
#define REG_START      (*(volatile uint32_t *)(NTT_BASE + 0x000))
#define REG_STATUS     (*(volatile uint32_t *)(NTT_BASE + 0x004))
#define REG_INPUT(i)   (*(volatile uint32_t *)(NTT_BASE + 0x100 + 4u*(i)))
#define REG_OUTPUT(i)  (*(volatile uint32_t *)(NTT_BASE + 0x500 + 4u*(i)))

#define RESULT         (*(volatile uint32_t *)0x00001000u)

int main(void)
{
    uint32_t i;
    uint32_t pass = 1;

    for (i = 0; i < 256; i++)
        REG_INPUT(i) = 0;

    REG_START = 1;

    while ((REG_STATUS & 1u) != 0u) {
        /* Wait while accelerator is busy. */
    }

    while ((REG_STATUS & 2u) == 0u) {
        /* Wait until completion is recorded. */
    }

    for (i = 0; i < 256; i++) {
        if (REG_OUTPUT(i) != 0)
            pass = 0;
    }

    RESULT = pass;

    while (1) {
        /* Stop here for testbench inspection. */
    }

    return 0;
}
