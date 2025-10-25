INCLUDE "constants.inc"

SECTION "Utils", ROM0

;; LCD OFF
;; DESTROYS: AF, HL
lcd_off::
   ;; BEWARE!!
   di
   call wait_vblank_start
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

wait_vblank_start::
   ld hl, rLY
   ld a, $90
   .loop:
      cp [hl]
   jr nz, .loop
ret

;; E=> Times
wait_vblank_ntimes::
   .do:
      call wait_vblank_start
      call consume_time
      dec e
   jr nz, .do
ret

consume_time:
   ld b, 127
   .do:
      nop
      nop
      dec b
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
ld      a, b
or      c
ret     z

.copy_loop:
   ld      a, [hl+]
   ld      [de], a
   inc     de
   dec     bc
   ld      a, b
   or      c
   jr      nz, .copy_loop

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
;; Inspired by Game Boy Coding Adventure Early Access, chapter 12
;; Code available here: https://github.com/mdagois/gca

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
println "HRAM usage: {d:HRAM_USAGE} bytes"
assert HRAM_USAGE <= $40, "Too many bytes used in HRAM"

;; Copies the DMA function to HRAM
init_dma_copy::
   ld de, HRAM_DMA_FUNC
   ld hl, dma_copy_func
   ld b, DMA_FUNC_SIZE
   jr memcpy_256


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Converts a 16-bit value in HL to 4-digit BCD
;; OUTPUT: [wTempBCDBuffer] = 4 bytes (digits 0000-9999)
;; DESTROYS: A, B, C, DE, HL
;;
utils_bcd_convert_16bit::
    ld de, wTempBCDBuffer
    xor a
    ld [de], a
    inc de
    ld [de], a
    inc de
    ld [de], a
    inc de
    ld [de], a
    
    ld de, wTempBCDBuffer

    ld bc, 1000
    call .bcd_digit
    inc de
    
    ld bc, 100
    call .bcd_digit
    inc de
    
    ld bc, 10
    call .bcd_digit
    inc de

    ld a, l
    ld [de], a
    ret

;; --- REVISED BCD SUB-ROUTINE ---
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CHECK PAD
;; RETURNS:
;; B: Current state of the joypad
;; 
;; DESTROYS: A, B, HL
;;

check_pad::
   ld a, SELECT_PAD
   ld hl, rJOYP
   ld [rJOYP], a ;;Select pad
   ld b, [hl]
   ld b, [hl]
   ld b, [hl]

   ret

check_buttons::
   ld a, SELECT_BUTTONS
   ld hl, rJOYP
   ld [rJOYP], a ;;Select pad
   ld b, [hl]
   ld b, [hl]
   ld b, [hl]

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

;;-------------------------------------------------------
;; Input: BC, DE (Two 16-bit numbers)
;; Output: BC = BC - DE
;; Condition: HL cannot be used
sub_bc_de::
   ld a, e
   sub a, c
   ld e, a

   ld a, d
   sbc a, b ;; sbc -> sub con acarreo
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
   call memcpy_256

   ret

find_first_set_bit_index::
    ld b, 0
    cp 0
    ret z
.loop
    rrca
    ret c
    inc b
    jr .loop