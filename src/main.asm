SECTION "Entry point", ROM0[$150]

main::
    ;; Bucle principal del juego.
    ;; Cuando sc_game_run termine (después del Game Over),
    ;; saltará de nuevo aquí, reiniciando el juego.
.game_loop:
    call sc_game_init
    call sc_game_run
    jp .game_loop