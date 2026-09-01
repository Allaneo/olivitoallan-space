---
title: "CanSat: trayendo un huevo desde el espacio con un parapente"
summary: "Cómo navegamos la aerodinámica de alas flexibles, desciframos sutilezas de la literatura, dedujimos ángulos de entrada a partir de fotos, calibramos suspentajes de Kevlar al milímetro y realizamos pruebas de caída con drones para cumplir con una exigente misión CanSat."
description: "Un recorrido técnico completo sobre la aerodinámica, el modelado, la manufactura, el guiado (GNC) y los ensayos de vuelo de un paracaídas tipo ram-air autónomo para la recuperación de un CanSat."
date: 2026-09-01T08:00:00-03:00
draft: false
translationKey: "ram-air-parachute-design"
slug: "trayendo-un-huevo-desde-el-espacio-con-un-parapente"
showMath: true
featureimagecaption: "El recorrido completo: desde las primeras iteraciones aerodinámicas hasta el ala tipo ram-air completamente inflada y autónoma en vuelo"
tags: ["aerodinámica", "parapente", "paracaídas ram-air", "CanSat", "GNC", "MATLAB", "Simulink", "manufactura"]
categories: ["proyectos"]
---

{{< katex >}}

Primero, una pequeña aclaración: en realidad no fuimos al espacio exterior.

Nuestro "espacio" fue un cohete sonda suborbital que alcanzaba un apogeo cercano a un kilómetro de altura. Pero cuando tenés la tarea de guiar de forma autónoma una carga útil frágil hasta una zona de aterrizaje precisa y entregar un huevo crudo de supermercado completamente intacto, un kilómetro se siente bastante alto.

Cuando se publicaron las bases de la competencia, un requerimiento definió por completo nuestro proyecto: **la carga útil del CanSat debía descender mediante un sistema de recuperación autónomo y direccionable, y liberar un huevo crudo a 2 metros del suelo.**

El pliego de la misión dividía la secuencia de descenso en dos etapas bien diferenciadas:

1. **La Etapa del Contenedor**: Tras la eyección en el apogeo del cohete (soportando un impacto de **~30 G**), el contenedor debía estabilizarse y descender a **15 m/s ± 3 m/s** usando un paracaídas pasivo convencional.
2. **La Etapa de la Carga Útil**: En pleno vuelo, el contenedor liberaba nuestra carga, la cual debía desplegar un **sistema de descenso autónomo y direccionable** con una tasa de caída de entre **2 y 8 m/s**, navegar hacia una coordenada objetivo y liberar de forma autónoma la cápsula del huevo a **2 metros sobre el terreno**, dejándolo intacto.

Diseñar, construir y ensayar el paracaídas pasivo del contenedor nos llevó apenas unos días de trabajo. Era un paracaídas octogonal plano clásico, con líneas de suspensión cortadas a 1.25× el diámetro.

Cumplir con el descenso direccionable, en cambio, implicaba construir un ala tipo ram-air (parafoil) autónoma desde cero. Eso se convirtió en un viaje de ingeniería de varios meses a través de la aerodinámica de alas flexibles, herramientas de trimado a medida en MATLAB, análisis forense de fotografías, atascos en la máquina de coser, suspentajes de Kevlar con precisión milimétrica y ensayos de caída libre a gran altura con drones.

> *Nota: Este artículo se enfoca estrictamente en el diseño técnico, el modelado, la fabricación y las pruebas de vuelo del sistema. Un artículo complementario que abordará los aprendizajes organizacionales y de gestión de equipo se publicará próximamente.*

---

## 1. Fundamentos Aerodinámicos y Hallazgos en la Literatura

Cuando empezamos a investigar alas flexibles direccionables, al principio tratamos a los paracaídas tipo ram-air y a los parapentes como conceptos intercambiables. No lo son.

<div style="max-width: 620px; margin: 24px auto; text-align: center;">
  <img src="paraglider-vs-ram-air.jpg" alt="Parapente vs Paracaídas Ram-Air en vuelo" style="width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
  <p style="font-size: 0.8rem; color: #64748b; margin-top: 8px;">
    <strong>Izquierda</strong>: Parapente despegado a pie (alto alargamiento, perfil delgado, bocas inferiores). 
    <strong>Derecha</strong>: Paracaídas Ram-Air eyectado en el aire (bajo alargamiento, perfil grueso, grandes bocas frontales).
  </p>
