---
titulo: Respirador Monnal T60
categoria: Material y equipos
estado: borrador
version: 0.1
fecha: 2026-10-15
palabras: respirador ventilador Monnal T60 Air Liquide AVCV IPPV volumen control CPAP BIPAP PSV VNI ventilación no invasiva mecánica PEEP presión soporte AI trigger ciclado volumen tidal peso ideal alarmas presión pico meseta
---

## ! Qué modo elegir
>! En pantalla el modo activo aparece abajo a la derecha (p. ej., **AVCV ADULTO**). Comprobar siempre **modo, tipo de paciente (adulto/niño)** y que la **interfaz** (tubo o mascarilla) coincide con el modo.

| Modo | Nombre en el Monnal | Paciente | Cuándo |
|---|---|---|---|
| **IPPV** (volumen control) | **AVCV** | **Intubado** o con supraglótico | Parada recuperada, TCE grave, fracaso de VMNI, cualquier paciente sin respiración eficaz |
| **CPAP** | **CPAP** (versión VNI) | Mascarilla, **respira solo** | **EAP hipoxémico** sin hipercapnia ni fatiga |
| **BIPAP** | **PSV-VNI** (presión de soporte + PEEP) | Mascarilla, **respira solo** | **EPOC** e hipercapnia, **EAP con fatiga**, asma seleccionada |

>i **Pendiente de confirmar en el equipo (guardia del día 20):** el nombre exacto de los modos CPAP y BIPAP en la pantalla de selección y si el equipo tiene la opción Duo-Levels.

**Paciente sin respiración espontánea fiable** (apnea, Glasgow bajo, parada): **nunca CPAP ni PSV**, siempre **AVCV**.

## Pantalla y manejo
Lo que se ve en el equipo (software v2.8.5):

- **Barra inferior:** parámetros programados (en AVCV: FiO₂, VT, f, PEEP, I:E). Tocar uno para cambiarlo.
- **Abajo a la derecha:** modo activo (p. ej., AVCV ADULTO). Tocarlo para cambiar de modo.
- **Botón de pausa (II):** detiene la ventilación. Solo con el paciente desconectado o ventilando con bolsa.
- **Columna derecha (medidos):** FiO₂, VTe (volumen espirado), f, Ti/Ttot, Ppico, Pplat. Los números pequeños en azul son los **límites de alarma**.
- **Botones laterales:** **100 % O₂** (preoxigenación o aspiración, dura unos minutos), Tendencias, girar pantalla 180°, Menú, Inicio.
- **Arriba:** campana de alarmas y candado de bloqueo de pantalla.

**Cambiar un parámetro:** tocar el parámetro → girar la ruleta (a la derecha de la pantalla) → **confirmar** pulsando la ruleta o tocando de nuevo. Un parámetro sin confirmar no se aplica.

>i Pendiente de verificar en el equipo: el gesto exacto de confirmación y el recorrido para cambiar de modo.

## IPPV (AVCV): paciente intubado
**Parámetros iniciales (adulto):**

| Parámetro | Inicio | Comentario |
|---|---|---|
| **FiO₂** | 100 % | Bajar después a SpO₂ 94–98 % (88–92 % en EPOC) |
| **VT** | **6–8 mL/kg de peso ideal** | Por la **talla**, no por el peso real (tabla) |
| **f** | 12–16/min | Ajustar por EtCO₂. **8–10 en asma o EPOC** |
| **PEEP** | 5 cmH₂O | Subir si hay hipoxemia (EAP, SDRA). Baja en TEP o hipotensión |
| **I:E** | 1:2 | **1:3 a 1:5 en asma o EPOC** (más tiempo para espirar) |

**Volumen corriente por talla (peso ideal):**

| Talla | Hombre 6–8 mL/kg | Mujer 6–8 mL/kg |
|---|---|---|
| 150 cm | 290–380 mL | 260–350 mL |
| 155 cm | 310–420 mL | 290–380 mL |
| 160 cm | 340–460 mL | 310–420 mL |
| 165 cm | 370–490 mL | 340–460 mL |
| 170 cm | 400–530 mL | 370–490 mL |
| 175 cm | 420–560 mL | 400–530 mL |
| 180 cm | 450–600 mL | 420–560 mL |
| 185 cm | 480–640 mL | 450–600 mL |
| 190 cm | 510–670 mL | 480–640 mL |

**Comprobar a los pocos minutos:**
- **EtCO₂ 35–45 mmHg** (35–40 en TCE). Subir o bajar la frecuencia para ajustarlo.
- **Pplat <30 cmH₂O.** Si es mayor, bajar el VT.
- **Presión de distensión (Pplat − PEEP) <15 cmH₂O.**
- **Ppico:** límite de alarma unos 10 cmH₂O por encima de la Ppico habitual (máx. 40–45).
- VTe parecido al VT programado (si es mucho menor: fuga o desconexión).

## CPAP: paciente con mascarilla
**Indicación:** EAP hipoxémico, paciente consciente, colaborador y con respiración espontánea eficaz (ver ficha de EAP).

| Parámetro | Inicio | Ajuste |
|---|---|---|
| **PEEP (CPAP)** | **5 cmH₂O** | Subir 1–2 cada 2–5 min hasta 10 si persiste la hipoxemia |
| **FiO₂** | 100 % si hipoxemia grave | Bajar a SpO₂ 94–98 % |

