SECTION "Movement Variables", WRAM0

frameCounter:: db ; De momento voy a poner esto en el main
def FRAME_LIMITER equ 4

SECTION "Entry point", ROM0[$150]

main::
   xor a
   ld [frameCounter], a

   call sc_game_init
   .loop:
      call wait_vblank_start
      ld a, [frameCounter]
      inc a
      ld [frameCounter], a
      cp FRAME_LIMITER
      jr nz, .skip

      xor a
      ld [frameCounter], a

      call movement_update
      call render_update

   .skip
      jr .loop