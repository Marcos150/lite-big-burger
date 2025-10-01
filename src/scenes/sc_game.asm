SECTION "Scene Game", ROM0

sc_game_init::
   call wait_vblank_start

   ld a, DEFAULT_PAL
   ld [rBGP], a
   
   ld hl, fence_tiles
   ld de, VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)
   ld b, 2 * VRAM_TILE_SIZE
   call memcpy_256
	

	ret