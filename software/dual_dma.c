#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "ff.h"
#include "xsdps.h"
#include "xaxidma.h"
#include "sleep.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"

#define DMA_TRANSFER_SIZE           (32)
#define MAX_FILE_SIZE               (500 * 1024 * 1024)
#define TASK_STACK_SIZE             (configMINIMAL_STACK_SIZE * 4)

#define SD_DEVICE_ID                XPAR_PSU_SD_0_DEVICE_ID
#define AXI_DMA_WRITE_DEVICE_ID     XPAR_AXI_DMA_0_DEVICE_ID
#define AXI_DMA_READ_DEVICE_ID      XPAR_AXI_DMA_1_DEVICE_ID
#define DDR_BASE_ADDR               XPAR_PSU_APM_0_S_AXI4_BASEADDR
#define WRITE_BASE_ADDR             (DDR_BASE_ADDR + 0x01100000)
#define READ_BASE_ADDR              (DDR_BASE_ADDR + 0x01300000)

static XSdPs sd_instance;
static FATFS fat_fs;
static FIL file_handle;

static XAxiDma dma_write;
static XAxiDma dma_read;

TaskHandle_t dma_write_task_handle = NULL;
TaskHandle_t dma_read_task_handle = NULL;

u16 sd_buffer[MAX_FILE_SIZE];    //  500 MB file max!!!!!!!!!
UINT bytes_read;

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
    FSIZE_t byte_remaining = f_size(&file_handle);
    xil_printf("File size: %llu bytes\r\n", (unsigned long long)byte_remaining);
    FRESULT rc = f_read(&file_handle, sd_buffer, byte_remaining, &bytes_read);
    if(rc) {
        xil_printf("Failed to read file, error: %d\r\n", rc);
        f_close(&file_handle);
        return;
    }
    if(bytes_read != byte_remaining) {
        xil_printf("Warning: Read %u bytes, expected %u bytes\r\n", bytes_read, byte_remaining);
    }
    xil_printf("Read: %u bytes\r\n", bytes_read);
}

int initialize_dma(void) {
    XAxiDma_Config *dma_config_write, *dma_config_read;
    int rc;
    dma_config_write = XAxiDma_LookupConfig(AXI_DMA_WRITE_DEVICE_ID);
    if(!dma_config_write) {
        xil_printf("DMA Write configuration lookup failed\r\n");
        return XST_FAILURE;
    }
    rc = XAxiDma_CfgInitialize(&dma_write, dma_config_write);
    if(rc != XST_SUCCESS) {
        xil_printf("DMA Write configuration initialization failed\r\n");
        return XST_FAILURE;
    }
    dma_config_read = XAxiDma_LookupConfig(AXI_DMA_READ_DEVICE_ID);
    if(!dma_config_read) {
        xil_printf("DMA Read configuration lookup failed\r\n");
        return XST_FAILURE;
    }
    rc = XAxiDma_CfgInitialize(&dma_read, dma_config_read);
    if (rc != XST_SUCCESS) {
        xil_printf("DMA Read configuration initialization failed\r\n");
        return XST_FAILURE;
    }
    XAxiDma_IntrDisable(&dma_write, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrDisable(&dma_write, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(&dma_read, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrDisable(&dma_read, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    return XST_SUCCESS;
}

void dma_write_task(void *pvParameters) {
    (void)pvParameters;
    u32 *dma_write_buffer = (u32 *)WRITE_BASE_ADDR;
    int rc;
    UINT iq_buffer_size = bytes_read / 4;
    UINT no_of_transfer = iq_buffer_size / DMA_TRANSFER_SIZE;
    for(UINT i = 0; i < no_of_transfer; i += 1) {
        for(UINT j = 0; j < DMA_TRANSFER_SIZE; j += 1) {
            dma_write_buffer[j] = ((u32)sd_buffer[j * 2 + 2 * DMA_TRANSFER_SIZE * i] << 16) | (sd_buffer[j * 2 + 2 * DMA_TRANSFER_SIZE * i + 1]);
        }
        //  UNCOMMENT FOR DEBUGGING
        //for(UINT i = 0; i < iq_buffer_size; i += 1) {
        //    xil_printf("dma_write_buffer[%d] = %X\r\n", i, dma_write_buffer[i]);
        //}
        Xil_DCacheFlushRange((UINTPTR)dma_write_buffer, DMA_TRANSFER_SIZE * sizeof(u32));
        Xil_DCacheInvalidateRange((UINTPTR)dma_write_buffer, DMA_TRANSFER_SIZE * sizeof(u32));
        rc = XAxiDma_SimpleTransfer(&dma_write,
                                    (UINTPTR)dma_write_buffer,
                                    DMA_TRANSFER_SIZE,
                                    XAXIDMA_DMA_TO_DEVICE
        );
        if(rc != XST_SUCCESS) {
            xil_printf("AXI DMA write transfer failed\r\n");
            break;
        }
        while(XAxiDma_Busy(&dma_write, XAXIDMA_DMA_TO_DEVICE));
        vTaskDelay(pdMS_TO_TICKS(1));
    }
    vTaskDelete(NULL);
}

void dma_read_task(void *pvParameters) {
    (void)pvParameters;
    u64 *pl_return_buffer = (u64 *)READ_BASE_ADDR;
    int rc;
    while(1) {
        Xil_DCacheFlushRange((UINTPTR)pl_return_buffer, DMA_TRANSFER_SIZE * sizeof(u64));
        Xil_DCacheInvalidateRange((UINTPTR)pl_return_buffer, DMA_TRANSFER_SIZE * sizeof(u64));
        rc = XAxiDma_SimpleTransfer(&dma_read,
                                    (UINTPTR)pl_return_buffer,
                                    DMA_TRANSFER_SIZE,
                                    XAXIDMA_DEVICE_TO_DMA
        );
        if(rc != XST_SUCCESS) {
            xil_printf("AXI DMA read transfer failed\r\n");
            break;
        }
        while(XAxiDma_Busy(&dma_read, XAXIDMA_DEVICE_TO_DMA));
        //  UNCOMMENT FOR DEBUGGING
        //for(int i = 0; i < DMA_TRANSFER_SIZE; i += 1) {
        //    xil_printf("pl_return_buffer[%d] = %X\r\n", i, pl_return_buffer[i]);
        //}
        vTaskDelay(pdMS_TO_TICKS(1));
    }
    vTaskDelete(NULL);
}

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    xil_printf("Stack overflow in task: %s\r\n", pcTaskName);
}

int main(void) {
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

    xTaskCreate(dma_write_task,
                "DMA_Write_Task",
                TASK_STACK_SIZE,
                NULL,
                tskIDLE_PRIORITY + 3,
                &dma_write_task_handle
    );

    xTaskCreate(dma_read_task,
                "DMA_Read_Task",
                TASK_STACK_SIZE, 
                NULL,
                tskIDLE_PRIORITY + 3,
                &dma_read_task_handle
    );
    vTaskStartScheduler();
    f_close(&file_handle);
    f_unmount("0:/");
    return XST_SUCCESS;
}
