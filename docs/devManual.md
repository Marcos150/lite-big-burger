# ECS

## Procesamiento de entidades

Para procesar todas las entidades (es decir, ejecutar una función sobre cada una) hay que utilizar la función `man_entity_for_each` del entity manager. Esta función itera por todas las entidades vivas y ejecuta la función que le pases por `HL`.

Además, en la función que le pases a `man_entity_for_each`, la entidad le llegará en el registro `DE`, por lo que habrá que usar este registro para realizar las operaciones con la entidad.

Por último, mencionar que se puede modificar todos los registros en la función de procesado ya que, antes de llamarla en `man_entity_for_each`, los datos de estos registros se guardan en el memory stack, y tras acabar la función de procesado se recuperan.

A continuación se muestra un ejemplo:

```asm
movement_update::
    ;; HL = Function to be executed by every (alive) entity
    ld hl, check_prota_movement
    ;; Process entities with the specified function
    call man_entity_foreach
    ret

    check_prota_movement:
        ;; DE = Entity address
        ;; FUNCTION CODE
```

## Acceso a componentes de entidades

Para acceder a los datos de una entidad primero hay que cambiar el valor del registro `D` (o donde se guarde la dirección de la entidad) al del componente correspondiente. Una vez hecho esto, solo hay que sumar a `DE` (o al registro usado antes) el valor de la propiedad a obtener.

A continuación se muestra un ejemplo:

```asm
change_sprite_to_19::
    ;; Select sprite component
    ld d, CMP_SPRITE_H

    ;; HL = sprite tile address
    ld bc, CMP_SPRITE_TILE
    ld h, d
    ld l, e
    add hl, bc

    ;; Change sprite tile to $19
    ld [hl], $19
ret
```