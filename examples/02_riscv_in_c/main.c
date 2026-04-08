#include <stdio.h>
extern int add(int x, int y);

int main() {
    int sum = add(3,4);
    printf("sum: %d",sum);
    return 0;
}
