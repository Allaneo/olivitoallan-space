---
title: "10 lecciones aprendidas diseñando un CanSat"
summary: "Participar en la AAS CanSat Competition construyendo un sistema guiado por parapente me enseñó que los mayores desafíos de ingeniería no estaban en las fórmulas, sino en la organización, la gestión de incertidumbre y los ensayos reales."
description: "Lecciones de ingeniería de sistemas, organización de equipos, ensayos y toma de decisiones a partir de nuestra participación en la AAS CanSat Competition."
date: 2026-08-30T13:45:00-03:00
draft: true
translationKey: "cansat-lessons-learned"
slug: "lecciones-aprendidas-cansat"
tags: ["ingeniería aeroespacial", "CanSat", "ingeniería de sistemas", "gestión de proyectos", "lecciones aprendidas"]
categories: ["experiencias", "proyectos"]
---

Cuando empezamos a trabajar para la **AAS CanSat Competition**, el objetivo parecía un problema técnico claro: construir un pequeño satélite del tamaño de una lata de gaseosa que, tras ser eyectado desde un cohete a cientos de metros de altura, desplegara un parapente de forma autónoma, guiara su trayectoria mediante actuadores y aterrizara un huevo completamente intacto.

Pronto descubrí que la parte más difícil del proyecto no estaba en calcular coeficientes aerodinámicos ni en programar leyes de control. Estaba en aprender a coordinar disciplinas distintas, tomar decisiones con información incompleta, diseñar ensayos que dieran respuestas útiles y lidiar con todo aquello que no sabíamos que no sabíamos.

Estas son diez lecciones que me dejó el proceso, desde el primer prototipo que cayó como una piedra hasta el sistema integrado final.

---

### 1. La coordinación "punto a punto" no alcanza: se necesita visión de sistema

Al principio dividimos el trabajo en tres áreas principales: mecánica y aerodinámica, electrónica, y programación. Cada grupo avanzaba en sus tareas y la comunicación se daba de forma puntual: cuando necesitábamos conocer las dimensiones de la placa o el torque de los servos, hablábamos directamente con la persona de electrónica.

Ese esquema funciona para resolver una duda aislada, pero no para gestionar un proyecto. Aprendí que, al no tener a alguien dedicado a mirar el sistema completo y fijar fechas límite internas, los subsistemas avanzan a ritmos desfasados. La coordinación punto a punto genera puntos ciegos en las interfaces y hace que nadie tenga el mapa global de dependencias hasta que ya es tarde.

---

### 2. Entre la parálisis por el análisis y la confusión por la acción

En varios momentos del proyecto nos encontramos congelados en la duda, postergando decisiones mientras buscábamos un paper más, una simulación extra o una fuente adicional que nos diera certeza absoluta. En el otro extremo estaba la tentación de salir a construir a ciegas sin haber analizado las cargas o los requerimientos mínimos.

Descubrí que ninguno de los dos extremos funciona. La clave está en pararse en el medio: entre la parálisis por el análisis y la confusión por la acción. Hay que definir un tiempo acotado para el análisis teórico, tomar una decisión fundamentada y pasar rápido a prototipar. La certeza completa no existe en los papeles; se construye a medida que los prototipos empiezan a interactuar con la física.

---

### 3. Respetar los hitos de diseño (PDR, CDR) como método de trabajo

La competencia exige entregar revisiones formales como el Preliminary Design Review (PDR) y el Critical Design Review (CDR). Al principio es fácil ver estas entregas como un requisito burocrático, pero entendí que en la práctica son la herramienta más valiosa para ordenar el avance.

Tener que presentar un PDR nos obligó a congelar la arquitectura conceptual y validar que los números generales cerraran antes de fabricar. Un CDR nos forzó a definir cada tornillo, interfaz y material. Respetar estas etapas evita el error común de rediseñar sobre la marcha de manera infinita.

---

### 4. Documentar el "por qué", no solo el "qué"

En el ritmo diario de diseñar y resolver problemas, anotábamos qué dimensiones tenía una pieza o qué tela habíamos elegido, pero a veces olvidábamos escribir por qué habíamos tomado esa decisión y bajo qué supuestos.

Aprendí que cuando más adelante surge la necesidad de hacer un cambio (por ejemplo, reducir 20 gramos en la estructura o achicar el área del ala), no tener las decisiones fundamentadas te obliga a repensar todo desde cero. Peor aún: corrés el riesgo de modificar un parámetro y romper sin darte cuenta una condición de la que dependía otro subsistema.

---

### 5. No sabés lo que no sabés hasta que el prototipo toca el mundo real

