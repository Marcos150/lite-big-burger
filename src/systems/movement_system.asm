INCLUDE "constants.inc"

DEF SPEED equ 1

; =============================================================================
; == DEFINICIÓN DE TILES Y ANIMACIÓN
; =============================================================================
DEF LADDER_TILE equ $96     ; Tile del personaje en la escalera.
DEF PROTA_WALK_TILE equ $8C ; Tile del personaje al caminar.
DEF LADDER_ANIM_SPEED equ 4 ; Velocidad de la animación.
; =============================================================================

SECTION "Movement System", ROM0

movement_update::
    ld hl, check_prota_movement
    call man_entity_for_each
    ret

check_prota_movement:
    call check_if_controllable
    ret z

    ld d, CMP_SPRITE_H
    call read_input

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

; =============================================================================
; == Rutina de Animación de Escalera (CORREGIDA)
; == Ahora salva y restaura los registros HL y DE para evitar corrupción.
; =============================================================================
animate_ladder_climb:
    push hl             ; Salvar HL para no corromperlo
    push de             ; Salvar DE
    
    ld hl, animation_frame_counter
    ld a, [hl]
    
    bit LADDER_ANIM_SPEED, a
    
    ld h, d             ; Hacemos que HL apunte al componente del sprite (Y)
    ld l, e
    inc hl              ; -> X
    inc hl              ; -> Tile
    inc hl              ; -> Atributos (Props)
    ld a, [hl]          ; Cargamos los atributos actuales

    jr z, .no_flip      ; Si el bit del contador es 0, no volteamos
    
.flip:
    or a, SPRITE_ATTR_FLIP_X ; Activamos el bit de volteo
    ld [hl], a
    jr .done

.no_flip:
    and a, %11011111         ; Desactivamos el bit de volteo
    ld [hl], a
    
.done:
    pop de              ; Restauramos DE
    pop hl              ; Restauramos HL
    ret

move_u:
    inc de
    ld a, [de]
    dec de
    cp $24
    jr z, .move
    cp $44
    jr nz, .no_ladder
.move:
    ld a, [de]
    cp $19
    jr z, .no_ladder
    sub a, SPEED
    ld [de], a

    ;-- Lógica de Escalera --
    push de
    inc de
    inc de
    ld a, LADDER_TILE
    ld [de], a
    pop de
    call animate_ladder_climb ; Llamamos a la animación

.no_ladder:
    ret

move_d:
    inc de
    ld a, [de]
    dec de
    cp $24
    jr z, .move
    cp $44
    jr nz, .no_ladder
.move:
    ld a, [de]
    cp $79
    jr z, .no_ladder
    add a, SPEED
    ld [de], a

    ;-- Lógica de Escalera --
    push de
    inc de
    inc de
    ld a, LADDER_TILE
    ld [de], a
    pop de
    call animate_ladder_climb ; Llamamos a la animación

.no_ladder:
    ret
    
; =============================================================================
; == move_r (CORREGIDA)
; == La lógica de volteo ahora es correcta y funciona como en el original.
; =============================================================================
move_r:
    ld a, [de]          ; Guardamos y en a para los calculos
    inc de              ; Seleccionamos la x
    cp $79              ; Cada comprobación aquí es para la base de las plataformas
    jr z, .move
    cp $61
    jr z, .move
    cp $49
    jr z, .move
    cp $31
    jr z, .move
    cp $19
    jr nz, .no_platform
.move:
    ;-- Restauramos el tile de caminar al original --
    push de             ; de apunta a X
    inc de              ; de apunta a Tile
    ld a, PROTA_WALK_TILE
    ld [de], a
    pop de              ; de vuelve a apuntar a X
    
    ld a, [de]          ; Guardamos x en a
    cp $58
    jr z, .no_platform
    add a, SPEED
    ld [de], a

    ;-- Lógica de volteo (CORREGIDA) --
    push af
    push hl
    ld h, d             ; de apunta a X, por tanto HL apunta a X
    ld l, e
    inc hl              ; HL ahora apunta a TILE
    inc hl              ; HL ahora apunta a PROPS
    ld a, [hl]
    or SPRITE_ATTR_FLIP_X
    ld [hl], a
    pop hl
    pop af

.no_platform:
    ret

move_l:
    ld a, [de]
    inc de
    cp $79
    jr z, .move
    cp $61
    jr z, .move
    cp $49
    jr z, .move
    cp $31
    jr z, .move
    cp $19
    jr nz, .no_platform
.move:
    push de
    inc de
    ld a, PROTA_WALK_TILE
    ld [de], a
    pop de
    
    ld a, [de]
    cp $10
    jr z, .no_platform
    sub a, SPEED
    ld [de], a

    push af
    push hl
    ld h, d
    ld l, e
    inc hl
    inc hl
    ld a, [hl]
    and %11011111
    ld [hl], a
    pop hl
    pop af

.no_platform:
    ret