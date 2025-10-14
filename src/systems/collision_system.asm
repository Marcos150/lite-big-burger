SECTION "Collision System Data", WRAM0

prota_y: ds 1
prota_x: ds 1

SECTION "Collision System Code", ROM0

collision_update::
    call get_prota_coords
    ld hl, prota_y
    ld [hl], b
    ld hl, prota_x
    ld [hl], c

    ld hl, check_win
    call man_entity_for_each
    ret

check_win:
    push de
    call check_if_prota
    pop de
    ret nz ;; If entity is main char, do nothing

    ;; BC = Prota Y,X
    ld hl, prota_y
    ld b, [hl]
    ld hl, prota_x
    ld c, [hl]

    ;; HA = Entity Y,X
    push de
    call load_y_to_a
    pop de
    ld h, a
    push hl
    call load_x_to_a
    pop hl

    
    cp a, c
    ret nz ;; No colisiona

    ld a, h
    cp a, b
    ret nz ;; No colisiona

    di
    halt

    ret