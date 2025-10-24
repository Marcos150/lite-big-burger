INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Game Scene Data", WRAM0

animation_frame_counter:: DS 1

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
mauricio_entity:
    DB ENTITY_WITH_ALL_1_SPRITE, 0, 0, 0, 0, 0, 0, 0 ;; CMP_INFO
    DB $60, $34, $8C, %00000000, 0, 0, 0, 0 ;; CMP_SPRITE
    DB 0, 0, 1, 0, 0, 0, 0, 0 ;; CMP_PHYSICS

SECTION "Scene Game", ROM0


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

    ld hl, main_game_screen_layout
    ld de, VRAM_SCREEN_START
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call memcpy


    .init_managers_and_systems
    call man_entity_init
    call collision_init

    .init_lives
    ld a, PLAYER_INITIAL_LIVES
    ld [wPlayerLives], a
    
    xor a
    ld [wPlayerInvincibilityTimer], a


    call init_dma_copy
    SET_BGP DEFAULT_PAL
    SET_OBP1 DEFAULT_PAL


    ld hl, rLCDC
    set rLCDC_OBJ_ENABLE, [hl]
    set rLCDC_OBJ_16x8, [hl]

    xor a
    ld [animation_frame_counter], a

    call lcd_on

    call sc_game_update_hud

    ld e, 2
    call wait_vblank_ntimes

    call render_update
    call sc_title_screen_hold

    .create_entities
    ld hl, mauricio_entity
    call create_one_entity
    ld d, 0
    ld e, 1
    call spawn_one_hazard
    ld d, 1
    ld e, 1
    call spawn_one_hazard

    .create_ingredients
    ld d, 1
    ld e, 1
    ld a, 0
    .for
       push de
       push af 
       call spawn_one_ingredient
       pop af
       pop de
       sla e
       sla d
       inc a
       cp 8
       jr nz, .for


    ret

sc_game_run::
    .main_loop:
       ld e, 2
       call wait_vblank_ntimes

       call sc_game_update_hud
       
       .update_invincibility_timer
       ld a, [wPlayerInvincibilityTimer]
       or a
       jr z, .skip_timer_dec
       dec a
       ld [wPlayerInvincibilityTimer], a
       .skip_timer_dec

       ld hl, animation_frame_counter
       inc [hl]

       call render_update
       call movement_update
       call physics_update
       call collision_update
       jr .pause
    jr .main_loop

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
       ld [hl+], a
       inc a
       ld [hl+], a
       inc a
       ld [hl+], a
       inc a 
       ld [hl+], a
       inc a
       ld [hl+], a
       inc a
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
       ld [hl+], a
       ld [hl+], a
       ld [hl+], a
       ld [hl+], a
       ld [hl+], a
       ld [hl+], a
       ld [hl+], a

       .wait_unpress_again:
           call read_input
           ld a, b
           cp 0
           jr nz, .wait_unpress_again

       jr .main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actualiza el HUD (Vidas) escribiendo en VRAM
;;
sc_game_update_hud::
    call wait_vblank_start

    ld hl, VRAM_SCREEN_START
    ld bc, (HUD_LIVES_VALUE_Y * 32) + HUD_LIVES_VALUE_X
    add hl, bc
    
    ld a, [wPlayerLives]
    add a, TILE_ID_NUM_0
    ld [hl], a

    ld hl, VRAM_SCREEN_START
    ld bc, (HUD_LIVES_ICON_Y * 32) + HUD_LIVES_ICON_X
    add hl, bc
    
    ld a, TILE_ID_HUD_ICON
    ld [hl], a
    
    ret

