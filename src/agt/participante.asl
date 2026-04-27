/* Planes */
/* Procesamiento de horas libres de lista a creencias */
+horas_libres(Lista) <- !descomponer_lista(Lista).

/*___________________________ Procesamiento de horas libres de lista a creencias ___________________________*/

+horas_libres(Lista) <- !descomponer_lista(Lista).

/*--------------- Convertimos la lista en creencias para ser más sencillamente manejadas, ---------------*/
/*--------------------- pudiendo estar la lista desordenada. --------------------------------------------*/

+!descomponer_lista([]).
+!descomponer_lista([H|Resto]) <-
    +libre(H);                 
    !descomponer_lista(Resto).

/*__________________________________________ Cotas Rango Reunion __________________________________________*/

+rango_reunion(MinG, MaxG) : horas_libres(Lista) <-
    
    /* Como la lista puede estar desordenada, inicializamos variables temporales
        con valores extremos para buscar nuestro mínimo y máximo iterando. */
    -+mi_cota_inferior(24);
    -+mi_cota_superior(-1);
    
    //Buscamos las cotas
    for ( libre(H) ) {
        ?mi_cota_inferior(ActualMin);
        if (H < ActualMin) { -+mi_cota_inferior(H); };
        
        ?mi_cota_superior(ActualMax);
        if (H > ActualMax) { -+mi_cota_superior(H); };
    };
    
    ?mi_cota_inferior(MiMin);
    ?mi_cota_superior(MiMax);
    
    .print("Mi agenda procesada abarca el rango: [", MiMin, " - ", MiMax, "]");
    .send(organizador, tell, cotas_PSR(MiMin, MiMax)).

/*__________________________ Planes de reacción a las propuestas del organizador __________________________*/

+propuesta(H) : libre(H) <- .send(organizador, tell, respuesta(H, H)).
+propuesta(H) : not libre(H) <- !buscar_siguiente(H, H + 1). // Buscamos la siguiente hora si hay
    
/*---------------------------------- Busqueda de Siguiente Hora Libre ----------------------------------*/

+!buscar_siguiente(Original, Actual) : libre(Actual) <- 
    .send(organizador, tell, respuesta(Original, Actual)).

+!buscar_siguiente(Original, Actual) : not libre(Actual) & mi_cota_superior(Max) & Actual < Max <-
    !buscar_siguiente(Original, Actual + 1).

+!buscar_siguiente(Original, Actual) : mi_cota_superior(Max) & Actual >= Max <-
    .send(organizador, tell, respuesta(Original, imposible)).

/*____________________________________________ Reunión fijada _____________________________________________*/

+reunion_fijada(H) <- .print("Reunión anotada a las ", H, ":00.").