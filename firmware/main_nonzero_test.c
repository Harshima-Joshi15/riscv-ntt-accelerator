
#include <stdint.h>
#include "test_vectors.h"

#define Q              3329u
#define NTT_BASE       0x10000000u

#define REG_START      (*(volatile uint32_t *)(NTT_BASE + 0x000))
#define REG_STATUS     (*(volatile uint32_t *)(NTT_BASE + 0x004))
#define REG_INPUT(i)   (*(volatile uint32_t *)(NTT_BASE + 0x100 + 4u*(i)))
#define REG_OUTPUT(i)  (*(volatile uint32_t *)(NTT_BASE + 0x500 + 4u*(i)))

#define RESULT         (*(volatile uint32_t *)0x00001000u)
#define MISMATCH_INDEX (*(volatile uint32_t *)0x00001004u)
#define DONE_FLAG      (*(volatile uint32_t *)0x00001008u)

int main(void)
{
    uint32_t i;
    uint32_t pass = 1;
    uint32_t mismatch_index = 0xFFFFFFFFu;

    /* Initialize result memory */
    RESULT = 0;
    MISMATCH_INDEX = 0xFFFFFFFFu;
    DONE_FLAG = 0;

    /* Wait until accelerator BRAM initialization completes */
    while ((REG_STATUS & 4u) == 0u) {
    }

    /* Load deterministic nonzero input coefficients */
    for (i = 0; i < 256; i++) {
        uint32_t value = i * 37u + 123u;

        if (value >= Q) value -= Q;
        if (value >= Q) value -= Q;

        REG_INPUT(i) = value;
    }

    /* Start NTT accelerator */
    REG_START = 1;

    /* Wait until accelerator reports completion */
    while ((REG_STATUS & 2u) == 0u) {
    }

    /* Compare all 256 hardware outputs with golden reference */
    for (i = 0; i < 256; i++) {
        if (REG_OUTPUT(i) != expected_ntt[i]) {
            pass = 0;
            mismatch_index = i;
            break;
        }
    }

    /* Report results to the testbench */
    MISMATCH_INDEX = mismatch_index;
    RESULT = pass;
    DONE_FLAG = 1;

    /* Stop firmware */
    while (1) {
    }

    return 0;
}
