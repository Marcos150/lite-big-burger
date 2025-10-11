;; I/O Registers
DEF rLY equ $FF44
DEF rBGP equ $FF47
def rLCDC equ $FF40
def rOBP1 equ $FF48
def rOBP2 equ $FF49
def rJOYP equ $FF00
def rDMA  equ $FF46
def _HRAM equ $FF80
def _WRAM equ $C000

;; rLCDC bits
DEF rLCDC_LCD_ENABLE equ 7
DEF rLCDC_OBJ_16x8 equ 2
DEF rLCDC_OBJ_ENABLE equ 1

;; Atributos de Sprite <-- AÑADIDO AQUÍ, EN UN LUGAR LÓGICO
DEF SPRITE_ATTR_FLIP_X equ %00100000  ; Bit 5 para el flip horizontal

DEF DEFAULT_PAL equ %11100100
DEF SPRITE_PAL equ %11100000
DEF VBLANK_START_LINE equ $90
DEF VRAM_TILE_START equ $8000
DEF VRAM_SCREEN_START equ $9800
DEF VRAM_TILE_SIZE equ $10
DEF VRAM_TILE_32 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

;; Joypad options
def SELECT_BUTTONS   equ $10
def SELECT_PAD       equ $20
def BUTTON_RIGHT     equ $01
def BUTTON_LEFT      equ $02
def BUTTON_UP        equ $04
def BUTTON_DOWN      equ $08
def BUTTON_A         equ $10
def BUTTON_B         equ $20
def BUTTON_SELECT    equ $40
def BUTTON_START     equ $80

; Tileset sizes
def SIZE_OF_MAINGAME equ 138 * 8 * 2
def SIZE_OF_MAURICIO equ 24 * 8 * 2
def SIZE_OF_ELEMENTS equ 56 * 8 * 2

def SCREEN_WIDTH  EQU $20
def SCREEN_HEIGHT EQU $20

;; <-- HE ELIMINADO LAS LÍNEAS DUPLICADAS DE AQUÍ
