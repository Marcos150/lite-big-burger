INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Game Scene Data", WRAM0

animation_frame_counter:: DS 1

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
mauricio_entity:
   DB ENTITY_WITH_ALL_1_SPRITE, 0, 0, 16, 8, 0, 0, 0 ;; CMP_INFO
   DB $60, $34, $8C, %00000000, 0, 0, 0, 0 ;; CMP_SPRITE
   DB 0, 0, 1, 0, 0, 0, 0, 0 ;; CMP_PHYSICS

SECTION "Scene Game", ROM0


sc_game_init::
   call lcd_off

   .init_managers_and_systems
   call man_entity_init
   call collision_init

   .create_entities
   ld hl, mauricio_entity
   call create_one_entity
   ld d, 0
   ld e, 1
   call spawn_one_hazard
   ld d, 1
   ld e, 1
   call spawn_one_hazard
   ld d, $25
   ld e, 0
   call spawn_one_ingredient
   ld d, $25
   ld e, 0

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

   xor a
   ld [animation_frame_counter], a 

   call lcd_on

	ret

sc_game_run::
   .loop:
      ld e, 2
      call wait_vblank_ntimes

      ; -- Incrementamos el contador de animación SIEMPRE --
      ld hl, animation_frame_counter
      inc [hl]

      call render_update
      call movement_update
      call physics_update
      call collision_update
   jr .loop