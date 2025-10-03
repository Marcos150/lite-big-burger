INCLUDE "constants.inc"
INCLUDE "macros.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Scene Game", ROM0

sc_game_init::
   call man_entity_init
   call man_entity_alloc

   SET_BGP DEFAULT_PAL
   SET_OBP1 DEFAULT_PAL
   ;; HL: Component Address (write)
   ld d, h
   ld e, l
   ld hl, sc_game_sprite_prota
   ld b, 4
   call memcpy_256

   call lcd_off
   ld hl, main_game_tiles
   ld de, VRAM_TILE_START
   ld bc, SIZE_OF_MAINGAME
   call memcpy

   ld hl, mauricio
   ld bc, SIZE_OF_MAURICIO
   call memcpy

   call lcd_on

   call lcd_off
   ld hl, main_game_screen_tiles
   ld de, VRAM_SCREEN_START
   ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
   call memcpy

   ld hl, rLCDC
   set rLCDC_OBJ_ENABLE, [hl]
   set rLCDC_OBJ_16x8, [hl]

   call lcd_on

	ret

sc_game_run::
   .loop:
      call sys_movement_update
      call sys_render_update
      ;; sys.....
   jr .loop
   ret