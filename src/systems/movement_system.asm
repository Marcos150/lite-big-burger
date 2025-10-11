INCLUDE "constants.inc"

DEF SPEED equ 1

SECTION "Movement System", ROM0

movement_update::
   ld hl, check_prota_movement ;; HL = Function to be executed by every entity 
   call man_entity_for_each ;; Processes entities with the specified function
   ret

   check_prota_movement:
      push de
      call check_if_prota
      pop de
      ret z ;; If entity is not main char, do nothing 

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

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; MOVIMIENTO DE MAURICIO EN LAS PLATAFORMAS
   ;; ¡¡ Los números son hexadecimales !!
   ;; Left ladder X: 24
   ;; Left ladder X: 44
   ;; Spawn point X: 34, Y: 79
   ;; Platforms  [Y: 79, Y: 61, Y: 49, Y: 31, Y: 19]
   ;; Limits     {X: 10, X: 58}
   ;; Falls      {X: 2B, X: 3C}

      move_u:
         inc de               ; Seleccionamos la x
         ld a, [de]           ; Guardamos x en a para los cálculos
         dec de               ; Volvemos a la y
            cp $24            ; Comrobamos si su x está en la escalera izquierda
            jr z, .move
            cp $44            ; Comrobamos si su x está en la escalera derecha
            jr nz, .no_ladder
         .move:
         ld a, [de]           ; Guardamos y en a 
            cp $19            ; Si está en la plataforma superior no le dejamos moverse
            jr z, .no_ladder
         sub a, SPEED         ; Calculamos la nueva posición del sprite
         ld [de], a           ; La guardamos
         .no_ladder:
         ret

      move_d:
         inc de               ; Seleccionamos la x
         ld a, [de]           ; Guardamos x en a para los cálculos
         dec de               ; Volvemos a la y
            cp $24            ; Comrobamos si su x está en la escalera izquierda
            jr z, .move
            cp $44            ; Comrobamos si su x está en la escalera derecha
            jr nz, .no_ladder
         .move:
         ld a, [de]           ; Guardamos y en a 
            cp $79            ; Si está en la plataforma inferior no le dejamos moverse
            jr z, .no_ladder
         add a, SPEED         ; Calculamos la nueva posición del sprite
         ld [de], a           ; La guardamos
         .no_ladder:
         ret

      move_r:
         ld a, [de]           ; Guardamos y en a para los calculos
         inc de               ; Seleccionamos la x
            cp $79            ; Cada comprobación aquí es para la base de las plataformas
            jr z, .move
            cp $61            ; Estamos viendo si la y coincide con una plataforma
            jr z, .move
            cp $49
            jr z, .move
            cp $31
            jr z, .move
            cp $19
            jr nz, .no_platform
         .move:
         ld a, [de]           ; Guardamos x en a
         cp $58               ; Si está en el borde derecho no le dejamos moverse
            jr z, .no_platform
         add a, SPEED         ; Calculamos la nueva posición del sprite
         ld [de], a           ; La guardamos
         .no_platform:
         ret

      move_l:
         ld a, [de]           ; Guardamos y en a para los calculos
         inc de               ; Seleccionamos la x
            cp $79            ; Cada comprobación aquí es para la base de las plataformas
            jr z, .move
            cp $61            ; Estamos viendo si la y coincide con una plataforma
            jr z, .move
            cp $49
            jr z, .move
            cp $31
            jr z, .move
            cp $19
            jr nz, .no_platform
         .move:
         ld a, [de]           ; Guardamos x en a
            cp $10            ; Si está en el borde izquierdo no le dejamos moverse
            jr z, .no_platform
         sub a, SPEED         ; Calculamos la nueva posición del sprite
         ld [de], a           ; La guardamos
         .no_platform:
         ret