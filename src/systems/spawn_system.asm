INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"

SECTION "Entity Buffer", WRAM0
; A 24-byte buffer to temporarily build a new entity
entity_build_buffer:
    DS 24

SECTION "Spawn Data", ROM0
ing_x:
    DB $01, $01, $01, $01, $60, $60, $60, $60
ing_x2:
    DB $01, $01, $01, $01, $90, $90, $90, $90

ing_y:
    DB $19, $31, $49, $61, $19, $31, $49, $61

hazards_x:
    DB $10, $22, $37, $4E
hazards_x_end:

hazards_x_level2:
    DB $20, $38, $4B, $66, $78
hazards_x_end_level2:

def BASE_SPRITE_TILE equ $A2
export def KNIFE_SPRITE equ $CE
def OIL_SPRITE equ $CC

SECTION "Spawn System", ROM0

spawn_init::
    call create_hazards

    jr create_ingredients

spawn_update::
    ;; Re-spawns ingredients if 1 or less left
    ld a, [alive_ingredients]
    cp INGREDIENTS_UNTIL_RESPAWN + 1
    call c, create_ingredients

    ;; Re-spawns enemies
    ld a, [current_iteration]
    add a
    ld b, a ;; B = current iteration * 2
    ld a, [alive_hazards_and_enemies]
    ld c, a
    ld a, MAX_HAZARDS
    add a, b ;; Max hazards = MAX_HAZARDS + (current iteration * 2)
    cp c
    jr nc, create_hazards
ret

create_ingredients:
ld d, 1
    ld e, 1
    ld a, 0
    .for
        push de
        push af 
        call spawn_one_ingredient
        pop af
        pop de
        sla e
        sla d
        inc a
        cp 8
    jr nz, .for
ret

