#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "ff.h"
#include "xsdps.h"
#include "xaxidma.h"
#include "sleep.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "xgpiops.h"
#include "xgpio.h"
#include "xtime_l.h"

#define NAV_VALID_IRQ_ID 			(121U)

#define DMA_TRANSFER_SIZE           (32)
#define MAX_FILE_SIZE               (500 * 1024 * 1024)

#define SD_DEVICE_ID                XPAR_PSU_SD_0_DEVICE_ID
#define DMA_DEVICE_ID               XPAR_AXI_DMA_0_DEVICE_ID
#define DDR_BASE_ADDR               XPAR_PSU_APM_0_S_AXI4_BASEADDR
#define WRITE_BASE_ADDR             (DDR_BASE_ADDR + 0x01100000)
#define READ_BASE_ADDR              (DDR_BASE_ADDR + 0x01300000)

#define MAX_BIT						(10000)

static XSdPs sd_instance;
static FATFS fat_fs;
static FIL file_handle;

static XAxiDma dma_instance;

static XScuGic interrupt_controller;
static XGpioPs gpio_ps;
static XGpio axi_gpio;

u16 sd_buffer[MAX_FILE_SIZE];    //  500 MB file max!!!!!!!!!
u32 iq_buffer[MAX_FILE_SIZE / 2];
u32 bytes_read = 0;
u32 no_of_transfer = 0;
u32 current_transfer = 0;

u32 *dma_write_buffer = (u32 *)WRITE_BASE_ADDR;

volatile u8 nav_bit[4][MAX_BIT];
volatile u32 nav_bit_count[4] = {0, 0, 0, 0};
const u8 nav_preamble[8] = {1, 0, 0, 0, 1, 0, 1, 1};

void nav_valid_handler(void *CallbackRef) {
	volatile u32 nav_data = XGpio_DiscreteRead(&axi_gpio, 1);
	for(int i = 0; i < 4; i = i + 1) {
		nav_bit[i][nav_bit_count[i]++] = ((nav_data >> i) & 0x01);
	}
}

int initialize_nav(void) {
	for(int i = 0; i < 4; i = i + 1) {
	    nav_bit_count[i] = 0;
	}
	int rc;
	XScuGic_Config *intc_cfg;
	XGpio_Config *gpio_cfg;
	gpio_cfg = XGpio_LookupConfig(XPAR_AXI_GPIO_0_DEVICE_ID);
	rc = XGpio_CfgInitialize(&axi_gpio, gpio_cfg, gpio_cfg->BaseAddress);
	if(rc != XST_SUCCESS) {
		xil_printf("GPIO initialization failed\r\n");
	    return XST_FAILURE;
	}
	XGpio_SetDataDirection(&axi_gpio, 1, 0xFFFFFFFF);
	intc_cfg = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
	rc = XScuGic_CfgInitialize(&interrupt_controller, intc_cfg, intc_cfg->CpuBaseAddress);
	if(rc != XST_SUCCESS) {
		xil_printf("Interrupt controller initialization failed\r\n");
		return XST_FAILURE;
	}
	XScuGic_SetPriorityTriggerType(&interrupt_controller, NAV_VALID_IRQ_ID, 0x00, 0x03);
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler,
	                    		&interrupt_controller);
	Xil_ExceptionEnable();
	rc = XScuGic_Connect(&interrupt_controller, NAV_VALID_IRQ_ID,
	                   	   (Xil_InterruptHandler)nav_valid_handler,
	                       (void *)&gpio_ps);
	if(rc != XST_SUCCESS) {
		xil_printf("Interrupt connect failed\r\n");
		return XST_FAILURE;
	}
	XScuGic_Enable(&interrupt_controller, NAV_VALID_IRQ_ID);
	return XST_SUCCESS;
}

int initialize_sd_card(const char *filename) {
    int rc;
    XSdPs_Config *sd_cfg = XSdPs_LookupConfig(SD_DEVICE_ID);
    rc = XSdPs_CfgInitialize(&sd_instance, sd_cfg, sd_cfg->BaseAddress);
    if(rc != XST_SUCCESS) {
        xil_printf("SD initialization failed\r\n");
        return XST_FAILURE;
    }
    rc = f_mount(&fat_fs, "0:/", 1);
    if(rc != FR_OK) {
        xil_printf("Failed to mount SD card, error: %d\r\n", rc);
        return XST_FAILURE;
    }
    rc = f_open(&file_handle, filename, FA_READ);
    if(rc != FR_OK) {
        xil_printf("Failed to open file %s, error: %d\r\n", filename, rc);
        return XST_FAILURE;
    }
    return XST_SUCCESS;
}

