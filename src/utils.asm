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
init_dma_copy:
   ld de, HRAM_DMA_FUNC
   ld hl, dma_copy_func
   ld b, DMA_FUNC_SIZE
   jr memcpy_256
