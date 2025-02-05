#include "gps_dispatcher_driver.h"

void get_acquisition_result(uint32_t *doppler_shift, uint32_t *code_delay, uint32_t *correlation_result) {
    for (int i = 0;i < 32; i++) {
        correlation_result[i] = AXIL->CORRELATION_BRAM[i];
        code_delay[i] = AXIL->CODE_DELAY_BRAM[i];
        doppler_shift[i] = AXIL->DOPPLER_BRAM[i];
    }
}

void set_tracker(uint32_t prn_id, uint32_t doppler_shift, uint32_t code_delay, uint32_t tracker_id) {
    if (tracker_id < 5) {
        AXIL->PRN_0_4 &= ~(0x3F << (tracker_id * 6));       // clear bits 
        AXIL->PRN_0_4 |= (prn_id << (tracker_id * 6));      // write prn_id
    } else {
        AXIL->PRN_5_7 &= ~(0x3F << ((tracker_id - 5) * 6)); // clear bits
        AXIL->PRN_5_7 |= (prn_id << ((tracker_id - 5) * 6));// write prn_id
    }

    // write doppler_shift
    AXIL->DOPPLER_TRACKER[tracker_id] = doppler_shift;

    // write code_delay
    AXIL->CODE_DELAY_TRACKER[tracker_id] = code_delay;
}

int get_lock_status(uint32_t tracker_id) {
    uint32_t status = AXIL->CTRL_CFG;
    return (status >> (tracker_id + 1)) & 0x1;
}

void get_dll(uint32_t *curr_dll) {
    *curr_dll = AXIL->DLL_RAW;
}