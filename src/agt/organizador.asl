/* Creencias iniciales */
horas_posibles([10, 11, 12, 13, 14, 15]).
total_participantes(3).

/* Metas iniciales */
!iniciar_psr.

/* Planes */

+!iniciar_psr : horas_posibles(L) <-
    .print("--- INICIANDO ALGORITMO VUELTA ATRÁS ---");
    !ejecutar_backtracking(L).

// Intenta asignar un valor (Hora) del dominio
+!ejecutar_backtracking([Hora|Resto]) <-
    .print("Asignando variable Hora = ", Hora, ":00h...");
    .abolish(voto(Hora, _)); 
    -+intento_actual(Hora);
    .broadcast(tell, propuesta(Hora));
    
    // Esperamos un momento a que todos voten (mecanismo de sincronización robusto)
    .wait(1000); 
    !verificar_consistencia(Hora, Resto).

// Si el dominio se agota
+!ejecutar_backtracking([]) <- 
    .print("FALLO: No existe ninguna asignación consistente en el dominio.").

// Comprobación de Consistencia (Paso clave del PSR)
+!verificar_consistencia(H, Resto) <-
    ?total_participantes(Total);
    
    // CORRECCIÓN: Usamos [source(Ag)] para contar cuántos agentes distintos enviaron el voto
    .count(voto(H, acepto)[source(Ag)], Aceptados);
    
    // Opcional: imprimir el recuento para ver lo que pasa por dentro
    // .print("Votos a favor recibidos: ", Aceptados, " de ", Total);
    
    if (Aceptados == Total) {
        .print("¡CONSISTENCIA ALCANZADA! Hora final: ", H, ":00h.");
        .broadcast(tell, reunion_fijada(H))
    } else {
        .print("Inconsistencia detectada en ", H, ":00h. Aplicando Vuelta Atrás...");
        !ejecutar_backtracking(Resto)
    }.