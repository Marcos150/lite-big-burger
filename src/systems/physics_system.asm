INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"

SECTION "Physics System Code", ROM0

def KNIFE_SPRITE equ $CE
def OIL_SPRITE equ $CC
def OBJ_Y_FLIP equ (1 << 6)  ; %01000000
def OBJ_X_FLIP equ (1 << 5)  ; %00100000

physics_update::
    ld hl, physics_update_one_entity
    call man_entity_for_each
    ld hl, confine_mauricio
    call man_entity_controllable
    ld hl, hazard_routine
    ld a, CMP_MASK_HAZARD
    call man_entity_for_each_filtered
ret

process_accel:
    ld bc, CMP_PHYSICS_AY
    add hl, bc
    ld a, [hl]

    cp MAX_ACCEL
    jr z, .add_accel
    inc a
    ld [hl], a

    .add_accel:
    ld c, a ;; C = Current accel
    push bc
    ld bc, CMP_PHYSICS_VY - CMP_PHYSICS_AY
    add hl, bc
    ld a, [hl] ;; A = Current speed
    pop bc

    cp MAX_SPEED
    ret z
    
    add a, c
    ld [hl], a
ret

;;Cambio: Ahora solo las entidades afectadas por la gravedad son actualizadas
physics_update_one_entity::
    ;;;;;;;;;;;;;;;;;;;;;;;;
    ld a, [de]
    and CMP_MASK_PHYSICS
    cp CMP_MASK_PHYSICS
    jr nz, .move_ingredient
    ;;;;;;;;;;;;;;;;;;;;;;;;

    ld h, CMP_PHYSICS_H
    ld d, CMP_SPRITE_H
    ld b, CMP_INFO_H
    ld l, e
    ld c, e

    push bc
    call process_accel
    pop bc

    ;; ASSUMES FIRST BYTE => Y
    .y_plus_vY
    ld a, [de]
    add [hl]
    ld [de], a

    ;; ASSUMES SECOND BYTE => X
    inc hl
    inc de

    .x_plus_vX
    ld a, [de]
    add [hl]
    ld [de], a

    ld a, [bc]
    and CMP_MASK_2_SPRITES
    ret z

    .sprite2
    dec hl
    ;; Sprite 2 Y
    ld a, CMP_SPRITE_Y_2 - CMP_SPRITE_X
    add a, e
    ld e, a
    ld a, [de] ; A = Sprite 2 Y
    add a, [hl]
    ld [de], a

    ;; Sprite 2 X
    inc hl
    inc de
    ld a, [de]
    add a, [hl]
    ld [de], a
ret


.move_ingredient:
    call ingredient_movement_update
ret

confine_mauricio::
    ld d, CMP_SPRITE_H
    inc de
    ld a, [de]
    cp LEFT_BORDER
    jr c, .reposition_left

    ld a, [current_level]
    cp LEVEL2
    ld a, [de]
    jr z, .level2

    .level1
    cp RIGHT_BORDER_LEVEL1
    jr nc, .reposition_right_level1
    ret

    .level2
    cp RIGHT_BORDER_LEVEL2
    jr nc, .reposition_right_level2
ret

.reposition_left:
    ld a, LEFT_BORDER + 1
    ld [de], a
ret

.reposition_right_level1:
    ld a, RIGHT_BORDER_LEVEL1 - 1
    ld [de], a
ret

.reposition_right_level2:
    ld a, RIGHT_BORDER_LEVEL2 - 1
    ld [de], a
ret

hazard_routine::
    ld d, CMP_SPRITE_H
    inc de
    inc de
    ld a, [de]
    cp KNIFE_SPRITE
    ret nz

    .check_bounce:
        dec de
        ld a, [de]
        cp $12
        jr c, .bounce_left
        cp $56
        jr nc, .bounce_right

    .bounce_left:
        ld a, $13
        ld [de],a 
        ld d, CMP_PHYSICS_H
        inc de
        ld a, 2
        ld [de], a
        ret

    .bounce_right:
        ld a, $55
        ld [de],a 
        ld d, CMP_PHYSICS_H
        inc de
        ld a, $FD
        ld [de], a
        ret