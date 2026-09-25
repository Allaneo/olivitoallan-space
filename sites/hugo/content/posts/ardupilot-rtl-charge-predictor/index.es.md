---
title: "¿Cuánta batería necesita un dron para volver a casa?"
summary: "Cuando a un cuadricóptero con ArduPilot se le ordena volver a casa, ¿cuánta batería le va a costar el viaje? Entrené redes neuronales, árboles y un modelo lineal con 349 vuelos simulados, y la mayor mejora vino de contarles a qué velocidad vuelve realmente el dron."
description: "Redes neuronales, árboles con gradient boosting y regresión Ridge prediciendo la carga de batería del return-to-launch en ArduPilot SITL, y por qué las entradas importaron más que la arquitectura."
date: 2026-09-28T08:00:00-03:00
draft: false
translationKey: "ardupilot-rtl-charge-predictor"
slug: "cuanta-bateria-necesita-un-dron-para-volver-a-casa"
showMath: true
featureimagecaption: "La velocidad de regreso se mantiene en 10 m/s hasta que un viento de frente fuerte lleva al dron a su límite de inclinación"
tags: ["machine learning", "redes neuronales", "feature engineering", "ArduPilot", "drones", "simulación"]
categories: ["proyectos"]
---

{{< katex >}}

Todo vuelo de dron tiene un momento en el que alguien, o algo, decide que es hora de volver. En un multicóptero con ArduPilot, el autopiloto de código abierto, ese momento es el Return to Launch (RTL): subir a una altura segura, volver en línea recta, descender, aterrizar y desarmar. Lo puede activar el piloto, y también el propio autopiloto cuando la batería se agota.

Cuando un autopiloto está configurado para volver con batería baja, el disparador suele ser un umbral fijo. El failsafe de batería baja de ArduPilot usa una capacidad restante fija, y PX4, el otro gran autopiloto de código abierto, una fracción fija de la batería (su nivel crítico es 7% por defecto). Un umbral fijo no sabe si la casa está a 200 m con el viento a favor o a 1,5 km contra un viento fuerte.

Lo que lleva a una pregunta simple con una respuesta incómoda. En el momento en que empieza el RTL, ¿cuánta batería va a costar el viaje de vuelta?

Al terminar *Advanced Learning Algorithms*, el segundo curso de la Machine Learning Specialization de Andrew Ng, quise apuntar sus herramientas, redes neuronales y ensambles de árboles, a esa pregunta. En [el proyecto anterior](/es/posts/decaimiento-orbital-con-regresion-lineal/) la lección fue que las features importaban más que el algoritmo. Esperaba que este fuera sobre arquitecturas. Otra vez se trató sobre todo de qué les conté a los modelos, y en especial de a qué velocidad vuelve realmente el dron.

## La pregunta, con precisión

El modelo predice la carga, en miliamperios-hora (mAh), usada desde que se ordena el RTL hasta que los motores se desarman en tierra. Solo puede usar lo que el vehículo sabe en ese momento: dónde está la casa, a qué altura vuela, el voltaje de la batería, qué cree el estimador de a bordo que hace el viento, y diez segundos de datos de vuelo recientes (corriente, acelerador, salidas de motor, actitud).

Comparar la predicción con la carga restante es aritmética simple. Lo difícil es la predicción.

## Volar 349 drones sin estrellar ninguno

No podía volar cientos de drones reales con viento controlado, así que usé ArduPilot SITL (software in the loop). SITL compila el código de vuelo real de ArduPilot, con el mismo estimador, los mismos controladores y los mismos modos de vuelo que corren en una controladora de vuelo, y lo conecta a un cuadricóptero simulado en lugar de sensores y motores reales.

Un script de Python voló cada misión por MAVLink, el protocolo de mensajes que usan los autopilotos y las estaciones de tierra para comunicarse: despegar, volar hacia afuera con un rumbo y una distancia dados, quedarse en hover durante una ventana de decisión de 10 segundos, ordenar el RTL y esperar el desarme automático. Cada vuelo se convirtió en una fila de datos. Su objetivo, leído del log de a bordo, coincidió con una integración independiente de la corriente de la batería dentro de 0,47 mAh en todos los vuelos.

