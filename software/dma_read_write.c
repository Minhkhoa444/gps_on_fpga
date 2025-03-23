#include "xparameters.h"
#include "xil_printf.h"
#include "ff.h"
#include "xsdps.h"
#include "xaxidma.h"

#define SD_DEVICE_ID        XPAR_XSDPS_0_DEVICE_ID
#define DMA_DEVICE_ID       XPAR_AXIDMA_0_DEVICE_ID
#define DDR_BASE_ADDR       XPAR_PS7_DDR_0_S_AXI_BASEADDR
#define DMA_BUFFER_ADDR     (DDR_BASE_ADDR + 0x1000000)
#define MAX_TRANSFER_SIZE   (1 * 1024 * 1024)  // 1MB buffer size

static FATFS fatfs;
static FIL file;
static XSdPs sd_instance;
static XAxiDma axi_dma;

int send_iq(void) {
    FRESULT rc;
    UINT br;
    u32 *dma_buffer_ptr = (u32 *)DMA_BUFFER_ADDR;
    int status;
    XAxiDma_Config *dma_cfg_ptr;
    FSIZE_t file_size;
    FSIZE_t byte_remaining;

    status = XSdPs_CfgInitialize(&sd_instance, XSdPs_LookupConfig(SD_DEVICE_ID));
    if(status != XST_SUCCESS) {
        xil_printf("SD initialization failed\r\n");
        return XST_FAILURE;
    }

    rc = f_mount(&fatfs, "0:/", 0);
    if(rc) {
        xil_printf("Failed to mount FAT file system, error: %d\r\n", rc);
        return XST_FAILURE;
    }

    rc = f_open(&file, ".dat", FA_READ);
    if(rc) {
        xil_printf("Failed to open file, error: %d\r\n", rc);
        return XST_FAILURE;
    }

    file_size = f_size(&file);
    byte_remaining = file_size;
    xil_printf("File size: %llu bytes\r\n", (unsigned long long)file_size);

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
        UINT chunk_size = (byte_remaining > CHUNK_SIZE) ? CHUNK_SIZE : (UINT)byte_remaining;

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
                  br, (float)(file_size - byte_remaining) * 100.0f / file_size);

        // Flush the data cache to ensure DMA sees the latest data
        Xil_DCacheFlushRange((UINTPTR)dma_buffer_ptr, br);

        // Start the DMA transfer
        status = XAxiDma_SimpleTransfer(&axi_dma, (UINTPTR)dma_buffer_ptr, br, XAXIDMA_DMA_TO_DEVICE);
        if(status != XST_SUCCESS) {
            xil_printf("DMA transfer failed\r\n");
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
