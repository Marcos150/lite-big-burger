INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"

SECTION "Maurice Variables", WRAM0
mau_y:: dw    ; Dirección de memoria de Y de Maurice
mau_x:: dw    ; Dirección de memoria de X de Maurice

SECTION "Entity Manager Data", WRAM0[_WRAM]

sprite_components: DS MAX_ENTITIES*SPRITE_SIZE
sprite_components_end:
DEF sprite_components_size = sprite_components_end - sprite_components
EXPORT sprite_components_size

;; Throws error when assembling if components don't start at xx00 adress. Needed for DMA
;; Extracted from Game Boy Coding Adventure Early Access, page 230
assert low(sprite_components) == 0, "components must be 256-byte-aligned"

alive_entities: DS 1

entities: DS MAX_ENTITIES*ENTITY_SIZE

SECTION "Entity Manager Code", ROM0

;; Initialize Entity Manager
;; DESTROYS: AF, B, HL
man_entity_init::
   ;; Alive Entites = 0
   xor a
   ld [alive_entities], a

   ;; Zero all components
   ld hl, sprite_components
   ld b, sprite_components_size
   xor a
   call memset_256

   ;; Invalidate all components (FF in first item, Y coordinate)
   ld hl, sprite_components
   ld de, SPRITE_SIZE
   ld b, MAX_ENTITIES
   .loop:
      ld [hl], INVALID_COMPONENT
      add hl, de
      dec b
   jr nz, .loop

   ;; Invalidate all entities (FF in first item)
   ld hl, entities
   ld de, ENTITY_SIZE
   ld b, MAX_ENTITIES
   .loop2:
      ld [hl], INVALID_COMPONENT
      add hl, de
      dec b
   jr nz, .loop2

   ret

;; Allocate space for one entity
;; RETURNS
;; HL: Address of allocated component
man_entity_alloc::
   ld hl, entities
   ld de, ENTITY_SIZE
   .loop:
      ld a, [hl] ;; A = Component_Sprite.Y
      cp INVALID_COMPONENT
      jr z, .found
      ;; Not found
      add hl, de
   jr .loop

   .found:
   ;; HL = Component Address
   ld [hl], RESERVED_COMPONENT

   ld d, h ;; Preserve in DE the component address to reassign it later again to HL
   ld e, l
   ld hl, alive_entities
   inc [hl]
   ld h, d
   ld l, e

   ret

;; Returns the address of the sprite component array
;; RETURNS
;; HL: Address of Sprite Components Start
;; B: Sprite components size
man_entity_get_sprite_components::
   ld hl, sprite_components
   ld b, sprite_components_size
   ret

;; Returns the address of the entities array
;; RETURNS
;; HL: Address of Entities Start
;; B: Entities size
man_entity_get_entities::
   ld hl, entities
   ld b, sprite_components_size
   ret


;; Copies entities to sprites array
;; DESTROYS hl, de, bc
man_copy_entities_to_sprites::
   ld hl, entities
   ld de, sprite_components
   ld c, MAX_ENTITIES

   .for:
      ld b, SPRITE_SIZE
      call memcpy_256
      REPT ENTITY_SIZE - SPRITE_SIZE
         inc hl
      ENDR
      dec c
   jr nz, .for

   ret