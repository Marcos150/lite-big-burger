INCLUDE "constants.inc"
INCLUDE "managers/entity_manager.inc"

SECTION "Collision Data", WRAM0
bbox_prota: ds 4
bbox_other: ds 4
prota_y: ds 1
touching_tile_l::  ds 1
touching_tile_r::  ds 1
touching_tile_dl::  ds 1
touching_tile_dr::  ds 1
touching_tile_ddl::  ds 1
touching_tile_ddr::  ds 1

collided_entity_type: ds 1

SECTION "Collision System", ROM0

collision_init::
    ld hl, bbox_prota + 1

    ;; Height
    ld [hl], SPRITE_HEIGHT

    ;; Width
    inc hl
    inc hl
    ld [hl], SPRITE_WIDTH

    ld hl, touching_tile_l
    xor a
    REPT collided_entity_type - prota_y
        ld [hl+], a
    ENDR
ret

collision_update::
    ld hl, check_collision
    call man_entity_controllable

    ld hl, check_tile
jp man_entity_controllable

wait_until_VRAM_readable:
    ld hl, rSTAT
    .wait
        bit 1, [hl]
        jr nz, .wait
ret


check_tile:
    ld h, CMP_SPRITE_H
    ld l, e
    call get_address_of_tile_being_touched
 
    push hl
    call wait_until_VRAM_readable
    pop hl

    ld a, [hl+]
    ld [touching_tile_l], a
    ld a, [hl]
    ld [touching_tile_r], a

    ld bc, $0020
    add hl, bc

    push hl
    call wait_until_VRAM_readable
    pop hl

    ld a, [hl]
    ld [touching_tile_dr], a
    dec hl
    ld a, [hl]
    ld [touching_tile_dl], a
 
    add hl, bc

    push hl
    call wait_until_VRAM_readable
    pop hl

    ld a, [hl+]
    ld [touching_tile_ddl], a
    ld a, [hl]
    ld [touching_tile_ddr], a
ret

;; INPUT:
;; DE: Prota entity address
check_collision:
    ld d, CMP_SPRITE_H
    ld a, [de]
    ld [prota_y], a
    ld d, CMP_INFO_H

    ;; Checks if floor underneath or on ladders to stop entity then
    ld hl, touching_tile_ddl
    call check_if_touching_floor
    jr z, .stop_entity
    inc hl
    call check_if_touching_floor
    jr z, .stop_entity

    ld hl, touching_tile_dl
    call check_if_touching_ladders
    jr nz, .bbox

    .stop_entity
    ld d, CMP_PHYSICS_H
    ld e, CMP_PHYSICS_VX
    xor a
    ld [de], a

    ld [has_jumped], a

    ld e, CMP_PHYSICS_VY
    ld a, [de]
    cp MAX_SPEED
    jr nz, .reduce_accel

    ld d, CMP_SPRITE_H
    ld a, [de]
    dec a
    dec a
    ld [de], a
    
    .reduce_accel
    ld d, CMP_PHYSICS_H
    ld a, -1
    ld [de], a
    
    .bbox:
    ld d, CMP_SPRITE_H
    ld hl, bbox_prota

    ;; ASSUMES FIRST BYTE IS Y ANS SECOND IS X
    assert CMP_SPRITE_Y == 0, "Y attribute is not the first one of sprite component. Y value: {CMP_SPRITE_Y}"
    assert CMP_SPRITE_X == 1, "X attribute is not the second one of sprite component. X value: {CMP_SPRITE_X}"

    ;; Store in RAM prota bbox value
    ld a, [de]
    ld [hl+], a
    inc hl
    inc de
    ld a, [de]
    ld [hl], a

    ld hl, check_collision_prota
    xor a ;; We clear a first to not use filters
    ;; If we want to use a filter we can do [ld a, CMP_MASK_INGREDIENT]
jp man_entity_for_each_filtered


