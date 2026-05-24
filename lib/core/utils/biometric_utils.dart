import 'dart:convert';

/// Helper para serializar/deserializar de manera estricta los vectores ML de 192 dimensiones
class BiometricSerializer {
  static String serializeEmbedding(List<double> embedding) {
    return jsonEncode(embedding);
  }

  static List<double>? deserializeEmbedding(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return null;
    }
  }
  static String serializeMultipleEmbeddings(List<List<double>> embeddings) {
    return jsonEncode(embeddings);
  }

  static List<List<double>>? deserializeMultipleEmbeddings(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        // Manejo defensivo: si el JSON viejo es un arreglo simple (un solo embedding),
        // lo envuelve en una lista para mantener el nuevo contrato List<List<double>>.
        if (decoded.isNotEmpty && decoded.first is num) {
          final single = decoded.map((e) => (e as num).toDouble()).toList();
          return [single];
        }
        
        // Formato esperado: List<List<double>>
        return decoded.map((e) {
          final list = e as List;
          return list.map((v) => (v as num).toDouble()).toList();
        }).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
