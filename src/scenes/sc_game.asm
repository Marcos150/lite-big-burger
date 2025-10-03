INCLUDE "constants.inc"
INCLUDE "macros.inc"

DEF VRAM_TILE_20 equ VRAM_TILE_START + ($20 * VRAM_TILE_SIZE)

;; ========================================
;; WRAM: Datos del objeto de colisión
;; ========================================
SECTION "Scene Game Data WRAM", WRAM0
;; Bloque: 2 sprites (arriba y abajo), 4 bytes cada uno = 8 bytes total
;; Formato: [Y1, X1, Tile1, Attr1, Y2, X2, Tile2, Attr2]
sc_game_colision:: DS 8
EXPORT sc_game_colision

SECTION "Scene Game", ROM0

;; ========================================
;; Inicialización de la escena del juego
;; Configura entidades, sprites, tiles y LCD
;; ========================================
sc_game_init::
   ;; Inicializar el sistema de entidades
   call man_entity_init
   
   ;; ========================================
   ;; CREAR PROTAGONISTA
   ;; ========================================
   call man_entity_alloc  ;; Reservar memoria para la entidad protagonista
   ;; HL ahora apunta al componente sprite del protagonista
   
   SET_BGP DEFAULT_PAL
   SET_OBP1 DEFAULT_PAL
   ;; HL: Component Address (write)
   ld d, h
   ld e, l
   ;; Copiar datos del sprite del protagonista
   ld hl, sc_game_sprite_prota
   ld b, 4  ;; 4 bytes: Y, X, Tile, Atributos
   call memcpy_256

   ;; ========================================
   ;; CREAR OBJETO DE COLISIÓN (2 sprites)
   ;; PUEDES CAMBIAR: Las coordenadas Y, X y los tiles
   ;; ========================================
   ld hl, sc_game_colision
   
   ;; Sprite superior del objeto de colisión
   ld a, 60        ;; PUEDES CAMBIAR: Coordenada Y inicial
   ld [hl+], a
   ld a, 80        ;; PUEDES CAMBIAR: Coordenada X inicial
   ld [hl+], a
   ld a, $20       ;; PUEDES CAMBIAR: Tile superior
   ld [hl+], a
   ld a, %00010000 ;; Atributos (palette 1)
   ld [hl+], a
   
   ;; Sprite inferior del objeto de colisión
   ld a, 68        ;; Y (60 + 8 píxeles) - alineado con sprite superior
   ld [hl+], a
   ld a, 80        ;; X (misma X que sprite superior)
   ld [hl+], a
   ld a, $21       ;; PUEDES CAMBIAR: Tile inferior
   ld [hl+], a
   ld a, %00010000 ;; Atributos (palette 1)
   ld [hl], a

   ;; ========================================
   ;; CONFIGURACIÓN DE VIDEO
   ;; ========================================
   call lcd_off
   
   ;; Copiar tiles del juego a VRAM
   ld hl, main_game_tiles
   ld de, VRAM_TILE_START
   ld bc, SIZE_OF_MAINGAME
   call memcpy

   ;; Copiar tiles de mauricio a VRAM
   ld hl, mauricio
   ld bc, SIZE_OF_MAURICIO
   call memcpy

   ;; Activar sprites en el LCD
   ld hl, rLCDC
   set rLCDC_OBJ_ENABLE, [hl]  ;; Habilitar objetos/sprites
   set rLCDC_OBJ_16x8, [hl]    ;; Usar sprites de 8x16 píxeles

   call lcd_on

   ;; ========================================
   ;; COPIAR OBJETO DE COLISIÓN A OAM
   ;; El objeto queda fijo en pantalla durante todo el juego
   ;; ========================================
   ld hl, sc_game_colision
   ld de, $FE04  ;; OAM posición 1 (después del protagonista en $FE00)
   ld b, 8       ;; 2 sprites × 4 bytes
   call memcpy_256

   ret

;; ========================================
;; Bucle principal del juego
;; Actualiza movimiento y renderizado continuamente
;; ========================================
sc_game_run::
   .loop:
      call sys_movement_update  ;; Actualizar movimiento del protagonista
      call sys_render_update    ;; Actualizar renderizado de sprites
      ;; sys.....
   jr .loop
   ret