void read_sd_card(void) {
    FSIZE_t file_size = f_size(&file_handle);
    xil_printf("File size: %llu bytes\r\n", (unsigned long long)file_size);
    FRESULT rc = f_read(&file_handle, sd_buffer, file_size, &bytes_read);
    if(rc) {
        xil_printf("Failed to read file, error: %d\r\n", rc);
        f_close(&file_handle);
        return;
    }
    if(bytes_read != file_size) {
        xil_printf("Warning: Read %u bytes, expected %u bytes\r\n", bytes_read, file_size);
        f_close(&file_handle);
        return;
    }
    xil_printf("Read: %u bytes\r\n", bytes_read);
    //  Convert u16 buffer to u32 IQ buffer
    for(u32 i = 0; i < MAX_FILE_SIZE / 2; i = i + 1) {
        iq_buffer[i] = ((u16)sd_buffer[2 * i] << 16) | sd_buffer[2 * i + 1];
    }
    no_of_transfer = (bytes_read / 4) / (DMA_TRANSFER_SIZE);
    //no_of_transfer = (224000000 / 4) / (DMA_TRANSFER_SIZE);
}

int initialize_dma(void) {
    XAxiDma_Config *dma_config;
    int rc;
    dma_config = XAxiDma_LookupConfig(DMA_DEVICE_ID);
    if(!dma_config) {
        xil_printf("DMA configuration lookup failed\r\n");
        return XST_FAILURE;
    }
    rc = XAxiDma_CfgInitialize(&dma_instance, dma_config);
    if(rc != XST_SUCCESS) {
        xil_printf("DMA configuration initialization failed\r\n");
        return XST_FAILURE;
    }
    XAxiDma_IntrDisable(&dma_instance, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrDisable(&dma_instance, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    return XST_SUCCESS;
}

void dma_write_task(void) {
    int rc;
    for(u32 i = 0; i < DMA_TRANSFER_SIZE; i += 1) {
        dma_write_buffer[i] = iq_buffer[current_transfer * DMA_TRANSFER_SIZE + i];
    }
    //  UNCOMMENT FOR DEBUGGING
    //for(u32 i = 0; i < DMA_TRANSFER_SIZE; i += 1) {
    //    xil_printf("dma_write_buffer[%d] = %X\r\n", i, dma_write_buffer[i]);
    //}
    Xil_DCacheFlushRange((UINTPTR)dma_write_buffer, DMA_TRANSFER_SIZE * sizeof(u32));
    Xil_DCacheInvalidateRange((UINTPTR)dma_write_buffer, DMA_TRANSFER_SIZE * sizeof(u32));
    rc = XAxiDma_SimpleTransfer(&dma_instance,
                                (UINTPTR)dma_write_buffer,
                                DMA_TRANSFER_SIZE * 4,
                                XAXIDMA_DMA_TO_DEVICE
    );
    if(rc != XST_SUCCESS) {
        xil_printf("AXI DMA write transfer failed\r\n");
        return;
    }
    u32 timeout_counter = 0;
    while(XAxiDma_Busy(&dma_instance, XAXIDMA_DMA_TO_DEVICE)) {
        usleep(1);   //  1 us sleep
        timeout_counter += 1;
        if(timeout_counter >= 100000) {    //  timeout after 100 ms
            xil_printf("AXI write timeout!\r\n");
            return;
        }
    }
    current_transfer += 1;
}

int32_t search_preamble(volatile u8 *bits) {
	for(u32 i = 0; i < MAX_BIT - 8; i = i + 1) {
		int match = 1;
		for(int j = 0; j < 8; j = j + 1) {
			if(bits[i + j] != nav_preamble[j]) {
				match = 0;
				break;
			}
		}
		if(match) {
			return i;
		}
	}
	return -1;
}

int main(void) {
    init_platform();

    XTime t_start, t_end;
    int rc;
    const char *data_file = "gps_10s.bin";
    //const char *data_file = "spain_gps_10s.mem";
    XTime_GetTime(&t_start);
    rc = initialize_nav();
    if(rc != XST_SUCCESS) {
    	xil_printf("Failed to initialize GPIO and interrupt, error: %d\r\n", rc);
        return XST_FAILURE;
    }
    rc = initialize_sd_card(data_file);
    if(rc != XST_SUCCESS) {
        xil_printf("Failed to initialize SD card, error: %d\r\n", rc);
        return XST_FAILURE;
    }
    read_sd_card();
    rc = initialize_dma();
    if(rc != XST_SUCCESS) {
        xil_printf("Failed to initialize DMA\r\n");
        f_close(&file_handle);
        f_unmount("0:/");
        return XST_FAILURE;
    }

    while(1) {
        if(current_transfer < no_of_transfer) {
            dma_write_task();
        }
        else {
        	break;
        }
    }
    xil_printf("Finished sending IQ data!\r\n");
    for(int i = 0; i < 4; i = i + 1) {
    	int32_t idx = search_preamble(nav_bit[i]);
    	if(idx != -1) {
    		xil_printf("Tracker %u preamble found at %d!\r\n", i, idx);
    	}
    	else {
    		xil_printf("Tracker %u preamble not found!\r\n", i);
    	}
    }
    XTime_GetTime(&t_end);
    printf("Elapsed: %f seconds\r\n", ((double)(t_end - t_start) / (double)COUNTS_PER_SECOND));
    f_close(&file_handle);
    f_unmount("0:/");
    cleanup_platform();
    return XST_SUCCESS;
}
