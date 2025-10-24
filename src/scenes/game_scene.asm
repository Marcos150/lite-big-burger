INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Game Scene Data", WRAM0

animation_frame_counter:: DS 1
current_level:: DS 1
ingredients_left:: DS 1

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
mauricio_entity:
   DB ENTITY_WITH_ALL_1_SPRITE, 0, 0, 0, 0, 0, 0, 0 ;; CMP_INFO
   DB $60, $34, $8C, %00000000, 0, 0, 0, 0 ;; CMP_SPRITE
   DB 0, 0, 1, 0, 0, 0, 0, 0 ;; CMP_PHYSICS

SECTION "Scene Game", ROM0

respawn_entities:
   ld hl, mauricio_entity
   call create_one_entity
   call spawn_init
ret

init_level:
   call lcd_off

   call man_entity_init
   call load_level_layout
   call respawn_entities

   jp lcd_on

load_level_layout:
   ld a, INGREDIENTS_TO_WIN
   ld [ingredients_left], a

   ld hl, main_game_screen_layout
   ld a, [current_level]
   ;; Check which is the current level
   cp LEVEL1
   jr z, .copy_tiles

   ld hl, level2_layout
   cp LEVEL2
   jr z, .copy_tiles

   ld hl, level3_layout

   .copy_tiles
   ld de, VRAM_SCREEN_START
   ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
   jp memcpy

sc_game_init::
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

   .init_managers_and_systems
   call man_entity_init
   call collision_init
   call movement_init


   call init_dma_copy
   SET_BGP DEFAULT_PAL
   SET_OBP1 DEFAULT_PAL


   ld hl, rLCDC
   set rLCDC_OBJ_ENABLE, [hl]
   set rLCDC_OBJ_16x8, [hl]

   xor a
   ld [animation_frame_counter], a
   ld [current_level], a

   ;; All channels in left and right
   ld a, $FF
   ld [rNR51], a

   call load_level_layout
   call render_update
   call lcd_on
   call sc_title_screen_hold

   jp respawn_entities

sc_game_run::
   .main_loop:
      ld e, 2
      call wait_vblank_ntimes

      ld hl, animation_frame_counter
      inc [hl]

      call render_update
      call collision_update
      call movement_update
      call physics_update
      call spawn_update

      ;; Checks if enough ingredients delivered to pass to next level
      ld a, [ingredients_left]
      cp 0
      jr nz, .check_out_of_screen
      ld hl, current_level
      inc [hl]

      call celebration
      call mute_music
      call init_level

      .check_out_of_screen
      ld hl, obliterate_entities
      call man_entity_for_each
   jr .pause

.pause:
   call read_input
   ld a, b
   and BUTTON_START
   jr z, .main_loop

   .is_paused:
      call wait_vblank_start
      ld hl, $9800
      ld a, $8B
      ld [hl+], a
      ld a, $E7

      REPT 5
         ld [hl+], a
         inc a
      ENDR

      ld a, $8B
      ld [hl], a
      .wait_unpress:
         call read_input
         ld a, b
         cp 0
         jr nz, .wait_unpress

      .loop_paused:
         call read_input
         ld a, b
         and BUTTON_START
         jr z, .loop_paused
      
      call wait_vblank_start
      ld hl, $9800
      ld a, $10
      REPT 7
         ld [hl+], a
      ENDR

      .wait_unpress_again:
         call read_input
         ld a, b
         cp 0
         jr nz, .wait_unpress_again

      jp .main_loop

obliterate_entities:
   ld d, CMP_SPRITE_H
   ld a, [de]           ;;Check y
   cp $B0
   jr nc, .obliterate
   inc de
   ld a, [de]           ;;Check x
   cp $B0
   dec de
   jr nc, .obliterate
ret

.obliterate:
   ld h, CMP_INFO_H
   ld l, e
   call man_entity_destroy
ret