</div>

Un parapente se **despega desde tierra**. El piloto corre hacia adelante en una pendiente para inflar las celdas con aire limpio antes de despegar. Como el choque de apertura es despreciable y el rendimiento de planeo lo es todo, los parapentes tienen alargamientos altos (AR ≈ 5 a 6), perfiles delgados y bocas de entrada pequeñas ocultas debajo del intradós.

Un paracaídas tipo ram-air se **despliega en el aire**. Se libera en caída libre a altas velocidades de descenso. Si desplegás un parapente delgado y de gran alargamiento en caída libre, los extremos del ala se colapsan hacia adentro, las pequeñas entradas inferiores no reciben flujo y las líneas se enredan antes de que el ala pueda presurizarse.

Las alas desplegadas en vuelo (documentadas en la literatura clásica de paracaídas por Knacke y Lingard) exigen un paradigma de diseño completamente diferente:
- **Bajo Alargamiento (AR ≈ 1.8 a 2.2)** para garantizar rigidez estructural y apertura simétrica a lo largo de la envergadura.
- **Perfiles gruesos (~16 a 18%)** para maximizar el volumen interno de las celdas y su presurización.
- **Bocas de entrada grandes y orientadas al frente**, expuestas directamente al flujo de aire relativo que impacta de frente.

### Dimensionamiento de las Bocas: Entendiendo los Regímenes de Lingard
Un paracaídas ram-air es una viga neumática de tela que solo mantiene su forma aerodinámica porque la presión dinámica del aire ingresa por el borde de ataque abierto y lo presuriza desde el interior:

$$q = \tfrac{1}{2}\rho V_\infty^2$$

Al dimensionar las tomas de aire, estudiamos el paper fundamental de J.S. Lingard sobre campanas ram-air. El trabajo plantea dos regímenes de operación muy distintos que tuvimos que separar con cuidado:
1. **Crucero en Régimen Permanente**: Una altura de boca del **8.4%c** (fracción de la cuerda) es suficiente cuando el ala ya está planeando, ya que la abertura solo necesita capturar el estrecho desplazamiento del punto de estancamiento en los ángulos de ataque de vuelo normal.
2. **Despliegue Dinámico e Inflado**: Durante la fase inicial de apertura, donde el ala se mueve en un flujo turbulento y desalineado, el paper utiliza una altura promedio de boca del **14%c** (11%c sobre las costillas rígidas y 15%c en el abombamiento de la tela entre costillas).

Nuestro diseño inicial utilizaba una boca demasiado ajustada (0.09c), lo que generaba fallas durante las perturbaciones del despliegue. Ampliar la abertura al régimen de despliegue dinámico fue clave para lograr inflados confiables.

### El Misterio del Corte a 45 Grados
Conocer la altura de la boca era solo la mitad del problema. ¿Qué ángulo debía formar el corte diagonal con la línea de la cuerda?

Revisamos papers y manuales técnicos, pero no encontramos valores explícitos para el ángulo de corte diagonal. Así que recurrimos al análisis fotográfico: descargamos fotos de campanas de paracaidismo deportivo, pausamos videos de YouTube de paracaídas RC a escala cuadro por cuadro e inspeccionamos modelos 3D.

<div style="max-width: 420px; margin: 24px auto; text-align: center;">
  <img src="rib-pattern-45deg-inlet.jpg" alt="Patrón de papel de la costilla con entrada a 45 grados y ventanas de presurización" style="width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
  <p style="font-size: 0.8rem; color: #64748b; margin-top: 8px;">
    El patrón de papel de la costilla mostrando el corte diagonal a 45° en el borde de ataque y las perforaciones circulares de presurización interna.
  </p>
</div>

Comparando la geometría en múltiples diseños, dedujimos un **corte diagonal a 45°**. Este ángulo coincidía físicamente con el vector de velocidad relativa esperado en vuelo de crucero, permitiendo que el flujo de aire ingrese de forma limpia a las celdas y preservando al mismo tiempo suficiente cuerda en el extradós para sostener la succión y sustentación sobre el borde de ataque.