Los escenarios variaron la distancia a casa (200 a 1.500 m), la altura (30 a 120 m), un viento constante de 0 a 6 m/s desde cualquier dirección y una carga útil de 0 a 1 kg sobre un cuadricóptero de 3 kg.

La carga útil necesitó un pequeño parche al simulador. El modelo de frame de SITL sí define la masa del vehículo, pero cambiarla también cambia el airframe de referencia y la calibración de su propulsión; el parche agrega una carga sobre un airframe sin cambios. El modelo nunca la ve. Un dron más pesado consume más corriente y necesita más acelerador, y el modelo tiene que inferir el peso a partir de esos síntomas, como tendría que hacerlo un autopiloto real. Tampoco ve el viento real, solo la estimación del EKF de ArduPilot (filtro de Kalman extendido, el estimador de a bordo que fusiona los sensores en posición, velocidad y, en este caso, viento), que se equivocaba en unos 0,5 m/s en promedio.

Los primeros 250 vuelos se dividieron por escenario en entrenamiento (172), validación (39) y test (39).

## La regla obvia

La estimación más simple es la que un piloto podría hacer de cabeza: tiempo de regreso esperado multiplicado por la corriente que se está consumiendo ahora. En los vuelos de test final, el error absoluto medio (MAE) de esa regla fue de 196 mAh, alrededor del 11% de un regreso típico. La corriente en hover en el punto de decisión no es la corriente del viaje de vuelta, y el tiempo de vuelta depende del viento de maneras que la regla no captura, como se vio después.

## Dejar que los modelos lo encuentren

Comparé tres familias de modelos sobre cuatro conjuntos de entradas, cada uno con más física precalculada que el anterior (en el repositorio se llaman F0 a F3):

| Conjunto | Qué agrega | Entradas |
| --- | --- | ---: |
| I0 | Ruta, voltaje de la batería, estimación de viento del EKF | 15 |
| I1 | Resúmenes de diez segundos de corriente, acelerador, motores, actitud y movimiento | 36 |
| I2 | Viento de frente, viento cruzado, tiempo de regreso nominal a la velocidad de RTL de 10 m/s, velocidad aerodinámica requerida, corriente × tiempo | 47 |
| I3 | La misma física reconstruida alrededor de una velocidad de regreso predicha (más abajo) | 43 |

Los números parecen más grandes de lo que son. La mayoría de las entradas son varios resúmenes de las mismas pocas señales durante los 10 segundos de hover (media, dispersión, percentiles), algunas nunca cambian en estos vuelos, y las de velocidad dicen poco mientras el dron mantiene la posición. En la práctica, los modelos trabajan con alrededor de una docena de magnitudes independientes: distancia, altura, dirección, voltaje, viento, corriente, acelerador, inclinación y la física construida a partir de ellas.

Los modelos fueron regresión Ridge (regresión lineal con una penalización sobre los pesos grandes), XGBoost (árboles de decisión con gradient boosting) y redes neuronales que escribí en NumPy para poder ver cada parte del entrenamiento: activaciones ReLU (unidad lineal rectificada), el optimizador Adam, una pérdida de Huber (error cuadrático para errores chicos y absoluto para los grandes, lo que evita que los outliers extremos dominen el entrenamiento) y early stopping.

El primer resultado fue el más de curso. En los vuelos de test originales, con las entradas crudas de I0, Ridge erró por 77 mAh y una red chica por 35. La red podía combinar distancia, viento y voltaje en algo útil por sí sola; el modelo lineal no. Pero dándole a Ridge las entradas derivadas de la física de I2, bajó a 27 mAh, a la par de la red con 26.

Los árboles fueron otra historia, y voy a volver a ellos.

## La velocidad que calculé mal

Toda entrada basada en tiempo necesita una velocidad de regreso. Mi primera suposición fue la obvia: el RTL vuelve a su velocidad de consigna de 10 m/s, así que el tiempo de vuelta es la distancia dividida por 10 m/s.

Para la mayoría de los vuelos, los logs coincidieron. El controlador de posición de ArduPilot mantiene 10 m/s respecto del suelo: con viento de cola se inclina menos, y con un viento de frente moderado se inclina más y sigue haciendo 10 m/s. En la figura de abajo, la línea punteada es esa suposición y los puntos son lo que pasó en realidad.

