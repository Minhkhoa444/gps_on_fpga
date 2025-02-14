#include "gps_dispatcher_driver.h"

// Giả lập vùng nhớ AXI Lite để mô phỏng
axi_lite_t AXI_LITE_SIM;
#undef AXIL
#define AXIL (&AXI_LITE_SIM)
#define num_tracker 8

void get_acquisition_result(uint32_t *doppler_shift, uint32_t *code_delay, correlation_data_t *correlation_result)
{
    for (int i = 0; i < 32; i++)
    {
        correlation_result[i].correlation_value = AXIL->CORRELATION_BRAM[i];
        correlation_result[i].prn_id = (correlation_result[i].correlation_value > 0) ? i : 0;
        code_delay[i] = AXIL->CODE_DELAY_BRAM[i];
        doppler_shift[i] = AXIL->DOPPLER_BRAM[i];
    }
}

void print_acquisition_result(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram)
{
    printf("Result from Acquisition:\n");
    for (int i = 0; i < 32; i++)
    {
        printf("PRN ID %2d: Code Delay: %#x, Doppler Shift: %#x, Correlation: %#x\n", correlation_bram[i].prn_id, code_delay_bram[i], doppler_bram[i], correlation_bram[i].correlation_value);
    }
}

void print_bram(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram)
{
    printf("\nCorrelation bram: ");
    for (int i = 0; i < 32; i++)
    {
        printf("%#x-%d, ", correlation_bram[i].correlation_value, correlation_bram[i].prn_id);
    }
    printf("\nDoppler bram: ");
    for (int i = 0; i < 32; i++)
    {
        printf("%#x, ", doppler_bram[i]);
    }
    printf("\nCode delay bram: ");
    for (int i = 0; i < 32; i++)
    {
        printf("%#x, ", code_delay_bram[i]);
    }
}

void set_tracker(uint32_t prn_id, uint32_t doppler_shift, uint32_t code_delay, uint32_t tracker_id)
{
    if (tracker_id < 5)
    {
        AXIL->PRN_0_4 &= ~(0x3F << (tracker_id * 6));  // clear bits
        AXIL->PRN_0_4 |= (prn_id << (tracker_id * 6)); // write prn_id
    }
    else
    {
        AXIL->PRN_5_7 &= ~(0x3F << ((tracker_id - 5) * 6));  // clear bits
        AXIL->PRN_5_7 |= (prn_id << ((tracker_id - 5) * 6)); // write prn_id
    }

    // write doppler_shift
    AXIL->DOPPLER_TRACKER[tracker_id] = doppler_shift;

    // write code_delay
    AXIL->CODE_DELAY_TRACKER[tracker_id] = code_delay;
}

int get_lock_status(uint32_t tracker_id)
{
    uint32_t status = AXIL->CTRL_CFG;
    return (status >> (tracker_id + 1)) & 0x1;
}

void get_dll(uint32_t *curr_dll)
{
    *curr_dll = AXIL->DLL_RAW;
}

void sort_correlation(correlation_data_t *correlation_bram)
{
    correlation_data_t temp_value;
    for (int i = 0; i < 32; i++)
    {
        for (int j = i + 1; j < 32; j++)
        {
            if (correlation_bram[j].correlation_value > correlation_bram[i].correlation_value)
            {
                temp_value = correlation_bram[i];
                correlation_bram[i] = correlation_bram[j];
                correlation_bram[j] = temp_value;
            }
        }
    }
    printf("--------------------------------------------------\nSorted Correlation:\n");
    for (int i = 0; i < 32; i++)
    {
        printf("PRN ID: %u, Correlation Value: %#x\n", correlation_bram[i].prn_id, correlation_bram[i].correlation_value);
    }
}

void print_prn_ids(uint32_t prn_id_1, uint32_t prn_id_2)
{
    printf("\nPRN_0_4 (Trackers 0-4):\n");
    for (int i = 0; i < 5; i++)
    {
        uint32_t prn_bits = (prn_id_1 >> (i * 6)) & 0x3F;
        printf("PRN ID %d: ", i);
        for (int bit = 5; bit >= 0; bit--)
        {
            printf("%d", (prn_bits >> bit) & 1);
        }
        printf(" (%d)\n", prn_bits);
    }

    printf("\nPRN_5_7 (Trackers 5-7):\n");
    for (int i = 0; i < 3; i++)
    {
        uint32_t prn_bits = (prn_id_2 >> (i * 6)) & 0x3F;
        printf("PRN ID %d: ", i + 5);
        for (int bit = 5; bit >= 0; bit--)
        {
            printf("%d", (prn_bits >> bit) & 1);
        }
        printf(" (%d)\n", prn_bits);
    }
    printf("\n");
}

