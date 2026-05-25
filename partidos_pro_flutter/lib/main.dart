import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as fb_firestore;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image/image.dart' as image_lib;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  Intl.defaultLocale = 'es_AR';
  runApp(const PartidosProApp());
}

const _accent = Color(0xFF087C63);
const _ink = Color(0xFF17211F);
const _fieldFill = Color(0xFFF7FAF9);

class PartidosProApp extends StatelessWidget {
  const PartidosProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Partidos Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF0ED),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _fieldFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD8E2DF)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Partido {
  Partido({
    this.documentName,
    this.id,
    required this.nombreJugador,
    required this.temporada,
    required this.tipoPartido,
    required this.torneo,
    required this.fase,
    required this.copa,
    required this.equipo,
    required this.rival,
    required this.cancha,
    this.canchaLat,
    this.canchaLng,
    required this.fechaTexto,
    required this.fechaPartido,
    required this.posicion,
    required this.analisis,
    required this.scoreHijo,
    required this.scoreRival,
    required this.golesHijo,
    required this.asistencias,
    required this.minutosJugados,
    required this.tarjetasAmarillas,
    required this.tarjetasRojas,
    required this.figuraPartido,
    required this.penales,
    required this.scorePenalesEquipo,
    required this.scorePenalesRival,
    required this.penalHijo,
    this.foto,
    this.fotoPath,
    this.creadoEn,
  });

  final String? documentName;
  final String? id;
  final String nombreJugador;
  final String temporada;
  final String tipoPartido;
  final String torneo;
  final String fase;
  final String copa;
  final String equipo;
  final String rival;
  final String cancha;
  final double? canchaLat;
  final double? canchaLng;
  final String fechaTexto;
  final DateTime fechaPartido;
  final String posicion;
  final String analisis;
  final int scoreHijo;
  final int scoreRival;
  final int golesHijo;
  final int asistencias;
  final int minutosJugados;
  final int tarjetasAmarillas;
  final int tarjetasRojas;
  final bool figuraPartido;
  final bool penales;
  final int scorePenalesEquipo;
  final int scorePenalesRival;
  final String penalHijo;
  final String? foto;
  final String? fotoPath;
  final DateTime? creadoEn;

  bool get gano =>
      scoreHijo > scoreRival ||
      (penales && scorePenalesEquipo > scorePenalesRival);

  bool get empato => scoreHijo == scoreRival && !penales;

  String get marcador {
    if (!penales) return '$scoreHijo - $scoreRival';
    return '$scoreHijo ($scorePenalesEquipo) - ($scorePenalesRival) $scoreRival';
  }

  Partido copyWith({
    String? documentName,
    String? id,
    String? nombreJugador,
    String? temporada,
    String? tipoPartido,
    String? torneo,
    String? fase,
    String? copa,
    String? equipo,
    String? rival,
    String? cancha,
    double? canchaLat,
    double? canchaLng,
    String? fechaTexto,
    DateTime? fechaPartido,
    String? posicion,
    String? analisis,
    int? scoreHijo,
    int? scoreRival,
    int? golesHijo,
    int? asistencias,
    int? minutosJugados,
    int? tarjetasAmarillas,
    int? tarjetasRojas,
    bool? figuraPartido,
    bool? penales,
    int? scorePenalesEquipo,
    int? scorePenalesRival,
    String? penalHijo,
    String? foto,
    String? fotoPath,
    DateTime? creadoEn,
  }) {
    return Partido(
      documentName: documentName ?? this.documentName,
      id: id ?? this.id,
      nombreJugador: nombreJugador ?? this.nombreJugador,
      temporada: temporada ?? this.temporada,
      tipoPartido: tipoPartido ?? this.tipoPartido,
      torneo: torneo ?? this.torneo,
      fase: fase ?? this.fase,
      copa: copa ?? this.copa,
      equipo: equipo ?? this.equipo,
      rival: rival ?? this.rival,
      cancha: cancha ?? this.cancha,
      canchaLat: canchaLat ?? this.canchaLat,
      canchaLng: canchaLng ?? this.canchaLng,
      fechaTexto: fechaTexto ?? this.fechaTexto,
      fechaPartido: fechaPartido ?? this.fechaPartido,
      posicion: posicion ?? this.posicion,
      analisis: analisis ?? this.analisis,
      scoreHijo: scoreHijo ?? this.scoreHijo,
      scoreRival: scoreRival ?? this.scoreRival,
      golesHijo: golesHijo ?? this.golesHijo,
      asistencias: asistencias ?? this.asistencias,
      minutosJugados: minutosJugados ?? this.minutosJugados,
      tarjetasAmarillas: tarjetasAmarillas ?? this.tarjetasAmarillas,
      tarjetasRojas: tarjetasRojas ?? this.tarjetasRojas,
      figuraPartido: figuraPartido ?? this.figuraPartido,
      penales: penales ?? this.penales,
      scorePenalesEquipo: scorePenalesEquipo ?? this.scorePenalesEquipo,
      scorePenalesRival: scorePenalesRival ?? this.scorePenalesRival,
      penalHijo: penalHijo ?? this.penalHijo,
      foto: foto ?? this.foto,
      fotoPath: fotoPath ?? this.fotoPath,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  static Partido fromSnapshot(
    fb_firestore.DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final fechaTexto = _str(data['fecha']);
    final fechaPartido =
        _date(data['fecha_partido']) ??
        _parseDateText(fechaTexto) ??
        _date(data['timestamp']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return Partido(
      documentName: doc.reference.path,
      id: doc.id,
      nombreJugador: _str(data['nombre_jugador'], 'Mi Hijo'),
      temporada: _str(data['temporada'], '${fechaPartido.toLocal().year}'),
      tipoPartido: _str(data['tipo_partido'], 'Liga'),
      torneo: _str(data['torneo'], 'Sin torneo'),
      fase: _str(data['fase'], 'Fase de Grupos'),
      copa: _str(data['copa'], 'Ninguna'),
      equipo: _firstStr(data, [
        'equipo',
        'equipo_hijo',
        'equipo_jugador',
        'mi_equipo',
      ], 'Cosmos FC'),
      rival: _str(data['rival'], 'Rival'),
      cancha: _str(data['cancha']),
      canchaLat: _double(data['cancha_lat']) ?? _double(data['lat']),
      canchaLng: _double(data['cancha_lng']) ?? _double(data['lng']),
      fechaTexto: fechaTexto,
      fechaPartido: fechaPartido,
      posicion: _str(data['posicion'], 'Delantero'),
      analisis: _str(data['analisis']),
      scoreHijo: _int(data['score_hijo']),
      scoreRival: _int(data['score_rival']),
      golesHijo: _int(data['goles_hijo'], _int(data['goles'])),
      asistencias: _int(data['asistencias']),
      minutosJugados: _int(data['minutos_jugados']),
      tarjetasAmarillas: _int(data['tarjetas_amarillas']),
      tarjetasRojas: _int(data['tarjetas_rojas']),
      figuraPartido: _bool(data['figura_partido']),
      penales: _bool(data['penales']),
      scorePenalesEquipo: _int(data['score_penales_equipo']),
      scorePenalesRival: _int(data['score_penales_rival']),
      penalHijo: _str(data['penal_hijo'], 'No pateo'),
      foto: _str(data['foto']).isEmpty ? null : _str(data['foto']),
      fotoPath: _str(data['foto_path']).isEmpty
          ? null
          : _str(data['foto_path']),
      creadoEn: _date(data['creado_en']),
    );
  }

  Map<String, dynamic> toMap({
    required String ownerUid,
    bool includeCreated = false,
  }) {
    final now = DateTime.now().toUtc();
    final fields = <String, dynamic>{
      'ownerUid': ownerUid,
      'nombre_jugador': nombreJugador,
      'temporada': temporada,
      'tipo_partido': tipoPartido,
      'torneo': torneo,
      'fase': tipoPartido == 'Torneo' ? fase : '',
      'copa': tipoPartido == 'Torneo' ? copa : 'Ninguna',
      'equipo': equipo,
      'equipo_hijo': equipo,
      'equipo_jugador': equipo,
      'rival': rival,
      'cancha': cancha,
      'cancha_lat': canchaLat,
      'cancha_lng': canchaLng,
      'fecha': fechaTexto,
      'fecha_partido': fb_firestore.Timestamp.fromDate(fechaPartido),
      'timestamp': fb_firestore.Timestamp.fromDate(fechaPartido),
      'actualizado_en': fb_firestore.Timestamp.fromDate(now),
      'posicion': posicion,
      'analisis': analisis,
      'score_hijo': scoreHijo,
      'score_rival': scoreRival,
      'goles_hijo': golesHijo,
      'asistencias': asistencias,
      'minutos_jugados': minutosJugados,
      'tarjetas_amarillas': tarjetasAmarillas,
      'tarjetas_rojas': tarjetasRojas,
      'figura_partido': figuraPartido,
      'penales': penales,
      'score_penales_equipo': penales ? scorePenalesEquipo : 0,
      'score_penales_rival': penales ? scorePenalesRival : 0,
      'penal_hijo': penales ? penalHijo : 'No pateo',
      'foto': foto ?? '',
      'foto_path': fotoPath ?? '',
    };
    if (includeCreated) {
      fields['creado_en'] = fb_firestore.Timestamp.fromDate(now);
    }
    return fields;
  }
}

class FootballRepository {
  FootballRepository();

  final _db = fb_firestore.FirebaseFirestore.instance;
  final _storage = fb_storage.FirebaseStorage.instance;
  final _auth = fb_auth.FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;

  String? _uid;
  bool _authUnavailable = false;
  bool _googleInitialized = false;

  fb_auth.User? get currentUser => _auth.currentUser;
  bool get authUnavailable => _authUnavailable;

  Future<String> _ensureUser() async {
    if (_authUnavailable) return 'legacy-unsecured';
    var user = _auth.currentUser;
    try {
      user ??= (await _auth.signInAnonymously()).user;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed') {
        _authUnavailable = true;
        _uid = 'legacy-unsecured';
        return _uid!;
      }
      rethrow;
    }
    final uid = user?.uid;
    if (uid == null) {
      throw StateError('No se pudo iniciar sesi\u00f3n en Firebase.');
    }
    _uid = uid;
    return uid;
  }

  Future<void> connect() async {
    await _ensureUser();
    if (!_authUnavailable) {
      await _claimLegacyDocsIfNeeded();
    }
  }

  Future<void> linkOrSignInWithEmail(String email, String password) async {
    final credential = fb_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked') {
        await _auth.signInWithCredential(credential);
      } else if (e.code == 'user-not-found') {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    _authUnavailable = false;
    _uid = _auth.currentUser?.uid;
    await _claimLegacyDocsIfNeeded();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  Future<void> linkOrSignInWithGoogle() async {
    await _ensureGoogleInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError('Google no est\u00e1 disponible en este dispositivo.');
    }

    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Firebase no recibi\u00f3 el token de Google. Revis\u00e1 la configuraci\u00f3n SHA y google-services.json.',
      );
    }

    final credential = fb_auth.GoogleAuthProvider.credential(idToken: idToken);
    try {
      final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked' ||
          e.code == 'account-exists-with-different-credential') {
        await _auth.signInWithCredential(credential);
      } else {
        rethrow;
      }
    }

    _authUnavailable = false;
    _uid = _auth.currentUser?.uid;
    await _claimLegacyDocsIfNeeded();
  }

  Future<void> _claimLegacyDocsIfNeeded() async {
    final uid = _uid ?? await _ensureUser();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('legacy_claimed_uid') == uid) return;

    final snapshot = await _db.collection('historial').get();
    final batch = _db.batch();
    var pending = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['ownerUid'] == null || data['ownerUid'] == '') {
        batch.update(doc.reference, {
          'ownerUid': uid,
          'migrado_a_sdk_en': fb_firestore.FieldValue.serverTimestamp(),
        });
        pending++;
      }
    }
    if (pending > 0) await batch.commit();
    await prefs.setString('legacy_claimed_uid', uid);
  }

  Future<List<Partido>> listPartidos() async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final snapshot = _authUnavailable
        ? await _db.collection('historial').get()
        : await _db
              .collection('historial')
              .where('ownerUid', isEqualTo: uid)
              .get();
    final all = snapshot.docs.map(Partido.fromSnapshot).toList();

    all.sort((a, b) => b.fechaPartido.compareTo(a.fechaPartido));
    return all;
  }

  Future<void> savePartido(Partido partido) async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final isEditing = partido.documentName != null;
    final data = partido.toMap(ownerUid: uid, includeCreated: !isEditing);
    if (_authUnavailable) {
      data.remove('ownerUid');
    }
    if (isEditing) {
      await _db.doc(partido.documentName!).update(data);
    } else {
      await _db.collection('historial').add(data);
    }
  }

  Future<void> deletePartido(Partido partido) async {
    await connect();
    if (partido.fotoPath != null && partido.fotoPath!.isNotEmpty) {
      await deletePhoto(partido.fotoPath!);
    }
    if (partido.documentName != null) {
      await _db.doc(partido.documentName!).delete();
    }
  }

  Future<String> uploadPhoto(Uint8List bytes) async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final processed = _compressImage(bytes);
    final objectName = _authUnavailable
        ? 'fotos/img_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : 'users/$uid/fotos/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(objectName);
    await ref.putData(
      processed,
      fb_storage.SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> deletePhoto(String objectName) async {
    await connect();
    try {
      await _storage.ref(objectName).delete();
    } catch (_) {
      // La foto puede haber sido borrada desde otro lugar.
    }
  }
}

