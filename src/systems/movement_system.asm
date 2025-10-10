INCLUDE "constants.inc"

DEF SPEED equ %1

SECTION "Movement System", ROM0

movement_update::
   ;; Left ladder X: 24
   ;; Left ladder X: 44
   ;; Spawn point X: 34, Y: 79
   ;; Platforms  [Y: 79, Y: 61, Y: 49, Y: 31, Y: 19]
   ;; Limits     {X: 10, X: 58}
   ;; Falls      {X: 2B, X: 3C}

   ;; TO-DO
   ;; ----------------------------------------------------------
   ;; IF Mauricio.x != 24 && Mauricio.x != 44: Disable UP_MOVE && DOWN_MOVE
   ;; IF Mauricio.y => 19: Disable UP_MOVE
   ;; IF Mauricio.y <= 79: Disable DOWN_MOVE
   ;; IF Mauricio.x <= 10: Disable LEFT_MOVE
   ;; IF Mauricio.x >= 58: Disable RIGHT_MOVE
   ;; IF Mauricio.x >= 2B && Mauricio.x <= 3C: Disable ALL_MOVE && Mauricio.FALL


   check_prota_movement:
      ;; For now we will act like the first sprite is always the protagonist one
      call man_entity_get_sprite_components
      ;; HL: sprite_components
      ld d, h ;; DE: sprite_components
      ld e, l

      call read_input
      ;; B: State of the pad

      ld a, b
      and BUTTON_UP
      jr z, .no_u
      call move_u
   .no_u:
      ld a, b
      and BUTTON_DOWN
      jr z, .no_d
      call move_d
   .no_d:
      ld a, b
      and BUTTON_RIGHT
      jr z, .no_r
      call move_r
   .no_r:
      ld a, b
      and BUTTON_LEFT
      jr z, .no_l
      call move_l
   .no_l:
      ret

      move_r:
         inc de
         ld a, [de]
         add a, SPEED
         ld [de], a
         ret

      move_l:
         inc de
         ld a, [de]
         sub a, SPEED
         ld [de], a
         ret

      move_u:
         ld a, [de]
         sub a, SPEED
         ld [de], a
         ret

      move_d:
         ld a, [de]
         add a, SPEED
         ld [de], a
         ret