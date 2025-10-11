INCLUDE "constants.inc"
INCLUDE "macros.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
mauricio_entity:: DB $79, $34, $8C, %00000000, %11000000

SECTION "Scene Game", ROM0

sc_game_init::
   call man_entity_init
   call man_entity_alloc

   SET_BGP DEFAULT_PAL
   SET_OBP1 SPRITE_PAL
   ;; HL: Component Address (write)
   ld d, h
   ld e, l
   ld hl, mauricio_entity
   ld b, 5
   call memcpy_256

   call lcd_off
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

   call lcd_on

   call lcd_off
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