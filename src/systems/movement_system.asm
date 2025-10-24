INCLUDE "constants.inc"
INCLUDE "managers/entity_manager.inc"

SECTION "MovementData", WRAM0

has_moved_to_sides: ds 1
has_jumped:: ds 1
ing_movement_count:: ds 1

; =============================================================================
; == DEFINICIÓN DE TILES Y ANIMACIÓN
; =============================================================================
DEF LADDER_TILE         equ $96     ; Tile del personaje en la escalera.
DEF PROTA_STATIC_TILE   equ $8C     ; Tile 1 de caminar y tile de REPOSO.
DEF PROTA_WALK_TILE     equ $8E     ; Tile 1 de caminar y tile de REPOSO.
DEF PROTA_WALK_TILE_2   equ $90     ; Tile 2 del personaje al caminar.
DEF PROTA_JUMP_TILE     equ $92

DEF LADDER_ANIM_SPEED   equ 2       ; Velocidad de la animación de la escalera.
DEF WALK_ANIM_SPEED     equ 2       ; Velocidad de la animación al caminar.

DEF ING_MOVEMENT_DELAY  equ 6
; =============================================================================

SECTION "Movement System", ROM0

movement_init::
    ld a, $FF
    ld [ing_movement_count], a
ret

movement_update::
    ld hl, move_routine
    call man_entity_controllable
ret

ingredient_movement_update::
    ld a, [ing_movement_count]
    cp 0
    jr z, .run_movement_logic

    dec a
    ld [ing_movement_count], a
ret

.run_movement_logic
    ld a, ING_MOVEMENT_DELAY
    ld [ing_movement_count], a

    ld hl, ing_move_routine
    ld a, CMP_MASK_INGREDIENT
    call man_entity_for_each_filtered
ret

move_routine:
    ld a, [has_jumped]
    cp 1
    ret z

    ld d, CMP_SPRITE_H
    call read_input

    ; Guardamos el estado del input para comprobarlo al final.
    push bc
    push de
    call check_movement
    pop de
    pop bc

    ; Guardamos el estado del input para comprobarlo al final.
    push de
    call check_jump
    pop de

    ; Lógica de reposo (idle)
    ld a, b
    and (BUTTON_UP | BUTTON_DOWN | BUTTON_LEFT | BUTTON_RIGHT)
    ret nz                   ; Si se pulsó algo, las funciones de `move` ya gestionaron el tile.

    inc de                          ; Apuntar a X
    ld a, [de]                      ; Cargar la posición X en A
    dec de                          ; Restaurar DE (vuelve a apuntar a Y)
    ld h, d
    ld l, e
    inc hl                          ; Apunta a la Posición X
    inc hl                          ; Apunta al byte del Tile

    push hl
    ld hl, touching_tile_dl
    call check_if_touching_ladders
    pop hl
    jr z, .set_ladder_idle_frame

    .idle:
    ; No estamos en una escalera, poner el frame de reposo normal.
    ld [hl], PROTA_STATIC_TILE
    ret                        ; Hemos terminado.

.set_ladder_idle_frame:
    ; Sí estamos en una escalera, poner el frame de escalera.
    ld a, LADDER_TILE               ; Cargar el tile de escalera ($96).
    ld [hl], a
ret

check_movement:
    ld hl, has_moved_to_sides
    ld [hl], 0

    ld a, b
    and BUTTON_RIGHT
    call nz, move_r

    ld a, [has_moved_to_sides]
    cp 0
    ret nz
.no_r:
    ld a, b
    and BUTTON_LEFT
    call nz, move_l

    ld a, [has_moved_to_sides]
    cp 0
    ret nz
.no_l:
    ld a, b
    and BUTTON_UP
    jp nz, move_u
.no_u:
    ld a, b
    and BUTTON_DOWN
    jp nz, move_d
.no_d:
ret

check_jump:
    ld a, b
    and BUTTON_A
    ret z

    ld hl, touching_tile_dl
    call check_if_touching_ladders
    ret z

    ld a, [has_jumped]
    cp 1
    ret z

    .jump
    call jump_sound

    ld d, CMP_PHYSICS_H
    ld e, CMP_PHYSICS_AY
    ld a, JUMP_ACCEL
    ld [de], a
    ld e, CMP_PHYSICS_VY
    ld a, JUMP_SPEED
    ld [de], a

    ld a, 1
    ld [has_jumped], a

    ld d, CMP_SPRITE_H
    ld e, CMP_SPRITE_TILE
    ld a, PROTA_JUMP_TILE
    ld [de], a
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
    ld h, CMP_SPRITE_H
    ld l, CMP_SPRITE_TILE
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

