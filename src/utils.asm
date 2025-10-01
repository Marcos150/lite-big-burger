INCLUDE "constants.inc"

SECTION "Utils", ROM0

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
