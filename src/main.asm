INCLUDE "constants.inc"

SECTION "Tile Data" , ROM0

fence_tiles:
   DB $00, $00, $00, $00
   DB $3C, $3C, $7E, $7E
   DB $7E, $7E, $7A, $5E
   DB $72, $4E, $72, $4E
   DB $72, $4E, $72, $4E
   DB $56, $4A, $4E, $42
   DB $6A, $46, $34, $6E
   DB $18, $3C, $00, $00

SECTION "Entry point", ROM0[$150]

memcpy_256::
      ld a, [hl+]
      ld [de], a
      inc de
      dec b
   jr nz, memcpy_256
   ret

main::
   call wait_vblank_start

   ld a, DEFAULT_PAL
   ld [rBGP], a
   
   ld hl, fence_tiles
   ld de, VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)
   ld b, 2 * VRAM_TILE_SIZE
   call memcpy_256

   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)