### El Perfil Clark Y al 18%
Lingard hace referencia frecuente al perfil **Clark Y**, una geometría histórica con un intradós plano que simplifica enormemente el trazado y la costura de las costillas de tela.

<div style="max-width: 360px; margin: 24px auto; text-align: center;">
  <img src="clark-y-18-surfplan-profile.jpg" alt="Configuración del perfil Clark YM-18 en Surfplan" style="width: 100%; height: auto; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
  <p style="font-size: 0.8rem; color: #64748b; margin-top: 8px;">
    Configuración de perfil en Surfplan: Clark Y engrosado al 18% (17.99% al 29.59% de la cuerda) con abertura de borde de ataque al 15%.
  </p>
</div>

El perfil Clark Y estándar tiene un espesor máximo del 11.7%. El paper de Lingard evaluaba explícitamente un **Clark Y engrosado al 18%**. Al principio no habíamos dimensionado el impacto de esta modificación, pero lo entendimos rápidamente antes de diseñar el Mk 2. El perfil más grueso incrementa notablemente el volumen y la presión interna de las celdas, otorgando rigidez estructural sin necesidad de varillas rígidas internas.

### La Advertencia de 5 Segundos en *SingleSkin* y el Factor Longitud de Líneas
Durante las primeras pruebas, los extremos del ala tendían a cerrarse hacia adentro apenas las líneas tomaban tensión. Ninguno de nuestros libros de texto tradicionales explicaba con claridad la causa.

La revelación vino de un lugar inesperado. Mientras probábamos geometrías en un software abierto para parapentes llamado ***SingleSkin***, apareció una ventana emergente que desapareció a los 5 segundos:

> `WARNING: The angle between the outer suspension lines and the local lower canopy surface shall be greater than 90°`

Ese mensaje fugaz señaló la raíz del problema: si una línea de suspensión se ancla formando un ángulo agudo (θ < 90°), la tensión genera una **fuerza lateral hacia el centro** que arrastra la tela y colapsa la celda externa. Cuando θ > 90°, la tensión tira ligeramente hacia afuera, estabilizando la envergadura.

Sin embargo, lograr un ángulo mayor a 90° en las puntas planteaba un dilema de diseño: o cambiabas la forma del ala a lo largo de la envergadura (introduciendo un arco anédrico) o alargabas las líneas de suspensión.

**Y acá hay un detalle crítico: la longitud de las líneas es determinante tanto para la estabilidad estática como para la dinámica.** La longitud fija la distancia pendular entre el centro de presiones (CP) del ala y el centro de gravedad (CG) de la carga suspendida. Modificar esta distancia altera de forma directa los momentos de restitución en cabeceo, la frecuencia de oscilación del péndulo y el amortiguamiento aerodinámico de todo el conjunto.

### La Solución del Arco Anédrico
Como alargar en exceso las líneas sumaba resistencia parásita y empeoraba la oscilación pendular, mantuvimos las líneas cortas y resolvimos la condición angular curvando el ala en un **arco anédrico**. Adoptamos un **arco de curvatura total de 82°**, lo que permitió que el peso de la carga suspendida traccionara hacia afuera a través del suspentaje, manteniendo la tensión transversal del ala sin requerir líneas largas.

---

## 2. Modelado Aerodinámico, Trimado y Dinámica de Vuelo

### 2.1 Resistencia Parásita, Relación L/D y Velocidad de Descenso
A la escala de un CanSat, la campana de tela representa solo una fracción de la resistencia total del sistema. Las líneas de suspensión, el cuerpo cilíndrico de la carga y las varillas estructurales de fibra de carbono actúan como cuerpos romos expuestos al flujo.

<div style="display: flex; gap: 16px; justify-content: center; align-items: flex-start; flex-wrap: wrap; max-width: 580px; margin: 24px auto;">
  <div style="flex: 1 1 240px; max-width: 280px; text-align: center;">
    <img src="drag-distribution.png" alt="Distribución de resistencia parásita en el sistema CanSat" style="width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
    <p style="font-size: 0.75rem; color: #64748b; margin-top: 6px;">Distribución de resistencia parásita: la estructura y el cuerpo generan el 75% del total.</p>
  </div>
  <div style="flex: 1 1 180px; max-width: 200px; text-align: center;">
    <img src="cansat-chassis-assembly.jpg" alt="Chasis estructural del CanSat" style="width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
    <p style="font-size: 0.75rem; color: #64748b; margin-top: 6px;">Chasis con 4 varillas estructurales de carbono (⌀5mm).</p>
  </div>
