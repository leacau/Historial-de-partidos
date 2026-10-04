import 'package:flutter/material.dart';

enum SistemaMarcador {
  goles,
  puntos,
  sets,
}

class SportConfig {
  const SportConfig({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.icono,
    required this.sistemaMarcador,
    required this.labelEquipo,
    required this.labelRival,
    required this.labelPuntos,
    required this.labelAnotacionHijo,
    required this.posicionesDisponibles,
    this.soportaPenales = false,
    this.soportaTarjetas = false,
    this.soportaSets = false,
  });

  final String id;
  final String nombre;
  final String emoji;
  final IconData icono;
  final SistemaMarcador sistemaMarcador;
  final String labelEquipo;
  final String labelRival;
  final String labelPuntos;
  final String labelAnotacionHijo;
  final List<String> posicionesDisponibles;
  final bool soportaPenales;
  final bool soportaTarjetas;
  final bool soportaSets;

  static const futbol = SportConfig(
    id: 'futbol',
    nombre: 'Fútbol',
    emoji: '⚽',
    icono: Icons.sports_soccer_rounded,
    sistemaMarcador: SistemaMarcador.goles,
    labelEquipo: 'Equipo',
    labelRival: 'Rival',
    labelPuntos: 'Goles',
    labelAnotacionHijo: 'Goles',
    posicionesDisponibles: [
      'Delantero',
      'Mediocampista',
      'Defensor',
      'Arquero',
    ],
    soportaPenales: true,
    soportaTarjetas: true,
  );

  static const rugby = SportConfig(
    id: 'rugby',
    nombre: 'Rugby',
    emoji: '🏉',
    icono: Icons.sports_rugby_rounded,
    sistemaMarcador: SistemaMarcador.puntos,
    labelEquipo: 'Equipo',
    labelRival: 'Rival',
    labelPuntos: 'Puntos',
    labelAnotacionHijo: 'Tries',
    posicionesDisponibles: [
      'Pilar',
      'Hooker',
      'Segunda Línea',
      'Tercera Línea',
      'Medio Scrum',
      'Apertura',
      'Centro',
      'Wing',
      'Fullback',
    ],
    soportaTarjetas: true,
  );

  static const hockey = SportConfig(
    id: 'hockey',
    nombre: 'Hockey',
    emoji: '🏑',
    icono: Icons.sports_hockey_rounded,
    sistemaMarcador: SistemaMarcador.goles,
    labelEquipo: 'Equipo',
    labelRival: 'Rival',
    labelPuntos: 'Goles',
    labelAnotacionHijo: 'Goles',
    posicionesDisponibles: [
      'Delantero',
      'Volante',
      'Defensor',
      'Arquero',
    ],
    soportaPenales: true,
    soportaTarjetas: true,
  );

  static const tenis = SportConfig(
    id: 'tenis',
    nombre: 'Tenis',
    emoji: '🎾',
    icono: Icons.sports_tennis_rounded,
    sistemaMarcador: SistemaMarcador.sets,
    labelEquipo: 'Jugador / Pareja',
    labelRival: 'Rival / Oponentes',
    labelPuntos: 'Sets',
    labelAnotacionHijo: 'Sets ganados',
    posicionesDisponibles: [
      'Singles',
      'Dobles',
    ],
    soportaSets: true,
  );

  static const padel = SportConfig(
    id: 'padel',
    nombre: 'Pádel',
    emoji: '🎾',
    icono: Icons.sports_tennis_rounded,
    sistemaMarcador: SistemaMarcador.sets,
    labelEquipo: 'Pareja',
    labelRival: 'Pareja rival',
    labelPuntos: 'Sets',
    labelAnotacionHijo: 'Sets ganados',
    posicionesDisponibles: [
      'Drive (Derecha)',
      'Revés (Izquierda)',
    ],
    soportaSets: true,
  );

  static const basquet = SportConfig(
    id: 'basquet',
    nombre: 'Básquet',
    emoji: '🏀',
    icono: Icons.sports_basketball_rounded,
    sistemaMarcador: SistemaMarcador.puntos,
    labelEquipo: 'Equipo',
    labelRival: 'Rival',
    labelPuntos: 'Puntos',
    labelAnotacionHijo: 'Puntos',
    posicionesDisponibles: [
      'Base',
      'Escolta',
      'Alero',
      'Ala-Pívot',
      'Pívot',
    ],
  );

  static const List<SportConfig> all = [
    futbol,
    rugby,
    hockey,
    tenis,
    padel,
    basquet,
  ];

  static SportConfig fromId(String? id) {
    if (id == null) return futbol;
    final normalized = id.trim().toLowerCase();
    return all.firstWhere(
      (s) => s.id == normalized,
      orElse: () => futbol,
    );
  }
}
