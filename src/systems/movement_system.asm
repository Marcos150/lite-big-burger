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
    ; Lógica de reposo (idle)
    pop bc ; Recuperamos el estado original del input.
    ld a, b
    and (BUTTON_UP | BUTTON_DOWN | BUTTON_LEFT | BUTTON_RIGHT)
    ret nz                   ; Si se pulsó algo, las funciones de `move` ya gestionaron el tile.

    push de                         ; Salvar DE (apunta a Y)
    inc de                          ; Apuntar a X
    ld a, [de]                      ; Cargar la posición X en A
    pop de                          ; Restaurar DE (vuelve a apuntar a Y)
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
;; RETURNS: Flag Z if touching, NZ otherwise
;; DESTROYS: AF, L
check_if_touching_stairs:
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