</div>

La elevada resistencia parásita de la estructura limitaba nuestra relación de planeo real a valores de L/D ≈ 2 a 3, lo que fijaba el ángulo de la senda de planeo en:

$$\gamma = -\arctan\left(\frac{1}{L/D}\right) \approx -18^\circ \text{ a } -26^\circ$$

Sin embargo, el valor de L/D determina la pendiente de planeo, no la velocidad absoluta de descenso. La tasa de caída vertical (V_sink) depende de la velocidad de equilibrio en aire (Va) sobre esa trayectoria:

$$V_a = \sqrt{\frac{2 m g}{\rho S \sqrt{C_L^2 + C_D^2}}}$$

$$V_{\text{sink}} = V_a \sin(-\gamma)$$

Al equilibrar la masa total de la carga (m ≈ 554 g), la superficie de referencia del ala (S = 0.53 m²) y el coeficiente de resistencia total, obtuvimos una velocidad de crucero Va ≈ 8 m/s y una tasa de caída vertical de **≈ 5 m/s**, cumpliendo holgadamente el **requerimiento de misión de 2 a 8 m/s**.

### 2.2 Coeficientes Aerodinámicos y Análisis de Trimado en MATLAB
Para evaluar el vuelo en equilibrio, utilizamos **XFLR5** y **Flow5** para extraer las polares aerodinámicas 3D de sustentación, resistencia y momentos del ala.

<div style="max-width: 500px; margin: 24px auto; text-align: center;">
  <img src="xflr5-aerodynamics.jpg" alt="Líneas de corriente 3D y análisis de paneles en XFLR5" style="width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
  <p style="font-size: 0.8rem; color: #64748b; margin-top: 8px;">
    Líneas de corriente 3D y análisis aerodinámico de paneles de la campana en XFLR5.
  </p>
</div>

Luego desarrollé un **programa de trimado en MATLAB** que acoplaba las polares aerodinámicas con la dinámica pendular de la carga suspendida:

El algoritmo resolvía el equilibrio de fuerzas y momentos de cabeceo respecto al centro de masa total:

$$C_{M,\text{total}} = C_{M,\text{ala}} + C_{M,\text{brazo}} + C_{M,\text{líneas}} = 0$$

$$\frac{dC_M}{d\alpha} < 0 \quad (\text{Estabilidad Estática Longitudinal})$$

El programa determinó nuestro punto nominal de operación en crucero:
- **Velocidad de crucero (Va)**: ≈ 8 m/s
- **Ángulo de ataque de trimado (α_trim)**: ≈ 3°
- **Ángulo de calaje (θ_rig)**: ≈ 11.7° respecto al eje vertical de la carga
- **Derivada de restitución en cabeceo (dCm/dα)**: Fuertemente negativa, confirmando estabilidad estática longitudinal.

### 2.3 Arquitectura de Guiado y Divergencia Espiral
Para la navegación autónoma adoptamos una estructura en dos lazos:
- **Lazo Externo (Guiado 3-DoF)**: Administraba la planificación de trayectoria y el seguimiento de waypoints en base a velocidad de aire, ángulo de trayectoria y rumbo.
- **Lazo Interno (Dinámica 6-DoF)**: Controlaba el accionamiento de los servos sobre las líneas de freno del borde de fuga, utilizando cuaterniones para evitar singularidades matemáticas durante perturbaciones de actitud.

Nuestras simulaciones y la literatura especializada evidenciaron una restricción dinámica fundamental: **las alas ram-air con alta carga alar son susceptibles a la divergencia espiral durante virajes sostenidos.**

Si el piloto automático comanda un viraje continuo en una misma dirección, el semiala exterior se acelera, el ángulo de alabeo se incrementa, el morro cae y la tasa de descenso aumenta de forma descontrolada.

