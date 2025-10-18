INCLUDE "constants.inc"
INCLUDE "managers/entity_manager.inc"

DEF SPEED equ 1

SECTION "MovementData", WRAM0

has_moved_to_sides: ds 1

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

check_prota_movement:
    call check_if_controllable
    ret z

    ld d, CMP_SPRITE_H
    call read_input

    ; Guardamos el estado del input para comprobarlo al final.
    push bc
    push de
    call check_movement
    pop de
    pop bc

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
    call check_if_touching_stairs
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

;; Assumes stairs tile ids range is $1F - $25
;; INPUT: HL: Starting address of tile pair to check
;; RETURNS: Flag Z if touching, NZ otherwise
;; DESTROYS: AF, C, HL
check_if_touching_stairs::
    ld c, 2
    .check_stairs:
        ld a, [hl+]
        cp $1F
        ret c ;; Rets if < 1F
        cp $26
        ret nc ;; Rets if > $25
        dec c
        ret z
    jr .check_stairs

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
        jr nc, .check_stair_floor ;; Checks for stair with floor if > $1E
    jr .is_floor

    .check_stair_floor:
        cp $21
        ret c ;; Rets if < 21
        cp $26
        ret nc ;; Rets if > $25
    
    .is_floor:
    cp a
ret

move_u:
    ld hl, touching_tile_dl
    call check_if_touching_stairs
    jr z, .move

    ld hl, touching_tile_ddl
    call check_if_touching_stairs
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
    ld hl, touching_tile_dl
    call check_if_touching_stairs
    jr z, .move

    ld hl, touching_tile_ddl
    call check_if_touching_stairs
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
    push de
    ld d, CMP_PHYSICS_H
    ld e, CMP_PHYSICS_VY
    ld a, [de]
    cp MAX_SPEED + 1
    pop de
    ret c
.move:
    ld a, [de]
    call get_closest_divisible_by_8
    inc a
    ld [de], a

    inc de
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
    ld hl, has_moved_to_sides
    ld [hl], 1
.no_platform:
    ret

move_l:
    push de
    ld d, CMP_PHYSICS_H
    ld e, CMP_PHYSICS_VY
    ld a, [de]
    cp MAX_SPEED + 1
    pop de
    ret c

.move:
    ld a, [de]
    call get_closest_divisible_by_8
    inc a
    ld [de], a

    inc de
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
    ld hl, has_moved_to_sides
    ld [hl], 1
.no_platform:
    ret