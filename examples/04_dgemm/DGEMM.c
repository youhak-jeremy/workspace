#include <stdio.h>
#include <stdlib.h>
#include <time.h>

static double now_sec(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

/*
  Column-major layout:
  M[i + j*n] == M[i][j]
*/
void dgemm(int n, double* A, double* B, double* C)
{
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
        {
            double cij = C[i + j * n];

            for (int k = 0; k < n; k++)
                cij += A[i + k * n] * B[k + j * n];

            C[i + j * n] = cij;
        }
}

int main(int argc, char** argv)
{
    int N = 1024;

    if (argc >= 2)
        N = atoi(argv[1]);

    printf("N = %d\n", N);
    printf("Generating matrices...\n");

    double start_gen = now_sec();

    double* A = malloc((size_t)N * N * sizeof(double));
    double* B = malloc((size_t)N * N * sizeof(double));
    double* C = malloc((size_t)N * N * sizeof(double));

    if (A == NULL || B == NULL || C == NULL)
    {
        printf("Memory allocation failed\n");
        free(A);
        free(B);
        free(C);
        return 1;
    }

    for (int i = 0; i < N * N; i++)
    {
        A[i] = (double)(N % 2);
        B[i] = (double)(N % 3);
        C[i] = 0.0;
    }

    double end_gen = now_sec();

    printf("Matrix generation took %.2f seconds.\n", end_gen - start_gen);

    printf("Starting multiplication...\n");

    double start = now_sec();

    dgemm(N, A, B, C);

    double end = now_sec();

    printf("Multiplication took %.2f minutes.\n", (end - start) / 60.0);
    printf("Multiplication took %.2f seconds.\n", end - start);

    double checksum = 0.0;
    for (int i = 0; i < N * N; i++)
        checksum += C[i];

    printf("Checksum = %.2f\n", checksum);

    free(A);
    free(B);
    free(C);

    return 0;
}