;; Assumes ladders tile ids range is $1F - $25
;; INPUT: HL: Starting address of tile pair to check
;; RETURNS: Flag Z if touching, NZ otherwise
;; DESTROYS: AF, C, HL
check_if_touching_ladders::
    ld c, 2
    .check_ladders:
        ld a, [hl+]
        cp $1F
        ret c ;; Rets if < 1F
        cp $26
        ret nc ;; Rets if > $25
        dec c
        ret z
    jr .check_ladders

;; Assumes floor tile ids range is $1C - $1E and $21-$25
;; INPUT: HL: Address of the tile to check
;; RETURNS: Flag Z if touching, NZ otherwise
;; DESTROYS: AF, C, HL
check_if_touching_floor::
    .check_floor:
        ld a, [hl]
        cp $1C
        ret c ;; Rets if < 1C
        cp $1F
        jr nc, .check_ladder_floor ;; Checks for ladder with floor if > $1E
    jr .is_floor

    .check_ladder_floor:
        cp $21
        ret c ;; Rets if < 21
        cp $26
        ret nc ;; Rets if > $25
    
    .is_floor:
    cp a
ret

move_u:
    ld hl, touching_tile_dl
    call check_if_touching_ladders
    jr nz, .no_ladder
.move:
    ld a, [de]
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
    ld hl, touching_tile_ddl
    call check_if_touching_ladders
    jr nz, .no_ladder
.move:
    ld a, [de]
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
    ld d, CMP_PHYSICS_H
    ld e, CMP_PHYSICS_VY
    ld a, [de]
    cp MAX_SPEED + 1
    ret c
.move:
    call correct_position

    ld l, CMP_SPRITE_X
    ld a, [current_level]
    cp LEVEL2
    jr z, .level2

    .level1
    ld a, [hl]
    cp RIGHT_BORDER_LEVEL1
    jr z, .no_platform
    jr .physics

    .level2
    ld a, [hl]
    cp RIGHT_BORDER_LEVEL2
    jr z, .no_platform

    .physics
    ld e, CMP_PHYSICS_VX
    ld a, [de]
    ld a, SPEED
    ld [de], a

    ld l, CMP_SPRITE_PROPS
    ld a, [hl]
    or SPRITE_ATTR_FLIP_X
    ld [hl], a
    call animate_walk
    ld hl, has_moved_to_sides
    ld [hl], 1
.no_platform:
    ret

move_l:
    ld d, CMP_PHYSICS_H
    ld e, CMP_PHYSICS_VY
    ld a, [de]
    cp MAX_SPEED + 1
    ret c

.move:
    call correct_position

    ld l, CMP_SPRITE_X
    ld a, [hl]
    cp LEFT_BORDER
    jr z, .no_platform

    ld e, CMP_PHYSICS_VX
    ld a, [de]
    ld a, -SPEED
    ld [de], a

    ld l, CMP_SPRITE_PROPS
    ld a, [hl]
    and %11011111
    ld [hl], a
    call animate_walk
    ld hl, has_moved_to_sides
    ld [hl], 1
.no_platform:
    ret

correct_position:
    ld h, CMP_SPRITE_H
    ld l, CMP_SPRITE_Y
    ld a, [hl]
    call get_closest_divisible_by_8
    inc a
    ld [hl], a
ret


ing_move_routine:
    ld d, CMP_SPRITE_H
    
    ld a, [de]
    cp $83
    jr nc, .conveyor_move

    inc de
    ld a, [de]
    cp LEFT_BORDER
    jr c, .left_tube_move

    ld a, [current_level]
    cp LEVEL2
    ld a, [de]
    jr z, .level2

    .level1
    cp RIGHT_BORDER_LEVEL1 - 7
    jr nc, .rigth_tuve_move

    .level2
    cp RIGHT_BORDER_LEVEL2 - 7
    jr nc, .rigth_tuve_move

    .ing_moved:
ret

.left_tube_move:
    add a, SPEED
    ld [de], a
    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    add a, SPEED
    ld [de], a

    jr .ing_moved

 .rigth_tuve_move:
    sub a, SPEED
    ld [de], a
    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    sub a, SPEED
    ld [de], a

    jr .ing_moved

.conveyor_move:
    ld d, CMP_INFO_H
    ld a, [de]
    bit CMP_BIT_PHYSICS, a
    jr z, .move

    ;; Removes physics bit
    res CMP_BIT_PHYSICS, a
    ld [de], a
    call stop_ch_1

    .move
    ld d, CMP_SPRITE_H
    inc de
    ld a, [de]
    add a, SPEED
    ld [de], a
    inc e
    inc e
    inc e
    inc e
    ld a, [de]
    add a, SPEED
    ld [de], a


    jr .ing_moved