void print_trackers()
{
    uint32_t prn_id_1 = AXIL->PRN_0_4;
    uint32_t prn_id_2 = AXIL->PRN_5_7;
    for (int i = 0; i < 5; i++)
    {
        uint32_t prn_id_extracted = (prn_id_1 >> (i * 6)) & 0x3F;
        printf("Tracker %d: PRN ID %d, doppler shift: %#x, code delay: %#x\n", i, prn_id_extracted, AXIL->DOPPLER_TRACKER[i], AXIL->CODE_DELAY_TRACKER[i]);
    }
    for (int i = 0; i < 3; i++)
    {
        uint32_t prn_id_extracted = (prn_id_2 >> (i * 6)) & 0x3F;
        printf("Tracker %d: PRN ID %d, doppler shift: %#x, code delay: %#x\n", i + 5, prn_id_extracted, AXIL->DOPPLER_TRACKER[i + 5], AXIL->CODE_DELAY_TRACKER[i + 5]);
    }
    // print_prn_ids(prn_id_1,prn_id_2);
}

void delete_data_used(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram, uint32_t index)
{
    doppler_bram[correlation_bram[index].prn_id] = 0;
    code_delay_bram[correlation_bram[index].prn_id] = 0;
    correlation_bram[index].prn_id = 0;
    correlation_bram[index].correlation_value = 0;
}

void write_to_trackers(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram)
{
    printf("\n-------------------------------------------\nWrite data to trackers...\n");
    for (int i = 0; i < num_tracker; i++)
    {
        set_tracker(correlation_bram[i].prn_id, doppler_bram[correlation_bram[i].prn_id], code_delay_bram[correlation_bram[i].prn_id], i);
        delete_data_used(doppler_bram, code_delay_bram, correlation_bram, i);
    }
}

bool replace_loss_tracker(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram, uint32_t tracker_id)
{
    for (int i = 0; i < 32; i++)
    {
        if (correlation_bram[i].prn_id != 0)
        {
            set_tracker(correlation_bram[i].prn_id, doppler_bram[correlation_bram[i].prn_id], code_delay_bram[correlation_bram[i].prn_id], tracker_id);
            delete_data_used(doppler_bram, code_delay_bram, correlation_bram, i);
            return true;
        }
    }
    return false;
}

bool check_lock_status(uint32_t *doppler_bram, uint32_t *code_delay_bram, correlation_data_t *correlation_bram)
{
    for (int i = 0; i < num_tracker; i++)
    {
        if (get_lock_status(i))
        {
            printf("\nLock loss at tracker %d\n", i);
            if (replace_loss_tracker(doppler_bram, code_delay_bram, correlation_bram, i))
            {
                printf("Replace successfully\n");
            }
            else
            {
                printf("No appropriate correlation to replace, terminate the GPS process\n");
                return false;
            }
        }
    }
    return true;
}

void gps_process()
{
    AXIL->CTRL_CFG = 0x00000003;
    uint32_t doppler_bram[32], code_delay_bram[32];
    correlation_data_t correlation_bram[32];
    uint32_t store_top_correlation[num_tracker];
    get_acquisition_result(doppler_bram, code_delay_bram, correlation_bram);
    print_acquisition_result(doppler_bram, code_delay_bram, correlation_bram);
    sort_correlation(correlation_bram);
    write_to_trackers(doppler_bram, code_delay_bram, correlation_bram);
    print_trackers();
    print_bram(doppler_bram, code_delay_bram, correlation_bram);
    if (!check_lock_status(doppler_bram, code_delay_bram, correlation_bram))
    {
        AXIL->CTRL_CFG = 0x00000000;
    }
    print_trackers();
    print_bram(doppler_bram, code_delay_bram, correlation_bram);
}

int main()
{
    // srand(time(NULL)); // Khởi tạo random cho mô phỏng
    for (int i = 0; i < 32; i++)
    {
        AXIL->CODE_DELAY_BRAM[i] = i;
        AXIL->DOPPLER_BRAM[i] = i;
        AXIL->CORRELATION_BRAM[i] = i;
    }
    gps_process();
    return 0;
}