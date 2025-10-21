MACRO SET_BGP
   ;; Set Background Palette
   ld a, \1
   ld [rBGP], a
ENDM

MACRO SET_OBP1
   ;; Set Sprite Palette 1
   ld a, \1
   ld [rOBP1], a ;; rOBP1
ENDM

MACRO MEMCPY_256
   ;; MOVE TO VRAM
   ld hl, \1
   ld de, \2
   ld b, \3
   call memcpy_256
ENDM

MACRO LOAD_PROPERTY_TO_A
   ld h, d
   ld l, e
   ld de, \1
   add hl, de
   ld a, [hl] ;; a = property value
ENDM
  
MACRO AUDIO_OFF
   xor a
   ld [NR52], a   
ENDM

MACRO AUDIO_ON
   ld a, $FF
   ld [NR52], a   
ENDM