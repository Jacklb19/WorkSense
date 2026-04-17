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
}
