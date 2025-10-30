INCLUDE "constants.inc"

SECTION "Render System Data", WRAM0

gConveyorBeltTimer: DS 1

SECTION "Render System Code", ROM0

def OAM_START equ $FE00
def CONVEYOR_BELT_ANIM_DELAY equ 10
def TILESET_BELT_START   equ $9A00
def TILE_BELT_A_START equ $26
def TILE_BELT_B_START equ $29
def TILE_BELT_OFFSET     equ 3

render_update::
   call dma_copy
   call animate_conveyor_belt

   ;; If invincible, change prota's palette every 2 frames
   ld a, [wPlayerInvincibilityTimer]
   bit 0, a
   ret z

   ld hl, rOBP2
   swap [hl]

   ret

animate_conveyor_belt::
    ld a, [gConveyorBeltTimer]
    or a ;; cp 0
    jr nz, .decrement_counter

    call wait_vblank_start
    ld a, CONVEYOR_BELT_ANIM_DELAY
    ld [gConveyorBeltTimer], a
    ld hl, TILESET_BELT_START
    ld b, $15 ; B = 20

.anim_loop:
    ld a, [hl]  ; Carga el tile actual
    ld c, a     ; Guarda el tile original en C

    ; --- Comprueba si es un tile del Frame A ($26-$28) ---
    sub TILE_BELT_A_START ; A = A - $26
    cp TILE_BELT_OFFSET   ; Compara con 3 (para 0, 1, 2)
    jr nc, .check_frame_b ; Si A >= 3, no está en el rango

    ; Está en el rango A. Cambiamos a Frame B.
    ld a, c               ; Recupera el tile original
    add TILE_BELT_OFFSET  ; A = A + 3
    ld [hl], a            ; Guarda el tile actualizado
    jr .next_tile

.check_frame_b:
    ; --- Comprueba si es un tile del Frame B ($29-$2B) ---
    ld a, c               ; Recupera el tile original
    sub TILE_BELT_B_START ; A = A - $29
    cp TILE_BELT_OFFSET   ; Compara con 3
    jr nc, .next_tile     ; Si A >= 3, no está en el rango

    ; Está en el rango B. Cambiamos a Frame A.
    ld a, c               ; Recupera el tile original
    sub TILE_BELT_OFFSET  ; A = A - 3
    ld [hl], a            ; Guarda el tile actualizado

.next_tile:
    inc hl      ; Siguiente tile en el mapa
    dec b       ; Decrementa el contador de tiles
    jr nz, .anim_loop
    ret

.decrement_counter:
    ; --- 3. Solo decrementar y salir ---
    dec a
    ld [gConveyorBeltTimer], a
    ret