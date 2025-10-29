INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

SECTION "Game Scene Data", WRAM0

animation_frame_counter:: DS 1
current_level:: DS 1
current_iteration:: DS 1 ;; Times that all levels have been beaten
ingredients_left:: DS 1
wTempBCDBuffer:: ds 5
wPlayerIsDead:: ds 1

SECTION "Scene Game Data" , ROM0

;; M A U R I C I O
mauricio_entity:
    DB ENTITY_WITH_ALL_1_SPRITE, 0, 0, 0, 0, 0, 0, 0 ;; CMP_INFO
    DB $60, $34, $8C, %00010000, 0, 0, 0, 0 ;; CMP_SPRITE (Usando OBP1)
    DB 0, 0, 1, 0, 0, 0, 0, 0 ;; CMP_PHYSICS

SECTION "Scene Game", ROM0

respawn_entities:
    ld hl, mauricio_entity
    call create_one_entity
    jp spawn_init

init_level:
    call lcd_off

   xor a
   ld [wPlayerInvincibilityTimer], a

    call man_entity_init
    call load_level_layout
    call respawn_entities
    call dma_copy
    ld hl, musiquita
    call hUGE_init
    call lcd_on

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
    cp LEVEL3
    jr z, .copy_tiles

    ld hl, level4_layout
    cp LEVEL4
    jr z, .copy_tiles
    
    ;; All levels done, start from 1 with more enemies
    ld hl, current_iteration
    inc [hl]

    xor a
    ld [current_level], a
    ld hl, main_game_screen_layout

    .copy_tiles
    ld de, VRAM_SCREEN_START
    ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
    jp memcpy

sc_game_init::
    ;; Enable vblank interrupt
    ld a, %00000001
    ld [rIE], a
    ei
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
    ld [wPlayerIsDead], a
    ld [current_iteration], a

    ;; All channels in left and right
    ld a, $FF
    ld [rNR51], a

    call load_level_layout
    call lcd_on
    call render_update
    call sc_title_screen_hold

    ld hl, musiquita
    call hUGE_init

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
        call hUGE_dosound
        call hUGE_dosound
        ;; Comprueba si el jugador ha muerto
        ld a, [wPlayerIsDead]
        or a
        jp nz, sc_game_over ; Si es 1, salta a la pantalla de Game Over

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
        jr z, .next_level
        cp -1
        jr nz, .check_out_of_screen

        .next_level:
        ld hl, current_level
        inc [hl]

        SET_OBP2 DEFAULT_PAL ;; Para el bug visual al pasarse nivel siendo invulnerable
        call mute_music_all
        call celebration
        call mute_music_all
        call fade_out
        call init_level
        call fade_in
        call unmmute_music_all

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
        call mute_music_all
        call unmmute_music_all

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
            call wait_vblank_start
            call read_input
            ld a, b
            or a ;; cp 0
            jr nz, .wait_unpress

        .loop_paused:
            call wait_vblank_start
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
            call wait_vblank_start
            call read_input
            ld a, b
            or a ;; cp 0
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

    ld b, 5 ; <-- Mantenido de 'cinco cifras' (dd597eb)
    ld de, wTempBCDBuffer

.draw_digit_loop:
    ld a, [de]
    add a, TILE_ID_NUM_0
    ld [hl+], a
    inc de
    dec b
    jr nz, .draw_digit_loop

.draw_order_ing_left:
    ld a, HUD_ORDER_VALUE_X
    ld l, a
    ld a, $9A
    ld h, a
    ld a, HUD_PEN_TILE
    ld [hl+], a
    ld a, HUD_NOTE_TILE
    ld [hl+], a
    ld a, TILE_ID_HUD_X
    ld [hl+], a
    ld a, [ingredients_left]
    add a, TILE_ID_NUM_0
    ld [hl+], a
    
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Añade puntos al marcador y gestiona vidas extra
;; INPUT:
;; BC: Puntos a añadir (ej. 10)
;;
sc_game_add_score::
    push hl
    push de
    push bc ; Salva BC (puntos a añadir)

    ;; --- Add to wPlayerScore (16-bit) ---
    ld hl, wPlayerScore
    ld a, [hl]
    add a, c
    ld [hl], a
    inc hl
    ld a, [hl]
    adc a, b
    ld [hl], a

    ;; --- Add to wPointsForExtraLife (16-bit) ---
    ld hl, wPointsForExtraLife
    ld a, [hl]
    add a, c
    ld [hl], a
    inc hl
    ld a, [hl]
    adc a, b
    ld [hl], a
    
    pop bc ; Restaura BC (puntos a añadir)
           ; (ya no se usa, pero equilibra la pila)

    ;; --- Check if wPointsForExtraLife >= POINTS_PER_EXTRA_LIFE (Looping) ---
.life_check_loop:
    ;; Carga el contador (CONTADOR) en DE
    ld hl, wPointsForExtraLife
    ld a, [hl]
    ld e, a
    inc hl
    ld a, [hl]
    ld d, a
    
    ;; Carga la constante (CONSTANTE) en BC
    ld bc, POINTS_PER_EXTRA_LIFE

    ;; Compara: if (DE < BC) salta a .no_life
    ld a, d
    cp b
    jr c, .no_life ; if D < B
    jr nz, .grant_life ; if D > B
    ; if D == B, check E
    ld a, e
    cp c
    jr c, .no_life ; if E < C

.grant_life:
    ;; 1. Dar vida (max 9)
    call extra_life_sound
    push de ; Salva el valor del CONTADOR
    push bc ; Salva el valor de la CONSTANTE
    
    ld hl, wPlayerLives
    ld a, [hl]
    cp 9
    jr z, .skip_inc_life
    inc a
    ld [hl], a
