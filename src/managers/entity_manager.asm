INCLUDE "managers/entity_manager.inc"
INCLUDE "constants.inc"
INCLUDE "macros.inc"

SECTION "Maurice Variables", WRAM0
mau_y:: dw    ; Dirección de memoria de Y de Maurice
mau_x:: dw    ; Dirección de memoria de X de Maurice

SECTION "Entity Manager Data", WRAM0[_WRAM]

components:
EXPORT DEF CMP_INFO_H = HIGH(@)
components_info: DS SIZEOF_ARRAY_CMP
DS ALIGN[8]


EXPORT DEF CMP_SPRITE_H = HIGH(@)
;; Throws error when assembling if components don't start at xx00 adress. Needed for DMA
;; Extracted from Game Boy Coding Adventure Early Access, page 230
assert low(@) == 0, "components must be 256-byte-aligned {CMP_SPRITE_H}"
components_sprite: DS SIZEOF_ARRAY_CMP
DS ALIGN[8]

EXPORT DEF CMP_PHYSICS_H = HIGH(@)
components_physics: DS SIZEOF_ARRAY_CMP
DS ALIGN[8]

alive_entities: DS 1
alive_ingredients:: DS 1
alive_hazards_and_enemies:: DS 1

SECTION "Entity Manager Code", ROM0

;; Initialize Entity Manager
;; DESTROYS: AF, B, HL
man_entity_init::
   ;; Alive Entites = 0
   .zero_alive_entities
   xor a
   ld [alive_entities], a
   ld [alive_ingredients], a
   ld [alive_hazards_and_enemies], a

   .zero_info:
      ld hl, components_info
      ld b, SIZEOF_ARRAY_CMP
      xor a
      call memset_256
   
   .zero_sprite:
      ld hl, components_sprite
      ld b, SIZEOF_ARRAY_CMP
      call memset_256

   .zero_physics:
      ld hl, components_physics
      ld b, SIZEOF_ARRAY_CMP
      call memset_256

   ret

;; Allocate space for one entity
;; RETURNS
;; HL: Address of allocated component
man_entity_alloc::
   .one_more_alive_entity:
   ld hl, alive_entities
   inc [hl]

   .find_first_free_slot:
   ld hl, (components_info - SIZEOF_CMP)
   ld de, SIZEOF_CMP
   .loop:
      add hl, de
      bit CMP_BIT_USED, [hl]
   jr nz, .loop

   .found_free_slot:
   ld [hl], RESERVED_COMPONENT
   ret

;; Destroys one entity
;; RETURNS
;; HL: Address of allocated component
man_entity_destroy::
   ld a, [hl]
   bit CMP_BIT_INGREDIENT, a
   push hl
   jr z, .check_if_hazard_enemy

   ;; Decreases alive_ingredients if entity is ingredient 
   ld hl, alive_ingredients
   dec [hl]
   ld hl, ingredients_left
   dec [hl]
   jr .destroy

   .check_if_hazard_enemy
   and CMP_MASK_HAZARD
   jr z, .destroy

   ;; Decreases alive_ingredients if entity is ingredient 
   ld hl, alive_hazards_and_enemies
   dec [hl]

   .destroy
   pop hl
   xor a
   ld [hl], a

   ld h, CMP_SPRITE_H
   ld [hl], a

   ld hl, alive_entities
   dec [hl]
ret

;; Returns the address of the sprite component array
;; RETURNS
;; HL: Address of Sprite Components Start
;; B: Sprite components size
man_entity_get_sprite_components::
   ld hl, components_sprite
   ld b, SIZEOF_ARRAY_CMP
   ret

;; Checks if entity is controllable
;; 📥 INPUT:
;; DE: Address of the entity
;; RETURNS:
;; Flag Z
;; DESTROYS: A
check_if_controllable::
   ld a, [de]
   bit CMP_BIT_CONTROLLABLE, a
   ret

check_if_ingredient::
   ld a, [de]
   bit CMP_BIT_INGREDIENT, a
   ret


process_entity:
   push bc
   push hl
   push de
   call simulated_call_hl
   pop de
   pop hl
   pop bc
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Processes all alive entities
;;
;; 📥 INPUT:
;; HL: Address of the processing routine
;;
man_entity_for_each::
   ld a, [alive_entities]
   .check_if_zero_entities
   cp 0
   ret z
   .process_alive_entities
   ld de, components_info ;; DONT GO OUT OF $Cx00!
   ld b, a
   .for:
      .check_if_valid
      ld a, [de] ;; CMPS
      and VALID_ENTITY
      cp VALID_ENTITY
      jr nz, .next
      .process
      call process_entity
      .check_end
      dec b
      ret z
      .next
      ld a, e ;; ONLY VALID FOR 64 ENTITIES
      add SIZEOF_CMP
      ld e, a
   jr .for

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Processes entities that are ALIVE, NON-CONTROLLABLE,
;; and match an ADDITIONAL filter mask.
;;
;; 📥 INPUT:
;; HL: Address of the processing routine to call.
;; A:  Additional filter mask (e.g., CMP_MASK_ENEMY).
;;     Use 0 for no additional filter.
;;     MAKE SURE TO CLEAR A IF NO FILTER IS BEING USED
;;
man_entity_for_each_filtered::
   ; Store the additional mask from A into C for safekeeping.
   ld c, a

   ld a, [alive_entities]
   cp 0
   ret z
   ld de, components_info ;; DONT GO OUT OF $Cx00!
   ld b, a
   .for:
      ld a, [de]
      and VALID_ENTITY
      cp VALID_ENTITY
      jr nz, .next

      ld a, [de]
      and CMP_MASK_CONTROLLABLE
      jr nz, .check_end

      ld a, c                
      or a                  ; Check if it's 0 and don't apply filter
      jr z, .process         
      ld a, [de]
      and c
      cp c                   

      jr nz, .next 

      .process:
      call process_entity

      .check_end:
      dec b
      ret z
      .next:
      ld a, e                ;; ONLY VALID FOR 64 ENTITIES
      add SIZEOF_CMP
      ld e, a
   jr .for

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Processes all alive controllable entities
;;
;; 📥 INPUT:
;; HL: Address of the processing routine
;;
man_entity_controllable::
   ld a, [alive_entities]
   .check_if_zero_entities
   cp 0
   ret z
   .process_alive_entities
   ld de, components_info ;; DONT GO OUT OF $Cx00!
   ld b, a
   .for:
      .check_if_valid
      ld a, [de] ;; CMPS
      and VALID_ENTITY
      cp VALID_ENTITY
      jr nz, .next
      ld a, [de]
      and CMP_MASK_CONTROLLABLE
      jr z, .check_end
      .process
      call process_entity
      ret
      .check_end
      dec b
      ret z
      .next
      ld a, e ;; ONLY VALID FOR 64 ENTITIES
      add SIZEOF_CMP
      ld e, a
   jr .for