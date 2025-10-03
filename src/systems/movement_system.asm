INCLUDE "constants.inc"

;; ========================================
;; CONFIGURACIÓN: Velocidad de movimiento
;; ========================================
;; Puedes cambiar este valor para ajustar qué tan rápido se mueve el protagonista
DEF SPEED equ 2

SECTION "Movement System Data", WRAM0
;; Variables temporales para almacenar la nueva posición antes de aplicarla
temp_new_y: DS 1  ;; Nueva coordenada Y propuesta
temp_new_x: DS 1  ;; Nueva coordenada X propuesta

SECTION "Movement System Code", ROM0

;; ========================================
;; Sistema de movimiento con detección de colisiones
;; Lee el estado del pad y mueve al protagonista si no hay colisiones
;; ========================================
sys_movement_update::
   ;; Obtener el sprite del protagonista desde el entity manager
   call man_entity_get_sprite_components
   ld d, h
   ld e, l
   ;; DE ahora apunta a los datos del sprite del protagonista [Y, X, Tile, Attr]

   ;; Leer el estado de los botones presionados
   call check_pad
   ;; B: Estado del pad (botones presionados)
   
   ;; Guardar la posición actual en variables temporales
   ;; Esto permite probar la nueva posición antes de aplicarla
   ld a, [de]              ;; Leer Y actual
   ld [temp_new_y], a      ;; Guardar en temporal
   inc de
   ld a, [de]              ;; Leer X actual
   ld [temp_new_x], a      ;; Guardar en temporal
   dec de
   ;; DE vuelve a apuntar a Y

   ;; ========================================
   ;; Verificar movimiento VERTICAL (arriba/abajo)
   ;; ========================================
   ld a, [de]  ;; A = Y actual del protagonista
   
   ;; Verificar si se presiona ARRIBA
   bit PAD_U, b
   jr z, .try_move_u
   
   ;; Verificar si se presiona ABAJO
   bit PAD_D, b
   jr z, .try_move_d
   
   ;; Si no hay movimiento vertical, verificar horizontal
   jr .check_horizontal

.try_move_u:
   ;; Intentar mover hacia ARRIBA
   sub a, SPEED            ;; Restar SPEED a Y (arriba en pantalla)
   ld [temp_new_y], a      ;; Guardar nueva Y propuesta
   call check_collision_at_new_pos  ;; Verificar si hay colisión
   jr c, .blocked          ;; Si carry=1, hay colisión, no mover
   ld a, [temp_new_y]      ;; Si no hay colisión, aplicar nueva Y
   ld [de], a
   ret

.try_move_d:
   ;; Intentar mover hacia ABAJO
   add a, SPEED            ;; Sumar SPEED a Y (abajo en pantalla)
   ld [temp_new_y], a      ;; Guardar nueva Y propuesta
   call check_collision_at_new_pos  ;; Verificar si hay colisión
   jr c, .blocked          ;; Si carry=1, hay colisión, no mover
   ld a, [temp_new_y]      ;; Si no hay colisión, aplicar nueva Y
   ld [de], a
   ret

   ;; ========================================
   ;; Verificar movimiento HORIZONTAL (izquierda/derecha)
   ;; ========================================
.check_horizontal:
   inc de                  ;; Mover puntero a X
   ld a, [de]              ;; A = X actual del protagonista
   
   ;; Verificar si se presiona DERECHA
   bit PAD_R, b
   jr z, .try_move_r
   
   ;; Verificar si se presiona IZQUIERDA
   bit PAD_L, b
   jr z, .try_move_l
   ret

.try_move_r:
   ;; Intentar mover hacia la DERECHA
   add a, SPEED            ;; Sumar SPEED a X (derecha en pantalla)
   ld [temp_new_x], a      ;; Guardar nueva X propuesta
   call check_collision_at_new_pos  ;; Verificar si hay colisión
   jr c, .blocked          ;; Si carry=1, hay colisión, no mover
   ld a, [temp_new_x]      ;; Si no hay colisión, aplicar nueva X
   ld [de], a
   ret

.try_move_l:
   ;; Intentar mover hacia la IZQUIERDA
   sub a, SPEED            ;; Restar SPEED a X (izquierda en pantalla)
   ld [temp_new_x], a      ;; Guardar nueva X propuesta
   call check_collision_at_new_pos  ;; Verificar si hay colisión
   jr c, .blocked          ;; Si carry=1, hay colisión, no mover
   ld a, [temp_new_x]      ;; Si no hay colisión, aplicar nueva X
   ld [de], a
   ret

.blocked:
   ;; Si hay colisión, no se aplica el movimiento
   ;; El sprite mantiene su posición actual
   ret

;; ========================================
;; Verificar si habrá colisión en la nueva posición propuesta
;; Usa detección AABB (Axis-Aligned Bounding Box)
;; Returns: Carry flag = 1 si HAY colisión, 0 si NO hay colisión
;; ========================================
check_collision_at_new_pos::
   push de
   push bc
   
   ;; Cargar la nueva posición propuesta del protagonista
   ld a, [temp_new_y]
   ld b, a         ;; B = nueva Y del protagonista
   ld a, [temp_new_x]
   ld c, a         ;; C = nueva X del protagonista
   
   ;; Obtener la posición del objeto de colisión desde WRAM
   ld hl, sc_game_colision
   ld a, [hl+]     ;; A = Y del objeto de colisión
   ld d, a
   ld a, [hl]      ;; A = X del objeto de colisión
   ld e, a
   
   ;; ========================================
   ;; Detección de colisión AABB (cajas delimitadoras alineadas a ejes)
   ;; CONFIGURACIÓN: Tamaños de las cajas de colisión
   ;; - Protagonista: 8 píxeles de ancho x 16 píxeles de alto
   ;; - Objeto de colisión: 8 píxeles de ancho x 16 píxeles de alto
   ;; PUEDES CAMBIAR: Los valores "16" y "8" en las sumas para ajustar el tamaño de las hitboxes
   ;; ========================================
   
   ;; Verificar solapamiento en el eje Y
   ld a, b
   add a, 16       ;; A = Y_protagonista + altura (PUEDES CAMBIAR: 16 = altura del sprite)
   cp d            ;; Comparar con Y_colision
   jr c, .no_collision  ;; Si Y_prota+altura < Y_colision, no hay colisión
   
   ld a, d
   add a, 16       ;; A = Y_colision + altura (PUEDES CAMBIAR: 16 = altura del sprite)
   cp b            ;; Comparar con Y_protagonista
   jr c, .no_collision  ;; Si Y_colision+altura < Y_prota, no hay colisión
   
   ;; Verificar solapamiento en el eje X
   ld a, c
   add a, 8        ;; A = X_protagonista + ancho (PUEDES CAMBIAR: 8 = ancho del sprite)
   cp e            ;; Comparar con X_colision
   jr c, .no_collision  ;; Si X_prota+ancho < X_colision, no hay colisión
   
   ld a, e
   add a, 8        ;; A = X_colision + ancho (PUEDES CAMBIAR: 8 = ancho del sprite)
   cp c            ;; Comparar con X_protagonista
   jr c, .no_collision  ;; Si X_colision+ancho < X_prota, no hay colisión
   
   ;; Si llegamos aquí, HAY COLISIÓN en ambos ejes
   pop bc
   pop de
   scf             ;; Set carry flag (indica colisión)
   ret

.no_collision:
   ;; No hay colisión, el movimiento es válido
   pop bc
   pop de
   or a            ;; Clear carry flag (indica sin colisión)
   ret