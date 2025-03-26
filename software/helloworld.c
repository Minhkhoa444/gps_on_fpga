/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "ff.h"
#include "xsdps.h"
#include "xaxidma.h"

//#define SD_DEVICE_ID        XPAR_XSDPS_0_DEVICE_ID
//#define DMA_DEVICE_ID       XPAR_AXIDMA_0_DEVICE_ID
//#define DDR_BASE_ADDR       XPAR_PS7_DDR_0_S_AXI_BASEADDR
#define SD_DEVICE_ID        XPAR_XSDPS_0_BASEADDR
#define DMA_DEVICE_ID       XPAR_XAXIDMA_0_BASEADDR
#define DDR_BASE_ADDR       XPAR_PSU_DDR_0_BASEADDRESS
#define DMA_BUFFER_ADDR     (DDR_BASE_ADDR + 0x00100000)
#define MAX_TRANSFER_SIZE   (0x20)

static FATFS fatfs;
static FIL file;
static XSdPs sd_instance;
static XAxiDma axi_dma;

void check_dma_error(XAxiDma *axi_dma) {
    u32 status = XAxiDma_ReadReg(axi_dma->RegBase, XAXIDMA_SR_OFFSET);
    xil_printf("DMA Status Reg: %X", status);     
}

int send_iq(void) {
    FRESULT rc;
    UINT br;
    u16 *dma_buffer_ptr = (u16 *)DDR_BASE_ADDR;
    int status;
    XAxiDma_Config *dma_cfg_ptr;
    FSIZE_t file_size;
    FSIZE_t byte_remaining;

    XSdPs_Config *sd_cfg = XSdPs_LookupConfig(SD_DEVICE_ID);
    status = XSdPs_CfgInitialize(&sd_instance, sd_cfg, sd_cfg->BaseAddress);
    if(status != XST_SUCCESS) {
        xil_printf("SD initialization failed\r\n");
        return XST_FAILURE;
    }

    rc = f_mount(&fatfs, "0:/", 0);
    if(rc) {
        xil_printf("Failed to mount FAT file system, error: %d\r\n", rc);
        return XST_FAILURE;
    }

    rc = f_open(&file, "gps_10s.bin", FA_READ);
    //rc = f_open(&file, "2013_04_04_GNSS_SIGNAL_at_CTTC_SPAIN.dat", FA_READ);
    if(rc) {
        xil_printf("Failed to open file, error: %d\r\n", rc);
        return XST_FAILURE;
    }

    file_size = f_size(&file);
    byte_remaining = file_size;
    xil_printf("File size: %llu bytes\r\n", (unsigned long long)file_size);

    /*
    /////////////////////////////////////////////////////////////////////////
    rc = f_read(&file, (void*)dma_buffer_ptr, 10, &br);
    if(rc) {
        xil_printf("Failed to read file, error: %d\r\n", rc);
        f_close(&file);
        return XST_FAILURE;
    }
    for(int i = 0; i < 10; i = i + 1) {
        xil_printf("0x%02X\r\n", (dma_buffer_ptr[i] & 0xFF00) >> 8);
        xil_printf("0x%02X\r\n", (dma_buffer_ptr[i] & 0x00FF) >> 0);
    }
    /////////////////////////////////////////////////////////////////////////
    */    

    dma_cfg_ptr = XAxiDma_LookupConfig(DMA_DEVICE_ID);
    if(!dma_cfg_ptr) {
        xil_printf("No DMA configuration found\r\n");
        f_close(&file);
        return XST_FAILURE;
    }

    status = XAxiDma_CfgInitialize(&axi_dma, dma_cfg_ptr);
    if(status != XST_SUCCESS) {
        xil_printf("DMA initialization failed\r\n");
        f_close(&file);
        return XST_FAILURE;
    }

    // Disable interrupts
    XAxiDma_IntrDisable(&axi_dma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

    while(byte_remaining > 0) {
        UINT chunk_size = (byte_remaining > MAX_TRANSFER_SIZE) ? MAX_TRANSFER_SIZE : (UINT)byte_remaining;

        // Read a chunk of data from file to buffer
        rc = f_read(&file, (void*)dma_buffer_ptr, chunk_size, &br);
        if(rc) {
            xil_printf("Failed to read file, error: %d\r\n", rc);
            f_close(&file);
            return XST_FAILURE;
        }

        if(br != chunk_size) {
            xil_printf("Warning: Read %u bytes, expected %u bytes\r\n", br, chunk_size);
        }

        xil_printf("Processing chunk: %u bytes (%.2f%%)\r\n", 
                  br, (double)(file_size - byte_remaining) * 100.0f / (double)file_size);

        // Flush the data cache to ensure DMA sees the latest data
        Xil_DCacheFlushRange((UINTPTR)dma_buffer_ptr, br);

        // Start the DMA transfer
        status = XAxiDma_SimpleTransfer(&axi_dma, (UINTPTR)dma_buffer_ptr, br, XAXIDMA_DMA_TO_DEVICE);
        if(status != XST_SUCCESS) {
            xil_printf("DMA transfer failed\r\n");
            check_dma_error(&axi_dma);
            f_close(&file);
            return XST_FAILURE;
        }

        // Wait for transfer to complete
        while(XAxiDma_Busy(&axi_dma, XAXIDMA_DMA_TO_DEVICE));
        byte_remaining -= br;
    }
    xil_printf("DMA transfer completed successfully\r\n");

    f_close(&file);
    return XST_SUCCESS;
}


int main()
{
    init_platform();

    send_iq();
    cleanup_platform();
    return 0;
}