- Mascarilla oronasal bien ajustada, explicar la técnica, dejar que el paciente se la sujete al principio.
- Vigilar la **PA** tras cada subida de presión.
- Si aparecen **hipercapnia, fatiga o somnolencia**: pasar a BIPAP.

## BIPAP (PSV-VNI): paciente con mascarilla
**Indicación:** EPOC agudizada con hipercapnia, EAP con fatiga o hipercapnia (ver fichas de EPOC y EAP).

>! En el Monnal la **presión de soporte (AI/PS) se suma a la PEEP.** La presión inspiratoria total (IPAP) = PEEP + PS. Ejemplo: **PEEP 5 + PS 5 = IPAP 10.**

**Equivalencias con las fichas clínicas (IPAP/EPAP):**

| Ficha dice (IPAP/EPAP) | Programar PEEP | Programar PS |
|---|---|---|
| 10 / 5 | 5 | 5 |
| 12 / 5 | 5 | 7 |
| 14 / 6 | 6 | 8 |
| 16 / 6 | 6 | 10 |
| 20 / 8 | 8 | 12 |

**Parámetros iniciales:**

| Parámetro | EAP | EPOC | Comentario |
|---|---|---|---|
| **PEEP** | 5–6 | 4–5 | Oxigenación |
| **PS (sobre PEEP)** | 5–8 | 6–10 | Trabajo respiratorio y CO₂ |
| **FiO₂** | Alta y bajar a 94–98 % | Mínima para 88–92 % | |
| **Trigger inspiratorio** | Sensible (2–3 L/min) | Sensible | Subir si hay autodisparos por fugas |
| **Ciclado espiratorio** | 25 % | **40–50 %** | En EPOC, ciclar antes para dar tiempo a espirar |
| **Ti máx.** | 1,2–1,5 s | 1,0 s | Evita inspiraciones largas con fugas |
| **f de respaldo / apnea** | Activar | Activar | Ventilación de seguridad si deja de respirar |

**Ajustes según el problema:**

| Problema | Ajuste |
|---|---|
| **Hipoxemia** | Subir PEEP (de 1 en 1 o de 2 en 2) y/o FiO₂ |
| **Mucho trabajo respiratorio, VT bajo, CO₂ alto** | Subir PS de 2 en 2 (IPAP total ≤20–25) |
| **SpO₂ ya en objetivo** | Bajar FiO₂ |
| **Asincronía, autodisparos** | Revisar fugas, ajustar trigger y ciclado |
| **Baja la PA** | No subir más la PEEP. Reevaluar |

## Alarmas y problemas frecuentes
**En el paciente intubado que empeora: DOPE**
- **D**esplazamiento del tubo (EtCO₂, auscultación).
- **O**bstrucción (secreciones, acodamiento, mordida): aspirar.
- **P**neumotórax: ver ficha.
- **E**quipo: desconectar y ventilar con bolsa al 100 %.

| Alarma | Causas habituales | Qué hacer |
|---|---|---|
| **Presión alta (Ppico)** | Secreciones, mordida, tos, broncoespasmo, tubo acodado o selectivo, neumotórax | Aspirar, cánula de Guedel, sedación, revisar tubo, auscultar |
| **VTe bajo / fuga** | Mascarilla mal ajustada, neumotaponamiento, desconexión | Ajustar interfaz, revisar circuito y balón |
| **Apnea** | Paciente sin esfuerzo en CPAP o PSV | Estimular, pasar a AVCV o ventilar con bolsa |
| **FiO₂ baja** | Oxígeno agotándose o desconectado | Revisar botella y conexión |
| **Batería** | Equipo sin corriente | Conectar a la red de la ambulancia |

>! Ante cualquier duda con el respirador y un paciente que se deteriora: **desconectar y ventilar con bolsa-válvula al 100 %**.

## Fracaso de la VMNI
Pasar a intubación o soporte avanzado si:
- Persiste o empeora la hipoxemia.
- Aumenta el trabajo respiratorio o aparece agotamiento.
- Baja el nivel de conciencia.
- Inestabilidad hemodinámica.
- Intolerancia o agitación no controlable.
- No puede proteger la vía aérea, vómitos.
- Apnea o parada respiratoria.

## Antes de cada servicio
- Test de arranque del equipo superado.
- Batería cargada y cable de red.
- Botella de oxígeno con presión suficiente y de reserva.
- Circuito, filtro, sensor de flujo y mascarillas de varias tallas.
- Comprobar que el equipo arranca en el tipo de paciente correcto.

## Fuentes y control
- Air Liquide Medical Systems. Catálogo y manual de usuario Monnal T60.
- ERS/ATS. Guía de ventilación no invasiva, 2017.
- ARDSNet. Ventilación protectora con volumen corriente bajo (peso ideal).
- Fichas de EAP, EPOC, asma, TCE y TEP de esta app.

>i Borrador. Parámetros clínicos basados en las guías citadas. **La navegación por la pantalla y los nombres exactos de CPAP y BIPAP están pendientes de verificar en el equipo** (foto disponible solo del modo AVCV). Pendiente de validación por el responsable médico.