![Velocidad de regreso medida respecto del suelo contra el viento de frente para 349 vuelos, coloreada por la carga útil oculta, con la primera suposición y la fórmula del límite de inclinación](featured.png "La línea punteada es lo que supuse al principio. Pasado el límite de inclinación la velocidad cae, y los drones más pesados conservan más.")

El problema está a la derecha, que es justo donde la batería más importa. Pasado cierto viento de frente, el dron deja de mantener 10 m/s y va frenando. Ahí es donde alcanza su ángulo máximo de inclinación, 30° por defecto en ArduPilot. No puede inclinarse más, así que no puede producir más empuje horizontal, y todo lo que se lleva el viento sale directamente de la velocidad respecto del suelo.

## El límite de inclinación

En el límite de inclinación, el dron se estabiliza aproximadamente en la velocidad aerodinámica en la que la resistencia equilibra la componente horizontal del empuje. En los vuelos de entrenamiento fue de 11,8 m/s, más o menos 0,8.

La dispersión no es ruido. Es el peso. En vuelo estable con un ángulo de inclinación fijo, la fuerza horizontal es W tan 30°, con W el peso, así que un dron más pesado empuja más fuerte y alcanza una velocidad aerodinámica mayor antes de que la resistencia lo iguale (ρ es la densidad del aire y C_D A el área de resistencia):

$$W\tan 30^\circ \approx \tfrac{1}{2}\rho V_{max}^2 C_D A$$

Entre los tercios de carga útil, la velocidad aerodinámica en el límite subió de 11,2 a 12,7 m/s. En el límite, los drones más pesados volaron más rápido contra el viento.

El modelo no conoce la carga útil, pero el acelerador sí. Así que la fórmula de velocidad usa el acelerador como sustituto del peso, y una recta alcanzó en este rango. Con V_max la velocidad aerodinámica en el límite de inclinación, y v_head y v_cross el viento de frente y el viento cruzado estimados:

$$V_{max} = a + b \cdot \text{throttle}$$

$$v_{ground} = \min\left(10,\ \sqrt{V_{max}^2 - v_{cross}^2} - v_{head}\right)$$

Dos parámetros, ajustados solo con vuelos que pasaron la mayor parte del regreso en el límite de inclinación. Con los 349 vuelos, a = 5,38 m/s y b = 15,09 m/s. Las líneas continuas de la figura son esta fórmula para un dron vacío y para uno con 1 kg de carga.

I3 lleva esta velocidad al tiempo de regreso, a la velocidad aerodinámica requerida, a corriente × tiempo y a un término de resistencia, así que todas las entradas basadas en tiempo ahora respetan el límite de inclinación.

## Un árbol no puede ir adonde no estuvo

Antes de escribir la fórmula, probé por el lado del machine learning: un random forest que predecía la velocidad de regreso a partir de las mismas entradas del momento de decisión. Anduvo bien, pero en validación nunca predijo menos de unos 7,2 m/s, ni siquiera para vuelos que volvieron arrastrándose a 5.

No es un bug; así funcionan los árboles. Un árbol predice promedios de los ejemplos de entrenamiento en cada hoja, así que no puede predecir fuera del rango que vio. Y había visto muy poco: de los primeros 250 vuelos, solo 17 volvieron contra 4 m/s o más de viento de frente. Esa misma limitación probablemente contribuye a que XGBoost quedara atrás en todos los conjuntos de entradas, aunque no es toda la historia: XGBoost corrió con una única configuración fija, mientras que las redes tuvieron un barrido completo de arquitecturas.

La fórmula extrapola porque es una relación física, no una tabla de consulta. Pero el problema de fondo era real para todos los modelos: 17 vuelos son muy pocos para aprender los casos más difíciles.

## Así que volé más de los difíciles

Volé 39 vuelos de entrenamiento extra, todos con 4 a 6 m/s de viento a menos de 30° de estar directamente en contra del camino de regreso.

