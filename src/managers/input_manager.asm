INCLUDE "constants.inc"

SECTION "Input Manager", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; READ INPUT
; RETURNS:: B: state of input
;   Bit 0: A
;   Bit 1: B
;   Bit 2: Select
;   Bit 3: Start
;   Bit 4: Right
;   Bit 5: Left
;   Bit 6: Up
;   Bit 7: Down
read_input::
    ld hl, rJOYP
    ld [hl], SELECT_PAD
    
    ld a, [hl]
    ld a, [hl]
    
    ; Leer y complementar (activos en bajo)
    ld a, [hl]
    cpl               ; Complementar (invertir)
    and $0F           ; Mantener los primeros 4 bits
    ld b, a           ; Guardar D-pad en B
    
    ; Seleccionar botones de acción
    ld [hl], SELECT_BUTTONS
    
    ; Esperar estabilización
    ld a, [hl]
    ld a, [hl]
    
    ; Leer y complementar
    ld a, [hl]
    cpl               ; Complementar (invertir)
    and $0F           ; Mantener los primeros 4 bits
    swap a            ; Invertir a
    or b              ; Complementar b
    ld b, a           ; Asignar b
    ld [hl], $30      ; Resetear PAD

    ret