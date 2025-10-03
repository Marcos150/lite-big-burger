INCLUDE "managers/entity_manager.inc"

SECTION "Entity Manager Data", WRAM0[$C000]

components:
sprite_components: DS MAX_ENTITIES*COMPONENT_SIZE
sprite_components_end:
DEF sprite_components_size = sprite_components_end - sprite_components
EXPORT sprite_components_size

;; Throws error when assembling if components don't start at xx00 adress. Needed for DMA
;; Extracted from Game Boy Coding Adventure Early Access, page 230
assert low(components) == 0, "components must be 256-byte-aligned"

alive_entities: DS 1

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
   ld de, COMPONENT_SIZE
   ld b, MAX_ENTITIES
   .loop:
      ld [hl], INVALID_COMPONENT
      add hl, de
      dec b
   jr nz, .loop

   ret

;; Allocate space for one entity
;; RETURNS
;; HL: Address of allocated component
man_entity_alloc::
   ld hl, sprite_components
   ld de, COMPONENT_SIZE
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

;; Returns the address of the sprite compnent array
;; RETURNS
;; HL: Address of Sprite Components Start
;; B: Sprite compnents size
man_entity_get_sprite_components::
   ld hl, sprite_components
   ld b, sprite_components_size
   ret