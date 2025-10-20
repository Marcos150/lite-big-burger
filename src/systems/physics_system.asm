INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"

SECTION "Physics System Code", ROM0

physics_update::
    ld hl, physics_update_one_entity
    call man_entity_for_each
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
    ld l, e

    call process_accel

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
ret


