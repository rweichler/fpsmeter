#include <stdio.h>
#include <time.h>

int *CARenderServerGetFrameCounter(int);


int get_frames()
{
    int *x = CARenderServerGetFrameCounter(0);
    return (int)x;
}

#define FREQUENCY 0.1

int main(int argc, char **argv)
{
    int x = get_frames();
    clock_t last = clock();
    while(1)
    {
        clock_t time = clock();
        int lastCount = x;
        if(time - last > FREQUENCY*CLOCKS_PER_SEC)
        {
            x = get_frames();
            int frameCount = x - lastCount;
            float fps = 1.0*CLOCKS_PER_SEC*frameCount/(time - last);
            printf("%d\n", (int)(fps + 0.5));
            last = time;
        }
    }
    return 0;
}
