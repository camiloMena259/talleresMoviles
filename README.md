 # Talleres Moviles — Ejercicios de asincronia y concurrencia

Este repo tiene una app sencilla en Flutter que muestra ejemplos de cosas asincronas: `Future`/`async`/`await`, `Timer` (cronometro) e `Isolate` (tarea pesada).

## Objetivo
Dar ejemplos practicos para:
- Ejecutar tareas asincronas sin dejar la UI pegada.
- Usar `Timer` para cronometros y actualizar cada cierto tiempo.
- Mandar tareas pesadas a un `Isolate` para que la UI siga respondiendo.

---

## Donde esta el codigo importante
- `lib/services/simulated_service.dart` — servicio simulado con `Future.delayed`.
- `lib/views/exercise/exercise_screen.dart` — pantalla que junta los 3 ejercicios (Future, Timer, Isolate).
- `lib/views/isolate/isolate_view.dart` — demo mas simple de Isolate que ya existia.
- `lib/routes/app_router.dart` — rutas, incluye `/exercise`.
- `lib/widgets/custom_drawer.dart` — drawer con acceso a la pantalla de ejercicios.

---

## 1) Future / async / await

Que es
- `Future` representa un valor que va a llegar despues.
- `async`/`await` sirven para escribir codigo asincrono de forma ordenada.

Cuando usarlo
- Para llamadas a APIs (HTTP).
- Para leer o escribir archivos o base de datos local.
- Para cualquier operacion I/O que tarda pero no usa mucho CPU.

Como lo hice aqui
- `SimulatedService.fetchData()` usa `await Future.delayed(...)` para simular latencia (2 segundos por defecto).
- En la vista `ExerciseScreen._runFuture()` se hace `await` y se manejan estados para que la UI no se congele.

Estados que se muestran
- Cargando... (_loading)
- Exito (_futureResult)
- Error (_futureError)

Logs y orden de ejecucion
- El servicio y la UI usan `debugPrint` en puntos claves: antes de llamar, despues del delay, al retornar y en el finally. Asi se puede ver en la consola el orden: `antes -> service antes -> service despues -> UI resultado -> finally`.


## 2) Timer (cronometro)

Que es
- `Timer` ejecuta una funcion despues de un retraso o repetidamente.

Cuando usarlo
- Para cronometros, contadores o tareas repetitivas simples en la UI.
- No es para tareas pesadas de CPU (ahi va Isolate).

Como lo hice aqui
- En `ExerciseScreen` hay botones: Iniciar / Pausar / Reanudar / Reiniciar.
- Se usa `Timer.periodic` para actualizar cada 1s.
- Al salir de la vista se cancela el timer en `dispose()`.

## 3) Isolate (tarea pesada)

Que es
- `Isolate` permite correr codigo en otro hilo en Dart. No comparte memoria; se comunican con `SendPort`/`ReceivePort`.

Cuando usarlo
- Para operaciones que consumen CPU y tardan mucho: procesar imagenes, cifrado, compresion, calculos grandes.

Como lo hice aqui
- `ExerciseScreen._runHeavyTaskInIsolate()`:
	1. Crea `ReceivePort` en la UI.
	2. `Isolate.spawn(...)` arranca el isolate y este manda su `SendPort` al UI.
	3. La UI manda `[n, replyPort]` pidiendo la suma 1..n.
	4. El isolate hace la suma y responde con el resultado.
	# Resumen rapido

	Este README contiene solo lo pedido: 1) cuando usar Future / async/await, Timer e Isolate; 2) diagrama/lista de pantallas y flujos (cronometro y proceso pesado).

	---

	## 1) Cuando usar cada cosa

	- Future / async / await
		- Usalo para operaciones I/O-bound: llamadas a APIs (HTTP), leer/escribir archivos o DB local, acceso a sensores, etc.
		- `async/await` hace que el codigo se lea de forma secuencial pero sin bloquear la UI mientras espera el `Future`.
		- Ejemplo en el repo: `SimulatedService.fetchData()` simula latencia con `Future.delayed`.

	- Timer
		- Usalo para cronometros, contadores o tareas repetitivas en la UI (actualizar cada segundo, refrescar un reloj, animaciones basicas).
		- No lo uses para trabajo CPU-bound largo (ahi hay que usar Isolate).
		- Acordate de cancelar el timer en `dispose()` para no dejar fugas.

	- Isolate
		- Usalo para tareas CPU-bound que tardan (procesar imagenes, cifrar, comprimir, calculos grandes). El Isolate corre en otro hilo y evita que la UI se congele.
		- Se comunican con mensajes (`SendPort`/`ReceivePort`), no comparten memoria.
		- Ejemplo en el repo: `ExerciseScreen` lanza un Isolate para sumar 1..N y devuelve el resultado.

	---

	## 2) Diagrama / lista de pantallas y flujos (cronometro y proceso pesado)

	Pantallas relevantes (archivos):
	- Home — `lib/views/home/home_screen.dart`
	- Ejercicio (Future / Timer / Isolate) — `lib/views/exercise/exercise_screen.dart`
	- Isolate (demo simple) — `lib/views/isolate/isolate_view.dart`

	Flujo: cronometro (Timer)
	1. Usuario pulsa "Iniciar" en la pantalla de ejercicio.
	2. Se crea `Timer.periodic` y cada tick (1s) se actualiza el estado con el tiempo transcurrido.
	3. Usuario puede "Pausar" (se cancela el timer), "Reanudar" (se crea otro timer) o "Reiniciar" (se pone tiempo en 0).
	4. Al salir de la pantalla se cancela el timer en `dispose()`.

	Flujo: proceso pesado (Isolate)
	1. Usuario pulsa "Ejecutar tarea en Isolate".
	2. UI crea `ReceivePort` y hace `Isolate.spawn(...)`.
	3. El isolate envia su `SendPort` al UI.
	4. La UI manda un mensaje con los parametros (por ejemplo `[n, replyPort]`) al isolate.
	5. El isolate ejecuta la tarea pesada (ej. suma 1..n) y envia el resultado a `replyPort`.
	6. La UI recibe el resultado y lo muestra; la UI no se congela porque la tarea se realizo en otro hilo.


