SECTION "Movement Variables", WRAM0

frameCounter:: db
animation_frame_counter:: db ; Correcto, los '::' la hacen global.
def FRAME_LIMITER equ 4

SECTION "Entry point", ROM0[$150]

main::
    xor a
    ld [frameCounter], a
    ld [animation_frame_counter], a 

    call sc_game_init
.loop:
    ld e, 2
    call wait_vblank_ntimes

    ; -- Incrementamos el contador de animación SIEMPRE --
    ld hl, animation_frame_counter
    inc [hl]
    inc [hl]
    inc [hl]

    call render_update
    call movement_update
    call physics_update
    call collision_update

.skip
    jr .loop