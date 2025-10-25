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

;; Audio registers 
DEF rNR10  equ $FF10 ;; Channel 1 sweep
DEF rNR11  equ $FF11 ;; Channel 1 length timer & duty cycle
DEF rNR12  equ $FF12 ;; Channel 1 volume and envelope
DEF rNR13  equ $FF13 ;; Channel 1 period low
DEF rNR14  equ $FF14 ;; Channel 1 period high and control

DEF rNR21  equ $FF16 ;; Channel 1 length timer & duty cycle
DEF rNR22  equ $FF17 ;; Channel 1 volume and envelope
DEF rNR23  equ $FF18 ;; Channel 1 period low
DEF rNR24  equ $FF19 ;; Channel 1 period high and control

DEF rNR41  equ $FF20 ;; Channel 4 length timer
DEF rNR42  equ $FF21 ;; Channel 4 volume and envelope
DEF rNR43  equ $FF22 ;; Channel 4 frequency and randomness
DEF rNR44  equ $FF23 ;; Channel 4 control

DEF rNR50  equ $FF24 ;; Master Volume & VIN panning
DEF rNR51  equ $FF25 ;; Sound panning
DEF rNR52  equ $FF26 ;; Audio master control

;; rLCDC bits
DEF rLCDC_LCD_ENABLE equ 7
DEF rLCDC_OBJ_16x8 equ 2
DEF rLCDC_OBJ_ENABLE equ 1
DEF rSTAT equ $FF41

;; Atributos de Sprite
DEF SPRITE_ATTR_FLIP_X equ %00100000  ; Bit 5 para el flip horizontal

DEF DEFAULT_PAL equ %11100100
DEF SPRITE_PAL equ %11100000
DEF VBLANK_START_LINE equ $90
DEF VRAM_TILE_START equ $8000
DEF VRAM_SCREEN_START equ $9800
DEF VRAM_TILE_SIZE equ $10
DEF VRAM_TILE_32 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

;; Joypad options
def SELECT_BUTTONS       equ $10
def SELECT_PAD           equ $20
def BUTTON_RIGHT         equ $01
def BUTTON_LEFT          equ $02
def BUTTON_UP            equ $04
def BUTTON_DOWN          equ $08
def BUTTON_A             equ $10
def BUTTON_B             equ $20
def BUTTON_SELECT        equ $40
def BUTTON_START         equ $80

; Tileset sizes
def SIZE_OF_MAINGAME equ 138 * 8 * 2
def SIZE_OF_MAURICIO equ 24 * 8 * 2
def SIZE_OF_ELEMENTS equ 81 * 8 * 2

def SCREEN_WIDTH  EQU $20
def SCREEN_HEIGHT EQU $20

;; Constantes para la colisi

def SPRITE_HEIGHT_2_SPRITES EQU 12
def SPRITE_WIDTH_2_SPRITES EQU 14

def ENEMY_HEIGHT EQU 10
def ENEMY_WIDTH EQU 6

def SPRITE_HEIGHT EQU 14
def SPRITE_WIDTH EQU 6

DEF FRAME_LIMITER EQU 4
DEF PLAYER_INITIAL_LIVES EQU 3
DEF PLAYER_INVINCIBILITY_FRAMES EQU 32

DEF SPEED EQU 1
DEF MAX_SPEED EQU 2
DEF MAX_ACCEL EQU 1
DEF JUMP_SPEED EQU -2
DEF JUMP_ACCEL EQU -2

; Define screen registers
DEF rSCY = $FF42
DEF rSCX = $FF43

; Define the maximum scroll value
DEF MAX_SCROLL_Y = 112

; Audio constants
DEF INIT_VOLUME EQU %01010101 ; 5 (available values: 0-8)
DEF MUTE_CHANNEL EQU 1
DEF UNMUTE_CHANNEL EQU 0
DEF CHANNEL_1 EQU 0
DEF CHANNEL_2 EQU 1

DEF INGREDIENTS_TO_WIN EQU 20
DEF LEVEL1 EQU 0
DEF LEVEL2 EQU 1
DEF LEVEL3 EQU 2
DEF LEFT_BORDER EQU $10
DEF RIGHT_BORDER_LEVEL1 EQU $58
DEF RIGHT_BORDER_LEVEL2 EQU $89

; HUD Constants (Score)
DEF HUD_SCORE_Y EQU 17
DEF HUD_SCORE_ICON_X EQU 11
DEF HUD_SCORE_X_X EQU 12
DEF HUD_SCORE_VALUE_X EQU 13

DEF TILE_ID_HUD_SCORE_ICON EQU $DF
DEF TILE_ID_HUD_X EQU $DE
DEF TILE_ID_NUM_0 EQU $D4

; HUD Constants (Lives)
DEF HUD_Y EQU 17
DEF HUD_VALUE_X EQU 1
DEF HUD_X_X EQU 2
DEF HUD_ICON_X EQU 3

DEF TILE_ID_HUD_ICON EQU $8C

; Game Logic Constants
DEF INGREDIENTS_PER_ORDER EQU 8
DEF POINTS_PER_INGREDIENT EQU 10
DEF POINTS_PER_ORDER_BONUS EQU 50
DEF POINTS_PER_EXTRA_LIFE EQU 1000