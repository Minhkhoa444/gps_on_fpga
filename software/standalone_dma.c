#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "ff.h"
#include "xsdps.h"
#include "xaxidma.h"
#include "sleep.h"

#define DMA_TRANSFER_SIZE           (32)
#define MAX_FILE_SIZE               (500 * 1024 * 1024)

#define SD_DEVICE_ID                XPAR_PSU_SD_0_DEVICE_ID
#define DMA_DEVICE_ID               XPAR_AXI_DMA_0_DEVICE_ID
#define DDR_BASE_ADDR               XPAR_PSU_APM_0_S_AXI4_BASEADDR
#define WRITE_BASE_ADDR             (DDR_BASE_ADDR + 0x01100000)
#define READ_BASE_ADDR              (DDR_BASE_ADDR + 0x01300000)

static XSdPs sd_instance;
static FATFS fat_fs;
static FIL file_handle;

static XAxiDma dma_instance;

u16 sd_buffer[MAX_FILE_SIZE];    //  500 MB file max!!!!!!!!!
u32 iq_buffer[MAX_FILE_SIZE / 2];
u32 bytes_read = 0;
u32 no_of_transfer = 0;
u32 current_transfer = 0;

u32 *dma_write_buffer = (u32 *)WRITE_BASE_ADDR;
u64 *pl_return_buffer = (u64 *)READ_BASE_ADDR;

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
                                DMA_TRANSFER_SIZE,
                                XAXIDMA_DMA_TO_DEVICE
    );
    if(rc != XST_SUCCESS) {
        xil_printf("AXI DMA write transfer failed\r\n");
        break;
    } 
    while(XAxiDma_Busy(&dma_instance, XAXIDMA_DMA_TO_DEVICE));
    current_transfer += 1;
}

void dma_read_task(void) {
    int rc;
    Xil_DCacheFlushRange((UINTPTR)pl_return_buffer, DMA_TRANSFER_SIZE * sizeof(u64));
    Xil_DCacheInvalidateRange((UINTPTR)pl_return_buffer, DMA_TRANSFER_SIZE * sizeof(u64));
    rc = XAxiDma_SimpleTransfer(&dma_instance,
                                (UINTPTR)pl_return_buffer,
                                DMA_TRANSFER_SIZE,
                                XAXIDMA_DEVICE_TO_DMA
    );
    if(rc != XST_SUCCESS) {
        xil_printf("AXI DMA read transfer failed\r\n");
        break;
    }
    u32 timeout_counter = 0;
    while(XAxiDma_Busy(&dma_instance, XAXIDMA_DEVICE_TO_DMA)) {
        usleep(1000);   //  1 ms sleep
        timeout_counter += 1;
        if(timeout_counter >= 100) {    //  timeout after 100 ms
            xil_printf("AXI read timeout!\r\n");
            break;
        }
    }
    //  UNCOMMENT FOR DEBUGGING
    //for(u32 i = 0; i < DMA_TRANSFER_SIZE; i += 1) {
    //    xil_printf("pl_return_buffer[%d] = %X\r\n", i, pl_return_buffer[i]);
    //}
}

int main(void) {
    init_platform();
    int rc;
    const char *data_file = "gps_10s.bin";
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
        dma_read_task();
    }

    f_close(&file_handle);
    f_unmount("0:/");
    cleanup_platform();
    return XST_SUCCESS;
}
