#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define MU 3.986005e14       // Earth's gravitational constant (m^3/s^2)
#define OMEGA_E 7.2921151467e-5 // Earth's rotation rate (rad/s)

// Struct to store Subframe 2 information
typedef struct {
    double idoe;     // Issue of Data (Ephemeris)
    double sqrtA;    // Square root of the semi-major axis
    double e;        // Eccentricity
    double M0;       // Mean anomaly at reference time
    double Delta_n;  // Mean Motion Difference From Computed Value
    double Cus, Cuc; // Argument of latitude correction terms
    double Crs;      // Radius correction term
    double t_oe;      // Time of ephemeris
} Subframe2Data;

// Struct to store Subframe 3 information
typedef struct {
    double i0;       // Inclination angle at reference time
    double Omega0;   // Longitude of ascending node at reference time
    double omega;    // Argument of perigee
    double Omegadot; // Rate of right ascension
    double idot;     // Rate of inclination angle
    double Cic, Cis; // Inclination correction terms
    double Crc;      // Radius correction term
} Subframe3Data;

// Function to extract bits from a binary string
double extractBits(const char *binary, int start, int length) {
    char buffer[64];
    strncpy(buffer, binary + start, length);
    buffer[length] = '\0';
    return strtol(buffer, NULL, 2);
}

// Function to extract bits spanning two segments
double extractSplitBits(const char *binary, int start1, int length1, int start2, int length2) {
    char buffer1[64], buffer2[64];
    strncpy(buffer1, binary + start1, length1);
    buffer1[length1] = '\0';
    strncpy(buffer2, binary + start2, length2);
    buffer2[length2] = '\0';

    char combined[128];
    snprintf(combined, sizeof(combined), "%s%s", buffer1, buffer2);
    return strtol(combined, NULL, 2);
}

// Function to parse Subframe 2 data from binary input
void parseSubframe2Binary(const char *line, Subframe2Data *subframe) {
    subframe->idoe = extractBits(line, 60, 8);
    subframe->Crs = extractBits(line, 68, 16) * pow(2, -5); // Crs (scaled by 2^-5)
    subframe->Delta_n = extractBits(line, 90, 16) * pow(2, -43); // Δn (scaled by 2^-43)
    subframe->M0 = extractSplitBits(line, 106, 8, 120, 24) * pow(2, -31); // M0 (scaled by 2^-31)
    subframe->Cuc = extractBits(line, 150, 16) * pow(2, -29); // Cuc (scaled by 2^-29)
    subframe->e = extractSplitBits(line, 166, 8, 180, 24) * pow(2, -33); // Eccentricity (scaled by 2^-33)
    subframe->Cus = extractBits(line, 210, 16) * pow(2, -29); // Cus (scaled by 2^-29)
    subframe->sqrtA = extractSplitBits(line, 226, 8, 240, 24) * pow(2, -19); // sqrt(A) (scaled by 2^-19)
    subframe->t_oe = extractBits(line, 270, 16) * pow(2, 4); // t_oe (scaled by 2^4)
}

// Function to parse Subframe 3 data from binary input
void parseSubframe3Binary(const char *line, Subframe3Data *subframe) {
    subframe->Cic = extractBits(line, 60, 16) * pow(2, -29); // Cic (scaled by 2^-29)
    subframe->Omega0 = extractSplitBits(line, 76, 8, 90, 24) * pow(2, -31); // Omega0 (scaled by 2^-31)
    subframe->Cis = extractBits(line, 120, 16) * pow(2, -29); // Cis (scaled by 2^-29)
    subframe->i0 = extractSplitBits(line, 136, 8, 150, 24) * pow(2, -31); // i0 (scaled by 2^-31)
    subframe->Crc = extractBits(line, 180, 16) * pow(2, -5); // Crc (scaled by 2^-5)
    subframe->omega = extractSplitBits(line, 196, 8, 210, 24) * pow(2, -31); // omega (scaled by 2^-31)
    subframe->Omegadot = extractBits(line, 240, 24) * pow(2, -43); // Omegadot (scaled by 2^-43)
    subframe->idot = extractBits(line, 278, 14) * pow(2, -43); // idot (scaled by 2^-43)
}