Para evitarlo:
- Se limitó por software el ángulo máximo de alabeo.
- Se acotó estrictamente la tasa de viraje.
- El sistema de guiado empleó **patrones de espera en figura de 8 alternada** cerca de los puntos de navegación en lugar de giros circulares continuos.

---

## 3. Evolución del Ala: del Mk 1 al Mk 2

Fabricamos dos prototipos completos de doble superficie:

<div style="display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; max-width: 600px; margin: 24px auto;">
  <div style="flex: 1 1 260px; max-width: 280px; text-align: center;">
    <img src="mk1-black-canopy.jpg" alt="Prototipo inicial Mk 1 de doble superficie" style="width: 100%; height: 180px; object-fit: cover; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.08);" />
    <p style="font-size: 0.75rem; color: #64748b; margin-top: 6px;"><strong>Prototipo Mk 1</strong>: Primera ala compacta de prueba.</p>
  </div>
  <div style="flex: 1 1 260px; max-width: 280px; text-align: center;">
    <img src="surfplan-3d-model.jpg" alt="Modelo CAD 3D de 8 celdas en Surfplan" style="width: 100%; height: 180px; object-fit: cover; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.08);" />
    <p style="font-size: 0.75rem; color: #64748b; margin-top: 6px;"><strong>Modelo Surfplan Mk 2</strong>: Ala escalada de 8 celdas con arco anédrico de 82°.</p>
  </div>
</div>

### Mk 1: El Primer Prototipo de Doble Capa
Nuestro primer prototipo fabricado, el Mk 1, fue un ala compacta de doble superficie. Si bien demostró que podíamos cortar y coser una estructura inflable, las pruebas revelaron tres problemas críticos:
1. **Ángulos de línea agudos**: Las fijaciones exteriores tenían ángulos < 90°, lo que colapsaba los extremos.
2. **Bocas pequeñas**: Con una altura cercana a 0.09c, las entradas no lograban capturar aire de forma confiable durante el despliegue dinámico.
3. **Alta carga alar y ángulo de ataque excesivo**: Como la superficie sustentadora era pequeña para el peso de la carga, el ala solo podía generar suficiente sustentación volando a un ángulo de ataque mucho más alto, cerca del régimen de pérdida, lo que degradaba el control y aumentaba la resistencia.

### El Descubrimiento de la Carga Alar y el Mk 2
Entre el Mk 1 y el Mk 2 encontramos en la literatura una relación fundamental que vincula la **superficie sustentadora con la masa total suspendida** (carga alar).

Esta correlación empírica demostró que para lograr nuestra velocidad de descenso objetivo en un ángulo de ataque seguro de crucero, el ala debía ser aproximadamente el doble de grande. Para el Mk 2 duplicamos el área y refinamos la geometría en *Surfplan*:

- **Superficie Alar (S)**: 0.53 m²
- **Envergadura (b)**: 1.03 m
- **Cuerda Constante**: 50 cm en todos los paneles
- **Perfil**: Clark Y al 18% con bocas diagonales a 45° (abertura al 14%c)
- **Curvatura Transversal**: Arco anédrico de 82°
- **Ventilación Intercelar (Cross-Ports)**: Orificios circulares cortados a tijera en cada costilla interna, permitiendo equilibrar la presión interna ante ráfagas asimétricas.

Adoptar una **cuerda constante de 50 cm** fue una decisión clave de manufactura. En el Mk 1, los extremos afilados requerían coser costillas diminutas, algo extremadamente complejo y propenso a errores en una máquina de coser hogareña. Una cuerda rectangular uniforme garantizó que todas las costillas y paños de tela fueran idénticos, haciendo el corte y armado totalmente repetible.

### El Error del Centro de Gravedad y la Solución Arquitectónica
Cuando terminamos de fabricar el Mk 2, nos dimos cuenta de un error grave de cálculo: **las longitudes de las líneas de suspentaje se habían calculado asumiendo que el centro de gravedad (CG) de la carga útil estaba en la placa superior de anclaje.**

En la realidad, la electrónica y la batería ubicadas abajo desplazaban el CG real mucho más abajo en el cuerpo del CanSat, arruinando por completo el brazo pendular y el balance de momentos de cabeceo.

