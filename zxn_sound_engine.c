#include <arch/zxn.h>
#include <z80.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "samples.h"

#pragma preproc_asm +

/* dma */

#define SAMPLE_COVOXPORT        0xffdf
#define SAMPLE_LOOP             D_WR5 | D_WR5_RESTART | D_WR5_CE_WAIT
#define SAMPLE_NOLOOP           D_WR5
#define SAMPLE_SCALER           12

typedef struct
{
    uint8_t disable_dma;
    uint8_t reset_dma;
    uint8_t reset_port_a;
    uint8_t timing_a_b;
    uint8_t wr0;
    void *source;
    uint16_t length;
    uint8_t wr1;
    uint8_t timing_a;
    uint8_t wr2;
    uint8_t wr2_scaler;
    uint8_t scaler;
    uint8_t wr4;
    void *dest;
    uint8_t wr5;
    uint8_t read_mask;
    uint8_t mask;
    uint8_t load;
    uint8_t force;
    uint8_t enable;
} dma_code_sample_t;


dma_code_sample_t dma_code_sample_io =
{
    .disable_dma = D_DISABLE_DMA,                               // r6-disable dma
    .reset_dma = 0xc3,                                          // r6-reset dma
    .reset_port_a = 0xc7,                                       // r6-reset port a timing
    .timing_a_b = 0xcb,                                         // r6-reset port b timing
    .wr0 = D_WR0 | D_WR0_X56_LEN | D_WR0_X34_A_START | D_WR0_TRANSFER_A_TO_B, // r0-transfer mode, a -> b
    .source = 0,                                                // r0-port a, start address
    .length = 8192,                                             // r0-block length
    .wr1 = D_WR1_X6_A_TIMING | D_WR1_A_IS_MEM_INC,              // 01010100 r1-port a address incrementing, variable timing
    .timing_a = D_WR1X6_A_CLEN_2,                               // r1-cycle length port b
    .wr2 = D_WR2_X6_B_TIMING | D_WR2_B_IS_IO_FIX,               // 01101000 r2-port b address fixed, variable timing
    .wr2_scaler = D_WR2X6_X5_PRESCALAR | D_WR2X6_B_CLEN_2,      // r2-cycle length port b 2t with pre-escaler
    .scaler = 8*SAMPLE_SCALER,                                  // r2-port b pre-escaler
    .wr4 = 0x80 | D_WR4_X23_B_START | D_WR4_BURST | 0x01,       // 11001101 r4-burst mode
    .dest = SAMPLE_COVOXPORT,                                   // r4-port b, start address
    .wr5 = SAMPLE_LOOP,                                         // r5-stop on end of block, rdy active low
    .read_mask = D_READ_MASK,                                   // 10111011 read mask follows
    .mask = D_RM_COUNTER,                                       // mask - read counter
    .load = D_LOAD,                                             // r6-load
    .force = 0xb3,                                              // r6-force ready
    .enable = D_ENABLE_DMA                                      // r6-enable dma
};


void dma_transfer_sample(void *source, uint16_t length, uint8_t scaler, int loop)
{
    dma_code_sample_io.source = source;
    dma_code_sample_io.length = length;
    dma_code_sample_io.scaler = scaler;
    dma_code_sample_io.wr5 = (loop ? SAMPLE_LOOP : SAMPLE_NOLOOP);
    dma_code_sample_io.dest = (void *)SAMPLE_COVOXPORT;

    z80_otir(&dma_code_sample_io, (uint8_t)&IO_DMA, sizeof(dma_code_sample_io));
}

/* sound */

#define MAX_CHANNELS    4

typedef struct
{
    void *start;
    void *end;
    int16_t len;
} sound_table_t;

static sound_table_t sound_table[] = {
    { sound0_start,  sound0_end, 0 },
    { sound1_start,  sound1_end, 0 },
    { sound2_start,  sound2_end, 0 },
    { sound3_start,  sound3_end, 0 },
    { sound4_start,  sound4_end, 0 },
    { sound5_start,  sound5_end, 0 },
    { sound6_start,  sound6_end, 0 },
    { sound7_start,  sound7_end, 0 },
    { sound8_start,  sound8_end, 0 },
    { sound9_start,  sound9_end, 0 },
};

#define CHUNKSZ 256

static int current_chunk = 0;
static int16_t current_chunk_len = 0;

static int16_t dma_counter = 0;

static int8_t ready_to_mix = 1;
static int8_t ready_to_play = 0;
static int8_t dma_ready = 1;

static uint8_t sound_buffer[CHUNKSZ*2];
static int16_t sound_buffer_len = 0;
static uint8_t *current_sound_buffer = NULL;

static uint16_t cur_pos[MAX_CHANNELS] = { 0, 0, 0, 0 };
static int8_t channels[MAX_CHANNELS] = { -1, -1, -1, -1 };

/* ------------------------------------------ */

static int8_t find_free_ch() {
    for ( int i = 0; i < MAX_CHANNELS; i++ ) {
        if ( channels[i] == -1 ) return i;
    }
    return -1;
}

/* ------------------------------------------ */

