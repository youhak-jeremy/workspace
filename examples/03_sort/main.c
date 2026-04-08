#include <stdio.h>

extern void sort(int *v, int n);

static void print_array(const int *v, int n) {
    for (int i = 0; i < n; i++) {
        printf("%d ", v[i]);
    }
    printf("\n");
}

int main(void) {
    int arr[] = {8, 3, 7, 4, 9, 2, 6, 5, 1};
    int n = sizeof(arr) / sizeof(arr[0]);

    printf("before: ");
    print_array(arr, n);

    sort(arr, n);

    printf("after : ");
    print_array(arr, n);

    return 0;
}