.skip_inc_life:
    pop bc ; Restaura CONSTANTE
    pop de ; Restaura CONTADOR (DE = CONTADOR)
    
    ;; 2. Restar puntos: DE = DE - BC (CONTADOR = CONTADOR - CONSTANTE)
    ld a, e
    sub c
    ld e, a
    ld a, d
    sbc b
    ld d, a
    
    ;; 3. Guardar el nuevo valor del CONTADOR (DE)
    ld a, e
    ld [wPointsForExtraLife], a ; Guarda el byte bajo
    ld a, d
    ld [wPointsForExtraLife+1], a ; Guarda el byte alto

    ;; 4. Volver al bucle para comprobar de nuevo
    jr .life_check_loop
    
.no_life:
    pop de
    pop hl
    ret

obliterate_entities:
    ld d, CMP_SPRITE_H
    ld a, [de]          ;;Check y
    cp $B0
    jr nc, .obliterate
    inc de
    ld a, [de]          ;;Check x
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
        inc l ;; rOBP2
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
    inc l ;; rOBP2
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
    inc l ;; rOBP2
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
    inc l ;; rOBP2
    scf
    rr [hl]
    scf
    rr [hl]
ret

death_animation_burn::
    ld d, CMP_SPRITE_H
    REPT CMP_SPRITE_TILE
        inc e
    ENDR

    ld h, d
    ld l, e

    ld [hl], $98
    call dma_copy

    ld e, 50
    call wait_vblank_ntimes

    ld [hl], $9B
    call dma_copy

    ld e, 50
    jp wait_vblank_ntimes

death_animation_cut::
    ld d, CMP_SPRITE_H
    REPT CMP_SPRITE_TILE
        inc e
    ENDR

    ld h, d
    ld l, e

    ld [hl], $9C
    call dma_copy

    ld e, 50
    call wait_vblank_ntimes

    ld [hl], $9E
    call dma_copy

    ld e, 50
    call wait_vblank_ntimes

    ld [hl], $A0
    call dma_copy

    ld e, 50
    jp wait_vblank_ntimes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Muestra la pantalla de Game Over
;;
sc_game_over::
    ld hl, game_over
    call hUGE_init
    ;; 1. Apagar sprites
    ld hl, rLCDC
    res rLCDC_OBJ_ENABLE, [hl]

    ;; 2. Fundido a negro
    call fade_out

    ;; 3. Pausa
    ld e, 60
    call wait_vblank_ntimes

    ;; 4. Apagar LCD
    call lcd_off

    ;; 5. Mover scroll a (0,0)
    xor a
    ld [rSCY], a
    ld [rSCX], a

    ;; 6. Limpiar área visible (20x18) en VRAM (0,0)
    ld hl, VRAM_SCREEN_START
    ld b, 18 ; Altura (18 tiles)
.clear_visible_y_loop:
    push bc
    push hl
    ld c, 20 ; Anchura (20 tiles)
.clear_visible_x_loop:
    ld a, $00 ; Tile vacío
    ld [hl+], a
    dec c
    jr nz, .clear_visible_x_loop
    
    pop hl
    ld bc, 32 ; Siguiente fila del mapa
    add hl, bc
    pop bc
    dec b
    jr nz, .clear_visible_y_loop

    ;; 7. Escribir "GAME OVER"
    ld hl, VRAM_SCREEN_START + (8 * 32) + 6
    ld a, $EC ; G
    ld [hl+], a
    ld a, $ED ; A
    ld [hl+], a
    ld a, $EE ; M
    ld [hl+], a
    ld a, $EF ; E
    ld [hl+], a
    ld a, $00 ; (espacio)
    ld [hl+], a
    ld a, $F1 ; O
    ld [hl+], a
    ld a, $F2 ; V
    ld [hl+], a
    ld a, $EF ; E
    ld [hl+], a
    ld a, $F8 ; R (mismo tile que en SCORE)
    ld [hl+], a

    ;; 8. Escribir "SCORE"
    ld hl, VRAM_SCREEN_START + (10 * 32) + 4
    ld a, $F5 ; S
    ld [hl+], a
    ld a, $F6 ; C
    ld [hl+], a
    ld a, $F7 ; O
    ld [hl+], a
    ld a, $F8 ; R
    ld [hl+], a
    ld a, $F9 ; E
    ld [hl+], a
    ld a, $00 ; (espacio)
    ld [hl+], a

    ;; 9. Mostrar puntuación
    push hl
    ld a, [wPlayerScore]
    ld l, a
    ld a, [wPlayerScore+1]
    ld h, a
    call utils_bcd_convert_16bit
    pop hl

    ld b, 5 ; 5 dígitos
    ld de, wTempBCDBuffer
.draw_score_loop:
    ld a, [de]
    add a, $D4 ; Base para '0'
    ld [hl+], a
    inc de
    dec b
    jr nz, .draw_score_loop

    ;; 10. Encender la LCD
    call lcd_on
    
    ;; 11. Fundido de entrada
    call fade_in

    ;; 12. Esperar pulsación START
.wait_press:
    call hUGE_dosound
    call wait_vblank_start
    call read_input
    ld a, b
    and BUTTON_START
    jr z, .wait_press

    ;; 13. Esperar soltar START
.wait_release:
    call hUGE_dosound
    call wait_vblank_start
    call read_input
    ld a, b
    and BUTTON_START
    jr nz, .wait_release

    call mute_music_all

    ;; 14. Salir de la escena
    ret