/* Planes */

/*___________________________ Procesamiento de horas libres de lista a creencias ___________________________*/


+horas_libres(Lista) <- !descomponer_lista(Lista).


/*--------------- Convertimos la lista en creencias para ser más sencillamente manejadas, ---------------*/
/*--------------------- pudiendo estar la lista desordenada. --------------------------------------------*/


+!descomponer_lista([]) <- +conversion_hecha.
+!descomponer_lista([H|Resto]) <-
   +libre(H);               
   !descomponer_lista(Resto).


/*__________________________________________ Cotas Rango Reunion __________________________________________*/

+rango_reunion(MinG, MaxG) <- !intentar_calcular_cotas(MinG, MaxG).
+!intentar_calcular_cotas(MinG, MaxG) : horas_libres(_) & conversion_hecha <-
  
   /* Como la lista puede estar desordenada, inicializamos variables temporales
       con valores extremos para buscar nuestro mínimo y máximo iterando. */
   -+mi_cota_inferior(24);
   -+mi_cota_superior(-1);
  
   //Buscamos las cotas
   for ( libre(H)[source(self)] ) {
        if(H >= MinG & H <= MaxG){
            ?mi_cota_inferior(ActualMin);
            if (H < ActualMin) { -+mi_cota_inferior(H); }; /* Para consistencia de Cotas */
            
            ?mi_cota_superior(ActualMax);
            if (H > ActualMax) { -+mi_cota_superior(H); }; /* Para consistencia de Cotas */
        };
       
   };
  
   ?mi_cota_inferior(MiMin);
   ?mi_cota_superior(MiMax);
  
   .print("Mi agenda procesada abarca el rango: [", MiMin, " - ", MiMax, "]");
   .send(organizador, tell, cotas_PSR(MiMin, MiMax)).

+!intentar_calcular_cotas(MinG, MaxG) : not conversion_hecha <-
   .wait(50);
   !intentar_calcular_cotas(MinG, MaxG).


/*__________________________ Planes de reacción a las propuestas del organizador __________________________*/


+propuesta(H) <- !buscar_hora(H, H).
  
/*---------------------------------- Busqueda de Siguiente Hora Libre ----------------------------------*/

+!buscar_hora(Original, Actual) : libre(Actual)[source(self)] <-
    .send(organizador, tell, respuesta(Original, Actual)).

+!buscar_hora(Original, Actual) : mi_cota_superior(Max)[source(self)] & Actual < Max & 
                                    not libre(Actual)[source(self)]  <- !buscar_hora(Original, Actual + 1).

+!buscar_hora(Original, Actual) : mi_cota_superior(Max)[source(self)] & Actual >= Max 
                                    <- .send(organizador, tell, respuesta(Original, -1)).

/*____________________________________________ Reunión fijada _____________________________________________*/


+reunion_fijada(H) <- .print("Reunión anotada a las ", H, ":00.").