INCLUDE "constants.inc"
INCLUDE "macros.inc"
INCLUDE "managers/entity_manager.inc"

SECTION "Tile Screen Data", WRAM0

animation_delay: DS 1

SECTION "Title Screen Scene" , ROM0

sc_title_screen_hold::
	ld a, 0
	ld [animation_delay], a
	.music_driver_init:
    ld hl, funiculi
   	call hUGE_init

	;; Lowers the volume
	ld a, INIT_VOLUME
	ld [rNR50], a

	call set_screen_to_bottom
	ld a, $10
	ld [animation_delay], a
	.loop:
		;; Plays music.
      	call hUGE_dosound

		ld a, [animation_delay]
		cp 0
		jr nz, .dont_play
		.play:
			call animate_start_button
			ld a, $30
			ld [animation_delay], a
		.dont_play:
			dec a
			ld [animation_delay], a
			call wait_vblank_start

		call read_input
		ld a, b
		and BUTTON_START

		jp z, .loop

		call mute_music
	.scroll_loop:
    	call wait_vblank_start
    	ld a, [rSCY]

    	dec a

    	ret z
    	
    	ld [rSCY], a
    	call render_update

    ; Loop until we reach the top.
    jr .scroll_loop

ret

set_screen_to_bottom::
    ld a, MAX_SCROLL_Y
    ld [rSCY], a
    ret

animate_start_button:
	call wait_vblank_start

	ld hl, $9A66
	ld a, [hl]
	cp $39
	jr z, .set_button

	ld a, $39
	REPT 7
		ld [hl+], a
	ENDR
	
	ret

	.set_button:
		ld a, $E0
		REPT 7
			ld [hl+], a
			inc a
		ENDR

	ret