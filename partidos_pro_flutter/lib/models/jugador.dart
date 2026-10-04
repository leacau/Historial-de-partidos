import 'dart:convert';
import 'package:flutter/material.dart';
import 'deporte.dart';

/// Representa el perfil completo e individual de un jugador de cualquier deporte.
class Jugador {
  const Jugador({
    required this.id,
    required this.nombre,
    this.apodo = '',
    this.clubActual = 'Cosmos FC',
    this.categoria = '',
    this.dorsal = '10',
    this.posicionHabitual = 'Delantero',
    this.fotoUrl,
    this.colorHex = 0xFF087C63,
    this.deporte = 'futbol',
  });

  final String id;
  final String nombre;
  final String apodo;
  final String clubActual;
  final String categoria;
  final String dorsal;
  final String posicionHabitual;
  final String? fotoUrl;
  final int colorHex;
  final String deporte;

  Color get color => Color(colorHex);

  SportConfig get sportConfig => SportConfig.fromId(deporte);

  /// Iniciales del jugador para mostrar en el avatar si no tiene foto.
  String get iniciales {
    final clean = nombre.trim();
    if (clean.isEmpty) return 'J';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Nombre para mostrar (prioriza apodo entrecomillado si existe).
  String get nombreDisplay {
    if (apodo.trim().isNotEmpty) {
      return '$nombre "$apodo"';
    }
    return nombre;
  }

  /// Subtítulo deportivo (ej: "Cosmos FC • #10 • Cat. 2014").
  String get subtituloDisplay {
    final bits = <String>[];
    if (clubActual.trim().isNotEmpty) bits.add(clubActual.trim());
    if (dorsal.trim().isNotEmpty) bits.add('#${dorsal.trim()}');
    if (categoria.trim().isNotEmpty) bits.add(categoria.trim());
    if (bits.isEmpty) return posicionHabitual;
    return bits.join(' • ');
  }

  Jugador copyWith({
    String? id,
    String? nombre,
    String? apodo,
    String? clubActual,
    String? categoria,
    String? dorsal,
    String? posicionHabitual,
    String? fotoUrl,
    int? colorHex,
    String? deporte,
  }) {
    return Jugador(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apodo: apodo ?? this.apodo,
      clubActual: clubActual ?? this.clubActual,
      categoria: categoria ?? this.categoria,
      dorsal: dorsal ?? this.dorsal,
      posicionHabitual: posicionHabitual ?? this.posicionHabitual,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      colorHex: colorHex ?? this.colorHex,
      deporte: deporte ?? this.deporte,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apodo': apodo,
      'clubActual': clubActual,
      'categoria': categoria,
      'dorsal': dorsal,
      'posicionHabitual': posicionHabitual,
      'fotoUrl': fotoUrl,
      'colorHex': colorHex,
      'deporte': deporte,
    };
  }

  factory Jugador.fromMap(Map<String, dynamic> map) {
    return Jugador(
      id: (map['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: (map['nombre'] as String?) ?? 'Mi Hijo',
      apodo: (map['apodo'] as String?) ?? '',
      clubActual: (map['clubActual'] as String?) ?? 'Cosmos FC',
      categoria: (map['categoria'] as String?) ?? '',
      dorsal: (map['dorsal'] as String?) ?? '10',
      posicionHabitual: (map['posicionHabitual'] as String?) ?? 'Delantero',
      fotoUrl: map['fotoUrl'] as String?,
      colorHex: (map['colorHex'] as num?)?.toInt() ?? 0xFF087C63,
      deporte: (map['deporte'] as String?) ?? 'futbol',
    );
  }

  String toJson() => json.encode(toMap());

  factory Jugador.fromJson(String source) =>
      Jugador.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Paleta de colores preestablecidos para avatares de jugadores.
  static const List<int> coloresDisponibles = [
    0xFF087C63, // Esmeralda turf
    0xFF1D4ED8, // Azul real
    0xFFB91C1C, // Rojo carmesí
    0xFFD97706, // Ámbar deportivo
    0xFF7C3AED, // Violeta intenso
    0xFF059669, // Verde menta oscuro
    0xFF0284C7, // Azul cielo oscuro
    0xFFBE185D, // Rosa fucsia
    0xFF374151, // Gris pizarra oscuro
  ];
}
