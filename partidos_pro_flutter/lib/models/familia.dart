import 'package:cloud_firestore/cloud_firestore.dart' as fb_firestore;
import 'jugador.dart';

/// Representa un grupo familiar compartido en Firestore.
class GrupoFamiliar {
  const GrupoFamiliar({
    required this.id,
    required this.codigo,
    required this.ownerUid,
    required this.nombreFamilia,
    this.miembros = const [],
    this.jugadores = const [],
    this.creadoEn,
    this.actualizadoEn,
  });

  final String id;
  final String codigo;
  final String ownerUid;
  final String nombreFamilia;
  final List<String> miembros;
  final List<Jugador> jugadores;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  bool isOwner(String? currentUid) => currentUid != null && currentUid == ownerUid;

  int get totalMiembros => miembros.length;

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo.toUpperCase(),
      'ownerUid': ownerUid,
      'nombreFamilia': nombreFamilia,
      'miembros': miembros,
      'jugadores': jugadores.map((j) => j.toMap()).toList(),
      'actualizadoEn': fb_firestore.FieldValue.serverTimestamp(),
    };
  }

  factory GrupoFamiliar.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is fb_firestore.Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawMiembros = map['miembros'];
    final List<String> miembrosList = rawMiembros is List
        ? rawMiembros.map((e) => e.toString()).toList()
        : [map['ownerUid']?.toString() ?? ''];

    final rawJugadores = map['jugadores'];
    final List<Jugador> jugadoresList = rawJugadores is List
        ? rawJugadores
            .whereType<Map<String, dynamic>>()
            .map(Jugador.fromMap)
            .toList()
        : [];

    return GrupoFamiliar(
      id: id,
      codigo: (map['codigo'] as String? ?? '').toUpperCase(),
      ownerUid: map['ownerUid'] as String? ?? '',
      nombreFamilia: map['nombreFamilia'] as String? ?? 'Mi Familia',
      miembros: miembrosList,
      jugadores: jugadoresList,
      creadoEn: parseDate(map['creadoEn']),
      actualizadoEn: parseDate(map['actualizadoEn']),
    );
  }

  factory GrupoFamiliar.fromSnapshot(
    fb_firestore.DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    return GrupoFamiliar.fromMap(snap.id, snap.data() ?? {});
  }

  GrupoFamiliar copyWith({
    String? id,
    String? codigo,
    String? ownerUid,
    String? nombreFamilia,
    List<String>? miembros,
    List<Jugador>? jugadores,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return GrupoFamiliar(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      ownerUid: ownerUid ?? this.ownerUid,
      nombreFamilia: nombreFamilia ?? this.nombreFamilia,
      miembros: miembros ?? this.miembros,
      jugadores: jugadores ?? this.jugadores,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