class Stats {
  Stats();

  int pj = 0;
  int pg = 0;
  int pe = 0;
  int pp = 0;
  int gf = 0;
  int gc = 0;
  int gp = 0;
  int asistencias = 0;
  int figuras = 0;
  int minutos = 0;
  int amarillas = 0;
  int rojas = 0;

  int get dg => gf - gc;

  void add(Partido p) {
    pj++;
    gf += p.scoreHijo;
    gc += p.scoreRival;
    gp += p.golesHijo;
    asistencias += p.asistencias;
    figuras += p.figuraPartido ? 1 : 0;
    minutos += p.minutosJugados;
    amarillas += p.tarjetasAmarillas;
    rojas += p.tarjetasRojas;
    if (p.gano) {
      pg++;
    } else if (p.empato) {
      pe++;
    } else {
      pp++;
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = FootballRepository();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _shortDateFormat = DateFormat('dd MMM yyyy');

  int _tab = 0;
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  String _playerName = 'Mi Hijo';
  List<String> _players = ['Mi Hijo'];
  bool _autoBackup = false;
  String _search = '';
  String _filterTipo = 'Todos';
  String _filterTorneo = 'Todos';
  String _filterRival = 'Todos';
  String _filterResultado = 'Todos';
  String _filterPosicion = 'Todos';
  String _filterJugador = 'Todos';
  String _filterTemporada = 'Todos';
  int? _filterYear;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Partido> _partidos = [];

  Partido? _editing;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  bool _removeCurrentPhoto = false;
  double? _canchaLat;
  double? _canchaLng;

  final _torneo = TextEditingController();
  final _equipo = TextEditingController(text: 'Cosmos FC');
  final _rival = TextEditingController();
  final _cancha = TextEditingController();
  final _analisis = TextEditingController();
  final _scoreHijo = TextEditingController(text: '0');
  final _scoreRival = TextEditingController(text: '0');
  final _penalesEquipo = TextEditingController(text: '0');
  final _penalesRival = TextEditingController(text: '0');
  final _profileName = TextEditingController();
  final _newPlayer = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _temporada = TextEditingController();
  final _asistencias = TextEditingController(text: '0');
  final _minutos = TextEditingController(text: '0');
  final _amarillas = TextEditingController(text: '0');
  final _rojas = TextEditingController(text: '0');

  DateTime _matchDate = DateTime.now();
  String _tipoPartido = 'Liga';
  String _fase = 'Fase de Grupos';
  String _copa = 'Ninguna';
  String _posicion = 'Delantero';
  String _penalHijo = 'No pateo';
  bool _penales = false;
  bool _figuraPartido = false;
  int _goles = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in [
      _torneo,
      _equipo,
      _rival,
      _cancha,
      _analisis,
      _scoreHijo,
      _scoreRival,
      _penalesEquipo,
      _penalesRival,
      _profileName,
      _newPlayer,
      _email,
      _password,
      _temporada,
      _asistencias,
      _minutos,
      _amarillas,
      _rojas,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlayers = prefs.getStringList('jugadores');
    final legacyName = prefs.getString('nombre') ?? 'Mi Hijo';
    _players = (savedPlayers == null || savedPlayers.isEmpty)
        ? [legacyName]
        : savedPlayers;
    _playerName = prefs.getString('jugador_activo') ?? _players.first;
    if (!_players.contains(_playerName)) _players.add(_playerName);
    _profileName.text = _playerName;
    _temporada.text = '${DateTime.now().year}';
    _autoBackup = prefs.getBool('auto_backup') ?? false;
    await _loadPartidos();
  }

  Future<void> _loadPartidos() async {
    setState(() => _loading = true);
    try {
      final partidos = await _repo.listPartidos();
      setState(() => _partidos = partidos);
      await _maybeRunAutoBackup(partidos);
    } catch (e) {
      _snack('No pude cargar Firebase: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Partido> get _filteredPartidos {
    final q = _search.toLowerCase().trim();
    return _partidos.where((p) {
      final matchesText =
          q.isEmpty ||
          p.torneo.toLowerCase().contains(q) ||
          p.rival.toLowerCase().contains(q) ||
          p.cancha.toLowerCase().contains(q) ||
          p.equipo.toLowerCase().contains(q);
      final matchesTipo =
          _filterTipo == 'Todos' || p.tipoPartido == _filterTipo;
      final matchesTorneo =
          _filterTorneo == 'Todos' || p.torneo == _filterTorneo;
      final matchesRival = _filterRival == 'Todos' || p.rival == _filterRival;
      final matchesPosicion =
          _filterPosicion == 'Todos' || p.posicion == _filterPosicion;
      final matchesJugador =
          _filterJugador == 'Todos' || p.nombreJugador == _filterJugador;
      final matchesTemporada =
          _filterTemporada == 'Todos' || p.temporada == _filterTemporada;
      final matchesYear =
          _filterYear == null || p.fechaPartido.toLocal().year == _filterYear;
      final matchesResult = switch (_filterResultado) {
        'Ganados' => p.gano,
        'Empatados' => p.empato,
        'Perdidos' => !p.gano && !p.empato,
        _ => true,
      };
      return matchesText &&
          matchesTipo &&
          matchesTorneo &&
          matchesRival &&
          matchesPosicion &&
          matchesJugador &&
          matchesTemporada &&
          matchesYear &&
          matchesResult;
    }).toList();
  }

  List<String> _uniqueValues(String Function(Partido) read) {
    final values =
        _partidos
            .map(read)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Todos', ...values];
  }

  List<String> _suggestions(String Function(Partido) read) {
    return _uniqueValues(read).skip(1).toList();
  }

  List<String> get _teamSuggestions {
    final teams = _suggestions((p) => p.equipo);
    if (!teams.contains('Cosmos FC')) teams.insert(0, 'Cosmos FC');
    return teams;
  }

  ({double lat, double lng})? _knownVenueLocation(String venue) {
    final normalized = venue.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final p in _partidos) {
      if (p.cancha.trim().toLowerCase() == normalized &&
          p.canchaLat != null &&
          p.canchaLng != null) {
        return (lat: p.canchaLat!, lng: p.canchaLng!);
      }
    }
    return null;
  }

  void _applyKnownVenueLocation(String venue) {
    final known = _knownVenueLocation(venue);
    if (known == null) return;
    setState(() {
      _canchaLat = known.lat;
      _canchaLng = known.lng;
    });
  }

  Future<void> _captureVenueLocation() async {
    final venue = _cancha.text.trim();
    if (venue.isEmpty) {
      _snack('Primero escribí o elegí el predio.', isError: true);
      return;
    }

    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack(
          'Activá la ubicación del teléfono para guardar el predio.',
          isError: true,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _snack('No tengo permiso para tomar la ubicación.', isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      setState(() {
        _canchaLat = pos.latitude;
        _canchaLng = pos.longitude;
      });
      _snack('Ubicación del predio guardada para este partido.');
    } catch (e) {
      _snack('No pude tomar la ubicación: $e', isError: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<VenuePoint> get _venuePoints {
    final byVenue = <String, List<Partido>>{};
    for (final p in _partidos) {
      if (p.cancha.trim().isEmpty ||
          p.canchaLat == null ||
          p.canchaLng == null) {
        continue;
      }
      byVenue.putIfAbsent(p.cancha, () => []).add(p);
    }
    final points = byVenue.entries.map((entry) {
      final partidos = entry.value
        ..sort((a, b) => b.fechaPartido.compareTo(a.fechaPartido));
      final first = partidos.first;
      return VenuePoint(
        name: entry.key,
        position: latlong.LatLng(first.canchaLat!, first.canchaLng!),
        partidos: partidos,
      );
    }).toList()..sort((a, b) => b.partidos.length.compareTo(a.partidos.length));
    return points;
  }

  double _travelKm(List<Partido> partidos) {
    final located =
        partidos
            .where((p) => p.canchaLat != null && p.canchaLng != null)
            .toList()
          ..sort((a, b) => a.fechaPartido.compareTo(b.fechaPartido));
    if (located.length < 2) return 0;
    const distance = latlong.Distance();
    var total = 0.0;
    for (var i = 1; i < located.length; i++) {
      final prev = located[i - 1];
      final current = located[i];
      total += distance.as(
        latlong.LengthUnit.Kilometer,
        latlong.LatLng(prev.canchaLat!, prev.canchaLng!),
        latlong.LatLng(current.canchaLat!, current.canchaLng!),
      );
    }
    return total;
  }

  List<int> get _availableYears {
    final years =
        _partidos.map((p) => p.fechaPartido.toLocal().year).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    return years;
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _filterTipo = 'Todos';
      _filterTorneo = 'Todos';
      _filterRival = 'Todos';
      _filterResultado = 'Todos';
      _filterPosicion = 'Todos';
      _filterJugador = 'Todos';
      _filterTemporada = 'Todos';
      _filterYear = null;
    });
  }

  Stats _statsFor(Iterable<Partido> partidos) {
    final stats = Stats();
    for (final p in partidos) {
      stats.add(p);
    }
    return stats;
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('jugadores', _players);
    await prefs.setString('jugador_activo', _playerName);
    await prefs.setString('nombre', _playerName);
  }

  Future<void> _addPlayer() async {
    final name = _newPlayer.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_players.contains(name)) _players.add(name);
      _playerName = name;
      _profileName.text = name;
      _newPlayer.clear();
    });
    await _savePlayers();
    _snack('Jugador agregado.');
  }

  Future<void> _selectPlayer(String name) async {
    setState(() {
      _playerName = name;
      _profileName.text = name;
    });
    await _savePlayers();
  }

  Future<void> _removePlayer(String name) async {
    if (_players.length <= 1) return;
    setState(() {
      _players.remove(name);
      if (_playerName == name) {
        _playerName = _players.first;
        _profileName.text = _playerName;
      }
    });
    await _savePlayers();
  }

  Future<void> _connectEmail() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      _snack(
        'Usa un email y una clave de al menos 6 caracteres.',
        isError: true,
      );
      return;
    }
    try {
      await _repo.linkOrSignInWithEmail(email, password);
      await _loadPartidos();
      _snack('Cuenta conectada.');
    } catch (e) {
      _snack('No pude conectar la cuenta: $e', isError: true);
    }
  }

