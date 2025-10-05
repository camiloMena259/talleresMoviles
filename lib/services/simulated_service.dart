import 'dart:async';

import 'package:flutter/foundation.dart';

/// Servicio simulado que retorna datos después de un retraso.
class SimulatedService {
  /// Simula una llamada asíncrona que tarda [delaySeconds] segundos.
  /// Si [shouldFail] es true lanza una excepción.
  Future<String> fetchData({bool shouldFail = false, int delaySeconds = 2}) async {
    debugPrint('SimulatedService: antes de await (fetchData)');
    // simulamos retraso en la red / backend
    await Future.delayed(Duration(seconds: delaySeconds));
    debugPrint('SimulatedService: luego del delay (fetchData)');

    if (shouldFail) {
      debugPrint('SimulatedService: lanzando excepción simulada');
      throw Exception('Error simulado desde SimulatedService');
    }

    final result = 'Datos simulados cargados correctamente';
    debugPrint('SimulatedService: retornando resultado: $result');
    return result;
  }
}
