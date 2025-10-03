INCLUDE "constants.inc"

DEF SPEED equ 1

SECTION "Movement System Code", ROM0

sys_movement_update::

   ;; For now we will act like the first sprite is always the protagonist one
   check_prota_movement:
      call man_entity_get_sprite_components
      ;; HL: sprite_components
      ld d, h ;; DE: sprite_components
      ld e, l

      call check_pad
      ;; B: State of the pad
      ld a, [de]

      bit PAD_U, b
      jr z, move_u
      bit PAD_D, b
      jr z, move_d

      inc de
      ld a, [de]
      bit PAD_R, b
      jr z, move_r
      bit PAD_L, b
      jr z, move_l

      ret

      move_r:
         add a, SPEED
         ld [de], a
         ret

      move_l:
         sub a, SPEED
         ld [de], a
         ret

      move_u:
         sub a, SPEED
         ld [de], a
         ret

      move_d:
         add a, SPEED
         ld [de], a
         ret