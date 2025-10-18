INCLUDE "managers/entity_manager.inc"

SECTION "Entity Buffer", WRAM0
; A 24-byte buffer to temporarily build a new entity
entity_build_buffer:
    DS 24

SECTION "Spawn Data", ROM0
ing_x:
    DB $01, $01, $01, $01, $60, $60, $60, $60

ing_y:
    DB $19, $31, $49, $61, $19, $31, $49, $61

def BASE_SPRITE_TILE equ $A2

SECTION "Spawn System", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SPAWN ONE INGREDIENT
;; INPUT:
;; D: Position bits (e.g., %00001000 for index 3)
;; E: Sprite bits (e.g., %00010000 for index 4)
;; HL: Address of the entity to modify (e.g., entity_array)
;; DESTROYS:
;; A, B, C, D, E, HL
spawn_one_ingredient:
	push de
	ld a, d
	call find_first_set_bit_index

	ld e, b         	; Use the index as an offset
    ld d, 0 	        ; DE is now our 16-bit offset
    ld hl, ing_y
    add hl, de
    ld c, [hl]      ; Store Y-pos in C

    ld hl, ing_x
    add hl, de
    ld b, [hl]      ; Store X-pos in B

    pop de
    push bc

    ; We calculate: Tile ID = BASE_SPRITE_TILE + (B * 4)
    ld a, e
    call find_first_set_bit_index

    ld a, b         ; B has the index
    sla a           ; A = index * 2
    sla a           ; A = index * 4
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
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a

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
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a

    ; HL pointing to the start again
    ld hl, entity_build_buffer
    call create_one_entity
ret