create_hazards:
    ld d, 0
    ld e, 1
    call spawn_one_hazard
    ld d, 1
    ld e, 1
    call spawn_one_hazard

    ld c, hazards_x_end - hazards_x
    ld hl, hazards_x
    ld a, [current_level]
    cp LEVEL1
    jr z, .spawn_oil

    ld c, hazards_x_end_level2 - hazards_x_level2
    ld hl, hazards_x_level2
    
    .spawn_oil
    .for
        ld d, [hl]
        inc hl
        ld e, 0
        push bc
        push hl
        call spawn_one_hazard
        pop hl
        pop bc
    dec c
    jr nz, .for
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SPAWN ONE INGREDIENT
;; INPUT:
;; D: Position bits (ex., %00001000 for index 3)
;; E: Sprite bits (ex., %00010000 for index 4)
;; DESTROYS:
;; A, B, C, D, E, HL
spawn_one_ingredient::
	push de
	ld a, d
	call find_first_set_bit_index

	ld e, b         	; Use the index as an offset
    ld d, 0 	        ; DE is now our 16-bit offset
    ld hl, ing_y
    add hl, de
    ld c, [hl]      ; Store Y-pos in C


    ld a, [current_level]
    cp LEVEL1
    jr z, .level1

    .level2
    ld hl, ing_x2
    jr .store_x

    .level1
    ld hl, ing_x

    .store_x
    add hl, de
    ld b, [hl]      ; Store X-pos in B

    pop de
    push bc

    ; We calculate: Tile ID = BASE_SPRITE_TILE + (B * 4)
    ld a, e
    call find_first_set_bit_index

    ld a, b         ; B has the index
    add a           ; A = index * 2
    add a           ; A = index * 4
    add BASE_SPRITE_TILE
    ld d, a         ; D = Base Tile ID

    pop bc
    ; We now have:
    ; D = Base Tile ID
    ; B = X-Position
    ; C = Y-Position

    ld hl, entity_build_buffer

    ; Write CMP_INFO (8 bytes)
    ld a, ENTITY_INGREDIENT_SPAWNING
    ld [hl+], a
    xor a           ; A = 0 (for all padding bytes)
    REPT 7
        ld [hl+], a
    ENDR

    ; Write CMP_SPRITE (8 bytes)
    ; Sprite 1
    ld a, c         ; Get Y-Pos
    ld [hl+], a
    ld a, b         ; Get X-Pos
    ld [hl+], a
    ld a, d         ; Get Base Tile ID
    ld [hl+], a
    ld a, %10000000 ; Get Attribute (Priority)
    ld [hl+], a

    ; Sprite 2
    ld a, c         ; Get Y-Pos
    ld [hl+], a
    ld a, b         ; Get X-Pos
    add 8           ; A = X + 8
    ld [hl+], a
    ld a, d         ; Get Base Tile ID
    add 2           ; A = Base Tile ID + 2
    ld [hl+], a
    ld a, %10000000        	; Get Attribute (0)
    ld [hl+], a
    
    ; Write CMP_PHYSICS (8 bytes)
    xor a
    REPT 8
        ld [hl+], a
    ENDR

    ld a, [alive_ingredients]
    inc a
    ld [alive_ingredients], a

    ; HL pointing to the start again
    ld hl, entity_build_buffer
    jp create_one_entity

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SPAWN ONE HAZARD
;; INPUT:
;; D: Position bits (10-58 for oil, 0 (Left) or 1 (Right) for knives)
;; E: Sprite bits (0 for oil and 1 for knives)
;; DESTROYS:
;; A, B, C, D, E, HL
spawn_one_hazard::
    ld a, HAZARD_RATIO
    ld hl, current_iteration
    add a, [hl] ;; ratio = HAZARD_RATIO + current_iteration
    ld b, a

    ld a, [rDIV]
    swap a
    cp b
    ret nc

    ld a, e
    or a ;; cp 0
    jr z, .define_oil

    .define_knife:
    ld b, KNIFE_SPRITE
    ld a, d
    or a ;; cp 0
    jr nz, .spawn_left
    .spawn_right:
    ld c, $58
    jr .spawn
    
    .spawn_left:
    ld c, LEFT_BORDER
    jr .spawn

    .define_oil:
    ld b, OIL_SPRITE
    ld c, d

    .spawn:
        ld hl, entity_build_buffer

        ; Write CMP_INFO (8 bytes)
        ld a, ENTITY_HAZARD_SPAWNING
        ld [hl+], a
        xor a           ; A = 0 (for all padding bytes)
        REPT 7
            ld [hl+], a
        ENDR

        ; Write CMP_SPRITE (8 bytes)
        ; Sprite 1
        xor a           ; Y-Pos = 0
        ld [hl+], a
        ld a, c         ; Get X-Pos
        ld [hl+], a
        ld a, b         ; Get Base Tile ID
        ld [hl+], a

        ; Attributes
        cp KNIFE_SPRITE
        jr nz, .skip_sprite_att

        ld a, c
        cp LEFT_BORDER
        jr nz, .flip_yx
        ld a, $40
        ld [hl+], a

        .flip_yx:
        ld a, $60
        ld [hl+], a
        jr .sec_sprite

        .skip_sprite_att:
        xor a           ; Get Attribute (None)
        ld [hl+], a

        ; Sprite 2
        .sec_sprite:
        xor a           ; Null
        REPT 4
            ld [hl+], a
        ENDR
        
        
        ; Write CMP_PHYSICS (8 bytes)
        ld a, 1
        ld [hl+], a
        ld a, b
        cp KNIFE_SPRITE
        jr nz, .skip_vel_x

        ld a, c
        cp LEFT_BORDER
        jr z, .vel_x_plus
        ld a, $FF
        ld [hl+], a
        jr .continue

        .vel_x_plus:
        ld a, 1
        ld [hl+], a
        jr .continue

        .skip_vel_x:
        xor a
        ld [hl+], a

        .continue:
        ld a, 1
        ld [hl+], a
        xor a
        REPT 5
            ld [hl+], a
        ENDR

        ld hl, alive_hazards_and_enemies
        inc [hl]

        ; HL pointing to the start again
        ld hl, entity_build_buffer
        jp create_one_entity