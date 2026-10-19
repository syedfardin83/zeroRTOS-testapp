#include "../libopencm3/include/libopencm3/stm32/rcc.h"
#include "../zeroRTOS/kernel/include/kernel.h"
#include "../zeroRTOS/kernel/include/tasks.h"

void rcc_setup(void){
    rcc_clock_setup_pll(&rcc_hsi_configs[RCC_CLOCK_CONFIG_HSI_32MHZ]);
}

volatile uint64_t a=0,b=0;
void task1(){
    a=5;
    while(1){
        if(a>9999) a=0;
        a++;
    }
}

void task2(){
    b=9;
    while(1){
        if(b>9999) b=0;
        b++;
    }
}

int main(){
    rcc_setup();
    zrtos_init();

    //  Task Creation testing
    zrtos_create_task(task1,"Task 1",512,3);
    zrtos_create_task(task2,"Task 2",512,3);

    zrtos_tasks_start();

    while(1){

    }

    return 0;
}