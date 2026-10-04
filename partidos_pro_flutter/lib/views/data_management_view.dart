import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/partido.dart';
import '../widgets/common_widgets.dart';

class DataManagementView extends StatefulWidget {
  const DataManagementView({
    super.key,
    required this.partidos,
    required this.onUpdatePartidos,
  });

  final List<Partido> partidos;
  final Future<void> Function(List<Partido> updatedPartidos, String message)
      onUpdatePartidos;

  @override
  State<DataManagementView> createState() => _DataManagementViewState();
}

class _DataManagementViewState extends State<DataManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Mapeos y agrupaciones ---

  Map<String, List<Partido>> get _torneosMap {
    final map = <String, List<Partido>>{};
    for (final p in widget.partidos) {
      final name = p.torneo.trim().isEmpty ? 'Sin torneo' : p.torneo.trim();
      map.putIfAbsent(name, () => []).add(p);
    }
    return map;
  }

  Map<String, List<Partido>> get _canchasMap {
    final map = <String, List<Partido>>{};
    for (final p in widget.partidos) {
      final name = p.cancha.trim().isEmpty ? 'Sin predio' : p.cancha.trim();
      map.putIfAbsent(name, () => []).add(p);
    }
    return map;
  }

  Map<String, List<Partido>> get _rivalesMap {
    final map = <String, List<Partido>>{};
    for (final p in widget.partidos) {
      final name = p.rival.trim().isEmpty ? 'Sin rival' : p.rival.trim();
      map.putIfAbsent(name, () => []).add(p);
    }
    return map;
  }

  ({double lat, double lng})? _getVenueCoords(String venueName) {
    final matches = _canchasMap[venueName] ?? [];
    for (final p in matches) {
      if (p.canchaLat != null && p.canchaLng != null) {
        return (lat: p.canchaLat!, lng: p.canchaLng!);
      }
    }
    return null;
  }

  // --- Diálogos de acción ---

  Future<void> _handleAction(
    Future<void> Function() action,
  ) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar datos: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 1. Torneos: Renombrar
  void _showRenameTorneoDialog(String currentTorneo, List<Partido> matches) {
    final textController = TextEditingController(text: currentTorneo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: appAccentColor),
            SizedBox(width: 8),
            Text('Renombrar Torneo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modificar el nombre en los ${matches.length} partido(s) registrados con este torneo:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nuevo nombre de torneo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isEmpty || newName == currentTorneo) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              await _handleAction(() async {
                final updated = matches.map((p) => p.copyWith(torneo: newName)).toList();
                await widget.onUpdatePartidos(
                  updated,
                  'Torneo renombrado a "$newName" en ${matches.length} partidos.',
                );
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // 1. Torneos: Unificar / Fusionar
  void _showMergeTorneoDialog(String sourceTorneo, List<Partido> matches) {
    final otherTorneos = _torneosMap.keys
        .where((t) => t.toLowerCase() != sourceTorneo.toLowerCase())
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (otherTorneos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay otros torneos disponibles para unificar.')),
      );
      return;
    }

    String selectedTarget = otherTorneos.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.call_merge_rounded, color: appAccentColor),
              SizedBox(width: 8),
              Text('Unificar Torneo'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(ctx).style.copyWith(fontSize: 13),
                    children: [
                      const TextSpan(text: 'Se transferirán los '),
                      TextSpan(
                        text: '${matches.length} partido(s)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' de "'),
                      TextSpan(
                        text: sourceTorneo,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: appAccentColor),
                      ),
                      const TextSpan(text: '" hacia el torneo seleccionado:'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedTarget,
                  decoration: const InputDecoration(
                    labelText: 'Torneo de destino',
                    border: OutlineInputBorder(),
                  ),
                  items: otherTorneos
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedTarget = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    'El nombre "$sourceTorneo" dejará de existir al quedar sin partidos.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: appAccentColor),
              onPressed: () async {
                Navigator.pop(ctx);
                await _handleAction(() async {
                  final updated =
                      matches.map((p) => p.copyWith(torneo: selectedTarget)).toList();
                  await widget.onUpdatePartidos(
                    updated,
                    'Se unificaron ${matches.length} partidos en "$selectedTarget".',
                  );
                });
              },
              child: const Text('Unificar'),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Predios: Renombrar / Unificar
  void _showRenameOrMergeCanchaDialog(String currentCancha, List<Partido> matches) {
    final textController = TextEditingController(text: currentCancha);
    final otherCanchas = _canchasMap.keys
        .where((c) => c.toLowerCase() != currentCancha.toLowerCase())
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_location_alt_rounded, color: appAccentColor),
            SizedBox(width: 8),
            Text('Predio / Cancha'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modificar el nombre o fusionar los ${matches.length} partido(s) jugados en "$currentCancha":',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del predio',
                  border: OutlineInputBorder(),
                ),
              ),
              if (otherCanchas.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'O unificar con un predio existente:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar predio destino',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.call_merge_rounded, color: appAccentColor),
                  ),
                  hint: const Text('Elegir entre todos los predios...'),
                  items: otherCanchas
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      textController.text = val;
                    }
                  },
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 130),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: otherCanchas.map((c) {
                          return ActionChip(
                            label: Text(c, style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              textController.text = c;
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isEmpty || newName == currentCancha) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);

              final targetCoords = _getVenueCoords(newName);
              await _handleAction(() async {
                final updated = matches.map((p) {
                  return p.copyWith(
                    cancha: newName,
                    canchaLat: targetCoords?.lat ?? p.canchaLat,
                    canchaLng: targetCoords?.lng ?? p.canchaLng,
                  );
                }).toList();
                await widget.onUpdatePartidos(
                  updated,
                  'Predio actualizado a "$newName" en ${matches.length} partidos.',
                );
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // 2. Predios: Editar Ubicación GPS
  void _showEditLocationDialog(String canchaName, List<Partido> matches) {
    final current = _getVenueCoords(canchaName);
    final latController =
        TextEditingController(text: current?.lat != null ? '${current!.lat}' : '');
    final lngController =
        TextEditingController(text: current?.lng != null ? '${current!.lng}' : '');
    bool isCapturingGps = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.pin_drop_rounded, color: appAccentColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Ubicación: $canchaName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esta ubicación se aplicará a los ${matches.length} partido(s) disputados en este predio.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: isCapturingGps
                      ? null
                      : () async {
                          setDialogState(() => isCapturingGps = true);
                          try {
                            final serviceEnabled =
                                await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor activá el GPS del celular.'),
                                  ),
                                );
                              }
                              return;
                            }
                            var permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                            }
                            if (permission == LocationPermission.denied ||
                                permission == LocationPermission.deniedForever) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Permiso de GPS denegado.'),
                                  ),
                                );
                              }
                              return;
                            }
                            final pos = await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(
                                accuracy: LocationAccuracy.high,
                                timeLimit: Duration(seconds: 10),
                              ),
                            );
                            setDialogState(() {
                              latController.text = pos.latitude.toStringAsFixed(6);
                              lngController.text = pos.longitude.toStringAsFixed(6);
                            });
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error GPS: $e')),
                              );
                            }
                          } finally {
                            setDialogState(() => isCapturingGps = false);
                          }
                        },
                  icon: isCapturingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, color: appAccentColor),
                  label: Text(
                    isCapturingGps ? 'Obteniendo GPS...' : 'Usar ubicación actual',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: latController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitud (ej. -34.6037)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lngController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitud (ej. -58.3816)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (current != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _handleAction(() async {
                    final updated = matches.map((p) {
                      return p.copyWith(clearLocation: true);
                    }).toList();
                    await widget.onUpdatePartidos(
                      updated,
                      'Ubicación eliminada de ${matches.length} partidos.',
                    );
                  });
                },
                child: const Text('Quitar GPS'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresá coordenadas válidas o cancelá.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await _handleAction(() async {
                  final updated = matches.map((p) {
                    return p.copyWith(canchaLat: lat, canchaLng: lng);
                  }).toList();
                  await widget.onUpdatePartidos(
                    updated,
                    'Ubicación guardada en ${matches.length} partidos de "$canchaName".',
                  );
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Rivales: Renombrar o Unificar
  void _showRenameOrMergeRivalDialog(String currentRival, List<Partido> matches) {
    final textController = TextEditingController(text: currentRival);
    final otherRivales = _rivalesMap.keys
        .where((r) => r.toLowerCase() != currentRival.toLowerCase())
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: appAccentColor),
            SizedBox(width: 8),
            Text('Corregir Rival'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modificar o unificar los ${matches.length} partido(s) contra "$currentRival":',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del rival',
                  border: OutlineInputBorder(),
                ),
              ),
              if (otherRivales.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'O unificar con un rival existente:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar rival destino',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.call_merge_rounded, color: appAccentColor),
                  ),
                  hint: const Text('Elegir entre todos los rivales...'),
                  items: otherRivales
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      textController.text = val;
                    }
                  },
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 130),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: otherRivales.map((r) {
                          return ActionChip(
                            label: Text(r, style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              textController.text = r;
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isEmpty || newName == currentRival) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              await _handleAction(() async {
                final updated = matches.map((p) => p.copyWith(rival: newName)).toList();
                await widget.onUpdatePartidos(
                  updated,
                  'Rival corregido a "$newName" en ${matches.length} partidos.',
                );
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // --- Construcción de Vistas ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión y Depuración de Datos',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: appAccentColor,
          labelColor: appAccentColor,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: [
            Tab(
              icon: const Icon(Icons.emoji_events_outlined, size: 20),
              text: 'Torneos (${_torneosMap.length})',
            ),
            Tab(
              icon: const Icon(Icons.stadium_outlined, size: 20),
              text: 'Predios (${_canchasMap.length})',
            ),
            Tab(
              icon: const Icon(Icons.shield_outlined, size: 20),
              text: 'Rivales (${_rivalesMap.length})',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barra de búsqueda rápida
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar torneo, predio o rival...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Contenido de las pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTorneosTab(),
                    _buildPrediosTab(),
                    _buildRivalesTab(),
                  ],
                ),
              ),
            ],
          ),

          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(width: 16),
                        Text('Actualizando partidos...',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTorneosTab() {
    final entries = _torneosMap.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.key.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No hay torneos registrados.'
              : 'No se encontraron torneos con "$_searchQuery".',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final name = entry.key;
        final matches = entry.value;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: appAccentColor.withValues(alpha: 0.12),
              child: const Icon(Icons.emoji_events_rounded, color: appAccentColor),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: Text(
              '${matches.length} partido(s) registrados',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Renombrar torneo',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showRenameTorneoDialog(name, matches),
                ),
                IconButton(
                  tooltip: 'Unificar en otro torneo',
                  icon: const Icon(Icons.call_merge_rounded, size: 20, color: appAccentColor),
                  onPressed: () => _showMergeTorneoDialog(name, matches),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrediosTab() {
    final entries = _canchasMap.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.key.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No hay predios registrados.'
              : 'No se encontraron predios con "$_searchQuery".',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final name = entry.key;
        final matches = entry.value;
        final coords = _getVenueCoords(name);
        final hasLocation = coords != null;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: hasLocation ? Colors.grey.shade300 : Colors.amber.shade400,
              width: hasLocation ? 1 : 1.4,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: hasLocation
                  ? appAccentColor.withValues(alpha: 0.12)
                  : Colors.amber.withValues(alpha: 0.15),
              child: Icon(
                hasLocation ? Icons.stadium_rounded : Icons.location_off_outlined,
                color: hasLocation ? appAccentColor : Colors.amber.shade900,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${matches.length} partido(s) jugados',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? '📍 Lat: ${coords.lat.toStringAsFixed(4)}, Lng: ${coords.lng.toStringAsFixed(4)}'
                      : '⚠️ Sin ubicación GPS asignada',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasLocation ? Colors.teal.shade800 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Asignar / Cambiar GPS',
                  icon: Icon(
                    hasLocation ? Icons.pin_drop_rounded : Icons.add_location_alt_rounded,
                    color: hasLocation ? appAccentColor : Colors.amber.shade900,
                    size: 22,
                  ),
                  onPressed: () => _showEditLocationDialog(name, matches),
                ),
                IconButton(
                  tooltip: 'Renombrar / Unificar predio',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showRenameOrMergeCanchaDialog(name, matches),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRivalesTab() {
    final entries = _rivalesMap.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.key.toLowerCase().contains(_searchQuery);
    }).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No hay rivales registrados.'
              : 'No se encontraron rivales con "$_searchQuery".',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final name = entry.key;
        final matches = entry.value;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey.withValues(alpha: 0.12),
              child: const Icon(Icons.shield_rounded, color: Colors.blueGrey),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: Text(
              '${matches.length} enfrentamiento(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: IconButton(
              tooltip: 'Renombrar / Unificar rival',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showRenameOrMergeRivalDialog(name, matches),
            ),
          ),
        );
      },
    );
  }
}
