SECTION "Physics System Code", ROM0

physics_update::
    ld hl, physics_update_one_entity ;; HL = Function to be executed by every entity 
    call man_entity_for_each ;; Processes entities with the specified function
ret

physics_update_one_entity::
    ld h, CMP_PHYSICS_H
    ld d, CMP_SPRITE_H
    ld l, e
    ;; ASSUMES FIRST BYTE => Y
    
    .y_plus_vY
    ld a, [de]
    add [hl] ;; A = Y + VY
    ld [de], a

    ;; ASSUMES SECOND BYTE => X
    inc hl
    inc de

    .x_plus_vX
    ld a, [de]
    add [hl] ;; A = Y + VY
    ld [de], a
ret
