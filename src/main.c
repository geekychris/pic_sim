/*
 * PIC18F452 starter: "blink" + counter, sized for the MPLAB Simulator.
 *
 *  - PORTB is an 8-bit binary counter (watch it in the Variables/Watch view).
 *  - RD0 toggles every time the counter wraps.
 *  - Timer0 overflow drives the count via a high-priority interrupt.
 *  - glennFunction() drives pin RC2 and reads the pin back into a variable
 *    (glenn_value); it flips RC2 every time the counter wraps.
 */
#include <xc.h>
#include <stdint.h>

/* ---- Configuration bits (PIC18F452) ---- */
#pragma config OSC = HS        /* HS crystal oscillator */
#pragma config OSCS = OFF      /* Oscillator switch disabled */
#pragma config PWRT = ON       /* Power-up timer enabled */
#pragma config BOR = OFF       /* Brown-out reset disabled */
#pragma config WDT = OFF       /* Watchdog off (otherwise it resets the sim) */
#pragma config CCP2MUX = ON    /* CCP2 on RC1 */
#pragma config STVR = ON       /* Stack overflow resets */
#pragma config LVP = OFF       /* Low-voltage programming off (frees RB5) */

#define _XTAL_FREQ 4000000UL   /* 4 MHz -> 1 MIPS instruction clock */

volatile uint8_t  tick_count = 0;   /* bumped by the ISR */
volatile uint16_t wraps      = 0;   /* how many times PORTB rolled over */
volatile uint8_t  glenn_value = 0;  /* RC2 as read back by glennFunction() */

void __interrupt(high_priority) isr(void)
{
    if (INTCONbits.TMR0IF) {
        INTCONbits.TMR0IF = 0;
        tick_count++;
    }
}

static void init(void)
{
    TRISB = 0x00;               /* PORTB all outputs */
    TRISD = 0x00;               /* PORTD all outputs */
    LATB  = 0x00;
    LATD  = 0x00;

    /* Timer0: 8-bit, internal clock, 1:2 prescaler -> overflow every 512 cycles */
    T0CON = 0b11000000;         /* TMR0ON=1, T08BIT=1, T0CS=0, PSA=0, PS=000 */
    INTCONbits.TMR0IF = 0;
    INTCONbits.TMR0IE = 1;
    INTCONbits.GIE    = 1;
}

/*
 * glennFunction: set pin RC2 (chip pin 17 on the 40-pin DIP) to `level`,
 * then read the pin and return what it actually reads.
 *
 * Writes go to the LAT (output latch) register; reads come from the PORT
 * register, which samples the physical pin. On real hardware a heavily
 * loaded pin could read back differently from what was written.
 */
uint8_t glennFunction(uint8_t level)
{
    uint8_t pin_value;

    TRISCbits.TRISC2 = 0;               /* RC2 = output */
    LATCbits.LATC2   = level ? 1 : 0;   /* set the pin */
    NOP();                              /* let the pin settle before sampling */
    pin_value = PORTCbits.RC2;          /* read the pin into a C variable */

    return pin_value;
}

void main(void)
{
    uint8_t last = 0;

    init();

    glenn_value = glennFunction(1);     /* <- step into this; glenn_value == 1 */

    for (;;) {
        if (tick_count != last) {       /* <- good breakpoint spot */
            last = tick_count;
            LATB = last;
            if (last == 0) {
                wraps++;
                LATDbits.LATD0 ^= 1;
                glenn_value = glennFunction(!glenn_value);  /* flip RC2 */
            }
        }
    }
}