En los modelos y simulaciones todo parecía controlado porque solo modelábamos los fenómenos que conocíamos. Sin embargo, apenas construimos el primer prototipo físico, empezaron a emerger categorías enteras de problemas que ni siquiera sabíamos que existían.

No se trataba de errores menores de cálculo, sino de fenómenos que estaban completamente fuera del radar: telas que no inflan por el tamaño y forma de las tomas de aire, líneas que se cruzan por la elasticidad del material o sobrepresiones internas que frenan los actuadores. Entendí que la única forma de hacer visibles esos problemas es construir y probar temprano.

---

### 6. La trampa del primer ensayo hiperrealista: aislar variables primero

Para el primer ensayo del parapente Mk 1, quisimos probar todo junto desde unos 20 metros de altura. Le colgamos una réplica idéntica del CanSat, con la misma distribución de masa, el centro de gravedad exacto y la forma geométrica completa para igualar el coeficiente de resistencia. Buscábamos un ensayo hiperrealista en el primer intento.

El resultado fue previsible: cayó como una piedra. Al mezclar tantas variables juntas en el primer test, fue casi imposible entender qué había fallado exactamente. ¿Fueron las líneas? ¿El inflado? ¿La masa? ¿La aerodinámica del contenedor? La lección que me quedó fue clara: en los primeros ensayos hay que aislar variables al máximo. Una masa puntual simple desde menor altura nos hubiera dado la misma información básica sin arriesgar el modelo completo.

---

### 7. Resolver un problema no termina el trabajo: "desbloquea" el siguiente

El desarrollo de hardware complejo no sigue una línea recta donde se arregla una cosa y todo queda listo. Descubrí que es un proceso por capas: solucionar una falla simplemente permite que el sistema opere lo suficiente como para revelar el siguiente cuello de botella que estaba oculto detrás.

Cuando tuvimos problemas con el inflado inicial del parapente, descubrimos que el ángulo de las líneas exteriores estaba cerrando el ala. Al corregir las líneas, el canopy empezó a inflar mejor, pero todavía le faltaba inflado. Eso nos llevó a investigar la diferencia entre parapentes de despegue terrestre y paracaídas ram-air eyectados en vuelo, rediseñando las bocas de entrada con mayor tamaño y ángulo. Cada solución desbloqueaba el siguiente nivel de aprendizaje.

---

### 8. La convergencia de subsistemas: el verdadero desafío de la integración

En un proyecto multidisciplinario, los subsistemas no pueden desarrollarse en aislamiento porque todos deben converger en momentos clave. Para probar el sistema de guiado autónomo, por ejemplo, no alcanzaba con tener el algoritmo programado: necesitábamos que aerodinámica tuviera el parapente terminado, que estructuras tuviera el CanSat listo para alojar la electrónica y unir el parapente al sistema, y que electrónica tuviera las placas y sensores operativos.

Aprendí que si un solo subsistema se retrasa, bloquea la capacidad de ensayo de todos los demás. Gestionar un proyecto de este tipo exige sincronizar los tiempos de entrega para que la integración no se convierta en un cuello de botella que paralice al equipo.

---

### 9. La ingeniería invisible: logística, compras, universidad y actores externos

Diseñar y programar fue solo una parte de nuestro trabajo. Gran parte del éxito del proyecto dependió de tareas que no aparecen en los libros de texto: buscar sponsors, conseguir fondos, comprar materiales específicos (Kevlar, telas ripstop recubiertas, tornillería métrica), gestionar tiempos de importación y coordinar con los talleres y laboratorios de la facultad.

Incluso la logística de las pruebas finales fue un desafío en sí mismo. Para nuestro último ensayo de campo, tuvimos que tramitar una restricción del espacio aéreo, coordinar con la administración de un aeródromo y organizar las operaciones con un piloto de drone para realizar la suelta a la altura requerida. Si la logística falla, la ingeniería no llega a volar.

---

### 10. Fail fast, succeed faster: el valor del fallo temprano

Es natural querer que el primer prototipo funcione a la perfección. Pero en sistemas complejos y novedosos para el equipo, el primer prototipo (Mk 1) rara vez vuela bien; su verdadero propósito es fallar rápido para enseñarte exactamente qué necesita tener el Mk 2 y el Mk 3.

Adoptar la mentalidad de *fail fast, succeed faster* reduce la frustración y acelera el desarrollo. La diferencia entre un proyecto que se estanca y uno que llega a la meta no es evitar equivocarse, sino aprender rápido de cada caída y volcar ese aprendizaje en la siguiente iteración.
