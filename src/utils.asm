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