Con ellos, el piso del forest desapareció y casi alcanzó a la fórmula: en vuelos nuevos, su error de velocidad fue de 0,29 m/s, contra 0,24 de la fórmula y 1,76 de unos 10 m/s fijos. No hice un experimento aparte para medir cuánto ayudaron los vuelos extra a los modelos de carga, así que no voy a afirmar un número. Pero todos los modelos finales se entrenaron con ellos, y el viento de frente fuerte dejó de ser una región que los modelos casi no habían visto.

## El test honesto

A esta altura, los 39 vuelos de validación y los 39 de test habían guiado demasiadas decisiones como para contar como examen final. Así que generé 60 vuelos nuevos, la mitad con viento de frente fuerte y la mitad repartidos por todo el rango. Antes de evaluar cualquiera de ellos, dejé por escrito los modelos candidatos, las semillas aleatorias, las reglas de entrenamiento y las comparaciones que iba a hacer. Después los evalué una sola vez.

![Error absoluto medio con intervalos del 95% en los 60 vuelos de confirmación para la regla de tiempo por corriente y cuatro modelos aprendidos](confirmation.png "Todos los modelos aprendidos le ganan a la regla simple por un factor de cinco. Entre ellos, 60 vuelos no alcanzan para separarlos.")

El regreso medio en esos vuelos usó 1.809 mAh. Los candidatos punteros, Ridge con I3 y la red con I3, erraron por unos 38 a 39 mAh, aproximadamente un 2%, en un conjunto cargado a propósito con vuelos difíciles de viento de frente. La regla de tiempo × corriente erró por 196.

La lectura honesta es modesta. Los mejores modelos están dentro de la incertidumbre de los otros: Ridge con I3 le ganó a Ridge con I2 por 6,5 mAh, con un intervalo del 95% de −15,4 a +1,9. Consistente, pero 60 vuelos no alcanzan para separar modelos que difieren en pocos mAh. Y por debajo de 2 m/s de viento de frente, todos los modelos aprendidos ya estaban dentro del 1 a 2% del valor real. Los modelos se diferencian con viento de frente fuerte, donde los errores aproximadamente se duplican.

## La arquitectura importó menos de lo que esperaba

El curso es sobre redes neuronales, así que las barrí en serio: 15 formas, de 16 unidades a 1.024, de una capa a diez, cada una entrenada con tres semillas. Una sola capa de 1.024 unidades ganó en validación y fue al test honesto.

Después repetí el barrido con validación cruzada de cinco folds sobre los 289 vuelos de entrenamiento, así cada vuelo pasó una vez por validación. La ventaja de la ganadora desapareció:

| Modelo | Parámetros | MAE con validación cruzada (mAh) |
| --- | ---: | ---: |
| 256 unidades | 11.521 | 20,5 |
| 512 unidades | 23.041 | 20,8 |
| 64-32-16 | 5.441 | 21,8 |
| 1.024 unidades | 46.081 | 21,9 |
| 128-64-32 | 16.001 | 22,1 |
| Ridge | 44 | 22,6 |
| 16 unidades | 721 | 25,9 |
| 10 capas × 16 | 3.169 | 50,8 |

Todo lo que va de unos 5.000 a 46.000 parámetros quedó dentro de unos 2,5 mAh. La red de 1.024 unidades siguió siendo competitiva, pero su ventaja venía de elegir el mejor de muchos ajustes sobre 39 vuelos, que es exactamente como un conjunto de validación chico puede engañarte.

Me sorprendió que ninguna red más profunda anduviera mejor, así que revisé si simplemente les faltaba entrenamiento: las dejé entrenar hasta 3.000 épocas en lugar de 600. Ninguna forma se movió más de 0,7 mAh, y las redes más profundas se detuvieron solas mucho antes del límite. Una vez que las entradas llevan la física del límite de inclinación, lo que queda por aprender es lo bastante suave para una sola capa ancha. Solo falló la red de diez capas, y eso es una dificultad de entrenamiento, no falta de épocas.

