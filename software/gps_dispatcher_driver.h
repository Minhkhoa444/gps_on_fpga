#ifndef AXI_LITE_H
#define AXI_LITE_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>
typedef struct __attribute__((packed, aligned(4)))
{
   volatile uint32_t CTRL_CFG;
   volatile uint32_t DLL_RAW;
   volatile uint32_t PRN_0_4;
   volatile uint32_t PRN_5_7;
   volatile uint32_t PRN_BRAM[32];
   volatile uint32_t CORRELATION_BRAM[32];
   volatile uint32_t DOPPLER_BRAM[32];
   volatile uint32_t CODE_DELAY_BRAM[32];
   volatile uint32_t DOPPLER_TRACKER[8];
   volatile uint32_t CODE_DELAY_TRACKER[8];
} axi_lite_t;

typedef struct
{
   uint32_t prn_id;
   uint32_t correlation_value;
} correlation_data_t;

#define AXI_LITE_BASE_ADDR (0x00000000U)
#define AXIL ((axi_lite_t *)AXI_LITE_BASE_ADDR)

void get_acquisition_result(uint32_t *doppler_shift, uint32_t *code_delay, correlation_data_t *correlation_result);
void print_acquisition_result(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram);
void print_bram(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram);

void set_tracker(uint32_t prn_id, uint32_t doppler_shift, uint32_t code_delay, uint32_t tracker_id);
int get_lock_status(uint32_t tracker_id);
void get_dll(uint32_t *curr_dll);

void sort_correlation(correlation_data_t *correlation_bram);
void print_prn_ids(uint32_t prn_id_1, uint32_t prn_id_2);
void print_trackers();

void delete_data_used(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram, uint32_t index);
void write_to_trackers(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram);

bool replace_loss_tracker(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram, uint32_t tracker_id);
bool check_lock_status(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram);

void gps_process();

#endif