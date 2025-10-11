INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"
INCLUDE "macros.inc"

SECTION "Maurice Variables", WRAM0
mau_y:: dw    ; Dirección de memoria de Y de Maurice
mau_x:: dw    ; Dirección de memoria de X de Maurice

SECTION "Entity Manager Data", WRAM0[_WRAM]

sprite_components: DS MAX_SPRITES*SPRITE_SIZE
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

   ;; Zero all sprites
   ld hl, sprite_components
   ld b, sprite_components_size
   xor a
   call memset_256

   ;; Invalidate all entities (FF in first item and 00 in tags)
   ld hl, entities
   ld b, MAX_ENTITIES
   .loop:
      ld de, E_TAGS
      ld [hl], INVALID_COMPONENT
      add hl, de
      ld [hl], INIT_TAGS

      ld de, ENTITY_SIZE - E_TAGS
      add hl, de
      dec b
   jr nz, .loop

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

;; Checks if entity is main character
;; 📥 INPUT:
;; DE: Address of the entity
;; RETURNS:
;; Flag Z
;; DESTROYS: HL, DE
check_if_prota::
   call load_tags_to_a   

   bit E_BIT_PROTA, a
   ret

;; Sets tags of entity to A register
;; 📥 INPUT:
;; DE: Address of the entity
;; RETURNS:
;; A: Tag property
;; DESTROYS: DE, HL
load_tags_to_a::
   LOAD_PROPERTY_TO_A E_TAGS
   ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Processes all alive entities in the entity_array.
;; So it iterates over all the entity array,
;; locating the alive ones (E_BIT_ALIVE=1).
;; To process an entity, it sets DE='entity address'
;; and calls the processing routine at HL.
;; The processing routine is given by the caller
;; in HL, so we can process entities in different
;; ways.
;;
;; 📥 INPUT:
;; HL: Address of the processing routine
;;
man_entity_for_each::
   ld de, entities
   ld c, MAX_ENTITIES
   .for:
      push hl
      push de ;; Save HL and DE original value
      call load_tags_to_a
      pop de ;; Get back original values
      pop hl
      bit E_BIT_ALIVE, a
      jr z, .next_item ;; If not alive, next entity
      
      push bc
      push hl ;; Save HL to recover it later
      push de ;; Save AF, DE and HL to recover it later
      ld bc, .ret_dir
      push bc ;; Next ret will go to .ret_dir
      jp hl

      .ret_dir:
      pop de
      pop hl
      pop bc

      .next_item:
         ;; TODO: Search for a better way to do this
         REPT ENTITY_SIZE
            inc de
         ENDR
         dec c
   jr nz, .for

   ret
