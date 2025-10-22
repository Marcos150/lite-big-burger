INCLUDE "hardware.inc"

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
    ld  a, $e1
    ldh [rNR12], a
    ld  a, $5a
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

stop_ch_4::
    ld  a, %01000000
    ldh [rNR44], a
ret