Un detalle importó más que la profundidad. Una red arranca con pesos aleatorios, fijados por una semilla, así que dos redes entrenadas con los mismos datos y distintas semillas terminan siendo un poco diferentes. Entrenar tres copias con semillas distintas y promediar sus predicciones, vuelo por vuelo, le ganó a cada copia individual. Para la red de 256 unidades, las tres copias por separado erraban entre 23,1 y 24,7 mAh en promedio; su predicción promediada erraba 20,5. No es una paradoja: en un vuelo dado, una copia puede errar 30 mAh por arriba y otra 30 mAh por abajo, y su promedio cae cerca del valor real. Promediar las predicciones cancela parte del error individual de cada copia.

## Entradas contra modelos, con todos los datos

Para la última comparación usé los 349 vuelos, validación cruzada de cinco folds y la red de 256 unidades.

![Mapa de calor del error absoluto medio para los conjuntos de entradas I0 a I3 contra Ridge, XGBoost y una red neuronal](inputs-vs-models.png "Leyendo una columna hacia abajo se ve cuánto valen las entradas. Leyendo una fila se ve cuánto vale el modelo.")

La red fue la mejor en todos los conjuntos de entradas, y fue la que menos dependió de la física precalculada: 33 mAh con las entradas crudas. Ridge fue el que más ganó con la física, de 92 a 25, porque no puede construir combinaciones no lineales por sí solo. XGBoost casi no se movió hasta I3 (66, 66, 52 y después 28): los árboles no pueden extrapolar a los regresos lentos en el límite de inclinación, y la fórmula de velocidad lo hace por ellos.

## El modelo final

El modelo final es la red de 256 unidades con las entradas de I3, promediada sobre tres semillas y entrenada con los 349 vuelos.

Para estimar qué tan bien predice vuelos que nunca vio, usé validación cruzada anidada. Todo el procedimiento (elegir entre Ridge y tres formas de red, y después entrenar) se repitió dentro de cinco folds, y cada fold se evaluó con vuelos que nunca tocó. Eligió 256 unidades en cuatro de los cinco.

![Carga de regreso predicha contra real para los 349 vuelos, coloreada por viento de frente, y error absoluto medio por franja de viento de frente para la red y Ridge](final-model.png "Cada punto es una predicción para un vuelo con el que el modelo no se entrenó.")

Error absoluto medio: 21,6 mAh (intervalo del 95% de 19,1 a 24,2), alrededor del 1,2% de la carga. Este número responde una pregunta distinta de los 38 mAh del test honesto: estima qué tan bien le va al procedimiento de selección final sobre los 349 vuelos, de los cuales solo alrededor de un cuarto tienen viento de frente fuerte, en lugar de sobre un conjunto nuevo cargado hacia los casos difíciles. Unos 13 mAh con viento de cola o viento de frente leve, 24 entre 2 y 4 m/s, 41 entre 4 y 6 m/s. Un caso típico con viento de frente fuerte: un vuelo a 1,37 km de casa, con 5,1 m/s de viento en contra y 0,5 kg de carga, usó 2.948 mAh para volver. El modelo, que nunca vio ese vuelo, predijo 2.918. La regla de tiempo × corriente dijo 3.448.

## ¿Por qué no un umbral fijo?

Un umbral de batería fijo tiene que elegir un único número para todos los regresos. En estos vuelos, el regreso costó entre 738 y 3.182 mAh, con una mediana de 1.659.

Si el umbral se dimensiona para un regreso típico, en el vuelo de arriba el dron habría empezado a volver con unos 1.290 mAh menos de los que necesitaba. Quedarse corto es el lado peligroso: el vehículo se queda sin batería antes de llegar y termina en un aterrizaje forzoso o un choque, en un lugar que no elegiste.

Si se dimensiona para el peor regreso visto, 3.182 mAh, el vuelo de arriba llega a casa con unos 230 mAh de sobra; bien, ¿no? Ahora tomemos un regreso corto y fácil: a 313 m de casa, con un viento de cola leve y 0,4 kg de carga. Usó 774 mAh, y el modelo predijo 769. Con el umbral del peor caso, ese dron habría pegado la vuelta con unos 2.400 mAh todavía sin usar, más del triple de lo que realmente costó el viaje. Pasarse es seguro pero caro: las misiones terminan antes, el dron cubre menos terreno por batería, y la solución habitual es una batería más grande y pesada, que tiene su propio costo en autonomía.

