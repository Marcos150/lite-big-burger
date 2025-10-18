INCLUDE "constants.inc"

DEF SPEED equ 1

; =============================================================================
; == DEFINICIÓN DE TILES Y ANIMACIÓN
; =============================================================================
DEF LADDER_TILE         equ $96     ; Tile del personaje en la escalera.
DEF PROTA_STATIC_TILE   equ $8C     ; Tile 1 de caminar y tile de REPOSO.
DEF PROTA_WALK_TILE     equ $8E     ; Tile 1 de caminar y tile de REPOSO.
DEF PROTA_WALK_TILE_2   equ $90     ; Tile 2 del personaje al caminar.

DEF LADDER_ANIM_SPEED   equ 2       ; Velocidad de la animación de la escalera.
DEF WALK_ANIM_SPEED     equ 2       ; Velocidad de la animación al caminar.
; =============================================================================

SECTION "Movement System", ROM0

movement_update::
    ld hl, check_prota_movement
    call man_entity_for_each
    ret

check_prota_movement:
    call check_if_controllable
    ret z

    ld d, CMP_SPRITE_H
    call read_input

    ; Guardamos el estado del input para comprobarlo al final.
    push bc

    ld a, b
    and BUTTON_UP
    call nz, move_u
.no_u:
    ld a, b
    and BUTTON_DOWN
    call nz, move_d
.no_d:
    ld a, b
    and BUTTON_RIGHT
    call nz, move_r
.no_r:
    ld a, b
    and BUTTON_LEFT
    call nz, move_l
.no_l:
    pop bc ; Recuperamos el estado original del input.

.done:
    ret


; =============================================================================
; == Rutinas de Animación y Movimiento (SIN CAMBIOS)
; =============================================================================

animate_walk:
    push af
    push hl
    ld hl, animation_frame_counter
    ld a, [hl]
    bit WALK_ANIM_SPEED, a
    ld h, d
    ld l, e
    inc hl
    jr z, .set_frame_1
.set_frame_2:
    ld a, PROTA_WALK_TILE_2
    ld [hl], a
    jr .animation_done
.set_frame_1:
    ld a, PROTA_WALK_TILE
    ld [hl], a
.animation_done:
    pop hl
    pop af
    ret

animate_ladder_climb:
    push hl
    push de
    ld hl, animation_frame_counter
    ld a, [hl]
    bit LADDER_ANIM_SPEED, a
    ld h, d
    ld l, e
    inc hl
    inc hl
    inc hl
    ld a, [hl]
    jr z, .no_flip
.flip:
    or a, SPRITE_ATTR_FLIP_X
    ld [hl], a
    jr .climb_done
.no_flip:
    and a, %11011111
    ld [hl], a
.climb_done:
    pop de
    pop hl
    ret

move_u:
    inc de
    ld a, [de]
    dec de
    cp $24
    jr z, .move
    cp $44
    jr nz, .no_ladder
.move:
    ld a, [de]
    cp $19
    jr z, .no_ladder
    sub a, SPEED
    ld [de], a
    push de
    inc de
    inc de
    ld a, LADDER_TILE
    ld [de], a
    pop de
    call animate_ladder_climb
.no_ladder:
    ret

move_d:
    inc de
    ld a, [de]
    dec de
    cp $24
    jr z, .move
    cp $44
    jr nz, .no_ladder
.move:
    ld a, [de]
    cp $79
    jr z, .no_ladder
    add a, SPEED
    ld [de], a
    push de
    inc de
    inc de
    ld a, LADDER_TILE
    ld [de], a
    pop de
    call animate_ladder_climb
.no_ladder:
    ret
    
move_r:
    ld a, [de]
    inc de
    cp $79
    jr z, .move
    cp $61
    jr z, .move
    cp $49
    jr z, .move
    cp $31
    jr z, .move
    cp $19
    jr nz, .no_platform
.move:
    ld a, [de]
    cp $58
    jr z, .no_platform
    add a, SPEED
    ld [de], a
    push af
    push hl
    ld h, d
    ld l, e
    inc hl
    inc hl
    ld a, [hl]
    or SPRITE_ATTR_FLIP_X
    ld [hl], a
    pop hl
    pop af
    call animate_walk
.no_platform:
    ret

move_l:
    ld a, [de]
    inc de
    cp $79
    jr z, .move
    cp $61
    jr z, .move
    cp $49
    jr z, .move
    cp $31
    jr z, .move
    cp $19
    jr nz, .no_platform
.move:
    ld a, [de]
    cp $10
    jr z, .no_platform
    sub a, SPEED
    ld [de], a
    push af
    push hl
    ld h, d
    ld l, e
    inc hl
    inc hl
    ld a, [hl]
    and %11011111
    ld [hl], a
    pop hl
    pop af
    call animate_walk
.no_platform:
    ret