  Future<void> _connectGoogle() async {
    try {
      await _repo.linkOrSignInWithGoogle();
      await _loadPartidos();
      _snack('Cuenta de Google conectada.');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _snack('Inicio con Google cancelado.');
      } else {
        _snack('No pude conectar Google: ${e.description}', isError: true);
      }
    } catch (e) {
      _snack('No pude conectar Google: $e', isError: true);
    }
  }

  void _appendAnalysisTemplate(String text) {
    final current = _analisis.text.trim();
    _analisis.text = current.isEmpty ? text : '$current. $text';
    _analisis.selection = TextSelection.collapsed(
      offset: _analisis.text.length,
    );
  }

  Future<void> _maybeRunAutoBackup(List<Partido> partidos) async {
    if (!_autoBackup || partidos.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString('last_auto_backup_date') == today) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/auto_backup_partidos.csv');
      await file.writeAsString(_buildCsv(partidos), encoding: utf8);
      await prefs.setString('last_auto_backup_date', today);
    } catch (_) {
      // El backup automÃƒÆ’Ã‚Â¡tico no debe interrumpir el uso normal de la app.
    }
  }

  int _winningStreak(List<Partido> partidos) {
    var streak = 0;
    for (final p in partidos) {
      if (!p.gano) break;
      streak++;
    }
    return streak;
  }

  Future<void> _exportCsv(List<Partido> partidos) async {
    try {
      final csv = _buildCsv(partidos);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/historial_partidos.csv');
      await file.writeAsString(csv, encoding: utf8);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Historial de partidos',
          text: 'Exportaci\u00f3n CSV de Partidos Pro.',
        ),
      );
    } catch (e) {
      _snack('No pude exportar CSV: $e', isError: true);
    }
  }

  Future<void> _exportPdf(List<Partido> partidos) async {
    try {
      final stats = _statsFor(partidos);
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'Partidos Pro',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Historial de $_playerName'),
            pw.SizedBox(height: 16),
            pw.Text(
              'PJ ${stats.pj} | PG ${stats.pg} | PE ${stats.pe} | PP ${stats.pp} | GF ${stats.gf} | GC ${stats.gc} | GP ${stats.gp}',
            ),
            pw.Text(
              'Asistencias ${stats.asistencias} | Figuras ${stats.figuras} | Minutos ${stats.minutos}',
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [
                'Fecha',
                'Temporada',
                'Evento',
                'Resultado',
                'Rival',
                'G',
                'A',
              ],
              data: partidos.map((p) {
                return [
                  _shortDateFormat.format(p.fechaPartido.toLocal()),
                  p.temporada,
                  p.torneo,
                  '${p.equipo} ${p.marcador}',
                  p.rival,
                  '${p.golesHijo}',
                  '${p.asistencias}',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'historial_partidos.pdf',
      );
    } catch (e) {
      _snack('No pude exportar PDF: $e', isError: true);
    }
  }

  String _buildCsv(List<Partido> partidos) {
    final rows = <List<String>>[
      [
        'Fecha',
        'Temporada',
        'Tipo',
        'Torneo',
        'Fase',
        'Copa',
        'Cancha',
        'Cancha Lat',
        'Cancha Lng',
        'Equipo',
        'Goles Favor',
        'Goles Contra',
        'Rival',
        'Jugador',
        'Goles Jugador',
        'Asistencias',
        'Minutos',
        'Amarillas',
        'Rojas',
        'Figura',
        'Posici\u00f3n',
        'Penales',
        'Penales Favor',
        'Penales Contra',
        'Penal Jugador',
        'An\u00e1lisis',
        'Foto',
      ],
      for (final p in partidos)
        [
          p.fechaTexto,
          p.temporada,
          p.tipoPartido,
          p.torneo,
          p.fase,
          p.copa,
          p.cancha,
          p.canchaLat?.toStringAsFixed(7) ?? '',
          p.canchaLng?.toStringAsFixed(7) ?? '',
          p.equipo,
          '${p.scoreHijo}',
          '${p.scoreRival}',
          p.rival,
          p.nombreJugador,
          '${p.golesHijo}',
          '${p.asistencias}',
          '${p.minutosJugados}',
          '${p.tarjetasAmarillas}',
          '${p.tarjetasRojas}',
          p.figuraPartido ? 'Si' : 'No',
          p.posicion,
          p.penales ? 'Si' : 'No',
          '${p.scorePenalesEquipo}',
          '${p.scorePenalesRival}',
          p.penalHijo,
          p.analisis,
          p.foto ?? '',
        ],
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _matchDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_matchDate),
    );
    if (time == null) return;
    setState(() {
      _matchDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _selectedPhotoBytes = result.files.single.bytes;
      _selectedPhotoName = result.files.single.name;
      _removeCurrentPhoto = false;
    });
  }

  Future<void> _save() async {
    if (_torneo.text.trim().isEmpty || _rival.text.trim().isEmpty) {
      _snack('Complet\u00e1 evento y rival para guardar.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      String? photoUrl = _editing?.foto;
      String? photoPath = _editing?.fotoPath;

      if (_removeCurrentPhoto && photoPath != null) {
        await _repo.deletePhoto(photoPath);
        photoUrl = null;
        photoPath = null;
      }

      if (_selectedPhotoBytes != null) {
        if (photoPath != null) await _repo.deletePhoto(photoPath);
        photoUrl = await _repo.uploadPhoto(_selectedPhotoBytes!);
        photoPath = _photoPathFromUrl(photoUrl);
      }

      final partido = Partido(
        documentName: _editing?.documentName,
        id: _editing?.id,
        nombreJugador: _playerName,
        temporada: _temporada.text.trim().isEmpty
            ? '${_matchDate.year}'
            : _temporada.text.trim(),
        tipoPartido: _tipoPartido,
        torneo: _torneo.text.trim(),
        fase: _fase,
        copa: _copa,
        equipo: _equipo.text.trim().isEmpty ? 'Cosmos FC' : _equipo.text.trim(),
        rival: _rival.text.trim(),
        cancha: _cancha.text.trim(),
        canchaLat: _canchaLat ?? _knownVenueLocation(_cancha.text.trim())?.lat,
        canchaLng: _canchaLng ?? _knownVenueLocation(_cancha.text.trim())?.lng,
        fechaTexto: _dateFormat.format(_matchDate),
        fechaPartido: _matchDate.toUtc(),
        posicion: _posicion,
        analisis: _analisis.text.trim(),
        scoreHijo: _parseInt(_scoreHijo.text),
        scoreRival: _parseInt(_scoreRival.text),
        golesHijo: _goles,
        asistencias: _parseInt(_asistencias.text),
        minutosJugados: _parseInt(_minutos.text),
        tarjetasAmarillas: _parseInt(_amarillas.text),
        tarjetasRojas: _parseInt(_rojas.text),
        figuraPartido: _figuraPartido,
        penales: _penales,
        scorePenalesEquipo: _parseInt(_penalesEquipo.text),
        scorePenalesRival: _parseInt(_penalesRival.text),
        penalHijo: _penalHijo,
        foto: photoUrl,
        fotoPath: photoPath,
        creadoEn: _editing?.creadoEn,
      );

      await _repo.savePartido(partido);
      _clearForm();
      await _loadPartidos();
      setState(() => _tab = 1);
      _snack(_editing == null ? 'Partido guardado.' : 'Partido actualizado.');
    } catch (e) {
      _snack('No pude guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _edit(Partido p) {
    setState(() {
      _editing = p;
      _playerName = p.nombreJugador;
      _profileName.text = p.nombreJugador;
      if (!_players.contains(p.nombreJugador)) _players.add(p.nombreJugador);
      _torneo.text = p.torneo;
      _temporada.text = p.temporada;
      _equipo.text = p.equipo;
      _rival.text = p.rival;
      _cancha.text = p.cancha;
      _canchaLat = p.canchaLat;
      _canchaLng = p.canchaLng;
      _analisis.text = p.analisis;
      _scoreHijo.text = '${p.scoreHijo}';
      _scoreRival.text = '${p.scoreRival}';
      _penalesEquipo.text = '${p.scorePenalesEquipo}';
      _penalesRival.text = '${p.scorePenalesRival}';
      _asistencias.text = '${p.asistencias}';
      _minutos.text = '${p.minutosJugados}';
      _amarillas.text = '${p.tarjetasAmarillas}';
      _rojas.text = '${p.tarjetasRojas}';
      _matchDate = p.fechaPartido.toLocal();
      _tipoPartido = p.tipoPartido;
      _fase = p.fase.isEmpty ? 'Fase de Grupos' : p.fase;
      _copa = p.copa.isEmpty ? 'Ninguna' : p.copa;
      _posicion = p.posicion;
      _penalHijo = p.penalHijo;
      _penales = p.penales;
      _figuraPartido = p.figuraPartido;
      _goles = p.golesHijo;
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
      _removeCurrentPhoto = false;
      _tab = 0;
    });
  }

  void _clearForm() {
    _editing = null;
    _torneo.clear();
    _temporada.text = '${DateTime.now().year}';
    _equipo.text = 'Cosmos FC';
    _rival.clear();
    _cancha.clear();
    _canchaLat = null;
    _canchaLng = null;
    _analisis.clear();
    _scoreHijo.text = '0';
    _scoreRival.text = '0';
    _penalesEquipo.text = '0';
    _penalesRival.text = '0';
    _asistencias.text = '0';
    _minutos.text = '0';
    _amarillas.text = '0';
    _rojas.text = '0';
    _matchDate = DateTime.now();
    _tipoPartido = 'Liga';
    _fase = 'Fase de Grupos';
    _copa = 'Ninguna';
    _posicion = 'Delantero';
    _penalHijo = 'No pateo';
    _penales = false;
    _figuraPartido = false;
    _goles = 0;
    _selectedPhotoBytes = null;
    _selectedPhotoName = null;
    _removeCurrentPhoto = false;
  }

  Future<void> _delete(Partido p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: const Text('Esta acci\u00f3n no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deletePartido(p);
      await _loadPartidos();
      _snack('Partido eliminado.');
    } catch (e) {
      _snack('No pude eliminar: $e', isError: true);
    }
  }

  Future<void> _share(Partido p) async {
    final result = p.gano ? 'Ganamos' : (p.empato ? 'Empate' : 'Buen partido');
    final text = [
      '$result: ${p.equipo} ${p.marcador} ${p.rival}',
      'Evento: ${p.torneo}',
      'Temporada: ${p.temporada}',
      'Fecha: ${p.fechaTexto}',
      'Cancha: ${p.cancha}',
      'Goles de ${p.nombreJugador}: ${p.golesHijo}',
      if (p.asistencias > 0) 'Asistencias: ${p.asistencias}',
      if (p.figuraPartido) 'Figura del partido',
      'Posici\u00f3n: ${p.posicion}',
      if (p.analisis.isNotEmpty) 'An\u00e1lisis: ${p.analisis}',
    ].join('\n');
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveProfile() async {
    final name = _profileName.text.trim().isEmpty
        ? 'Mi Hijo'
        : _profileName.text.trim();
    setState(() {
      final index = _players.indexOf(_playerName);
      if (index >= 0) {
        _players[index] = name;
      } else if (!_players.contains(name)) {
        _players.add(name);
      }
      _players = _players.toSet().toList();
      _playerName = name;
    });
    await _savePlayers();
    _snack('Perfil actualizado.');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildForm(),
      _buildStatsAndHistory(),
      _buildMap(),
      _buildGallery(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Partidos Pro',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadPartidos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : pages[_tab],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Cargar',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Galer\u00eda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Header(
          title: _editing == null ? 'Registrar partido' : 'Editar partido',
          subtitle: _editing == null
              ? 'Carga el resultado y el rendimiento.'
              : 'Se va a respetar la fecha real del partido.',
        ),
        _SectionCard(
          title: 'Contexto',
          icon: Icons.event_available_rounded,
          child: Column(
            children: [
              _choiceRow(
                'Tipo',
                ['Liga', 'Torneo', 'Amistoso'],
                _tipoPartido,
                (v) => setState(() => _tipoPartido = v),
              ),
              const SizedBox(height: 12),
              _suggestField(
                'Evento',
                controller: _torneo,
                options: _suggestions((p) => p.torneo),
              ),
              const SizedBox(height: 12),
              _suggestField(
                'Temporada',
                controller: _temporada,
                options: _suggestions((p) => p.temporada),
              ),
              if (_tipoPartido == 'Torneo') ...[
                const SizedBox(height: 12),
                _adaptivePair(
                  _dropdown('Fase', _fase, [
                    'Fase de Grupos',
                    'Octavos',
                    'Cuartos',
                    'Semifinal',
                    'Final',
                  ], (v) => setState(() => _fase = v)),
                  _dropdown('Copa', _copa, [
                    'Ninguna',
                    'Oro',
                    'Plata',
                    'Bronce',
                  ], (v) => setState(() => _copa = v)),
                ),
              ],
              const SizedBox(height: 12),
              _adaptivePair(
                _suggestField(
                  'Cancha / Predio',
                  controller: _cancha,
                  options: _suggestions((p) => p.cancha),
                  showAllOnTap: true,
                  onSelectedValue: _applyKnownVenueLocation,
                  onChangedValue: (value) {
                    if (_knownVenueLocation(value) != null) {
                      _applyKnownVenueLocation(value);
                    }
                  },
                ),
                InkWell(
                  onTap: _pickDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora',
                    ),
                    child: Text(
                      _dateFormat.format(_matchDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _venueLocationBar(),
            ],
          ),
        ),
        _SectionCard(
          title: 'Partido',
          icon: Icons.scoreboard_rounded,
          child: Column(
            children: [
              _adaptivePair(
                _suggestField(
                  'Equipo',
                  controller: _equipo,
                  options: _teamSuggestions,
                  showAllOnTap: true,
                ),
                _suggestField(
                  'Rival',
                  controller: _rival,
                  options: _suggestions((p) => p.rival),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _scoreBox(_scoreHijo),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _scoreBox(_scoreRival),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _penales,
                onChanged: (v) => setState(() => _penales = v),
                title: const Text('Definici\u00f3n por penales'),
              ),
              if (_penales)
                _adaptiveTriple(
                  TextField(
                    controller: _penalesEquipo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Penales equipo',
                    ),
                  ),
                  TextField(
                    controller: _penalesRival,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Penales rival',
                    ),
                  ),
                  _dropdown('Penal', _penalHijo, [
                    'No pateo',
                    'Anoto',
                    'Erro',
                  ], (v) => setState(() => _penalHijo = v)),
                ),
            ],
          ),
        ),
        _SectionCard(
          title: 'Rendimiento',
          icon: Icons.auto_awesome_rounded,
          child: Column(
            children: [
              _adaptivePair(
                _dropdown(
                  'Jugador',
                  _playerName,
                  _players,
                  (v) => _selectPlayer(v),
                ),
                _dropdown('Posici\u00f3n', _posicion, [
                  'Delantero',
                  'Mediocampista',
                  'Defensor',
                  'Arquero',
                ], (v) => setState(() => _posicion = v)),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Foto'),
                ),
              ),
              if (_selectedPhotoName != null ||
                  (_editing?.foto != null && !_removeCurrentPhoto)) ...[
                const SizedBox(height: 12),
                _photoPreview(),
              ],
              const SizedBox(height: 12),
              _adaptiveTriple(
                TextField(
                  controller: _asistencias,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Asistencias'),
                ),
                TextField(
                  controller: _minutos,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minutos'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _figuraPartido,
                  onChanged: (v) => setState(() => _figuraPartido = v),
                  title: const Text('Figura'),
                ),
              ),
              const SizedBox(height: 12),
              _adaptivePair(
                TextField(
                  controller: _amarillas,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amarillas'),
                ),
                TextField(
                  controller: _rojas,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rojas'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _analisis,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notas y an\u00e1lisis t\u00e9cnico',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final template in const [
                    'Buen pase',
                    'Presi\u00f3n alta',
                    'Asistencia',
                    'Definici\u00f3n',
                    'Actitud',
                    'Marca',
                    'Recuperaci\u00f3n',
                    'Trabajo en equipo',
                  ])
                    ActionChip(
                      label: Text(template),
                      onPressed: () => _appendAnalysisTemplate(template),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Goles de $_playerName',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 18),
                  IconButton.filledTonal(
                    onPressed: _goles == 0
                        ? null
                        : () => setState(() => _goles--),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 54,
                    child: Center(
                      child: Text(
                        '$_goles',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => setState(() => _goles++),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (_editing != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(_clearForm),
                  child: const Text('Cancelar edici\u00f3n'),
                ),
              ),
            if (_editing != null) const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _editing == null ? 'Guardar partido' : 'Actualizar',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsAndHistory() {
    final filtered = _filteredPartidos;
    final stats = _statsFor(filtered);
    final byTournament = <String, Stats>{};
    for (final p in filtered) {
      byTournament.putIfAbsent(p.torneo, Stats.new).add(p);
    }

    return RefreshIndicator(
      onRefresh: _loadPartidos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Header(
            title: 'Rendimiento',
            subtitle: '${filtered.length} de ${_partidos.length} partidos',
          ),
          _StatsGrid(stats: stats),
          const SizedBox(height: 12),
          _EvolutionSummary(
            partidos: filtered,
            streak: _winningStreak(_partidos),
          ),
          const SizedBox(height: 12),
          _ProDashboard(partidos: filtered),
          const SizedBox(height: 12),
          _GoalChart(partidos: filtered.take(10).toList().reversed.toList()),
          const SizedBox(height: 12),
          _AdvancedFilters(
            search: _search,
            tipo: _filterTipo,
            torneo: _filterTorneo,
            rival: _filterRival,
            resultado: _filterResultado,
            posicion: _filterPosicion,
            jugador: _filterJugador,
            temporada: _filterTemporada,
            year: _filterYear,
            years: _availableYears,
            torneos: _uniqueValues((p) => p.torneo),
            rivales: _uniqueValues((p) => p.rival),
            posiciones: _uniqueValues((p) => p.posicion),
            jugadores: _uniqueValues((p) => p.nombreJugador),
            temporadas: _uniqueValues((p) => p.temporada),
            onSearch: (v) => setState(() => _search = v),
            onTipo: (v) => setState(() => _filterTipo = v),
            onTorneo: (v) => setState(() => _filterTorneo = v),
            onRival: (v) => setState(() => _filterRival = v),
            onResultado: (v) => setState(() => _filterResultado = v),
            onPosicion: (v) => setState(() => _filterPosicion = v),
            onJugador: (v) => setState(() => _filterJugador = v),
            onTemporada: (v) => setState(() => _filterTemporada = v),
            onYear: (v) => setState(() => _filterYear = v),
            onClear: _clearFilters,
          ),
          const SizedBox(height: 12),
          _CalendarSection(
            month: _calendarMonth,
            partidos: _partidos,
            dateFormat: _shortDateFormat,
            onPrev: () => setState(
              () => _calendarMonth = DateTime(
                _calendarMonth.year,
                _calendarMonth.month - 1,
              ),
            ),
            onNext: () => setState(
              () => _calendarMonth = DateTime(
                _calendarMonth.year,
                _calendarMonth.month + 1,
              ),
            ),
            onDayTap: _showDayPartidos,
          ),
          const SizedBox(height: 12),
          _RivalRanking(partidos: filtered),
          const SizedBox(height: 12),
          _TournamentMode(partidos: filtered),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Por torneo',
            icon: Icons.emoji_events_outlined,
            child: Column(
              children: byTournament.entries.map((entry) {
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${entry.value.pj} partidos'),
                  children: [_StatsGrid(stats: entry.value, compact: true)],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _ExportSection(
            count: filtered.length,
            onCsv: filtered.isEmpty ? null : () => _exportCsv(filtered),
            onPdf: filtered.isEmpty ? null : () => _exportPdf(filtered),
          ),
          const SizedBox(height: 12),
          ...filtered.map(
            (p) => _PartidoCard(
              partido: p,
              date: _shortDateFormat.format(p.fechaPartido.toLocal()),
              onOpen: () => _showPartidoDetail(p),
              onEdit: () => _edit(p),
              onDelete: () => _delete(p),
              onShare: () => _share(p),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayPartidos(DateTime day, List<Partido> partidos) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              _shortDateFormat.format(day),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final p in partidos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sports_soccer_rounded),
                title: Text('${p.equipo} ${p.marcador} ${p.rival}'),
                subtitle: Text('${p.torneo} | ${p.cancha}'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartidoDetail(p);
                },
              ),
          ],
        );
      },
    );
  }

  void _showPartidoDetail(Partido p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (p.foto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      p.foto!,
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  p.torneo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${p.equipo} ${p.marcador} ${p.rival}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Chip(
                      icon: Icons.calendar_today_outlined,
                      label: p.fechaTexto,
                    ),
                    _Chip(icon: Icons.flag_outlined, label: p.temporada),
                    if (p.cancha.isNotEmpty)
                      _Chip(icon: Icons.place_outlined, label: p.cancha),
                    if (p.canchaLat != null && p.canchaLng != null)
                      const _Chip(
                        icon: Icons.map_outlined,
                        label: 'Predio ubicado',
                      ),
                    _Chip(icon: Icons.sports_outlined, label: p.posicion),
                    _Chip(
                      icon: Icons.stars_outlined,
                      label: '${p.golesHijo} goles',
                    ),
                    if (p.asistencias > 0)
                      _Chip(
                        icon: Icons.handshake_outlined,
                        label: '${p.asistencias} asist.',
                      ),
                    if (p.minutosJugados > 0)
                      _Chip(
                        icon: Icons.timer_outlined,
                        label: '${p.minutosJugados} min',
                      ),
                    if (p.figuraPartido)
                      const _Chip(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Figura',
                      ),
                    if (p.penales)
                      _Chip(
                        icon: Icons.adjust_rounded,
                        label:
                            'Penales ${p.scorePenalesEquipo}-${p.scorePenalesRival}',
                      ),
                  ],
                ),
                if (p.analisis.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    p.analisis,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _edit(p);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _share(p),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Compartir'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGallery() {
    final withPhotos = _partidos.where((p) => p.foto != null).toList();
    return RefreshIndicator(
      onRefresh: _loadPartidos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Header(
            title: 'Galer\u00eda',
            subtitle: '${withPhotos.length} fotos guardadas',
          ),
          if (withPhotos.isEmpty)
            const _SectionCard(
              title: 'Fotos',
              icon: Icons.photo_library_outlined,
              child: Text('Las fotos que cargues en partidos aparecen aca.'),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 620 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: withPhotos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final p = withPhotos[index];
                    return InkWell(
                      onTap: () => _showPartidoDetail(p),
                      borderRadius: BorderRadius.circular(14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(p.foto!, fit: BoxFit.cover),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                color: Colors.black.withValues(alpha: 0.55),
                                child: Text(
                                  '${p.torneo}\n${_shortDateFormat.format(p.fechaPartido.toLocal())}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final venues = _venuePoints;
    final center = venues.isEmpty
        ? const latlong.LatLng(-34.6037, -58.3816)
        : venues.first.position;
    final travelKm = _travelKm(_partidos);

    return RefreshIndicator(
      onRefresh: _loadPartidos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Header(
            title: 'Mapa de predios',
            subtitle:
                '${venues.length} predios ubicados | ${travelKm.toStringAsFixed(1)} km recorridos',
          ),
          _SectionCard(
            title: 'Recorrido',
            icon: Icons.route_outlined,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                _InfoTile(label: 'Predios', value: '${venues.length}'),
                _InfoTile(
                  label: 'Partidos ubicados',
                  value:
                      '${_partidos.where((p) => p.canchaLat != null && p.canchaLng != null).length}',
                ),
                _InfoTile(
                  label: 'Km recorridos',
                  value: travelKm.toStringAsFixed(1),
                ),
                _InfoTile(
                  label: 'Más visitado',
                  value: venues.isEmpty ? 'Sin datos' : venues.first.name,
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Mapa',
            icon: Icons.map_outlined,
            child: venues.isEmpty
                ? const Text(
                    'Cuando guardes la ubicación de un predio, va a aparecer en este mapa.',
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 420,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 10.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.leaestudio.partidos_pro',
                          ),
                          MarkerLayer(
                            markers: [
                              for (final venue in venues)
                                Marker(
                                  point: venue.position,
                                  width: 54,
                                  height: 54,
                                  child: Tooltip(
                                    message:
                                        '${venue.name} (${venue.partidos.length})',
                                    child: GestureDetector(
                                      onTap: () => _showVenueDetail(venue),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${venue.partidos.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          for (final venue in venues)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.place_outlined, color: _accent),
                title: Text(
                  venue.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${venue.partidos.length} partidos | ${venue.position.latitude.toStringAsFixed(5)}, ${venue.position.longitude.toStringAsFixed(5)}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showVenueDetail(venue),
              ),
            ),
        ],
      ),
    );
  }

  void _showVenueDetail(VenuePoint venue) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              venue.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${venue.position.latitude.toStringAsFixed(5)}, ${venue.position.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 12),
            for (final p in venue.partidos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sports_soccer_rounded),
                title: Text('${p.equipo} ${p.marcador} ${p.rival}'),
                subtitle: Text('${p.torneo} | ${p.fechaTexto}'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartidoDetail(p);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _Header(
          title: 'Perfil',
          subtitle:
              'Personaliz\u00e1 el nombre que aparece en rendimiento y compartidos.',
        ),
        _SectionCard(
          title: 'Jugador',
          icon: Icons.person_rounded,
          child: Column(
            children: [
              TextField(
                controller: _profileName,
                decoration: const InputDecoration(
                  labelText: 'Nombre del jugador',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar perfil'),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _newPlayer,
                decoration: const InputDecoration(
                  labelText: 'Agregar otro jugador',
                  suffixIcon: Icon(Icons.person_add_alt_1_outlined),
                ),
                onSubmitted: (_) => _addPlayer(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar'),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final player in _players)
                    InputChip(
                      selected: player == _playerName,
                      label: Text(player),
                      onPressed: () => _selectPlayer(player),
                      onDeleted: _players.length <= 1
                          ? null
                          : () => _removePlayer(player),
                    ),
                ],
              ),
            ],
          ),
        ),
        _SectionCard(
          title: 'Cuenta',
          icon: Icons.lock_outline_rounded,
          child: Column(
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Clave'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _connectEmail,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Conectar cuenta'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _connectGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('Continuar con Google'),
                ),
              ),
              const SizedBox(height: 10),
              _SecurityRow(
                label: 'Sesi\u00f3n',
                value: _repo.currentUser?.isAnonymous == false
                    ? 'Email'
                    : 'An\u00f3nima segura',
                color: _accent,
              ),
            ],
          ),
        ),
        _SectionCard(
          title: 'Backup autom\u00e1tico',
          icon: Icons.backup_outlined,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoBackup,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('auto_backup', value);
              setState(() => _autoBackup = value);
              if (value) await _maybeRunAutoBackup(_partidos);
            },
            title: const Text('Guardar CSV diario'),
            subtitle: const Text('Se actualiza al abrir o refrescar la app.'),
          ),
        ),
        _SectionCard(
          title: 'Seguridad Firebase',
          icon: Icons.verified_user_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecurityRow(
                label: 'Modo actual',
                value: _repo.authUnavailable
                    ? 'Compatibilidad legacy'
                    : 'Firebase SDK por usuario',
                color: _repo.authUnavailable ? Colors.orange : _accent,
              ),
              const SizedBox(height: 10),
              const _SecurityRow(
                label: 'Reglas',
                value: 'Activas por usuario',
                color: _accent,
              ),
              const SizedBox(height: 12),
              Text(
                'La app usa la sesion del telefono para leer y guardar solo los partidos del usuario actual.',
                style: TextStyle(color: Colors.grey.shade800, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoPreview() {
    Widget image;
    if (_selectedPhotoBytes != null) {
      image = Image.memory(
        _selectedPhotoBytes!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      image = Image.network(
        _editing!.foto!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          image,
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              onPressed: () => setState(() {
                _selectedPhotoBytes = null;
                _selectedPhotoName = null;
                _removeCurrentPhoto = true;
              }),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _venueLocationBar() {
    final hasLocation = _canchaLat != null && _canchaLng != null;
    final known = _knownVenueLocation(_cancha.text);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on : Icons.location_searching,
                color: _accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasLocation
                      ? 'Predio ubicado: ${_canchaLat!.toStringAsFixed(5)}, ${_canchaLng!.toStringAsFixed(5)}'
                      : known != null
                      ? 'Este predio ya tiene ubicación guardada.'
                      : 'Sin ubicación para este predio.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _locating ? null : _captureVenueLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(
                  _locating ? 'Ubicando...' : 'Usar ubicación actual',
                ),
              ),
              if (known != null && !hasLocation)
                OutlinedButton.icon(
                  onPressed: () => _applyKnownVenueLocation(_cancha.text),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Usar guardada'),
                ),
              if (hasLocation)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _canchaLat = null;
                    _canchaLng = null;
                  }),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Quitar ubicación'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(TextEditingController controller) {
    return SizedBox(
      width: 86,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _adaptivePair(
    Widget first,
    Widget second, {
    int firstFlex = 1,
    int secondFlex = 1,
    double breakpoint = 390,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 12), second],
          );
        }
        return Row(
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 12),
            secondFlex == 0
                ? second
                : Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }

  Widget _adaptiveTriple(Widget first, Widget second, Widget third) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 470) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: 12),
              second,
              const SizedBox(height: 12),
              third,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
            const SizedBox(width: 12),
            Expanded(child: third),
          ],
        );
      },
    );
  }

  Widget _suggestField(
    String label, {
    required TextEditingController controller,
    required List<String> options,
    bool showAllOnTap = false,
    ValueChanged<String>? onSelectedValue,
    ValueChanged<String>? onChangedValue,
  }) {
    return Autocomplete<String>(
      key: ValueKey('$label-${controller.text}-${options.length}'),
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (text) {
        final query = text.text.toLowerCase().trim();
        final controllerText = controller.text.toLowerCase().trim();
        final shouldShowAll =
            query.isEmpty || (showAllOnTap && query == controllerText);
        final matches = shouldShowAll
            ? options
            : options
                  .where((option) => option.toLowerCase().contains(query))
                  .toList();
        return matches.take(8);
      },
      onSelected: (value) {
        controller.text = value;
        onSelectedValue?.call(value);
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: options.isEmpty
                ? null
                : const Icon(Icons.arrow_drop_down_rounded),
          ),
          onChanged: (value) {
            controller.text = value;
            onChangedValue?.call(value);
          },
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, values) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final value = values.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history_rounded, size: 18),
                    title: Text(value, overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(value),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: options.contains(value) ? value : options.first,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _choiceRow(
    String label,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: SegmentedButton<String>(
            segments: options
                .map((o) => ButtonSegment(value: o, label: Text(o)))
                .toList(),
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ],
    );
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _accent,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.sports_soccer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _accent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({
    required this.search,
    required this.tipo,
    required this.torneo,
    required this.rival,
    required this.resultado,
    required this.posicion,
    required this.jugador,
    required this.temporada,
    required this.year,
    required this.years,
    required this.torneos,
    required this.rivales,
    required this.posiciones,
    required this.jugadores,
    required this.temporadas,
    required this.onSearch,
    required this.onTipo,
    required this.onTorneo,
    required this.onRival,
    required this.onResultado,
    required this.onPosicion,
    required this.onJugador,
    required this.onTemporada,
    required this.onYear,
    required this.onClear,
  });

  final String search;
  final String tipo;
  final String torneo;
  final String rival;
  final String resultado;
  final String posicion;
  final String jugador;
  final String temporada;
  final int? year;
  final List<int> years;
  final List<String> torneos;
  final List<String> rivales;
  final List<String> posiciones;
  final List<String> jugadores;
  final List<String> temporadas;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onTipo;
  final ValueChanged<String> onTorneo;
  final ValueChanged<String> onRival;
  final ValueChanged<String> onResultado;
  final ValueChanged<String> onPosicion;
  final ValueChanged<String> onJugador;
  final ValueChanged<String> onTemporada;
  final ValueChanged<int?> onYear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Filtros avanzados',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          TextField(
            controller: TextEditingController(text: search)
              ..selection = TextSelection.collapsed(offset: search.length),
            onChanged: onSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Buscar por torneo, rival, cancha o equipo',
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 430;
              final fields = [
                _filterDropdown('Tipo', tipo, [
                  'Todos',
                  'Liga',
                  'Torneo',
                  'Amistoso',
                ], onTipo),
                _filterDropdown('Resultado', resultado, [
                  'Todos',
                  'Ganados',
                  'Empatados',
                  'Perdidos',
                ], onResultado),
                _filterDropdown('Torneo', torneo, torneos, onTorneo),
                _filterDropdown('Rival', rival, rivales, onRival),
                _filterDropdown(
                  'Posici\u00f3n',
                  posicion,
                  posiciones,
                  onPosicion,
                ),
                _filterDropdown('Jugador', jugador, jugadores, onJugador),
                _filterDropdown(
                  'Temporada',
                  temporada,
                  temporadas,
                  onTemporada,
                ),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'A\u00f1o'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...years.map(
                      (y) => DropdownMenuItem<int>(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: onYear,
                ),
              ];
              if (narrow) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: fields
                    .map(
                      (field) => SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: field,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final safeValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: safeValue,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _EvolutionSummary extends StatelessWidget {
  const _EvolutionSummary({required this.partidos, required this.streak});

  final List<Partido> partidos;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final stats = Stats();
    final byPosition = <String, int>{};
    var maxGoals = 0;
    for (final p in partidos) {
      stats.add(p);
      byPosition[p.posicion] = (byPosition[p.posicion] ?? 0) + 1;
      maxGoals = max(maxGoals, p.golesHijo);
    }
    final averageGoals = stats.pj == 0 ? 0 : stats.gp / stats.pj;
    final favoritePosition = byPosition.entries.isEmpty
        ? 'Sin datos'
        : (byPosition.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    return _SectionCard(
      title: 'Evoluci\u00f3n',
      icon: Icons.trending_up_rounded,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: [
          _InfoTile(
            label: 'Promedio goles',
            value: averageGoals.toStringAsFixed(2),
          ),
          _InfoTile(label: 'Mejor marca', value: '$maxGoals goles'),
          _InfoTile(label: 'Racha actual', value: '$streak victorias'),
          _InfoTile(label: 'Posici\u00f3n usual', value: favoritePosition),
        ],
      ),
    );
  }
}

class _ProDashboard extends StatelessWidget {
  const _ProDashboard({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final stats = Stats();
    final byCancha = <String, Stats>{};
    final byTemporada = <String, Stats>{};
    final byRival = <String, Stats>{};
    for (final p in partidos) {
      stats.add(p);
      if (p.cancha.isNotEmpty) byCancha.putIfAbsent(p.cancha, Stats.new).add(p);
      if (p.temporada.isNotEmpty) {
        byTemporada.putIfAbsent(p.temporada, Stats.new).add(p);
      }
      if (p.rival.isNotEmpty) byRival.putIfAbsent(p.rival, Stats.new).add(p);
    }

    String bestLabel(Map<String, Stats> values, int Function(Stats) score) {
      if (values.isEmpty) return 'Sin datos';
      final list = values.entries.toList()
        ..sort((a, b) => score(b.value).compareTo(score(a.value)));
      return list.first.key;
    }

    final avgMinutes = stats.pj == 0 ? 0 : stats.minutos / stats.pj;
    final totalCards = stats.amarillas + stats.rojas;

    return _SectionCard(
      title: 'Dashboard pro',
      icon: Icons.dashboard_customize_outlined,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.75,
        children: [
          _InfoTile(
            label: 'Mejor cancha',
            value: bestLabel(byCancha, (s) => s.pg * 3 + s.pe),
          ),
          _InfoTile(
            label: 'Temporada top',
            value: bestLabel(byTemporada, (s) => s.gp + s.asistencias),
          ),
          _InfoTile(
            label: 'Rival m\u00e1s dif\u00edcil',
            value: bestLabel(byRival, (s) => s.pp * 3 + s.gc),
          ),
          _InfoTile(
            label: 'Prom. minutos',
            value: avgMinutes.toStringAsFixed(0),
          ),
          _InfoTile(label: 'Asistencias', value: '${stats.asistencias}'),
          _InfoTile(label: 'Tarjetas', value: '$totalCards'),
        ],
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.month,
    required this.partidos,
    required this.dateFormat,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  final DateTime month;
  final List<Partido> partidos;
  final DateFormat dateFormat;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime day, List<Partido> partidos) onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final firstWeekday = first.weekday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final monthPartidos = partidos.where((p) {
      final d = p.fechaPartido.toLocal();
      return d.year == month.year && d.month == month.month;
    }).toList();
    final byDay = <int, List<Partido>>{};
    for (final p in monthPartidos) {
      final day = p.fechaPartido.toLocal().day;
      byDay.putIfAbsent(day, () => []).add(p);
    }
    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final dayPartidos = byDay[day] ?? [];
      cells.add(
        _CalendarCell(
          day: day,
          count: dayPartidos.length,
          onTap: dayPartidos.isEmpty
              ? null
              : () => onDayTap(
                  DateTime(month.year, month.month, day),
                  dayPartidos,
                ),
        ),
      );
    }

    return _SectionCard(
      title: 'Calendario',
      icon: Icons.calendar_month_rounded,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy', 'es_AR').format(month),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: cells,
          ),
          const SizedBox(height: 8),
          Text(
            '${monthPartidos.length} partidos en el mes',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.day, required this.count, this.onTap});

  final int day;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: active
              ? _accent.withValues(alpha: 0.12)
              : const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _accent : const Color(0xFFDDE6E3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: const TextStyle(fontWeight: FontWeight.w900)),
            if (active)
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: _accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RivalSummary {
  RivalSummary(this.rival);

  final String rival;
  final stats = Stats();

  void add(Partido p) => stats.add(p);
}

class VenuePoint {
  VenuePoint({
    required this.name,
    required this.position,
    required this.partidos,
  });

  final String name;
  final latlong.LatLng position;
  final List<Partido> partidos;
}

class _RivalRanking extends StatelessWidget {
  const _RivalRanking({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final rivals = <String, RivalSummary>{};
    for (final p in partidos) {
      rivals.putIfAbsent(p.rival, () => RivalSummary(p.rival)).add(p);
    }
    final ranking = rivals.values.toList()
      ..sort((a, b) {
        final byPoints = (b.stats.pg * 3 + b.stats.pe).compareTo(
          a.stats.pg * 3 + a.stats.pe,
        );
        return byPoints != 0 ? byPoints : b.stats.gp.compareTo(a.stats.gp);
      });

    return _SectionCard(
      title: 'Ranking de rivales',
      icon: Icons.leaderboard_rounded,
      child: ranking.isEmpty
          ? const Text('Todavia no hay datos para rankear.')
          : Column(
              children: ranking.take(8).map((r) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    r.rival,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${r.stats.pj} PJ | ${r.stats.pg}G ${r.stats.pe}E ${r.stats.pp}P',
                  ),
                  trailing: Text(
                    '${r.stats.gp} GP',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _accent,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _TournamentMode extends StatelessWidget {
  const _TournamentMode({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final tournaments = <String, List<Partido>>{};
    for (final p in partidos.where((p) => p.tipoPartido == 'Torneo')) {
      tournaments.putIfAbsent(p.torneo, () => []).add(p);
    }

    return _SectionCard(
      title: 'Modo torneo',
      icon: Icons.account_tree_outlined,
      child: tournaments.isEmpty
          ? const Text(
              'Marca partidos como Torneo para ver fases, copas y resumen.',
            )
          : Column(
              children: tournaments.entries.map((entry) {
                final stats = Stats();
                final phases = <String, int>{};
                for (final p in entry.value) {
                  stats.add(p);
                  final label = p.copa != 'Ninguna' && p.copa.isNotEmpty
                      ? '${p.fase} - Copa ${p.copa}'
                      : p.fase;
                  phases[label] = (phases[label] ?? 0) + 1;
                }
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${stats.pj} partidos | DG ${stats.dg} | ${stats.gp} goles de jugador',
                  ),
                  children: [
                    _StatsGrid(stats: stats, compact: true),
                    const SizedBox(height: 8),
                    for (final phase in phases.entries)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(phase.key.isEmpty ? 'Sin fase' : phase.key),
                        trailing: Text('${phase.value}'),
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _ExportSection extends StatelessWidget {
  const _ExportSection({
    required this.count,
    required this.onCsv,
    required this.onPdf,
  });

  final int count;
  final VoidCallback? onCsv;
  final VoidCallback? onPdf;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Backup y exportaci\u00f3n',
      icon: Icons.ios_share_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Exporta los $count partidos filtrados.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onCsv,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('CSV'),
              ),
              OutlinedButton.icon(
                onPressed: onPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, this.compact = false});

  final Stats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('PJ', stats.pj, _ink),
      ('PG', stats.pg, Colors.green.shade700),
      ('PE', stats.pe, Colors.orange.shade800),
      ('PP', stats.pp, Colors.red.shade700),
      ('GF', stats.gf, Colors.blue.shade700),
      ('GC', stats.gc, Colors.blueGrey.shade700),
      ('DG', stats.dg, Colors.indigo.shade700),
      ('GP', stats.gp, _accent),
      ('AST', stats.asistencias, Colors.teal.shade700),
      ('FIG', stats.figuras, Colors.purple.shade700),
      ('MIN', stats.minutos, Colors.brown.shade700),
      ('TAR', stats.amarillas + stats.rojas, Colors.deepOrange.shade700),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: compact ? 1.15 : 1.05,
      children: [
        for (final item in items)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE6E3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.$1,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.$2}',
                  style: TextStyle(
                    fontSize: 22,
                    color: item.$3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GoalChart extends StatelessWidget {
  const _GoalChart({required this.partidos});

  final List<Partido> partidos;

  @override
  Widget build(BuildContext context) {
    final maxGoals = max(
      1,
      partidos.fold<int>(0, (m, p) => max(m, p.golesHijo)),
    );
    return _SectionCard(
      title: 'Goles \u00faltimos 10',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final p in partidos)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${p.golesHijo}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 22,
                    height: max(8, (p.golesHijo / maxGoals) * 92),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PartidoCard extends StatelessWidget {
  const _PartidoCard({
    required this.partido,
    required this.date,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  final Partido partido;
  final String date;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (partido.tipoPartido) {
      'Torneo' => Colors.amber.shade100,
      'Amistoso' => Colors.green.shade100,
      _ => const Color(0xFFEAF0ED),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      partido.tipoPartido,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Compartir',
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
              Text(
                partido.torneo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partido.equipo,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    partido.marcador,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      partido.rival,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Chip(icon: Icons.calendar_today_outlined, label: date),
                  _Chip(icon: Icons.flag_outlined, label: partido.temporada),
                  if (partido.cancha.isNotEmpty)
                    _Chip(icon: Icons.place_outlined, label: partido.cancha),
                  if (partido.canchaLat != null && partido.canchaLng != null)
                    const _Chip(
                      icon: Icons.map_outlined,
                      label: 'Predio ubicado',
                    ),
                  _Chip(
                    icon: Icons.stars_outlined,
                    label: '${partido.golesHijo} goles',
                  ),
                  if (partido.asistencias > 0)
                    _Chip(
                      icon: Icons.handshake_outlined,
                      label: '${partido.asistencias} asist.',
                    ),
                  if (partido.figuraPartido)
                    const _Chip(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Figura',
                    ),
                  _Chip(icon: Icons.sports_outlined, label: partido.posicion),
                ],
              ),
              if (partido.foto != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    partido.foto!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (partido.analisis.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  partido.analisis,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _str(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String _firstStr(
  Map<String, dynamic> data,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = _str(data[key]).trim();
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

DateTime? _date(dynamic value) {
  if (value is fb_firestore.Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

DateTime? _parseDateText(String raw) {
  if (raw.trim().isEmpty) return null;
  for (final format in ['dd/MM/yyyy HH:mm', 'dd/MM/yyyy']) {
    try {
      return DateFormat(format).parse(raw).toUtc();
    } catch (_) {
      continue;
    }
  }
  return null;
}

int _parseInt(String raw) => int.tryParse(raw.trim()) ?? 0;

Uint8List _compressImage(Uint8List bytes) {
  final decoded = image_lib.decodeImage(bytes);
  if (decoded == null) return bytes;
  final longest = max(decoded.width, decoded.height);
  final resized = longest > 1920
      ? image_lib.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 1920 : null,
          height: decoded.height > decoded.width ? 1920 : null,
        )
      : decoded;
  var quality = 88;
  var jpg = image_lib.encodeJpg(resized, quality: quality);
  while (jpg.length > 2 * 1024 * 1024 && quality > 35) {
    quality -= 8;
    jpg = image_lib.encodeJpg(resized, quality: quality);
  }
  return Uint8List.fromList(jpg);
}

String? _photoPathFromUrl(String? url) {
  if (url == null) return null;
  final marker = '/o/';
  final start = url.indexOf(marker);
  if (start == -1) return null;
  final end = url.indexOf('?alt=', start);
  final raw = end == -1
      ? url.substring(start + marker.length)
      : url.substring(start + marker.length, end);
  return Uri.decodeComponent(raw);
}
