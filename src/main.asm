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
    call wait_vblank_start

    ; -- Incrementamos el contador de animación SIEMPRE --
    ld hl, animation_frame_counter
    inc [hl]

    ; -- Lógica del limitador de frames --
    ld a, [frameCounter]
    inc a
    ld [frameCounter], a
    cp FRAME_LIMITER
    jr nz, .skip

    xor a
    ld [frameCounter], a

    call movement_update
    call physics_update
    call render_update
    call collision_update

.skip
    jr .loop