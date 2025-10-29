include "sound/huge_driver/include/hUGE.inc"

SECTION "musiquita Song Data", ROM0

musiquita::
db 7
dw order_cnt
dw order1, order2, order3, order4
dw duty_instruments, wave_instruments, noise_instruments
dw routines
dw waves

order_cnt: db 8
order1: dw P0,P0,P0,P0
order2: dw P0,P0,P0,P0
order3: dw P14,P2,P6,P10
order4: dw P0,P0,P0,P0

P0:
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P2:
 dn D_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_5,1,$000
 dn F_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn A_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_5,1,$000
 dn F_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn A_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_5,1,$000
 dn F_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn A_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn A_5,1,$000
 dn F_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn A_5,1,$000
 dn ___,0,$C00
 dn ___,0,$D01
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P6:
 dn E_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_5,1,$000
 dn G_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn B_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn E_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_5,1,$000
 dn G_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn B_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn E_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_5,1,$000
 dn G_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn B_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn E_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn B_5,1,$000
 dn G_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn B_5,1,$000
 dn ___,0,$C00
 dn ___,0,$D01
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P10:
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn A#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn A#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn A#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn D_6,1,$000
 dn A#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn D_6,1,$000
 dn ___,0,$C00
 dn ___,0,$D01
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

P14:
 dn C_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_5,1,$000
 dn D#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_5,1,$000
 dn D#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_5,1,$000
 dn D#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn C_5,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn G_5,1,$000
 dn D#6,1,$000
 dn ___,0,$C00
 dn ___,0,$000
 dn G_5,1,$000
 dn ___,0,$C00
 dn ___,0,$D01
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000
 dn ___,0,$000

duty_instruments:


wave_instruments:
itWaveinst1:
db 0
db 32
db 0
dw 0
db 128



noise_instruments:


routines:
__hUGE_Routine_0:

__end_hUGE_Routine_0:
ret

__hUGE_Routine_1:

__end_hUGE_Routine_1:
ret

__hUGE_Routine_2:

__end_hUGE_Routine_2:
ret

__hUGE_Routine_3:

__end_hUGE_Routine_3:
ret

__hUGE_Routine_4:

__end_hUGE_Routine_4:
ret

__hUGE_Routine_5:

__end_hUGE_Routine_5:
ret

__hUGE_Routine_6:

__end_hUGE_Routine_6:
ret

__hUGE_Routine_7:

__end_hUGE_Routine_7:
ret

__hUGE_Routine_8:

__end_hUGE_Routine_8:
ret

__hUGE_Routine_9:

__end_hUGE_Routine_9:
ret

__hUGE_Routine_10:

__end_hUGE_Routine_10:
ret

__hUGE_Routine_11:

__end_hUGE_Routine_11:
ret

__hUGE_Routine_12:

__end_hUGE_Routine_12:
ret

__hUGE_Routine_13:

__end_hUGE_Routine_13:
ret

__hUGE_Routine_14:

__end_hUGE_Routine_14:
ret

__hUGE_Routine_15:

__end_hUGE_Routine_15:
ret

waves:
wave0: db 254,220,186,152,118,84,50,16,18,52,86,120,154,188,222,255