// Function to compute satellite position in ECEF coordinates
void computeSatellitePosition(Subframe2Data subframe2, Subframe3Data subframe3, double t, double *x, double *y, double *z) {
    double A = subframe2.sqrtA * subframe2.sqrtA; // Semi-major axis
    double n0 = sqrt(MU / (A * A * A));        // Nominal mean motion
    double n = n0 + subframe2.Delta_n;          // Corrected mean motion
    double t_k = t - subframe2.t_oe;            // Time from ephemeris reference epoch
    double M_k = subframe2.M0 + n * t_k; // Mean anomaly

    // Solve Kepler's Equation for Eccentric Anomaly (iterative)
    double E_0 = M_k;                              // initial value (radians)
    double E_j, E_j_minus_1 = E_0; 
    for (int i = 0; i < 10; i++) {          
        E_j = E_j_minus_1 + ((M_k - E_j_minus_1 + subframe2.e * sin(E_j_minus_1))) / (1 - subframe2.e * cos(E_j_minus_1));
        E_j_minus_1 = E_j;
    }

    double E_k = E_j;                              // Final value (radians)

    double v_k = 2 * atan2(sqrt((1 + subframe2.e)/(1 - subframe2.e)) * tan(E_k/2), 1); // True anomaly

    // Corrected argument of latitude   
    double phi_k = v_k + subframe3.omega;           // Argument of Latitude
    double delta_u_k = subframe2.Cus * sin(2 * phi_k) + subframe2.Cuc * cos(2 * phi_k);
    double delta_r_k = subframe2.Crs * sin(2 * phi_k) + subframe3.Crc * cos(2 * phi_k);
    double delta_i_k = subframe3.Cis * sin(2 * phi_k) + subframe3.Cic * cos(2 * phi_k);

    //u += delta_u;
    double u_k = phi_k + delta_u_k;                       // Corrected Argument of Latitude
    double r = A * (1 - subframe2.e * cos(E_k)) + delta_r_k;
    double i_k = subframe3.i0 + delta_i_k + subframe3.idot * t_k;

    // Positions in orbital plane
    double x_orb = r * cos(u_k);
    double y_orb = r * sin(u_k);

    // Correct for Earth rotation
    double Omega_k = subframe3.Omega0 + (subframe3.Omegadot - OMEGA_E) * t_k - OMEGA_E * subframe2.t_oe;

    // Transform to ECEF coordinates
    *x = x_orb * cos(Omega_k) - y_orb * cos(i_k) * sin(Omega_k);
    *y = x_orb * sin(Omega_k) + y_orb * cos(i_k) * cos(Omega_k);
    *z = y_orb * sin(i_k);
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
    Subframe2Data subframe2;
    Subframe3Data subframe3;

    if (fgets(line, sizeof(line), file) == NULL) {
        fprintf(stderr, "Error skipping Subframe 1 data\n");
        fclose(file);
        return EXIT_FAILURE;
    }

    // Read Subframe 2 data from the file
    if (fgets(line, sizeof(line), file) != NULL) {
        parseSubframe2Binary(line, &subframe2);
    } else {
        fprintf(stderr, "Error reading Subframe 2 data\n");
        fclose(file);
        return EXIT_FAILURE;
    }

    // Read Subframe 3 data from the file
    if (fgets(line, sizeof(line), file) != NULL) {
        parseSubframe3Binary(line, &subframe3);
    } else {
        fprintf(stderr, "Error reading Subframe 3 data\n");
        fclose(file);
        return EXIT_FAILURE;
    }

    fclose(file);

    // Compute satellite position at a given time t
    double x, y, z;
    double t = 432000; // Example: GPS time of the week in seconds
    computeSatellitePosition(subframe2, subframe3, t, &x, &y, &z);

    printf("Satellite Position (ECEF):\n");
    printf("x: %.3f meters\n", x);
    printf("y: %.3f meters\n", y);
    printf("z: %.3f meters\n", z);

    return 0;
}
