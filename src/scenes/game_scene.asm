INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
;; Y, X, Tile, Props, tags, size_x, size_y, vel_y, init_y
mauricio_entity:
   DB ENTITY_NO_PHYSICS_1_SPRITE, 0, 0, 0, 0, 0, 0, 0 ;; CMP_INFO
   DB $79, $34, $8C, %00000000, 0, 0, 0, 0 ;; CMP_SPRITE
   DB 0, 0, 0, 0, 0, 0, 0, 0 ;; CMP_PHYSICS

;; Test entity
;; Y, X, Tile, Props, tags, size_x, size_y, vel_y, init_y
test_entity:
   DB ENTITY_NO_PHYSICS_NO_CONTROLLABLE, 0, 0, 0, 0, 0, 0, 0 ;; CMP_INFO
   DB $60, $14, $A6, %00000000, $60, $14 + $8, $A8, %00000000 ;; CMP_SPRITE
   DB 0, 0, 0, 0, 0, 0, 0, 0 ;; CMP_PHYSICS

SECTION "Scene Game", ROM0

;; CREATE ONE ENTITY
;; HL: Entity Template Data
create_one_entity:
   push hl ;; Save Template Address
  
   .reserve_space_for_entity
   call man_entity_alloc
   ;; HL: Component Address (write)

   .copy_info_cmp
   ld d, h
   ld e, l
   pop hl ;; HL -> Entity Template Data
   push hl
   push de
   ld b, SIZEOF_CMP
   call memcpy_256

   .copy_sprite_cmp
   pop de
   pop hl
   ld d, CMP_SPRITE_H
   ld bc, SIZEOF_CMP
   add hl, bc
   push hl
   push de
   ld b, c
   call memcpy_256

   .copy_physics_cmp
   pop de
   pop hl
   ld d, CMP_PHYSICS_H
   ld bc, SIZEOF_CMP
   add hl, bc
   ld b, c
   call memcpy_256

   ret

sc_game_init::
   call lcd_off

   .init_managers_and_systems
   call man_entity_init
   call collision_init

   .create_entities
   ld hl, mauricio_entity
   call create_one_entity
   ld hl, test_entity
   call create_one_entity

   ld hl, main_game_tiles
   ld de, VRAM_TILE_START
   ld bc, SIZE_OF_MAINGAME
   call memcpy

   ld hl, mauricio_tiles ;Mauricio
   ld bc, SIZE_OF_MAURICIO
   call memcpy

   ld hl, elements_tiles
   ld bc, SIZE_OF_ELEMENTS
   call memcpy

   ld hl, main_game_screen_layout
   ld de, VRAM_SCREEN_START
   ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
   call memcpy

   call init_dma_copy
   SET_BGP DEFAULT_PAL
   SET_OBP1 DEFAULT_PAL

   ld hl, rLCDC
   set rLCDC_OBJ_ENABLE, [hl]
   set rLCDC_OBJ_16x8, [hl]

   call lcd_on

	ret