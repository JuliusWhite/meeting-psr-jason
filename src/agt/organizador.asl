/* Creencias iniciales */
total_participantes(3).

/* Metas iniciales */
!iniciar_convocatoria.

/* Planes */

/*_______________________________Planes de Inicialización y Validación rango_reunion_______________________________*/

// La creencia existe y es válida
+!iniciar_convocatoria : rango_reunion(Min, Max) & Min >= 0 & Min < Max <-
    // Guardamos las cotas
    -+cota_inferior_global(Min);
    -+cota_superior_global(Max);
    
    .print("-> ORGANIZANDO REUNION. Por favor, dadme vuestras cotas superiores y inferiores de horas libres respecto a este rango [", Min, " - ", Max, "]");
    .broadcast(tell, rango_reunion(Min, Max)).

// La creencia existe pero es errónea (por ejemplo: -1:00 a 0:00 o 1:00 a 23:00)
+!iniciar_convocatoria : rango_reunion(Min, Max) & (Min < 0 | Max > 23 | Min >= Max) <-
    .print("Error en organizador: El rango de reunión proporcionado [", Min, " , ", Max, "] es inválido. Ejecución detenida.").

// La creencia no existe
+!iniciar_convocatoria : not rango_reunion(_, _) <-
    .print("Error en organizador: No se encontró la creencia 'rango_reunion' en el mas2j. Ejecución detenida.").


/*_____________________________________________PSR_____________________________________________*/

+cotas_PSR(CotaMin, CotaMax)[source(Ag)] <-
    +voto_recibido(Ag);
    
    // Ajusta la cota inferior si un agente está libre más tarde que los demás (CONSISTENCIA DE COTAS)
    ?cota_inferior_global(ActualMin);
    if (CotaMin > ActualMin) { -+cota_inferior_global(CotaMin); };

    // Ajusta la cota superior si el agente está libre más temprano y después ya no
    ?cota_superior_global(ActualMax);
    if (CotaMax < ActualMax) { -+cota_superior_global(CotaMax); };

    !verificar_inicio.

+!verificar_inicio : not fase_propuestas <-
    .count(voto_recibido(_), Recibidas);
    ?total_participantes(Total);
    
    if (Recibidas == Total) {
        +fase_propuestas;

        ?cota_inferior_global(Inicio);
        ?cota_superior_global(Fin);
        .print("Todas las cotas recibidas. Rango final optimizado: [", Inicio, " - ", Fin, "]");
        !proponer_hora(Inicio);
    }.
+!verificar_inicio.
/* Propuesta de una hora*/
+!proponer_hora(H) : cota_superior_global(MaxG) & H > MaxG <-
    .print("FIN: No es posible que se reunan.");
    -fase_propuestas.

+!proponer_hora(H) <-
    .print("--- Propuesta: ", H, ":00h ---");
    .abolish(acepto(_));
    .abolish(rechazo(_, _));
    .broadcast(tell, propuesta(H));

    .wait(1000);
    !evaluar_respuestas(H).

/* Evaluación de Respuestas a a la Propuesta*/

+!evaluar_respuestas(H) <-
    ?total_participantes(Total);
    .count(acepto(H)[source(_)], Aceptados);
    
    if (Aceptados == Total) {
        .print("FIN: Ha sido posible poner una hora libre para todos. Será a las ", H, ":00. ¡Suerte en la reunión!");
        .broadcast(tell, reunion_fijada(H));
        -fase_propuestas;
    } else {
        -+salto_maximo(H);
        
        // Buscamos el salto más lejano iterando las creencias de rechazo
        for ( rechazo(H, ProximaLibre) ) {
            if (ProximaLibre == imposible) {
                -+salto_maximo(imposible); // Si alguien dice imposible, abortamos directamente.
            } else {
                ?salto_maximo(Actual);
                // Solo comparamos el salto si no estamos ya en modo cancelación (imposible)
                if (Actual \== imposible & ProximaLibre > Actual) { 
                    -+salto_maximo(ProximaLibre); 
                }
            }
        };
        
        ?salto_maximo(NuevaHora);
        
        if (NuevaHora == imposible) { 
            .print("FIN: No es posible que se reunan.");
            -fase_propuestas;
        } else {
            .print("Saltando a las ", NuevaHora, ":00h.");
            !proponer_hora(NuevaHora);
        }
    }.