INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Game Scene Data", WRAM0

animation_frame_counter:: DS 1
current_level:: DS 1
ingredients_left:: DS 1
wTempBCDBuffer:: ds 4

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
mauricio_entity:
    DB ENTITY_WITH_ALL_1_SPRITE, 0, 0, 0, 0, 0, 0, 0 ;; CMP_INFO
    DB $60, $34, $8C, %00010000, 0, 0, 0, 0 ;; CMP_SPRITE
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
   call lcd_on
   call dma_copy

   jp sc_game_update_hud

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
    ld hl, main_game_screen_layout
    ld de, VRAM_SCREEN_START
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    call memcpy

    call init_dma_copy
    SET_BGP DEFAULT_PAL
    SET_OBP1 DEFAULT_PAL
    SET_OBP2 DEFAULT_PAL

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
    call lcd_on
    call render_update
    call sc_title_screen_hold

    .init_game_state
    ld a, PLAYER_INITIAL_LIVES
    ld [wPlayerLives], a
    
    xor a
    ld [wPlayerInvincibilityTimer], a
    ld [wOrderProgress], a
    ld [wPlayerScore], a
    ld [wPlayerScore+1], a
    ld [wPointsForExtraLife], a
    ld [wPointsForExtraLife+1], a
    call sc_game_update_hud


    jp respawn_entities

sc_game_run::
    .main_loop:
       ld e, 2
       call wait_vblank_ntimes

       ld hl, animation_frame_counter
       inc [hl]
       
       .update_invincibility_timer
       ld a, [wPlayerInvincibilityTimer]
       or a
       jr z, .skip_timer_dec
       dec a
       ld [wPlayerInvincibilityTimer], a
       .skip_timer_dec

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
      call fade_out
      call init_level
      call fade_in

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actualiza el HUD (Vidas y Puntos) escribiendo en VRAM
;;
sc_game_update_hud::
    call wait_vblank_start

    ;; --- Draw Lives HUD ---
    ld hl, VRAM_SCREEN_START
    ld bc, (HUD_Y * 32) + HUD_VALUE_X
    add hl, bc
    
    ld a, [wPlayerLives]
    cp 10
    jr nc, .cap_lives_display
    add a, TILE_ID_NUM_0
    jr .draw_lives
.cap_lives_display:
    ld a, TILE_ID_NUM_0 + 9
.draw_lives:
    ld [hl+], a
    
    ld a, TILE_ID_HUD_X
    ld [hl+], a

    ld a, TILE_ID_HUD_ICON
    ld [hl], a

    ;; --- Draw Score HUD ---
    ld hl, VRAM_SCREEN_START
    ld bc, (HUD_SCORE_Y * 32) + HUD_SCORE_ICON_X
    add hl, bc
    
    ld a, TILE_ID_HUD_SCORE_ICON
    ld [hl+], a

    ld a, TILE_ID_HUD_X
    ld [hl+], a
    
    push hl

    ld a, [wPlayerScore]
    ld l, a
    ld a, [wPlayerScore+1]
    ld h, a
    call utils_bcd_convert_16bit

    pop hl

    ld b, 4
    ld de, wTempBCDBuffer

.draw_digit_loop:
    ld a, [de]
    add a, TILE_ID_NUM_0
    ld [hl+], a
    inc de
    dec b
    jr nz, .draw_digit_loop
    
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Añade puntos al marcador y gestiona vidas extra
;; INPUT:
;; BC: Puntos a añadir (ej. 10)
;;
sc_game_add_score::
    push hl
    push de

    ;; --- Add to wPlayerScore (16-bit) ---
    ld hl, wPlayerScore
    ld a, [hl]
    add a, c
    ld [hl], a
    inc hl
    ld a, [hl]
    adc a, b
    ld [hl], a

    ;; --- Cap score at 9999 ---
    cp HIGH(10000)
    jr c, .score_ok
    ld a, LOW(10000)
    dec hl
    cp [hl]
    jr c, .score_ok
    ld [hl], $0F
    inc hl
    ld [hl], $27
    
.score_ok:
    ;; --- Add to wPointsForExtraLife (16-bit) ---
    ld hl, wPointsForExtraLife
    ld a, [hl]
    add a, c
    ld [hl], a
    inc hl
    ld a, [hl]
    adc a, b
    ld [hl], a

    ;; --- Check if wPointsForExtraLife >= POINTS_PER_EXTRA_LIFE ---
    ld a, HIGH(POINTS_PER_EXTRA_LIFE)
    cp [hl]
    jr c, .grant_life
    jr nz, .no_life

    ld a, LOW(POINTS_PER_EXTRA_LIFE)
    dec hl
    cp [hl]
    jr c, .no_life

.grant_life:
    ld hl, wPlayerLives
    ld a, [hl]
    cp 9
    jr z, .reset_life_counter
    
    inc a
    ld [hl], a

.reset_life_counter:
    ;; --- Subtract POINTS_PER_EXTRA_LIFE from wPointsForExtraLife ---
    ld hl, wPointsForExtraLife
    ld de, POINTS_PER_EXTRA_LIFE
    ld a, [hl]
    sub a, e
    ld [hl], a
    inc hl
    ld a, [hl]
    sbc a, d
    ld [hl], a
    
.no_life:
    pop de
    pop hl
    ret

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

   ;; If prota falls, -1 life
   ld a, [hl]
   and CMP_MASK_CONTROLLABLE
   jp nz, player_hit_hazard

   call man_entity_destroy
ret

fade_out:
    ld b, 3
    .for:
        push bc
        ld e, 20
        call wait_vblank_ntimes
        ld hl, rBGP
        sla [hl]
        sla [hl]
        ld hl, rOBP1
        sla [hl]
        sla [hl]
        pop bc
        dec b
    jr nz, .for
ret

fade_in:
    ld e, 20
    call wait_vblank_ntimes

    ld hl, rBGP
    scf
    rr [hl]
    rr [hl]
    ld hl, rOBP1
    scf
    rr [hl]
    rr [hl]

    ld e, 20
    call wait_vblank_ntimes

    ld hl, rBGP
    rr [hl]
    scf
    rr [hl]
    ld hl, rOBP1
    rr [hl]
    scf
    rr [hl]

    ld e, 20
    call wait_vblank_ntimes

    ld hl, rBGP
    scf
    rr [hl]
    scf
    rr [hl]
    ld hl, rOBP1
    scf
    rr [hl]
    scf
    rr [hl]
ret