;; INPUT:
;; DE: Other entity address
check_collision_prota:
    ld b, SPRITE_HEIGHT
    ld c, SPRITE_WIDTH
    ld a, CMP_BIT_CONTROLLABLE
    ld [collided_entity_type], a
    ld a, [de]

    bit CMP_BIT_HAZARD, a
    jr z, .check_if_ingredient

    ;; Collides with enemy or hazard
    ld b, ENEMY_HEIGHT
    ld c, ENEMY_WIDTH
    ld a, CMP_BIT_HAZARD
    ld [collided_entity_type], a
    jr .detect

    .check_if_ingredient
    bit CMP_BIT_INGREDIENT, a
    jr z, .detect

    ;; Collides with ingredient
    ld b, SPRITE_HEIGHT_2_SPRITES
    ld c, SPRITE_WIDTH_2_SPRITES
    ld a, CMP_BIT_INGREDIENT
    ld [collided_entity_type], a

    .detect
    ld d, CMP_SPRITE_H
    ld hl, bbox_other

    ;; Y and height
    ld a, [de]
    ld [hl+], a
    ld a, b
    ld [hl], a

    ;; X and width
    push de
    inc de
    inc hl
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld [hl], c

    ld de, bbox_prota
    ld hl, bbox_other
    call are_boxes_colliding

    pop de
    ret nc

    ld a, [collided_entity_type]
    cp CMP_BIT_HAZARD
    jr nz, .check_ingredient_col

    ld a, [wPlayerInvincibilityTimer]
    or a
    ret nz

    jr player_hit_hazard

    .check_ingredient_col
    cp CMP_BIT_INGREDIENT
    jr z, ingredient_col ;; Collides with ingredient
ret

player_hit_hazard::
    call start_sound
    ld a, PLAYER_INVINCIBILITY_FRAMES
    ld [wPlayerInvincibilityTimer], a

    ld a, [wPlayerLives]
    dec a
    ld [wPlayerLives], a
    
    ;; --- INICIO DE LA MODIFICACIÓN ---
    cp 0
    jr nz, .update_hud ; Si no es 0, solo actualiza el HUD

    ; Si vidas == 0, avisa a game_scene
    ld a, 1
    ld [wPlayerIsDead], a
    ret ; Salir, no reiniciar al jugador
    
.update_hud:
    ;; --- FIN DE LA MODIFICACIÓN ---

    ld hl, reset_player_state
    call man_entity_controllable
    
    call stop_ch_4
    call sc_game_update_hud

    ret

ingredient_col:
    ld h, CMP_SPRITE_H
    ld l, e

    ;; Check that prota is on the same "y" as ingredient 
    ld a, [prota_y]
    ld c, a
    ld a, [hl]
    cp c
    ret nz

    ;; Check that ingredient is not already falling
    ld h, CMP_INFO_H
    bit CMP_BIT_PHYSICS, [hl]
    ret nz

    call falling_sound
    set CMP_BIT_PHYSICS, [hl]

    ;; --- Add points for ingredient ---
    ld bc, POINTS_PER_INGREDIENT
    call sc_game_add_score
    call sc_game_update_hud

    ;; --- Check for order complete ---
    ld hl, wOrderProgress
    inc [hl]
    ld a, [hl]
    cp INGREDIENTS_PER_ORDER
    ret nz

    ;; --- Grant bonus and reset counter ---
    xor a
    ld [hl], a
    ld bc, POINTS_PER_ORDER_BONUS
    call sc_game_add_score
    jp sc_game_update_hud

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Checks if two integral intervals overlap in one dimension
;; It receives the addresses of 2 intervals in memory
;; in HL and DE:
;;
;; Address |HL| +1| |DE| +1|
;; Values [p1][w1] ......[p2][w2]
;;
;; Returns Carry Flag (C=0, NC) when NOT-Colliding,
;; and (C=1, C) when overlapping.
;;
;; :inbox_tray: INPUT:
;; HL: Address of Interval 1 (p1, w1)
;; DE: Address of Interval 2 (p2, w2)
;; :back: OUTPUT:
;; Carry: { NC: No overlap }, { C: Overlap }
;;
are_intervals_overlapping:
    ;; B = [HL] + [HL + 1] = p1 + w1
    ld a, [hl+]
    ld b, [hl]
    add a, b
    ld b, a

    ;; a = p2
    ld a, [de]

    ;; Return hl back to original address
    dec hl

    ;; p2 > p1 + w1 ?
    cp a, b
    ret nc ;; Return if no overlap

    ;; B = [DE] + [DE + 1] = p2 + w2
    ld b, a
    inc de
    ld a, [de]
    add a, b
    ld b, a

    ;; a = p1
    ld a, [hl]

    ;; Return de back to original address
    dec de

    ;; p1 > p2 + w2 ?
    cp a, b
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gets the Address in VRAM of the tile the entity is touching.
;; An entity touches a tile if it is placed in the same
;; region in the screen (they both overlap).
;; As entity is placed in pixel coordinates, this routine
;; has to convert pixel coordinates to tiles coordinates.
;; Each tile is 8x8 pixels. It also takes into account the
;; Game Boy visible screen area:
;; - Horizontal: pixels 8-167 visible (0-7 off-screen left)
;; - Vertical: pixels 16-159 visible (0-15 off-screen top)
;; - A sprite at (8,16) appears at screen top-left corner.
;;
;; Receives the address of the sprite component of an
;; entity in HL:
;;
;; Address: |HL| +1| +2| +3|
;; Value: [ y][ x][id][at]
;;
;; Example: Sprite at (24, 32)
;; TX = (24-8)/8 = 2
;; TY = (32-16)/8 = 2
;; Address = $9800 + 2*32 + 2 = $9842
;;
;; 📥 INPUT:
;; HL: Address of the Sprite Component
;; 🔙 OUTPUT;
;; HL: VRAM Address of the tile the sprite is touching
;; DESTROYS: A, BC, DE
;:
get_address_of_tile_being_touched::
    ;; Y
    ld a, [hl+]
    call convert_y_to_ty
    ld b, a

    ;; X
    ld a, [hl]
    call convert_x_to_tx

    ld l, b
