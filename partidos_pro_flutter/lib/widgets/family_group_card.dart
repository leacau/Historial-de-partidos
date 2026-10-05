import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/familia.dart';
import '../models/jugador.dart';
import '../repositories/football_repository.dart';
import 'common_widgets.dart';

/// Tarjeta y gestor interactivo del Sistema de Código Familiar.
/// Permite vincular múltiples dispositivos familiares (padres, abuelos, etc.)
/// para seguir en tiempo real al mismo jugador y sus partidos.
class FamilyGroupCard extends StatefulWidget {
  const FamilyGroupCard({
    super.key,
    required this.repo,
    required this.jugadores,
    required this.onFamilyChanged,
    required this.onSnack,
  });

  final FootballRepository repo;
  final List<Jugador> jugadores;
  final Future<void> Function() onFamilyChanged;
  final void Function(String message, {bool isError}) onSnack;

  @override
  State<FamilyGroupCard> createState() => _FamilyGroupCardState();
}

class _FamilyGroupCardState extends State<FamilyGroupCard> {
  bool _loading = true;
  bool _inFamily = false;
  bool _isAdmin = false;
  String? _familyCode;
  String? _familyNombre;
  GrupoFamiliar? _activeFamily;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final inFam = await widget.repo.isInFamily();
      final isAdm = await widget.repo.isFamilyAdmin();
      final code = await widget.repo.getActiveFamilyCode();
      final nombre = await widget.repo.getActiveFamilyNombre();
      GrupoFamiliar? fam;
      if (inFam) {
        fam = await widget.repo.getActiveFamily();
      }

      if (mounted) {
        setState(() {
          _inFamily = inFam;
          _isAdmin = isAdm;
          _familyCode = code ?? fam?.codigo;
          _familyNombre = nombre ?? fam?.nombreFamilia;
          _activeFamily = fam;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleCreateFamily() async {
    setState(() => _loading = true);
    try {
      final playerName = widget.jugadores.isNotEmpty
          ? widget.jugadores.first.nombreDisplay
          : 'Jugador';
      final familyName = 'Familia de $playerName';

      final code = await widget.repo.getOrCreateFamilyCode(
        jugadores: widget.jugadores,
        nombreFamilia: familyName,
      );

      widget.onSnack('¡Código familiar creado con éxito: $code!');
      await _loadStatus();
      await widget.onFamilyChanged();
    } catch (e) {
      widget.onSnack('Error al crear código familiar: $e', isError: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showJoinDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        bool joining = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: Color(0xFF087C63)),
                  SizedBox(width: 8),
                  Text(
                    'Unirme a Familia',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresá el código de 6 caracteres que te compartió el administrador de la familia:',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      maxLength: 8,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Color(0xFF087C63),
                      ),
                      decoration: InputDecoration(
                        hintText: 'EJ: SALVI7',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          letterSpacing: 2,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAF9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFDDE6E3)),
                        ),
                        counterText: '',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresá el código';
                        }
                        if (val.trim().length < 5) {
                          return 'El código tiene al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: joining ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF087C63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: joining
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => joining = true);
                          try {
                            final code = controller.text.trim().toUpperCase();
                            final fam = await widget.repo.joinFamilyWithCode(code);
                            if (ctx.mounted) Navigator.pop(ctx);
                            widget.onSnack(
                              '¡Te uniste a "${fam.nombreFamilia}" correctamente!',
                            );
                            await _loadStatus();
                            await widget.onFamilyChanged();
                          } catch (e) {
                            setDialogState(() => joining = false);
                            widget.onSnack('$e', isError: true);
                          }
                        },
                  child: joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Unirme',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLeaveFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('¿Salir del grupo familiar?'),
        content: const Text(
          'Dejarás de recibir actualizaciones en vivo de este grupo. Podrás volver a unirte cuando quieras ingresando nuevamente el código.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir del grupo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await widget.repo.leaveFamily();
      widget.onSnack('Saliste del grupo familiar.');
      await _loadStatus();
      await widget.onFamilyChanged();
    } catch (e) {
      widget.onSnack('Error al salir: $e', isError: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyCode() {
    if (_familyCode == null) return;
    Clipboard.setData(ClipboardData(text: _familyCode!));
    widget.onSnack('¡Código $_familyCode copiado al portapapeles!');
  }

  Future<void> _shareViaWhatsApp() async {
    if (_familyCode == null) return;
    final playerName = widget.jugadores.isNotEmpty
        ? widget.jugadores.first.nombreDisplay
        : 'nuestro jugador';
    final text = '¡Hola! Te invito a seguir los partidos y estadísticas de $playerName '
        'en Partidos Pro en tiempo real ⚽📱.\n\n'
        '1️⃣ Abrí la aplicación en tu celular.\n'
        '2️⃣ Andá a Perfil > Grupo Familiar.\n'
        '3️⃣ Seleccioná "Unirme a Familia" e ingresá este código:\n\n'
        '👉 *$_familyCode*\n\n'
        '¡Listo! Podrás ver los partidos, fotos y goles al instante.';

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2EBE8)),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_inFamily && _familyCode != null) {
      return _buildActiveFamilyCard();
    }

    return _buildJoinOrCreateCard();
  }

  Widget _buildActiveFamilyCard() {
    final miembrosCount = _activeFamily?.totalMiembros ?? 1;
    final title = _familyNombre ?? 'Grupo Familiar';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF087C63).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087C63).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF087C63).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF087C63),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _isAdmin
                                  ? const Color(0xFF087C63)
                                  : const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isAdmin ? 'ADMIN' : 'FAMILIAR',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sincronización en vivo con tu familia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caja destacada del código
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F2B24), Color(0xFF084E3E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CÓDIGO DE INVITACIÓN',
                            style: TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$miembrosCount disp. vinculados',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _familyCode!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFA7F3D0)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _copyCode,
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text(
                                'Copiar código',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _shareViaWhatsApp,
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: const Text(
                                'Enviar por WhatsApp',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Jugadores sincronizados
                if (_activeFamily?.jugadores.isNotEmpty == true) ...[
                  Text(
                    'Jugadores en el grupo:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _activeFamily!.jugadores.map((j) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⚽', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              j.nombreDisplay,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Acciones secundarias
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF087C63),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await _loadStatus();
                          await widget.onFamilyChanged();
                          widget.onSnack('¡Datos familiares sincronizados!');
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text(
                          'Sincronizar ahora',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleLeaveFamily,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Salir',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinOrCreateCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF087C63).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: Color(0xFF087C63),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grupo Familiar 👨‍👩‍👧‍👦',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seguí a tu hijo desde varios celulares',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Compartí los partidos, fotos y goles en tiempo real con padres, abuelos o tíos. Quien tenga tu código familiar podrá ver todas las actuaciones actualizadas al instante.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF087C63),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleCreateFamily,
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text(
                      'Crear Código',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF087C63),
                      side: const BorderSide(color: Color(0xFF087C63)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showJoinDialog,
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      'Tengo un Código',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