Fabricar un ala "Mk 3" estaba descartado: confeccionar el Mk 2 había requerido días de intenso trabajo manual y nos estábamos quedando sin tiempo. Teníamos que resolver la estabilidad sin rehacer el ala.

Lo solucionamos con dos acciones:
1. Ajustamos las longitudes del suspentaje de Kevlar para compensar parte del desvío.
2. **Reubicamos físicamente la bandeja de electrónica mucho más arriba dentro de la estructura del CanSat**, elevando el CG real.

Fue una lección fantástica sobre cómo los requerimientos heredados pueden encasillar un diseño: la electrónica se había colocado abajo por un requerimiento estructural anterior que ya no aplicaba tras un rediseño de chasis. Eliminar esa restricción nos permitió rebalancear el cabeceo del sistema sin tener que cortar un solo paño de tela nuevo.

---

## 4. Manufactura y el Protocolo de Suspentaje Milimétrico

### 4.1 Telas, Hilos y Moldería
- **Nylon Ripstop Recubierto de Baja Porosidad**: La baja permeabilidad al aire es crítica en alas ram-air. Si el aire se escapa a través del tejido, la presión interna cae y el perfil se desinfla. Utilizamos nylon ripstop con recubrimiento de poliuretano/silicona (~40 a 50 g/m²).
- **Patrones de Papel y Armado**: Imprimimos moldes de CAD en escala 1:1 con márgenes de costura y marcas de registro.
- **El "Toile" (Muestra de Prueba)**: Antes de cortar la tela técnica costosa, cosimos un prototipo completo en tela de descarte barata. Esto permitió detectar a tiempo problemas en márgenes de costura, tolerancias y el orden de ensamble de los paneles.
- **Hilo y Aguja**: Utilizamos hilo de nylon bondeado de alta tenacidad Tex T-45 con **agujas punta bolita #10/70**. Las agujas afiladas pueden cortar los filamentos estructurales del ripstop; las agujas de punta redondeada separan las fibras del tejido sin dañarlas.

<div style="display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; max-width: 580px; margin: 20px auto;">
  <div style="width: calc(50% - 6px); max-width: 260px; text-align: center;">
    <img src="printed-paper-patterns.jpg" alt="Moldes de CAD impresos en papel" style="width: 100%; height: 140px; object-fit: cover; border-radius: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.06);" />
    <p style="font-size: 0.7rem; color: #64748b; margin-top: 4px;">Patrones de CAD en papel</p>
  </div>
  <div style="width: calc(50% - 6px); max-width: 260px; text-align: center;">
    <img src="sewing-assembly-clips.jpg" alt="Paneles fijados con clips de costura" style="width: 100%; height: 140px; object-fit: cover; border-radius: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.06);" />
    <p style="font-size: 0.7rem; color: #64748b; margin-top: 4px;">Clips de costura y líneas de tiza</p>
  </div>
  <div style="width: calc(50% - 6px); max-width: 260px; text-align: center;">
    <img src="internal-ribs-crossports.jpg" alt="Ventanas de presurización intercelar cortadas a mano" style="width: 100%; height: 140px; object-fit: cover; border-radius: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.06);" />
    <p style="font-size: 0.7rem; color: #64748b; margin-top: 4px;">Ventanas de presurización (cross-ports)</p>
  </div>
  <div style="width: calc(50% - 6px); max-width: 260px; text-align: center;">
    <img src="orange-panels-layout.jpg" alt="Disposición de paños de nylon ripstop naranja con marcas de borde de fuga" style="width: 100%; height: 140px; object-fit: cover; border-radius: 6px; box-shadow: 0 2px 6px rgba(0,0,0,0.06);" />
    <p style="font-size: 0.7rem; color: #64748b; margin-top: 4px;">Paños de intradós/extradós marcados</p>
  </div>
</div>

### 4.2 El Protocolo de Suspentaje de Kevlar al Milímetro
Elegimos cordino trenzado de Kevlar de 50 lb (D ≈ 0.5 mm) para el suspentaje debido a su altísima resistencia y nula elasticidad bajo carga.

