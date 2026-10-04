import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'models/deporte.dart';
import 'models/hito.dart';
import 'models/jugador.dart';
import 'models/partido.dart';
import 'repositories/football_repository.dart';
import 'widgets/common_widgets.dart';
import 'widgets/photo_viewer.dart';
import 'widgets/player_widgets.dart';
import 'views/history_view.dart';
import 'views/stats_view.dart';
import 'views/gallery_view.dart';
import 'views/data_management_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Intl.defaultLocale = 'es_AR';
  runApp(const PartidosProApp());
}

class PartidosProApp extends StatelessWidget {
  const PartidosProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Partidos Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: appAccentColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF0ED),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: appFieldFillColor,
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
      home: const ResponsiveShell(child: HomePage()),
    );
  }
}

/// Contenedor responsivo que optimiza la vista en PC (Windows Desktop / Web Chrome)
/// centrando la interfaz con proporciones móviles para una experiencia idéntica al celular.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 650) {
          return Scaffold(
            backgroundColor: const Color(0xFF1B2422),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
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

  int _tab = 0; // 0: Historial, 1: Stats, 2: Cargar, 3: Galería, 4: Perfil
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  List<Jugador> _jugadores = [
    const Jugador(id: 'default', nombre: 'Mi Hijo', clubActual: 'Cosmos FC'),
  ];
  Jugador? _jugadorActivo;
  String get _playerName =>
      _jugadorActivo?.nombre ??
      (_jugadores.isNotEmpty ? _jugadores.first.nombre : 'Mi Hijo');
  List<String> get _players => _jugadores.map((j) => j.nombre).toList();
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
  final _scoreDetalle = TextEditingController();
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
      _scoreDetalle,
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
    final savedPlayersJson = prefs.getStringList('jugadores_perfiles');
    if (savedPlayersJson != null && savedPlayersJson.isNotEmpty) {
      _jugadores = savedPlayersJson.map(Jugador.fromJson).toList();
    } else {
      final savedPlayers = prefs.getStringList('jugadores');
      final legacyName = prefs.getString('nombre') ?? 'Mi Hijo';
      final names = (savedPlayers == null || savedPlayers.isEmpty)
          ? [legacyName]
          : savedPlayers;
      _jugadores = names.asMap().entries.map((e) {
        return Jugador(
          id: '${DateTime.now().millisecondsSinceEpoch}_${e.key}',
          nombre: e.value,
          clubActual: 'Cosmos FC',
          dorsal: '10',
          posicionHabitual: 'Delantero',
          colorHex: Jugador.coloresDisponibles[e.key % Jugador.coloresDisponibles.length],
        );
      }).toList();
      await _savePlayers();
    }

    final activeId = prefs.getString('jugador_activo_id');
    if (activeId != null && _jugadores.any((j) => j.id == activeId)) {
      _jugadorActivo = _jugadores.firstWhere((j) => j.id == activeId);
    } else {
      final activeName = prefs.getString('jugador_activo');
      _jugadorActivo = _jugadores.firstWhere(
        (j) => j.nombre == activeName,
        orElse: () => _jugadores.first,
      );
    }

    if (_jugadorActivo != null) {
      _profileName.text = _jugadorActivo!.nombre;
      _equipo.text = _jugadorActivo!.clubActual;
      _posicion = _jugadorActivo!.posicionHabitual;
    }

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
      if (_jugadorActivo != null) {
        if (p.nombreJugador.trim().toLowerCase() !=
            _jugadorActivo!.nombre.trim().toLowerCase()) {
          return false;
        }
      }
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
    final base = _jugadorActivo == null
        ? _partidos
        : _partidos.where(
            (p) =>
                p.nombreJugador.trim().toLowerCase() ==
                _jugadorActivo!.nombre.trim().toLowerCase(),
          );
    final values =
        base
            .map(read)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Todos', ...values];
  }

  List<String> _competitionsForType(String tipo) {
    final base = _jugadorActivo == null
        ? _partidos
        : _partidos.where(
            (p) =>
                p.nombreJugador.trim().toLowerCase() ==
                _jugadorActivo!.nombre.trim().toLowerCase(),
          );
    final filtered = tipo == 'Todos'
        ? base
        : base.where(
            (p) => p.tipoPartido.trim().toLowerCase() == tipo.trim().toLowerCase(),
          );
    final values = filtered
        .map((p) => p.torneo)
        .where((t) => t.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Todos', ...values];
  }

  List<String> _suggestions(String Function(Partido) read) {
    final values = _partidos
        .map(read)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> _suggestionsForType(String Function(Partido) read, String tipo) {
    final filtered = _partidos.where(
      (p) => p.tipoPartido.trim().toLowerCase() == tipo.trim().toLowerCase(),
    );
    final values = filtered
        .map(read)
        .map((s) => s.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values.isEmpty ? _suggestions(read) : values;
  }

  List<String> get _teamSuggestions {
    final defaultClub = _jugadorActivo?.clubActual ?? 'Cosmos FC';
    final teams = _suggestions((p) => p.equipo);
    if (!teams.contains(defaultClub)) teams.insert(0, defaultClub);
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
      _snack('Ubicación del predio guardada.');
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

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'jugadores_perfiles',
      _jugadores.map((j) => j.toJson()).toList(),
    );
    await prefs.setStringList('jugadores', _players);
    if (_jugadorActivo != null) {
      await prefs.setString('jugador_activo_id', _jugadorActivo!.id);
      await prefs.setString('jugador_activo', _jugadorActivo!.nombre);
      await prefs.setString('nombre', _jugadorActivo!.nombre);
    } else {
      await prefs.remove('jugador_activo_id');
      await prefs.setString('jugador_activo', 'Todos');
    }
  }

  void _selectPlayer(Jugador? jugador) {
    setState(() {
      _jugadorActivo = jugador;
      if (jugador != null) {
        _profileName.text = jugador.nombre;
        _equipo.text = jugador.clubActual;
        _posicion = jugador.posicionHabitual;
      }
    });
    _savePlayers();
  }

  void _selectPlayerByName(String name) {
    final match = _jugadores.where((j) => j.nombre == name).toList();
    if (match.isNotEmpty) {
      _selectPlayer(match.first);
    }
  }

  void _showPlayerForm([Jugador? existing]) {
    showDialog(
      context: context,
      builder: (ctx) => PlayerFormDialog(
        jugador: existing,
        onSave: (saved) async {
          setState(() {
            final idx = _jugadores.indexWhere((j) => j.id == saved.id);
            if (idx >= 0) {
              _jugadores[idx] = saved;
              if (_jugadorActivo?.id == saved.id) {
                _jugadorActivo = saved;
                _equipo.text = saved.clubActual;
                _posicion = saved.posicionHabitual;
              }
            } else {
              _jugadores.add(saved);
              _jugadorActivo = saved;
              _equipo.text = saved.clubActual;
              _posicion = saved.posicionHabitual;
            }
          });
          await _savePlayers();
          _snack(
            existing == null
                ? 'Jugador "${saved.nombre}" creado.'
                : 'Perfil de "${saved.nombre}" actualizado.',
          );
        },
      ),
    );
  }

  Future<void> _removeJugador(Jugador j) async {
    if (_jugadores.length <= 1) {
      _snack('No podés eliminar el único jugador registrado.', isError: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar perfil de ${j.nombre}?'),
        content: const Text(
          'El perfil del jugador se eliminará de la lista. Sus partidos anteriores permanecerán en la base de datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _jugadores.removeWhere((item) => item.id == j.id);
      if (_jugadorActivo?.id == j.id) {
        _jugadorActivo = _jugadores.first;
      }
    });
    await _savePlayers();
    _snack('Jugador eliminado.');
  }

  void _showPlayerSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlayerSwitcherModal(
        jugadores: _jugadores,
        jugadorActivo: _jugadorActivo,
        allPartidos: _partidos,
        onSelectPlayer: (j) => _selectPlayer(j),
        onSelectTodos: () => _selectPlayer(null),
        onAddPlayer: () => _showPlayerForm(null),
        onEditPlayer: (j) => _showPlayerForm(j),
      ),
    );
  }

  void _showShareStatsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SharePlayerStatsModal(
        jugadores: _jugadores,
        jugadorInicial: _jugadorActivo,
        allPartidos: _partidos,
        dateFormat: _shortDateFormat,
      ),
    );
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
    } on Exception catch (e) {
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
    } catch (_) {}
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
          text: 'Exportación CSV de Partidos Pro.',
        ),
      );
    } catch (e) {
      _snack('No pude exportar CSV: $e', isError: true);
    }
  }

  Future<void> _exportPdf(List<Partido> partidos) async {
    try {
      final activeJugador = _jugadores.firstWhere(
        (j) => j.nombre == _playerName,
        orElse: () => Jugador(
          id: _playerName,
          nombre: _playerName,
          clubActual: _teamSuggestions.firstOrNull ?? '',
        ),
      );
      final stats = Stats();
      for (final p in partidos) {
        stats.add(p);
      }
      await PlayerPdfHelper.exportDossier(
        context: context,
        jugador: activeJugador,
        stats: stats,
        matches: partidos,
        temporada: _filterTemporada == 'Todos' ? 'Todas' : _filterTemporada,
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
        'Posición',
        'Penales',
        'Penales Favor',
        'Penales Contra',
        'Penal Jugador',
        'Análisis',
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
      _removeCurrentPhoto = false;
    });
  }

  Future<void> _save() async {
    if (_torneo.text.trim().isEmpty || _rival.text.trim().isEmpty) {
      _snack('Completá evento y rival para guardar.', isError: true);
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

      final activeJugador = _jugadores.firstWhere(
        (j) => j.nombre == _playerName,
        orElse: () => Jugador(id: _playerName, nombre: _playerName, clubActual: _equipo.text),
      );
      final currentSport = _editing?.deporte ?? activeJugador.deporte;
      final defaultClub = currentSport == 'futbol' ? 'Cosmos FC' : '';

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
        equipo: _equipo.text.trim().isEmpty ? defaultClub : _equipo.text.trim(),
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
        deporte: currentSport,
        scoreDetalle: _scoreDetalle.text.trim().isEmpty ? null : _scoreDetalle.text.trim(),
      );

      await _repo.savePartido(partido);
      _clearForm();
      await _loadPartidos();
      setState(() => _tab = 0); // Vuelve al Historial
      _snack(_editing == null ? 'Partido guardado.' : 'Partido actualizado.');
    } catch (e) {
      _snack('No pude guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleBatchUpdatePartidos(
    List<Partido> updatedPartidos,
    String message,
  ) async {
    await _repo.updatePartidosBatch(updatedPartidos);
    setState(() {
      for (final updated in updatedPartidos) {
        final idx = _partidos.indexWhere((p) =>
            (p.documentName != null && p.documentName == updated.documentName) ||
            (p.id != null && p.id == updated.id));
        if (idx != -1) {
          _partidos[idx] = updated;
        }
      }
      if (_editing != null) {
        final updatedEdit = updatedPartidos.where((p) =>
            (p.documentName != null && p.documentName == _editing!.documentName) ||
            (p.id != null && p.id == _editing!.id)).firstOrNull;
        if (updatedEdit != null) {
          _editing = updatedEdit;
        }
      }
    });
    _snack(message);
  }

  void _edit(Partido p) {
    setState(() {
      _editing = p;
      final playerMatch = _jugadores.where((j) => j.nombre == p.nombreJugador).toList();
      if (playerMatch.isNotEmpty) {
        _jugadorActivo = playerMatch.first;
      }
      _profileName.text = p.nombreJugador;
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
      _scoreDetalle.text = p.scoreDetalle ?? '';
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
      _removeCurrentPhoto = false;
      _tab = 2; // Va a la pestaña Cargar/Editar
    });
  }

  void _clearForm() {
    _editing = null;
    _torneo.clear();
    _temporada.text = '${DateTime.now().year}';
    _equipo.text = _jugadorActivo?.clubActual.isNotEmpty == true
        ? _jugadorActivo!.clubActual
        : (_jugadorActivo?.sportConfig.id == 'futbol' ? 'Cosmos FC' : '');
    _rival.clear();
    _cancha.clear();
    _canchaLat = null;
    _canchaLng = null;
    _analisis.clear();
    _scoreHijo.text = '0';
    _scoreRival.text = '0';
    _scoreDetalle.clear();
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
    _posicion = _jugadorActivo?.posicionHabitual ?? (_jugadorActivo?.sportConfig.posicionesDisponibles.first ?? 'Delantero');
    _penalHijo = 'No pateo';
    _penales = false;
    _figuraPartido = false;
    _goles = 0;
    _selectedPhotoBytes = null;
    _removeCurrentPhoto = false;
  }

  Future<void> _delete(Partido p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: const Text('Esta acción no se puede deshacer.'),
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
      'Posición: ${p.posicion}',
      if (p.analisis.isNotEmpty) 'Análisis: ${p.analisis}',
    ].join('\n');
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPartidos;
    final hitosPorPartido = HitoDetector.calcularHitosPorPartido(filtered);
    final efemerides = HitoDetector.detectarEfemerides(filtered);

    final pages = [
      // 0: HISTORIAL
      HistoryView(
        key: const PageStorageKey('tab_history_view'),
        partidos: filtered,
        allPartidos: _partidos,
        hitosPorPartido: hitosPorPartido,
        efemerides: efemerides,
        search: _search,
        filterResultado: _filterResultado,
        filterTipo: _filterTipo,
        winningStreak: _winningStreak(filtered),
        playerName: _playerName,
        dateFormat: _shortDateFormat,
        onRefresh: _loadPartidos,
        onSearchChanged: (v) => setState(() => _search = v),
        onResultadoChanged: (v) => setState(() => _filterResultado = v),
        onTipoChanged: (v) {
          setState(() {
            _filterTipo = v;
            final availableComps = _competitionsForType(v);
            if (_filterTorneo != 'Todos' &&
                !availableComps.contains(_filterTorneo)) {
              _filterTorneo = 'Todos';
            }
          });
        },
        onClearFilters: _clearFilters,
        onOpenFiltersModal: _showFiltersModal,
        onOpenDetail: _showPartidoDetail,
        onEdit: _edit,
        onDelete: _delete,
        onShare: _share,
        onNewMatch: () {
          _clearForm();
          setState(() => _tab = 2);
        },
      ),

      // 1: ESTADÍSTICAS
      StatsView(
        key: const PageStorageKey('tab_stats_view'),
        partidos: filtered,
        allPartidos: _partidos,
        playerName: _playerName,
        winningStreak: _winningStreak(filtered),
        calendarMonth: _calendarMonth,
        dateFormat: _shortDateFormat,
        onRefresh: _loadPartidos,
        onShareStats: _showShareStatsModal,
        onOpenDetail: _showPartidoDetail,
        onPrevMonth: () => setState(
          () => _calendarMonth = DateTime(
            _calendarMonth.year,
            _calendarMonth.month - 1,
          ),
        ),
        onNextMonth: () => setState(
          () => _calendarMonth = DateTime(
            _calendarMonth.year,
            _calendarMonth.month + 1,
          ),
        ),
        onDayTap: _showDayPartidos,
        onExportCsv: filtered.isEmpty ? null : () => _exportCsv(filtered),
        onExportPdf: filtered.isEmpty ? null : () => _exportPdf(filtered),
      ),

      // 2: CARGAR / EDITAR PARTIDO
      _buildForm(),

      // 3: GALERÍA DE FOTOS
      GalleryView(
        key: const PageStorageKey('tab_gallery_view'),
        partidos: filtered,
        dateFormat: _shortDateFormat,
        onRefresh: _loadPartidos,
        onOpenDetail: _showPartidoDetail,
      ),

      // 4: PERFIL Y PREDIOS
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: PlayerBadge(
          jugadorActivo: _jugadorActivo,
          totalJugadores: _jugadores.length,
          onTap: _showPlayerSelectorModal,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Compartir Ficha Deportiva',
            onPressed: _showShareStatsModal,
            icon: const Icon(Icons.share_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: _loading ? null : _loadPartidos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SharedAxisTabSwitcher(
                currentIndex: _tab,
                children: pages,
              ),
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _clearForm();
                setState(() => _tab = 2);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nuevo Partido',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: appAccentColor,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) {
          HapticFeedback.selectionClick();
          setState(() => _tab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box_rounded),
            label: 'Cargar',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library_rounded),
            label: 'Galería',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _showFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: appAccentColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Filtros de Búsqueda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            _clearFilters();
                            setModalState(() {});
                            setState(() {});
                          },
                          child: const Text('Limpiar todo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _filterDropdownModal(
                      'Resultado',
                      _filterResultado,
                      ['Todos', 'Ganados', 'Empatados', 'Perdidos'],
                      (v) {
                        setState(() => _filterResultado = v);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _filterDropdownModal(
                      'Tipo de Partido',
                      _filterTipo,
                      ['Todos', 'Liga', 'Torneo', 'Amistoso'],
                      (v) {
                        setState(() {
                          _filterTipo = v;
                          final availableComps = _competitionsForType(v);
                          if (_filterTorneo != 'Todos' &&
                              !availableComps.contains(_filterTorneo)) {
                            _filterTorneo = 'Todos';
                          }
                        });
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _filterDropdownModal(
                      'Torneo / Evento',
                      _filterTorneo,
                      _competitionsForType(_filterTipo),
                      (v) {
                        setState(() => _filterTorneo = v);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _filterDropdownModal(
                      'Rival',
                      _filterRival,
                      _uniqueValues((p) => p.rival),
                      (v) {
                        setState(() => _filterRival = v);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _filterDropdownModal(
                      'Posición en Cancha',
                      _filterPosicion,
                      _uniqueValues((p) => p.posicion),
                      (v) {
                        setState(() => _filterPosicion = v);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _filterDropdownModal(
                      'Temporada',
                      _filterTemporada,
                      _uniqueValues((p) => p.temporada),
                      (v) {
                        setState(() => _filterTemporada = v);
                        setModalState(() {});
                      },
                    ),
                    if (_availableYears.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _filterDropdownModal(
                        'Año',
                        _filterYear != null ? '${_filterYear!}' : 'Todos',
                        ['Todos', ..._availableYears.map((y) => '$y')],
                        (v) {
                          setState(() => _filterYear = int.tryParse(v));
                          setModalState(() {});
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Ver ${_filteredPartidos.length} partidos'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _filterDropdownModal(
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
                leading: const Icon(Icons.sports_soccer_rounded, color: appAccentColor),
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
    final resultColor = p.gano
        ? const Color(0xFF087C63)
        : (p.empato ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    final resultText = p.gano ? 'VICTORIA' : (p.empato ? 'EMPATE' : 'DERROTA');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // Banner con foto interactiva
                if (p.foto != null) ...[
                  GestureDetector(
                    onTap: () {
                      FullScreenImageViewer.show(
                        context,
                        imageUrl: p.foto!,
                        title: '${p.equipo} ${p.marcador} ${p.rival}',
                        subtitle: '${p.torneo} • ${p.fechaTexto}',
                        badge: resultText,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.network(
                            p.foto!,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ver pantalla completa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (p.esCampeon) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFB45309),
                          Color(0xFFF59E0B),
                          Color(0xFFD97706),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡CAMPEÓN DEL TORNEO!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Final ganada • ${p.torneo}${p.copa.isNotEmpty && p.copa != 'Ninguna' ? ' (Copa ${p.copa})' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (p.esSubcampeon) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF334155), Color(0xFF64748B)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64748B).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🥈', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SUBCAMPEÓN DEL TORNEO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Final disputada • ${p.torneo}${p.copa.isNotEmpty && p.copa != 'Ninguna' ? ' (Copa ${p.copa})' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Resultado y evento
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: resultColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resultText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.torneo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: appInkColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Marcador grande
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDDE6E3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.equipo,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              p.marcador,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: resultColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p.rival,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      if (p.penales) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Definición por penales: ${p.scorePenalesEquipo} a ${p.scorePenalesRival}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rendimiento individual y detalles
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PartidoChip(icon: Icons.calendar_today_outlined, label: p.fechaTexto),
                    PartidoChip(icon: Icons.flag_outlined, label: 'Temp ${p.temporada}'),
                    if (p.cancha.isNotEmpty)
                      PartidoChip(icon: Icons.place_outlined, label: p.cancha),
                    if (p.canchaLat != null && p.canchaLng != null)
                      const PartidoChip(icon: Icons.map_outlined, label: 'Predio ubicado'),
                    PartidoChip(icon: Icons.sports_outlined, label: p.posicion),
                    PartidoChip(icon: Icons.stars_outlined, label: '${p.golesHijo} goles'),
                    if (p.asistencias > 0)
                      PartidoChip(icon: Icons.handshake_outlined, label: '${p.asistencias} asist.'),
                    if (p.minutosJugados > 0)
                      PartidoChip(icon: Icons.timer_outlined, label: '${p.minutosJugados} min'),
                    if (p.figuraPartido)
                      const PartidoChip(
                        icon: Icons.workspace_premium_outlined,
                        label: '🌟 Figura del partido',
                      ),
                    if (p.tarjetasAmarillas > 0)
                      PartidoChip(
                        icon: Icons.square,
                        label: '${p.tarjetasAmarillas} amarilla',
                      ),
                    if (p.tarjetasRojas > 0)
                      PartidoChip(
                        icon: Icons.square,
                        label: '${p.tarjetasRojas} roja',
                      ),
                  ],
                ),

                if (p.analisis.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Análisis del partido:',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      p.analisis,
                      style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Botones de acción
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

  Widget _buildForm() {
    final activeJugador = _jugadores.firstWhere(
      (j) => j.nombre == _playerName,
      orElse: () => Jugador(id: _playerName, nombre: _playerName, clubActual: _equipo.text),
    );
    final sport = _editing != null
        ? SportConfig.fromId(_editing!.deporte)
        : activeJugador.sportConfig;

    final recentRivals = _suggestions((p) => p.rival).take(6).toList();

    return ListView(
      key: const PageStorageKey('tab_form_view'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
      children: [
        // Cabecera compacta con Jugador Activo
        Header(
          title: _editing == null ? 'Cargar Partido' : 'Editar Partido',
          subtitle: _editing == null
              ? 'Carga rápida en 30 segundos. Completá lo indispensable y guardá.'
              : 'Editando encuentro contra ${_editing!.rival}.',
        ),

        // Banner del jugador en vista con opción de cambio rápido
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: activeJugador.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: activeJugador.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              PlayerAvatar(jugador: activeJugador, size: 38, showDorsal: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeJugador.nombre,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: activeJugador.color,
                      ),
                    ),
                    Text(
                      '${sport.emoji} ${sport.nombre} • ${activeJugador.clubActual.isNotEmpty ? activeJugador.clubActual : "Perfil deportivo"}',
                      style: const TextStyle(fontSize: 12, color: appMutedColor),
                    ),
                  ],
                ),
              ),
              if (_players.length > 1)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.swap_horiz_rounded, color: appAccentColor),
                  tooltip: 'Cambiar jugador',
                  onSelected: _selectPlayerByName,
                  itemBuilder: (context) => _players.map((pName) {
                    return PopupMenuItem(
                      value: pName,
                      child: Text(
                        pName,
                        style: TextStyle(
                          fontWeight: pName == _playerName ? FontWeight.bold : FontWeight.normal,
                          color: pName == _playerName ? appAccentColor : appInkColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),

        // SECCIÓN 1: CARGA ULTRARRÁPIDA (LO INDISPENSABLE)
        SectionCard(
          title: 'Resultado del Partido',
          icon: Icons.bolt_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Rival y chips frecuentes
              _suggestField(
                sport.labelRival,
                controller: _rival,
                options: _suggestions((p) => p.rival),
              ),
              if (recentRivals.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        '${sport.labelRival} frecuente: ',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appMutedColor),
                      ),
                      for (final r in recentRivals)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(r, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              setState(() {
                                _rival.text = r;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 2. Marcador con botones +/- (Steppers) y Detalle de sets si aplica
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: appFieldFillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDE6E3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: _matchScoreStepper(
                            label: sport.soportaSets
                                ? 'Sets ${_equipo.text.trim().isEmpty ? _playerName : _equipo.text.trim()}'
                                : (_equipo.text.trim().isEmpty ? _playerName : _equipo.text.trim()),
                            controller: _scoreHijo,
                            color: appAccentColor,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: appInkColor,
                            ),
                          ),
                        ),
                        Flexible(
                          child: _matchScoreStepper(
                            label: sport.soportaSets
                                ? 'Sets ${sport.labelRival}'
                                : (_rival.text.trim().isEmpty ? sport.labelRival : _rival.text.trim()),
                            controller: _scoreRival,
                            color: const Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                    if (sport.soportaSets) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _scoreDetalle,
                        decoration: const InputDecoration(
                          labelText: 'Detalle de Sets (games)',
                          hintText: 'Ej: 6-4, 3-6, 7-6',
                          prefixIcon: Icon(Icons.scoreboard_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final preset in const [
                              ('2-0', '6-4, 6-3', 2, 0),
                              ('2-1', '6-4, 3-6, 6-4', 2, 1),
                              ('2-0', '6-2, 6-1', 2, 0),
                              ('1-2', '4-6, 6-3, 3-6', 1, 2),
                              ('0-2', '3-6, 4-6', 0, 2),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text('${preset.$1} (${preset.$2})', style: const TextStyle(fontSize: 11)),
                                  onPressed: () {
                                    setState(() {
                                      _scoreHijo.text = '${preset.$3}';
                                      _scoreRival.text = '${preset.$4}';
                                      _scoreDetalle.text = preset.$2;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Anotaciones de Salvador / Jugador (Goles, Tries, Puntos)
              if (!sport.soportaSets) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE6E3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(sport.icono, color: appAccentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${sport.labelAnotacionHijo} de $_playerName:',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: _goles == 0 ? null : () => setState(() => _goles--),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Container(
                            width: 38,
                            alignment: Alignment.center,
                            child: Text(
                              '$_goles',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: appAccentColor,
                              ),
                            ),
                          ),
                          IconButton.filled(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () {
                              setState(() {
                                _goles++;
                                final sc = int.tryParse(_scoreHijo.text) ?? 0;
                                if (sc < _goles && sport.sistemaMarcador == SistemaMarcador.goles) {
                                  _scoreHijo.text = '$_goles';
                                }
                              });
                            },
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Chips de un solo toque para anotaciones
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final g in (sport.id == 'basquet'
                                ? [0, 5, 10, 15, 20]
                                : [0, 1, 2, 3, 4]))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    g == 0
                                        ? '0 ${sport.labelAnotacionHijo.toLowerCase()}'
                                        : (sport.id == 'basquet'
                                            ? '🏀 $g pts'
                                            : (g == 3
                                                ? '🎩 3'
                                                : (g == 4
                                                    ? '⚡ 4+'
                                                    : '${sport.emoji} $g'))),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _goles == g ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  selected: _goles == g,
                                  onSelected: (_) {
                                    setState(() {
                                      _goles = g;
                                      final sc = int.tryParse(_scoreHijo.text) ?? 0;
                                      if (sc < g && sport.sistemaMarcador == SistemaMarcador.goles) {
                                        _scoreHijo.text = '$g';
                                      }
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 4. Tipo de partido y Torneo
              _choiceRow(
                'Tipo',
                ['Torneo', 'Liga', 'Amistoso'],
                _tipoPartido,
                (v) => setState(() => _tipoPartido = v),
              ),
              const SizedBox(height: 10),
              _suggestField(
                'Torneo / Evento',
                controller: _torneo,
                options: _suggestionsForType((p) => p.torneo, _tipoPartido),
              ),
              const SizedBox(height: 18),

              // 5. BOTÓN PRINCIPAL DE GUARDADO INMEDIATO
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: appAccentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: Text(
                  _editing == null ? '⚡ Guardar Partido (Rápido)' : 'Actualizar Partido',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),

        // SECCIÓN 2: MÁS DETALLES Y ESTADÍSTICAS (ACORDEÓN DESPLEGABLE)
        Container(
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE6E3)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: PageStorage(
              bucket: PageStorageBucket(),
              child: ExpansionTile(
                initiallyExpanded: _editing != null,
                maintainState: true,
                leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appAccentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: appAccentColor),
              ),
              title: const Text(
                'Más detalles y estadísticas',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: appInkColor),
              ),
              subtitle: const Text(
                'Cancha, fase, penales, asistencias, minutos, tarjetas, notas y fotos',
                style: TextStyle(fontSize: 12, color: appMutedColor),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                const Divider(height: 24),

                // Subsección A: Cancha, Fecha y Temporada
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
                      decoration: const InputDecoration(labelText: 'Fecha y hora'),
                      child: Text(
                        _dateFormat.format(_matchDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _adaptivePair(
                  _suggestField(
                    'Temporada',
                    controller: _temporada,
                    options: _suggestions((p) => p.temporada),
                  ),
                  _suggestField(
                    sport.labelEquipo == 'Equipo'
                        ? 'Equipo de $_playerName'
                        : '${sport.labelEquipo} de $_playerName',
                    controller: _equipo,
                    options: _teamSuggestions,
                    showAllOnTap: true,
                  ),
                ),
                const SizedBox(height: 12),
                _venueLocationBar(),

                // Subsección B: Fase de torneo y penales
                if (_tipoPartido == 'Torneo') ...[
                  const SizedBox(height: 16),
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
                if (sport.soportaPenales) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _penales,
                    onChanged: (v) => setState(() => _penales = v),
                    title: const Text(
                      'Definición por penales',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_penales)
                    _adaptiveTriple(
                      TextField(
                        controller: _penalesEquipo,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Penales equipo'),
                      ),
                      TextField(
                        controller: _penalesRival,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Penales rival'),
                      ),
                      _dropdown('Penal pateado', _penalHijo, [
                        'No pateo',
                        'Anoto',
                        'Erro',
                      ], (v) => setState(() => _penalHijo = v)),
                    ),
                ],

                const SizedBox(height: 16),
                const Divider(height: 24),

                // Subsección C: Rendimiento individual (Posición, Asistencias, Minutos, Tarjetas)
                _dropdown(
                  'Posición',
                  sport.posicionesDisponibles.contains(_posicion)
                      ? _posicion
                      : sport.posicionesDisponibles.first,
                  sport.posicionesDisponibles,
                  (v) => setState(() => _posicion = v),
                ),
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
                    decoration: const InputDecoration(labelText: 'Minutos jugados'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _figuraPartido,
                    onChanged: (v) => setState(() => _figuraPartido = v),
                    title: const Text('¿Fue figura?', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                if (sport.soportaTarjetas) ...[
                  const SizedBox(height: 12),
                  _adaptivePair(
                    TextField(
                      controller: _amarillas,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarjetas amarillas'),
                    ),
                    TextField(
                      controller: _rojas,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarjetas rojas'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _analisis,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notas y análisis del partido',
                    hintText: 'Comentarios, jugadas destacadas, etc.',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final template in const [
                      'Buen pase',
                      'Presión alta',
                      'Asistencia',
                      'Definición',
                      'Actitud',
                      'Marca',
                      'Recuperación',
                      'Trabajo en equipo',
                    ])
                      ActionChip(
                        label: Text(template),
                        onPressed: () => _appendAnalysisTemplate(template),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 24),

                // Subsección D: Foto del encuentro
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto del partido',
                    style: TextStyle(fontWeight: FontWeight.w800, color: appInkColor, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _selectedPhotoBytes != null || (_editing?.foto != null && !_removeCurrentPhoto)
                          ? 'Cambiar foto'
                          : 'Seleccionar foto',
                    ),
                  ),
                ),
                if (_selectedPhotoBytes != null ||
                    (_editing?.foto != null && !_removeCurrentPhoto)) ...[
                  const SizedBox(height: 12),
                  _photoPreview(),
                ],

                const SizedBox(height: 20),

                // Botón al pie del acordeón
                Row(
                  children: [
                    if (_editing != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(_clearForm),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _editing == null ? 'Guardar con Detalles' : 'Actualizar Partido',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
      ],
    );
  }

  Widget _buildProfile() {
    final venues = _venuePoints;
    final center = venues.isEmpty
        ? const latlong.LatLng(-34.6037, -58.3816)
        : venues.first.position;
    final travelKm = _travelKm(_partidos);

    return ListView(
      key: const PageStorageKey('tab_profile_view'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        const Header(
          title: 'Perfil & Herramientas',
          subtitle: 'Administrá jugadores, predios y sincronización.',
        ),

        // Jugadores
        SectionCard(
          title: 'Perfiles de Jugadores',
          icon: Icons.groups_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cada jugador cuenta con estadísticas, goles, clubes y palmarés independientes.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              for (final j in _jugadores) ...[
                Builder(
                  builder: (context) {
                    final isActivo = _jugadorActivo?.id == j.id;
                    final matches = _partidos
                        .where((p) => p.nombreJugador == j.nombre)
                        .toList();
                    final stats = Stats.fromPartidos(matches);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActivo
                            ? appAccentColor.withValues(alpha: 0.06)
                            : appFieldFillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActivo
                              ? appAccentColor
                              : const Color(0xFFDDE6E3),
                          width: isActivo ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(jugador: j, size: 44, showDorsal: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        j.nombreDisplay,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isActivo) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: appAccentColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'EN VISTA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  j.subtituloDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${stats.pj} partidos • ${stats.gp} goles'
                                  '${stats.campeonatos > 0 ? " • ${stats.campeonatos} 🏆" : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar jugador',
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showPlayerForm(j),
                          ),
                          if (!isActivo)
                            IconButton(
                              tooltip: 'Ver estadísticas de este jugador',
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 22,
                                color: appAccentColor,
                              ),
                              onPressed: () => _selectPlayer(j),
                            )
                          else if (_jugadores.length > 1)
                            IconButton(
                              tooltip: 'Eliminar jugador',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () => _removeJugador(j),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPlayerForm(null),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Nuevo Jugador'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _showShareStatsModal,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartir Ficha'),
                      style: FilledButton.styleFrom(
                        backgroundColor: appAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mapa de predios
        SectionCard(
          title: 'Mapa de predios',
          icon: Icons.map_outlined,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniCardStat(label: 'Predios', value: '${venues.length}'),
                  _MiniCardStat(
                    label: 'Partidos ubicados',
                    value: '${_partidos.where((p) => p.canchaLat != null && p.canchaLng != null).length}',
                  ),
                  _MiniCardStat(label: 'Km recorridos', value: travelKm.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 300,
                  child: venues.isEmpty
                      ? const Center(
                          child: Text(
                            'Cuando guardes la ubicación de un predio, va a aparecer acá.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : FlutterMap(
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
                                    width: 48,
                                    height: 48,
                                    child: GestureDetector(
                                      onTap: () => _showVenueDetail(venue),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: appAccentColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${venue.partidos.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
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
            ],
          ),
        ),

        // Gestión y Depuración de Datos
        SectionCard(
          title: 'Depuración y Gestión de Datos',
          icon: Icons.auto_fix_high_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Corregí nombres con errores de tipeo, unificá torneos duplicados, renombrá predios o rivales, y actualizá ubicaciones GPS en lote.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DataManagementView(
                          partidos: _partidos,
                          onUpdatePartidos: _handleBatchUpdatePartidos,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: const Text(
                    'Abrir Gestor de Datos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cuenta y sincronización
        SectionCard(
          title: 'Cuenta y Sincronización',
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
              const SizedBox(height: 12),
              SecurityRow(
                label: 'Sesión',
                value: _repo.currentUser?.isAnonymous == false
                    ? 'Email'
                    : 'Anónima segura',
                color: appAccentColor,
              ),
            ],
          ),
        ),

        // Backup automático
        SectionCard(
          title: 'Backup automático',
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
            title: const Text('Guardar CSV diario en el dispositivo'),
            subtitle: const Text('Se actualiza al abrir o refrescar la app.'),
          ),
        ),
      ],
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
                leading: const Icon(Icons.sports_soccer_rounded, color: appAccentColor),
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

  Widget _photoPreview() {
    Widget image;
    if (_selectedPhotoBytes != null) {
      image = Image.memory(
        _selectedPhotoBytes!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      image = Image.network(
        _editing!.foto!,
        height: 160,
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
        color: appFieldFillColor,
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
                color: appAccentColor,
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


  Widget _matchScoreStepper({
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    final val = int.tryParse(controller.text) ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: appInkColor,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: val <= 0
                  ? null
                  : () {
                      setState(() {
                        controller.text = '${val - 1}';
                      });
                    },
              icon: const Icon(Icons.remove_rounded),
            ),
            Container(
              width: 38,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  isDense: true,
                ),
              ),
            ),
            IconButton.filled(
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: () {
                setState(() {
                  controller.text = '${val + 1}';
                });
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adaptivePair(
    Widget first,
    Widget second, {
    int firstFlex = 1,
    int secondFlex = 1,
    double breakpoint = 390,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < breakpoint) {
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
  }

  Widget _adaptiveTriple(Widget first, Widget second, Widget third) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 470) {
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
  }

  Widget _suggestField(
    String label, {
    required TextEditingController controller,
    required List<String> options,
    bool showAllOnTap = false,
    ValueChanged<String>? onSelectedValue,
    ValueChanged<String>? onChangedValue,
  }) {
    return SuggestField(
      label: label,
      controller: controller,
      options: options,
      showAllOnTap: showAllOnTap,
      onSelectedValue: onSelectedValue,
      onChangedValue: onChangedValue,
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
        backgroundColor: isError ? Colors.red.shade700 : appAccentColor,
      ),
    );
  }
}

class SuggestField extends StatefulWidget {
  const SuggestField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    this.showAllOnTap = false,
    this.onSelectedValue,
    this.onChangedValue,
  });

  final String label;
  final TextEditingController controller;
  final List<String> options;
  final bool showAllOnTap;
  final ValueChanged<String>? onSelectedValue;
  final ValueChanged<String>? onChangedValue;

  @override
  State<SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<SuggestField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      focusNode: _focusNode,
      textEditingController: widget.controller,
      optionsBuilder: (text) {
        final query = text.text.toLowerCase().trim();
        if (query.isEmpty) {
          return widget.showAllOnTap ? widget.options : const Iterable<String>.empty();
        }
        final startsWith = <String>[];
        final contains = <String>[];
        for (final option in widget.options) {
          final optLower = option.toLowerCase().trim();
          if (optLower.startsWith(query)) {
            startsWith.add(option);
          } else if (optLower.contains(query)) {
            contains.add(option);
          }
        }
        return [...startsWith, ...contains];
      },
      onSelected: (value) {
        widget.controller.text = value;
        widget.onSelectedValue?.call(value);
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return ListenableBuilder(
          listenable: textController,
          builder: (context, _) {
            return TextField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (textController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          textController.clear();
                          widget.onChangedValue?.call('');
                        },
                      ),
                    if (widget.options.isNotEmpty)
                      IconButton(
                        tooltip: 'Ver opciones',
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onPressed: () {
                          focusNode.requestFocus();
                          if (textController.text.isNotEmpty) {
                            textController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: textController.text.length,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              onChanged: (value) {
                widget.onChangedValue?.call(value);
              },
              onSubmitted: (_) => onSubmitted(),
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, values) {
        final labelLower = widget.label.toLowerCase();
        final IconData leadingIcon;
        if (labelLower.contains('cancha') || labelLower.contains('predio')) {
          leadingIcon = Icons.location_on_outlined;
        } else if (labelLower.contains('rival')) {
          leadingIcon = Icons.shield_outlined;
        } else if (labelLower.contains('torneo')) {
          leadingIcon = Icons.emoji_events_outlined;
        } else if (labelLower.contains('equipo')) {
          leadingIcon = Icons.sports_soccer_outlined;
        } else {
          leadingIcon = Icons.search_rounded;
        }

        return PageStorage(
          bucket: PageStorageBucket(),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280, maxWidth: 360),
                child: Scrollbar(
                  child: ListView.builder(
                    primary: false,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      final value = values.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: Icon(leadingIcon, size: 18, color: appAccentColor),
                        title: Text(
                          value,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(value),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniCardStat extends StatelessWidget {
  const _MiniCardStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: appFieldFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6E3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: appAccentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
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

int _parseInt(String raw) => int.tryParse(raw.trim()) ?? 0;

String? _photoPathFromUrl(String? url) {
  if (url == null) return null;
  const marker = '/o/';
  final start = url.indexOf(marker);
  if (start == -1) return null;
  final end = url.indexOf('?alt=', start);
  final raw = end == -1
      ? url.substring(start + marker.length)
      : url.substring(start + marker.length, end);
  return Uri.decodeComponent(raw);
}