jr calculate_address_from_tx_and_ty

;; 1. Convert Y to TY, and X to TX
;; 2. Calculate the VRAM address using TX and TY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts a value in pixel coordinates to VRAM tilemap
;; coordinates. The value is a sprite X-coordinate
;; and takes into account the non-visible 8 pixels
;; on the left of the screen.
;;
;; 📥 INPUT:
;; A: Sprite X-coordinate value
;; 🔙 OUTPUT:
;; A: Associated VRAM Tilemap TX-coordinate value
;:
convert_x_to_tx:
    ;; For the 8 non-visible pixels
    sub a, 8

    ;; a = a/8 (8 pixels per tile)
    srl a
    srl a
    srl a
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts a value in pixel coordinates to VRAM tilemap
;; coordinates. The value is a sprite Y-coordinate
;; and takes into account the non-visible 16 pixels
;; on the upper side of the screen.
;;
;; 📥 INPUT:
;; A: Sprite Y-coordinate value
;; 🔙 OUTPUT:
;; A: Associated VRAM Tilemap TY-coordinate value
;:
convert_y_to_ty:
    ;; For the 16 non-visible pixels
    sub a, 16

    ;; a = a/8 (8 pixels per tile)
    srl a
    srl a
    srl a
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculates an VRAM Tilemap Address from itx tile
;; coordinates (TX, TY). The tilemap is 32x32, and
;; address $9800 is assumed as the address of tile (0,0)
;; in tile coordinates.
;;
;; 📥 INPUT:
;; L: TY coordinate
;; A: TX coordinate
;; 🔙 OUTPUT:
;; HL: Address where the (TX, TY) tile is stored
;: DESTROYS: A, BC, DE 
;;
calculate_address_from_tx_and_ty:
    ;; de = $9800 + A (TX)
    ld e, a
    ld d, $98

    ;; for every TY add $0020
    ld bc, $0020
    xor a
    cp l
    .for:
        jr z, .next
        call add_de_bc
        dec l
    jr .for

    .next:
    ld h, d
    ld l, e
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Checks if two Axis Aligned Bounding Boxes (AABB) are
;; colliding.
;; 1. First, checks if they collide on the Y axis
;; 2. Then checks the X axis, only if Y intervals overlap
;;
;; Receives in DE and HL the addresses of two AABBs:
;; --AABB 1-- --AABB 2--
;; Address |HL| +1| +2| +3| |DE| +1| +2| +3|
;; Values [y1][h1][x1][w1] ....[y2][h2][x2][w2]
;;
;; Returns Carry Flag (C=0, NC) when NOT colliding,
;; and (C=1, C) when colliding.
;;
;; :inbox_tray: INPUT:
;; HL: Address of AABB 1
;; DE: Pointer of AABB 2
;; :back: OUTPUT:
;; Carry: { NC: Not colliding } { C: colliding }
;;
are_boxes_colliding:
    call are_intervals_overlapping
    ret nc

    inc de
    inc de
    inc hl
    inc hl
jr are_intervals_overlapping
;; No hace falta ret, al hacer jr el ret de are_intervals_overlapping ya vuelve a donde deberia

reset_player_state:
    ld h, CMP_PHYSICS_H
    ld l, e
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

    ld h, CMP_SPRITE_H
    ld l, e
    ld a, $60
    ld [hl+], a
    ld [hl], $34
    ret