
// Reacción si reciben una propuesta y la hora coincide con su regla de "ocupado"
+propuesta(H) : ocupado(H) <-
    .print("Tengo la hora ", H, " ocupada. Rechazando...");
    .send(organizador, tell, voto(H, rechazo)).

// Reacción si reciben una propuesta y NO está en su regla de "ocupado"
+propuesta(H) : not ocupado(H) <-
    .print("Estoy libre a las ", H, ":00h. Aceptando...");
    .send(organizador, tell, voto(H, acepto)).

// Reacción al éxito final
+reunion_fijada(H) <-
    .print("Anotado en mi agenda: Reunión hoy a las ", H, ":00h.").