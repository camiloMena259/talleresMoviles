import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/simulated_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  // Servicio simulado
  final SimulatedService _service = SimulatedService();

  // --- Future / async state
  String? _futureResult;
  String? _futureError;
  bool _loading = false;

  // --- Timer state
  Timer? _timer;
  int _milliseconds = 0; // usado como cronómetro en ms
  bool _running = false;

  // --- Isolate state
  String _isolateResult = 'Presiona Ejecutar Isolate';

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  // ========== FUTURE (Simulado) ===========
  Future<void> _runFuture({bool shouldFail = false}) async {
    debugPrint('UI: antes de llamar a fetchData()');
    setState(() {
      _loading = true;
      _futureResult = null;
      _futureError = null;
    });
    try {
      final res = await _service.fetchData(shouldFail: shouldFail, delaySeconds: 2);
      debugPrint('UI: obtuve resultado del servicio: $res');
      if (!mounted) return;
      setState(() {
        _futureResult = res;
      });
    } catch (e, st) {
      debugPrint('UI: captura error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _futureError = e.toString();
      });
    } finally {
      debugPrint('UI: finalmente, después del await');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  // ========== TIMER (Cronómetro) ===========
  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      setState(() {
        _milliseconds += 1000;
      });
    });
    setState(() {
      _running = true;
    });
  }

  void _pauseTimer() {
    _cancelTimer();
    setState(() {
      _running = false;
    });
  }

  void _resumeTimer() {
    if (_running) return;
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      setState(() {
        _milliseconds += 1000;
      });
    });
    setState(() {
      _running = true;
    });
  }

  void _resetTimer() {
    _cancelTimer();
    setState(() {
      _milliseconds = 0;
      _running = false;
    });
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$sec';
  }

  // ========== ISOLATE (Tarea pesada) ===========
  Future<void> _runHeavyTaskInIsolate() async {
    debugPrint('UI: antes de iniciar Isolate');
    final receivePort = ReceivePort();
    await Isolate.spawn(_heavyComputationEntry, receivePort.sendPort);
    // primer mensaje será el SendPort del isolate
    final sendPort = await receivePort.first as SendPort;

    final responsePort = ReceivePort();
    sendPort.send([10000000, responsePort.sendPort]); // pedir suma hasta N
    final result = await responsePort.first;
    debugPrint('UI: resultado recibido del isolate: $result');
    if (!mounted) return;
    setState(() {
      _isolateResult = 'Resultado: $result';
    });
    receivePort.close();
    responsePort.close();
  }

  // entry point para Isolate
  static void _heavyComputationEntry(SendPort initialReplyTo) {
    final port = ReceivePort();
    initialReplyTo.send(port.sendPort);
    port.listen((message) {
      final n = message[0] as int;
      final SendPort replyTo = message[1] as SendPort;
      // tarea pesada: sumar 1..n
      int64Sum(n).then((value) {
        replyTo.send(value);
      });
    });
  }

  // función que usa compute para hacer la suma en un futuro separado (opcional), devuelve Future<int>
  static Future<int> int64Sum(int n) async {
    // algoritmo simple O(n) — intencionalmente costoso para demostrar Isolate
    int sum = 0;
    for (int i = 1; i <= n; i++) {
      sum += i;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ejercicio: Future / Timer / Isolate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Future section
            const Text('1) Future (simulado)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _runFuture(shouldFail: false),
              child: const Text('Cargar datos (éxito)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _runFuture(shouldFail: true),
              child: const Text('Cargar datos (falla)'),
            ),
            const SizedBox(height: 8),
            if (_loading) const Text('Cargando...', style: TextStyle(color: Colors.orange)),
            if (_futureResult != null) Text('Éxito: $_futureResult', style: const TextStyle(color: Colors.green)),
            if (_futureError != null) Text('Error: $_futureError', style: const TextStyle(color: Colors.red)),
            const Divider(height: 32),

            // --- Timer section
            const Text('2) Timer (cronómetro)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: Text(_formatTime(_milliseconds), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(onPressed: _startTimer, child: const Text('Iniciar')),
                ElevatedButton(onPressed: _pauseTimer, child: const Text('Pausar')),
                ElevatedButton(onPressed: _resumeTimer, child: const Text('Reanudar')),
                ElevatedButton(onPressed: _resetTimer, child: const Text('Reiniciar')),
              ],
            ),
            const Divider(height: 32),

            // --- Isolate section
            const Text('3) Isolate (tarea pesada)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _runHeavyTaskInIsolate, child: const Text('Ejecutar tarea en Isolate')),
            const SizedBox(height: 8),
            Text(_isolateResult),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
