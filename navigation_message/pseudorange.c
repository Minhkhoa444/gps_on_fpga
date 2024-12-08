#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define SPEED_OF_LIGHT 299792458.0 // Speed of light (m/s)

// Struct to store Subframe 1 information
typedef struct {
    double af0; // Satellite clock offset
    double af1; // Satellite clock drift
    double af2; // Satellite clock drift rate
    double TGD; // Group Delay Differential (useful for L1/L2 corrections)
    double t_oc; // Reference clock time
    double tow; // Signal reception time at the GPS receiver
} Subframe1Data;

// Function to calculate satellite clock correction
double calculateClockCorrection(Subframe1Data subframe, double t_tx) {
    double delta_t = t_tx - subframe.t_oc;
    return subframe.af0 + subframe.af1 * delta_t + subframe.af2 * delta_t * delta_t;
}

// Function to extract bits from a binary string
double extractBits(const char *binary, int start, int length) {
    char buffer[64];
    strncpy(buffer, binary + start, length);
    buffer[length] = '\0';
    return strtol(buffer, NULL, 2);
}

// Function to parse Subframe 1 data from binary input
void parseSubframe1Binary(const char *line, Subframe1Data *subframe) {
    // Extract corresponding fields from binary input
    subframe->af0 = extractBits(line, 270, 22) * pow(2, -31); // af0 (scaled by 2^-31)
    subframe->af1 = extractBits(line, 248, 16) * pow(2, -43); // af1 (scaled by 2^-43)
    subframe->af2 = extractBits(line, 240, 8) * pow(2, -55);  // af2 (scaled by 2^-55)
    subframe->TGD = extractBits(line, 196, 8) * pow(2, -31); // TGD (scaled by 2^-31)
    subframe->t_oc = extractBits(line, 218, 16) * pow(2, 4);  // t_oc (scaled by 2^4)
    subframe->tow = extractBits(line, 30, 17) * 6; // tow
}

// Main function
int main() {
    // Open the input file
    FILE *file = fopen("navigation_message.txt", "r");
    if (file == NULL) {
        perror("Error opening file");
        return EXIT_FAILURE;
    }

    char line[312]; // Each subframe has 300 bits, plus newline and null terminator
    Subframe1Data subframe1;

    // Read Subframe 1 data from the first line
    if (fgets(line, sizeof(line), file) != NULL) {
        parseSubframe1Binary(line, &subframe1);
    } else {
        fprintf(stderr, "Error reading Subframe 1 data\n");
        fclose(file);
        return EXIT_FAILURE;
    }

    fclose(file);

    printf("Extracted Subframe 1 Data (Decimal):\n");
    printf("af0: %.10f\n", subframe1.af0);
    printf("af1: %.10f\n", subframe1.af1);
    printf("af2: %.10f\n", subframe1.af2);
    printf("TGD: %.10f\n", subframe1.TGD);
    printf("t_oc: %.10f\n", subframe1.t_oc);
    printf("tow: %.10f\n", subframe1.tow);

    // Calculate transmission time (t_tx)
    //double clock_correction = calculateClockCorrection(subframe1, subframe1.tow);
    //double tow = subframe1.tow - clock_correction;

    // Calculate pseudorange
    double pseudorange = SPEED_OF_LIGHT * (subframe1.tow - (int)subframe1.tow/2);

    // Output results
    printf("Pseudorange: %.3f meters\n", pseudorange);

    return 0;
}
