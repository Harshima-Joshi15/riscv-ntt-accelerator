
#include <stdint.h>
#include "test_vectors_near_modulus.h"
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
    uint32_t offset = 0;
    uint32_t pass = 1;
    uint32_t mismatch_index = 0xFFFFFFFFu;

    RESULT = 0;
    MISMATCH_INDEX = 0xFFFFFFFFu;
    DONE_FLAG = 0;

    /* Near-modulus input: 3328, 3327, 3326, 3325, 3324 */
    for (i = 0; i < 256; i++) {
        REG_INPUT(i) = 3328u - offset;

        offset++;
        if (offset == 5u) {
            offset = 0;
        }
    }

    REG_START = 1;

    while ((REG_STATUS & 2u) == 0u) {
    }

    for (i = 0; i < 256; i++) {
        if (REG_OUTPUT(i) != expected_ntt[i]) {
            pass = 0;
            mismatch_index = i;
            break;
        }
    }

    MISMATCH_INDEX = mismatch_index;
    RESULT = pass;
    DONE_FLAG = 1;

    while (1) {
    }

    return 0;
}
