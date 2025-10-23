INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"

SECTION "Physics System Code", ROM0

physics_update::
    ld hl, physics_update_one_entity
    call man_entity_controllable

    ld a, CMP_MASK_PHYSICS
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

physics_update_one_entity::
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


