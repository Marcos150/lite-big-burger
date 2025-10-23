INCLUDE "constants.inc"

SECTION "Sounds", ROM0

;; RETURNS: NZ if playing sound on channel 1, Z otherwise
is_playing_sound_ch1:
    ld a, [rNR52]
    bit 0, a
ret

jump_sound::
    ;; Jump does not work as intended, and executes twice per jump
    ;; This is to avoid playing the sound 2 times
    call is_playing_sound_ch1
    ret nz

    ld  a, $16
    ldh [rNR10], a
    ld  a, $40
    ldh [rNR11], a
    ld  a, $E1
    ldh [rNR12], a
    ld  a, $5A
    ldh [rNR13], a
    ld  a, $84
    ldh [rNR14], a
ret

death_sound::
    ld  a, $00
    ldh [rNR41], a
    ld  a, $E7
    ldh [rNR42], a
    ld  a, $24
    ldh [rNR43], a
    ld  a, %10000000
    ldh [rNR44], a
ret

falling_sound::
    ld  a, $7E
    ldh [rNR10], a
    ld  a, $08
    ldh [rNR11], a
    ld  a, $C5
    ldh [rNR12], a
    ld  a, $72
    ldh [rNR13], a
    ld  a, $85
    ldh [rNR14], a
ret

start_sound::
    ld  a, $00
    ldh [rNR10], a
    ld  a, $81
    ldh [rNR11], a
    ld  a, $F1
    ldh [rNR12], a
    ld  a, $D2
    ldh [rNR13], a
    ld  a, %11000110
    ldh [rNR14], a
ret

life_sound::
    ld  a, $35
    ldh [rNR10], a
    ld  a, $01
    ldh [rNR11], a
    ld  a, $CF
    ldh [rNR12], a
    ld  a, $03
    ldh [rNR13], a
    ld  a, $85
    ldh [rNR14], a
ret

stop_ch_4::
    ld  a, %01000000
    ldh [rNR44], a
ret