Sin embargo, **hacer un nudo consume longitud de línea**. En un ala flexible, un desvío de apenas unos milímetros modifica notablemente el ángulo de ataque local.

Para mantener una precisión milimétrica en todo el suspentaje, implementamos un protocolo riguroso:
1. **Regla de Cero Absoluto**: Recortamos una regla de acero para que el origen de la escala coincidiera exactamente con el borde físico del metal.
2. **Corte y Gazas**: Cortábamos cada tramo de Kevlar con margen y formábamos una gaza o lazo terminal en un extremo.
3. **Medición Calibrada**: Midiendo desde la gaza, marcábamos con tinta la longitud exacta calculada para cada estación de costilla (`Costillas 1, 3, 5, 7`) y fila de línea (`SUSPENTAS: A, B, C` o `FRENOS: D`).
4. **Anclaje**: Atábamos la línea a la lengüeta de la costilla posicionando el nudo de modo que la marca coincidiera con el punto de anclaje, fijándolo luego con una gota de cianoacrilato.
5. **Interfaz de Bandas**: Las líneas de sustentación de cada lado se agrupaban hacia su respectiva banda (riser), mientras que los frenos del borde de fuga se conectaban a los servomotores. La unión a las bandas de poliéster de 15 mm se hizo mediante anillas de acero inoxidable (split-rings), facilitando ajustes modulares sin desatar nudos.

<div style="max-width: 280px; margin: 24px auto; text-align: center;">
  <img src="featured.jpg" alt="Sosteniendo el ala Mk 2 terminada con líneas tensadas en el taller" style="width: 100%; height: auto; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.08);" />
  <p style="font-size: 0.8rem; color: #64748b; margin-top: 8px;">
    Sosteniendo el ala Mk 2 completa con las líneas de suspentaje tensadas sobre la mesa de trabajo.
  </p>
</div>

---

## 5. Despliegue: La Bolsa D-Bag y el Arnés Antienredos

### La Trampa de la Caída Libre en Gravedad Cero Relativa
Al inicio nos preguntamos si era realmente necesaria una bolsa de despliegue (D-Bag), esperando que el ala pudiera salir directamente del contenedor. Nos equivocamos.

Cuando una campana plegada es expulsada de un contenedor en caída libre, la carga y la tela aceleran hacia abajo al mismo ritmo. Sin tensión en las líneas, el suspentaje queda completamente flojo. El ala empieza a revolotear entre sus propias líneas sueltas, provocando enredos severos y fallas totales de inflado.

### Diseñado y Probado: El Plegado dentro del D-Bag
Debido a esta trampa dinámica de la caída libre, la forma exacta en que plegamos el paracaídas ram-air dentro de la bolsa D-Bag fue pensada, diseñada y probada exhaustivamente en decenas de extracciones de ensayo.

No nos limitamos a enrollar o embutir la tela. Desarrollamos un procedimiento de plegado estricto y repetible:
1. **Plegado en Acordeón de las Celdas**: Las celdas del ala se plegaban en zigzag sobre la mesa, asegurando que las tomas de aire a 45° quedaran alineadas hacia el frente y libres de pliegues internos.
2. **Estibado Escalonado del Suspentaje**: Las líneas de suspensión se recogían en bucles en "S" sujetados con bandas elásticas calibradas, garantizando que se liberaran progresivamente desde las bandas hacia la campana sin cruzarse.
3. **Extracción Secuencial (Líneas Primero)**: Al abrir el contenedor, el paracaídas piloto extrae primero las líneas de suspensión, tensándolas completamente por la inercia de la carga útil.
4. **Liberación del Ala por Tensión**: Solo cuando las líneas alcanzan su tensión total se abre la boca del D-Bag, liberando la campana directamente en el flujo de aire limpio.
5. **Inflado desde el Centro hacia Afuera**: Las tomas frontales a 45° capturan la presión dinámica e inflan el ala de forma simétrica desde las celdas centrales hacia los extremos en 1.0 a 1.5 segundos.

El análisis de nuestros videos en cámara lenta confirmó este principio: cada lanzamiento manual que infló correctamente fue aquel donde las líneas se tensaron por completo antes de liberar la tela, exactamente lo que nuestro protocolo de D-Bag forzaba a hacer mecánicamente.

