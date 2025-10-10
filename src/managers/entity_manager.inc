DEF MAX_ENTITIES equ 40
DEF INVALID_COMPONENT equ $FF
DEF RESERVED_COMPONENT EQU $DE

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
DEF ENTITY_SIZE RB 0