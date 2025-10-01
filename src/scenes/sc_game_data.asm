SECTION "Scene Game Data" , ROM0

;; Fence: 2 tiles
sc_game_fence_tiles::
   DB $00, $00, $00, $00
   DB $3C, $3C, $7E, $7E
   DB $7E, $7E, $7A, $5E
   DB $72, $4E, $72, $4E
   DB $72, $4E, $72, $4E
   DB $56, $4A, $4E, $42
   DB $6A, $46, $34, $6E
   DB $18, $3C, $00, $00

sc_game_sprite_1:: DB 32, 16, $20, %00000000
sc_game_sprite_2:: DB 32, 120, $20, %00000000