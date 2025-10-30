INCLUDE "constants.inc"

SECTION "Utils", ROM0

;; LCD OFF
;; DESTROYS: AF, HL
lcd_off::
    ;; BEWARE!!
    di
    call wait_vblank_start_no_interrupt
    ld hl, rLCDC
    res 7, [hl] ;; LCD OFF
    ei
    ret

;; LCD ON
;; DESTROYS: AF, HL
lcd_on::
    ld hl, rLCDC
    set rLCDC_LCD_ENABLE, [hl] ;; LCD ON
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VBLANK
;; DESTROYS AF, HL

wait_vblank_start_no_interrupt::
    ld hl, rLY
    ld a, $90
.loop:
    cp [hl]
    jr nz, .loop
ret

wait_vblank_start::
    halt
ret

;; E=> Times
wait_vblank_ntimes::
.do:
    call wait_vblank_start
    dec e
    jr nz, .do
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MEMCPY
;; INPUT:
;; HL: Source Address
;; DE: Destiny Address
;; B: Bytes to copy
;; 
;; DESTROYS: AF, B, HL, DE
;;

memcpy_256::
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, memcpy_256
    ret

;; BC: Bytes to copy
;; DESTROYS: AF, BC, HL, DE

memcpy::
    ld a, b
    or c
    ret z

.copy_loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .copy_loop

ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MEMCPY_MAPS
;; INPUT:
;; HL: Source Address
;; DE: Destiny Address
;; B: Colums to copy
;; 
;; DESTROYS: AF, BC, HL, DE
;;

memcpy_maps::
    ld a, b
    or a
    ret z

.row_loop:
    ld c, 20 ; C = 20

.column_loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .column_loop

    push hl
    push bc
    
    ; Movemos DE a HL para poder sumar
    ld h, d
    ld l, e

    ; Cargamos el salto (12)
    ld bc, 12
    add hl, bc

    ; Movemos el resultado de vuelta a DE
    ld d, h
    ld e, l
    
    ; Restauramos
    pop bc
    pop hl

    ; Siguiente fila
    dec b
    jr nz, .row_loop

    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MEMSET 256
;; INPUT:
;; HL: Destination Address
;; B: Bytes to set
;; A: Value to write
;; 
;; DESTROYS: AF, B, HL
;;

memset_256::
    ld [hl+], a
    dec b
    jr nz, memset_256
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DMA CODE

;; Function to call from our code. Initializes the DMA
dma_copy::
    jp HRAM_DMA_FUNC

;; DMA activation code. This is the code that needs to be copied to the HRAM as ROM is unaccessible during DMA
dma_copy_func:
    ld a, CMP_SPRITE_H
    ldh [rDMA], a
    ld c, 40
.wait_copy:
    dec c
    jr nz, .wait_copy
    ret
dma_copy_func_end:

;; Size of the code that has to be copied to the HRAM
def DMA_FUNC_SIZE equ (dma_copy_func_end - dma_copy_func)

rsset _HRAM

def HRAM_DMA_FUNC rb DMA_FUNC_SIZE
def HRAM_END rb 0

;; Checks that the DMA function is not too large, so it does not collide with other HRAM data
def HRAM_USAGE equ (HRAM_END - _HRAM)
assert HRAM_USAGE <= $40, "Too many bytes used in HRAM. Bytes in HRAM: {d:HRAM_USAGE}"

;; Copies the DMA function to HRAM
init_dma_copy::
    ld de, HRAM_DMA_FUNC
    ld hl, dma_copy_func
    ld b, DMA_FUNC_SIZE
    jr memcpy_256


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts a 16-bit value in HL to 5-digit BCD
;; OUTPUT: [wTempBCDBuffer] = 5 bytes (digits 00000-65535)
;; DESTROYS: A, B, C, DE, HL
;;
utils_bcd_convert_16bit::
    ld de, wTempBCDBuffer
    xor a
    ld [de], a  ; Pone a 0 el dígito 1 (Decenas de millar)
    inc de
    ld [de], a  ; Pone a 0 el dígito 2 (Unidades de millar)
    inc de
    ld [de], a  ; Pone a 0 el dígito 3 (Centenas)
    inc de
    ld [de], a  ; Pone a 0 el dígito 4 (Decenas)
    inc de
    ld [de], a  ; Pone a 0 el dígito 5 (Unidades)
    
    ld de, wTempBCDBuffer ; Reinicia el puntero al buffer

    ; --- Decenas de Millar (10000s) ---
    ld bc, 10000
    call .bcd_digit
    inc de

    ; --- Unidades de Millar (1000s) ---
    ld bc, 1000
    call .bcd_digit
    inc de
    
    ; --- Centenas (100s) ---
    ld bc, 100
    call .bcd_digit
    inc de
    
    ; --- Decenas (10s) ---
    ld bc, 10
    call .bcd_digit
    inc de

    ; --- Unidades (1s) ---
    ld a, l       ; Lo que queda en HL (específicamente en L) son las unidades
    ld [de], a
    ret

;; --- REVISED BCD SUB-ROUTINE ---
; (Esta sub-rutina no se ha modificado, ya era correcta)
.bcd_digit:
    xor a
.digit_loop:
    ;; Compare hl with bc (16-bit)
    ld a, h
    cp a, b
    jr c, .digit_done
    jr nz, .subtract

    ld a, l
    cp a, c
    jr c, .digit_done

.subtract:
    ;; hl = hl - bc
    ld a, l
    sub a, c
    ld l, a
    ld a, h
    sbc a, b
    ld h, a

    ;; inc counter (a)
    ld a, [de]
    inc a
    ld [de], a

    jr .digit_loop

.digit_done:
    ret

simulated_call_hl::
    jp hl

;;-------------------------------------------------------
;; Input: DE, BC (Two 16-bit numbers)
;; Output: DE = DE + BC
;; Condition: HL cannot be used
add_de_bc::
    ld a, e
    add a, c
    ld e, a

    ld a, d
    adc a, b ;; adc -> add con acarreo
    ld d, a
ret

;; INPUT:  A = number
;; OUTPUT: A
get_closest_divisible_by_8::
    and %11111000
ret
    
;; CREATE ONE ENTITY
;; HL: Entity Template Data
create_one_entity::
    push hl ;; Save Template Address
    
    .reserve_space_for_entity
    call man_entity_alloc
    ;; HL: Component Address (write)

    .copy_info_cmp
    ld d, h
    ld e, l
    pop hl ;; HL -> Entity Template Data
    push hl
    push de
    ld b, SIZEOF_CMP
    call memcpy_256

    .copy_sprite_cmp
    pop de
    pop hl
    ld d, CMP_SPRITE_H
    ld bc, SIZEOF_CMP
    add hl, bc
    push hl
    push de
    ld b, c
    call memcpy_256

    .copy_physics_cmp
    pop de
    pop hl
    ld d, CMP_PHYSICS_H
    ld bc, SIZEOF_CMP
    add hl, bc
    ld b, c
    jp memcpy_256

find_first_set_bit_index::
    ld b, 0
    or a ;; cp 0
    ret z
.loop
    rrca
    ret c
    inc b
    jr .loop