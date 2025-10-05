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

DEF DEFAULT_PAL equ %11100100
DEF VBLANK_START_LINE equ $90
DEF VRAM_TILE_START equ $8000
DEF VRAM_TILE_SIZE equ $10
DEF VRAM_TILE_32 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

;; Joypad options
def SELECT_BUTTONS     equ $10
def SELECT_PAD         equ $20
def PAD_R         	   equ 0
def PAD_L         	   equ 1
def PAD_U              equ 2
def PAD_D              equ 3