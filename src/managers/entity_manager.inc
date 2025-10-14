DEF MAX_SPRITES equ 40 ;; Max sprites allowed by Game Boy
DEF MAX_ENTITIES equ 20
DEF INVALID_COMPONENT equ $FF
DEF RESERVED_COMPONENT EQU $DE
DEF INIT_TAGS EQU %00000000

;;; Sprite Structure
;;; struct Sprite { unsigned char  x, y, tile, props; };
RSRESET
DEF S_X RB 1
DEF S_Y RB 1
DEF S_TILE RB 1
DEF S_PROPS RB 1
DEF SPRITE_SIZE RB 0

;;; Entity Structure
;;; struct Entity { unsigned char x, y, tile, props, tags; };
RSRESET
DEF E_X RB 1
DEF E_Y RB 1
DEF E_TILE RB 1
DEF E_PROPS RB 1
DEF E_TAGS RB 1
DEF E_SIZE_X RB 1
DEF E_SIZE_Y RB 1
DEF E_VEL_Y RB 1
DEF E_INIT_Y RB 1
DEF ENTITY_SIZE RB 0
EXPORT ENTITY_SIZE

DEF E_BIT_ALIVE EQU 7
DEF E_BIT_PROTA EQU 6
DEF E_BIT_ENEMY EQU 5 ;;If not prota and not enemy -> ingredient