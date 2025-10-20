SECTION "Render System Code", ROM0

;sys_render_init::

DEF OAM_START equ $FE00

render_update::
   call dma_copy

   ret