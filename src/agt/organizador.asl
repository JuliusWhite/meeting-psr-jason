/* Creencias iniciales */
total_participantes(3).

/* Metas iniciales */
!iniciar_convocatoria.

/* Planes */
/*_______________________________ Planes de Inicialización y Validación rango_reunion _______________________________*/

// La creencia existe y es válida
+!iniciar_convocatoria : rango_reunion(Min, Max) & Min >= 0 & Max <= 23 & Min < Max <-
    // Guardamos las cotas
    -+cota_inferior_global(Min);
    -+cota_superior_global(Max);
    
    .print("-> ORGANIZANDO REUNION. Por favor, dadme vuestras cotas superiores y inferiores de horas libres respecto a este rango [", Min, " - ", Max, "]");
    +fase_puede_iniciar;
    .broadcast(tell, rango_reunion(Min, Max)).

/*  La creencia existe pero es erróneo.

    Por ejemplo:
        HORARIO DEL MISMO DÍA
        _____________________
        Min     Max
        -1:00   0:00
        23:00   24:00 
        23:00   1:00
*/
+!iniciar_convocatoria : rango_reunion(Min, Max) & (Min < 0 | Max > 23 | Min >= Max) <-
    .print("Error en organizador: El rango de reunión proporcionado [", Min, " , ", Max, "] es inválido. Ejecución detenida.").

// La creencia no existe
+!iniciar_convocatoria : not rango_reunion(_, _) <-
    .print("Error en organizador: No se encontró la creencia 'rango_reunion' en el mas2j. Ejecución detenida.").


/*________________________________________________ Solución al PSR ________________________________________________*/

/*----------------------- Conseguir Cotas superiores e inferiores de todos los agentes -----------------------*/
+cotas_PSR(CotaMin, CotaMax)[source(Ag)] : not voto_recibido(Ag) <-
    +voto_recibido(Ag);
    
    /* Ajusta la cota inferior si un agente está libre más tarde que los demás.
        -> Lo cual es una de las partes que genera Consistencia de Cotas
        (junto con algo de otro plan más adelante en este asl). */
    ?cota_inferior_global(ActualMin);
    if (CotaMin > ActualMin) { -+cota_inferior_global(CotaMin); };

    /* Ajusta la cota superior si el agente está libre más temprano y después ya no -> Consistencia de Cotas */
    ?cota_superior_global(ActualMax);
    if (CotaMax < ActualMax) { -+cota_superior_global(CotaMax); };

    !verificar_si_inicio.

@verificar_plan[atomic] // Atómico para que no se generen varios objetivos y escriba por pantalla varias veces el contenido
+!verificar_si_inicio : fase_puede_iniciar <-
    .count(voto_recibido(_), Recibidas);
    ?total_participantes(Total);
    
    if (Recibidas == Total) { // si ya han llegado todas las cotas de todos los agentes, empezamos con el PSR 
        -fase_puede_iniciar; /* Cambiamos de estado, para que no nos pase duplicaciones de este mismo objetivo*/

        ?cota_inferior_global(Inicio);
        ?cota_superior_global(Fin);
        .print("Todas las cotas recibidas. Rango final optimizado: [", Inicio, " - ", Fin, "]");
        !proponer_hora(Inicio);
    }.
    
+!verificar_si_inicio.
                                           
/*------------------------------------------ Propuesta de una hora ------------------------------------------*/
+!proponer_hora(H) : cota_superior_global(MaxG) & H > MaxG <- //Caso H es erronea
    .print("FIN: No es posible que se reunan.");
    -fase_propuestas.

+!proponer_hora(H) <-
    .print("--- Propuesta: ", H, ":00h ---");
    .abolish(respuesta(_, _)); // limpiamos aceptos y rechazos anteriores
    .abolish(evaluando(_));
    .broadcast(tell, propuesta(H)).

/*---------------------------------------- Recepción de respuestas ------------------------------------------*/
@recepcion_respuestas[atomic]
+respuesta(H, _) : not evaluando(H) <-
        ?total_participantes(Total);
        
        // Contamos todas las respuestas recibidas para la hora propuesta (H)
        .count(respuesta(H, _)[source(_)], Recibidas);
        
        if (Recibidas == Total) {
            +evaluando(H);
            !evaluar_respuestas(H);
        }.

/*------------------------------- Evaluación de Respuestas a a la Propuesta ---------------------------------*/
+!evaluar_respuestas(H) <-
    ?total_participantes(Total);
    .count(respuesta(H, H)[source(_)], Aceptados);
    
    if (Aceptados == Total) {
        .print("FIN: Ha sido posible poner una hora libre para todos. Será a las ", H, ":00. ¡Suerte en la reunión!");
        .broadcast(tell, reunion_fijada(H));
        
    } else {
        -+salto_maximo(H);
        
        // Buscamos el salto más lejano iterando las creencias de rechazo
        for (respuesta(H, ProximaLibre)) {
                ?salto_maximo(Actual);
                
                // Solo comparamos el salto si no estamos ya en modo cancelación (imposible)
                if (ProximaLibre > Actual) { 
                    -+salto_maximo(ProximaLibre); 
                }
        };
        
        ?salto_maximo(NuevaHora);
        
        .print("Saltando a las ", NuevaHora, ":00h.");
        !proponer_hora(NuevaHora);
    }.