### El Arnés Antienredos en las Bandas
Para evitar que las líneas se cruzaran durante la extracción violenta, fabricamos una **estructura de cinchas antienredo** con cinta de poliéster de 15 mm.

Esta estructura vinculaba las bandas de sustentación y de freno justo antes de las anillas de conexión al suspentaje (funcionando de manera similar a un slider de paracaidismo, pero fija en su posición). Esto mantuvo los haces de líneas separados durante el empaquetado y evitó vueltas indeseadas durante el despliegue sin añadir partes móviles.

---

## 6. Campaña de Ensayos en Campo

Decidimos no realizar ensayos en túnel de viento para el ala flexible. Ensayar un ala de tela no rígida e inflable dentro de un túnel pequeño es extremadamente complejo frente al flujo real en exteriores. Llevamos las pruebas directamente al campo.

1. **Lanzamientos desde Estructuras Altas (15 a 30 m)**: Tirar el conjunto desde edificios altos permitió comprobar que el D-Bag tensaba las líneas antes de liberar la campana y verificar la simetría de inflado de las celdas.
2. **Lanzamientos con Dron (100 a 250 m)**: Utilizando un dron multirrotor, elevamos el CanSat a gran altura y lo liberamos en caída libre para ensayos completos de descenso.

<div style="max-width: 520px; margin: 24px auto; text-align: center;">
  <video controls style="width: 100%; border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.12);" preload="metadata">
    <source src="drone-descent-test.mp4" type="video/mp4">
    Tu navegador no soporta el elemento de video.
  </video>
  <p style="font-size: 0.8rem; color: #64748b; margin-top: 8px;">
    <em>Ensayo de descenso con dron: validación de la separación de la carga, extensión de líneas bajo tensión, inflado del ala ram-air y planeo estabilizado.</em>
  </p>
</div>

Las pruebas de descenso validaron el rendimiento aerodinámico y de apertura:
- El D-Bag secuenció la apertura de forma limpia, permitiendo que la campana se inflara simétricamente en **1.0 a 1.5 segundos** tras la tensión de líneas.
- El ala flexible estableció un planeo estable con una tasa de descenso vertical de **≈ 5 m/s**, cumpliendo de forma consistente con el **requerimiento de 2 a 8 m/s**.

---

## 7. Reflexiones Finales

Cuando empezamos este proyecto, no existía un manual paso a paso para construir un paracaídas ram-air autónomo a microescala. Los papers académicos tradicionales aportaban ecuaciones de alto nivel, pero omitían los detalles prácticos que hacen que un ala de tela funcione en el mundo real: el ángulo exacto de corte en el borde de ataque, la geometría angular del suspentaje para evitar el colapso de las puntas y la cinemática de despliegue escalonado necesaria para abrir un ala blanda desde caída libre sin enredos.

Tuvimos que deducir y experimentar casi cada parámetro crítico por cuenta propia:
- Deducir el ángulo de entrada a 45° haciendo zoom y congelando videos de paracaidismo cuadro a cuadro.
- Descubrir la condición angular de 90° en las líneas gracias a un cartel de advertencia que duró 5 segundos en un software libre.
- Duplicar la superficie alar en el Mk 2 al darnos cuenta de que la carga alar inicial era demasiado alta para una senda de planeo segura.
- Salvar el proyecto tras un error importante en el cálculo del centro de gravedad, cuestionando nuestra propia distribución estructural y subiendo la batería para no tener que coser un ala nueva.
- Diseñar y validar un método de plegado en D-Bag y un arnés antienredos a fuerza de pruebas de caída iterativas.

A pesar de la información incompleta en la literatura, los errores de cálculo sobre la marcha y los plazos ajustados, logramos un paracaídas ram-air funcional y desplegable que se presurizaba simétricamente, mantenía su perfil aerodinámico y conseguía un planeo estable desde cero.

Tomar teoría fragmentada, contrastarla contra la física real y resolver cada obstáculo práctico con nuestras propias manos en el taller fue el verdadero aprendizaje de este desarrollo.

Próximamente publicaremos un artículo complementario enfocado en la dinámica de equipo, los aprendizajes de gestión y las conclusiones organizacionales de la competencia.