Una predicción que se adapta a la distancia, el viento y la carga permite que el regreso empiece cuando realmente hace falta, con una reserva dimensionada para el error del modelo y no para el peor caso de todo el rango.

## Dónde todavía falla

La peor subestimación fue de 130 mAh, y los errores tienen un patrón claro: la velocidad de regreso. En el test honesto, los dos errores más grandes vinieron después de sobrestimar la velocidad en 0,7 a 0,9 m/s, y con viento de frente fuerte el error de carga siguió de cerca al error de velocidad (correlación −0,81). Un experimento anterior apunta en la misma dirección. Antes de los vuelos extra con viento de frente, un modelo Ridge anterior, entrenado con los primeros 172 vuelos, subestimó un vuelo de validación por 414 mAh. Dándole la velocidad de regreso *medida* en lugar de una predicha, algo que ningún dron tiene de antemano, su peor error bajó a 60 mAh. Predecir mejor la velocidad en el límite de inclinación es la palanca que queda.

Estos modelos predicen la carga esperada, así que el regreso real a menudo cuesta un poco más: el modelo final subestimó el 47% de los vuelos. Quien use una predicción así debería sumarle una reserva, dimensionada con errores sobre datos no vistos para que una proporción elegida de los vuelos, por ejemplo el 95%, use menos que la predicción más la reserva. Como los errores crecen con el viento de frente, probablemente esa reserva también debería crecer con él.

## Lo que esto no es

Esto es un solo cuadricóptero simulado con la física incorporada de SITL, con viento constante y uniforme y una carga útil puntual. El viento real tiene ráfagas, las baterías reales caen con la temperatura y la edad, y los sensores de corriente reales necesitan calibración. El modelo predice la carga esperada, no una garantía de seguridad.

Lo que sí se trasladaría es la estructura. Las entradas son en su mayoría cosas que cualquier multicóptero registra: ruta, estimación de viento, corriente, acelerador. El límite de inclinación en sí es un parámetro del controlador, así que un vehículo real con ArduPilot también lo va a alcanzar. Lo que no está validado es todo lo que se deriva de eso en hardware real: la velocidad aerodinámica en la que se estabiliza, cómo escala con el peso y cuánta energía cuesta después el regreso.

Para otro dron, o para vuelos reales de este, reajustaría los dos parámetros de la fórmula de velocidad con algunos vuelos en el límite de inclinación, y después adaptaría la red en lugar de empezar de cero: conservar su capa oculta y reentrenar la capa de salida con algunas decenas de vuelos reales, o entrenar un modelo chico de corrección sobre la diferencia entre la realidad y la predicción entrenada en simulación. No probé ninguna de las dos, así que es un próximo paso, no un resultado.

## Lo que me llevo

**Mirar qué hace realmente el sistema antes de modelarlo.** Mi primera suposición de velocidad era correcta para la mayoría de los vuelos y equivocada justo donde importaba. Los logs mostraron un límite duro que no había tenido en cuenta.

**Una fórmula puede ir adonde los datos no llegaron.** El forest no podía predecir velocidades que nunca había visto. Dos parámetros con una razón física detrás, sí.

**Si los casos difíciles son raros, hay que ir a buscar más.** 17 vuelos con viento de frente fuerte no alcanzaban para aprender.

**Desconfiar de un ganador elegido con un conjunto de validación chico.** La red de 1.024 unidades ganó el primer barrido, pero ese barrido comparó 45 redes sobre los mismos 39 vuelos, y el mejor de 45 puntajes con tan pocos vuelos es en parte suerte. Con validación cruzada sobre los 289 vuelos de entrenamiento quedó en la mitad del grupo, y las redes buenas quedaron todas a unos 2,5 mAh entre sí.

**Entradas antes que arquitectura, otra vez.** La misma lección que en el proyecto de decaimiento orbital, a la que llegué desde el otro lado: la red podía llegar lejos con entradas crudas, pero todos los modelos anduvieron mejor cuando la física se calculaba por ellos.

La configuración del simulador, el pipeline de vuelos, los modelos y todas las figuras de este post son públicos:

**[Ver el predictor de carga de RTL de ArduPilot en GitHub](https://github.com/Allaneo/ardupilot-rtl-charge-predictor)**
