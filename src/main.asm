SECTION "Entry point", ROM0[$150]

main::
   call sc_game_init
   .loop:
      call movement_update
      call render_update
      ;; sys.....
   jr .loop
   ret
   di
   halt
