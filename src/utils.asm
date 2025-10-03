INCLUDE "constants.inc"

SECTION "Utils", ROM0

;; LCD OFF
;; DESTROYS: AF, HL
lcd_off::
   ;; BEWARE!!
   call wait_vblank_start
   ld hl, rLCDC
   res rLCDC_LCD_ENABLE, [hl] ;; LCD OFF
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
   ld a, VBLANK_START_LINE
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MEMSET 256
;; INPUT:
;; HL: Destination Address
;; B: Bytes to set
;; A: BValue to write
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

;; DMA CODE
;; Inspired by Game Boy Coding Adventure Early Access, chapter 12

;; Function to call from the code
dma_copy::
   jp HRAM_DMA_FUNC

;; DMA activation code
dma_copy_func:
   ld a, high($C000)
   ldh [rDMA], a
   ld c, 40
   .wait_copy:
      dec c
   jr nz, .wait_copy
   ret
dma_copy_func_end:

def DMA_FUNC_SIZE equ (dma_copy_func_end - dma_copy_func)

rsset _HRAM

def HRAM_DMA_FUNC rb DMA_FUNC_SIZE
def HRAM_END rb 0

;; Checks that the DMA function is not too large, so it does not collide with other HRAM data
def HRAM_USAGE equ (HRAM_END - _HRAM)
println "HRAM usage: {d:HRAM_USAGE} bytes"
assert HRAM_USAGE <= $40, "Too many bytes used in HRAM"

;; Copies the DMA function to HRAM as ROM is unaccesible during DMA
init_dma_copy:
   ld hl, HRAM_DMA_FUNC
   ld de, dma_copy_func
   ld c, DMA_FUNC_SIZE
   .func_copy:
      ld a, [de]
      ld [hli], a
      inc de
      dec c
   jr nz, .func_copy
ret