int8_t SoundPlay( int8_t id ) __z88dk_fastcall {
    int n, ch = -1;
    
    if ( !sound_table[ id ].start ) return -1;

    for ( n = 0; n < MAX_CHANNELS; n++ ) {
        if ( channels[ n ] == id ) return n;
        if ( ch == -1 && channels[ n ] == -1 ) ch = n;
    }

    if ( ch != -1 ) {
        channels[ ch ] = id;
        cur_pos[ ch ] = 0;
    }
    return ch;
}

void SoundStop( int8_t id ) __z88dk_fastcall {
    for ( int n = 0; n < MAX_CHANNELS; n++ ) {
        if ( id == -1 || channels[ n ] == id ) {
            channels[ n ] = -1;
            cur_pos[ n ] = 0;
        }
    }
    if ( id == -1 ) {
        memset( sound_buffer, '\0', sizeof( sound_buffer ) );
        sound_buffer_len = 0;
        ready_to_mix = 1;
        ready_to_play = 0;
        dma_ready = 1;
        dma_counter = current_chunk_len = 0;
    }
}

int8_t SoundIsPlaying( int8_t id ) __z88dk_fastcall {
    for ( int n = 0; n < MAX_CHANNELS; n++ ) if ( channels[ n ] == id ) return 1;
    return 0;
}

void SoundInit( void ) {
    current_sound_buffer = &sound_buffer[0];
    current_chunk = 0;
    for ( int i = 0; i < sizeof( sound_table ) / sizeof( sound_table[0] ); i++ ) sound_table[ i ].len = (uint16_t) sound_table[i].end - (uint16_t) sound_table[i].start;

    // Clear sound_buffer
    memset( sound_buffer, '\0', sizeof( sound_buffer ) );
}

void SoundExecute( void ) {

//        z80_outp(__IO_DMA_DATAGEAR, D_READ_MASK );                                   // 10111011 read mask follows
//        z80_outp(__IO_DMA_DATAGEAR, D_RM_COUNTER /*D_RM_STATUS*/ );                                         // mask - status
//        int16_t dma_counter = z80_inp(__IO_DMA_DATAGEAR ) +  z80_inp(__IO_DMA_DATAGEAR ) * 256; // mask - counter

    __asm
        di
        push af
        ld a, D_READ_MASK
        out (__IO_DMA_DATAGEAR), a
        ld a, D_RM_COUNTER
        out (__IO_DMA_DATAGEAR), a
        in a,(__IO_DMA_DATAGEAR)
        ld (_dma_counter),a
        in a,(__IO_DMA_DATAGEAR)
        ld (_dma_counter+1),a
        pop af
        ei
    __endasm;

    // Chunk complete
    if ( dma_counter == current_chunk_len ) {
        for ( int ii = 0; ii < MAX_CHANNELS; ii++ ) {
            if ( channels[ii] != -1 && cur_pos[ii] >= sound_table[ channels[ii] ].len ) {
                channels[ii] = -1;
                cur_pos[ii] = 0;
            }
        }
        current_chunk_len = 0;
        dma_ready = 1;
    }

    if ( ready_to_mix ) {
        uint16_t sample_length;
        uint16_t * cur_pos_ptr = cur_pos;
        int8_t * channels_ptr = channels;

        // Mix Channels
        int8_t ii = MAX_CHANNELS;
        while ( ii-- ) {
            if ( *channels_ptr != -1 && *cur_pos_ptr < ( sample_length = sound_table[ *channels_ptr ].len ) ) {
                uint8_t *sample_source = ((uint8_t *)sound_table[ *channels_ptr ].start ) + *cur_pos_ptr;
                uint16_t len = ( ( *cur_pos_ptr + CHUNKSZ ) > sample_length ) ? sample_length % CHUNKSZ : CHUNKSZ;
                uint8_t *p = current_sound_buffer;
                int16_t i = len;
                while ( i-- ) {
                    int16_t sample = *p - 128;
                    sample += *sample_source++ - 128;
                    if ( sample > 127 ) sample = 127;
                    if ( sample < -128 ) sample = -128;
                    *p++ = sample + 128;
                }

                if ( len > sound_buffer_len ) sound_buffer_len = len;

                *cur_pos_ptr += CHUNKSZ;

//                if ( *cur_pos_ptr >= sample_length ) {
//                    *cur_pos_ptr = 0;
//                    *channels_ptr = -1;
//                }
            }
            channels_ptr++;
            cur_pos_ptr++;
        }

        if ( sound_buffer_len ) {
            ready_to_mix = 0;
            ready_to_play = 1;
        }
    }

    if ( dma_ready && ready_to_play && sound_buffer_len > 0 ) {
        __asm
            di
        __endasm;

        dma_transfer_sample((void *)current_sound_buffer, sound_buffer_len, SAMPLE_SCALER*12, 0);

        __asm
            ei
        __endasm;

        current_sound_buffer = &sound_buffer[ current_chunk ? CHUNKSZ : 0 ];
        current_chunk ^= 1;

        current_chunk_len = sound_buffer_len;

        // Clear sound_buffer
        memset( current_sound_buffer, '\0', CHUNKSZ );

        sound_buffer_len = 0;

        dma_ready = 0;
        ready_to_play = 0;
        ready_to_mix = 1;
    }
}
