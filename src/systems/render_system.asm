INCLUDE "constants.inc"

SECTION "Render System Code", ROM0

DEF OAM_START equ $FE00

render_update::
   call dma_copy

   ;; If invincible, change prota's palette every 2 frames
   ld a, [wPlayerInvincibilityTimer]
   bit 0, a
   ret z

   ld hl, rOBP2
   swap [hl]

   ret