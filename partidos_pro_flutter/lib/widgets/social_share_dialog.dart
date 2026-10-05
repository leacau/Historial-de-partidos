import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/deporte.dart';
import '../models/jugador.dart';
import '../models/partido.dart';

/// Diálogo interactivo para previsualizar y generar placas de partidos
/// con 3 opciones de diseño visual para compartir en Instagram, Facebook y WhatsApp.
class SocialShareDialog extends StatefulWidget {
  const SocialShareDialog({
    super.key,
    required this.partido,
    this.jugador,
  });

  final Partido partido;
  final Jugador? jugador;

  static Future<void> show(
    BuildContext context, {
    required Partido partido,
    Jugador? jugador,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SocialShareDialog(
        partido: partido,
        jugador: jugador,
      ),
    );
  }

  @override
  State<SocialShareDialog> createState() => _SocialShareDialogState();
}

class _SocialShareDialogState extends State<SocialShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  int _selectedDesign = 0; // 0: Match Day Pro, 1: Clean & Minimalista, 2: Story 9:16
  bool _isGenerating = false;

  SportConfig get sport => widget.partido.sportConfig;

  String get _captionText {
    final p = widget.partido;
    final r = p.resultadoTexto.toUpperCase();
    final buffer = StringBuffer();
    buffer.writeln('${sport.emoji} ¡Día de ${sport.nombre}! ($r)');
    buffer.writeln('${p.nombreJugador} con ${p.equipo}');
    buffer.writeln('⚔️ vs ${p.rival}');
    buffer.writeln('📊 Marcador: ${p.marcador}');
    if (p.scoreDetalle != null && p.scoreDetalle!.isNotEmpty) {
      buffer.writeln('🎾 Detalle: ${p.scoreDetalle}');
    }
    if (p.golesHijo > 0) {
      buffer.writeln('🔥 ${sport.labelAnotacionHijo}: ${p.golesHijo}');
    }
    if (p.asistencias > 0) {
      buffer.writeln('👟 Asistencias: ${p.asistencias}');
    }
    if (p.figuraPartido) {
      buffer.writeln('⭐ ¡Elegido Figura del partido!');
    }
    if (p.cancha.isNotEmpty) {
      buffer.writeln('📍 Predio: ${p.cancha}');
    }
    buffer.writeln('#PartidosPro #${sport.nombre.replaceAll(' ', '')}');
    return buffer.toString();
  }

  Future<File?> _captureImage() async {
    try {
      setState(() => _isGenerating = true);
      // Breve pausa para asegurar renderizado completo
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/partido_post_$timestamp.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error capturando imagen de placa: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareToWhatsApp() async {
    final file = await _captureImage();
    if (file == null) {
      _showError('No se pudo generar la imagen para compartir.');
      return;
    }

    try {
      // Intento directo con WhatsApp o fallback a Share sheet
      final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(_captionText)}');
      if (await canLaunchUrl(uri)) {
        // Enviar con imagen usando ShareXFiles
        await Share.shareXFiles(
          [XFile(file.path)],
          text: _captionText,
        );
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: _captionText,
        );
      }
    } catch (_) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _captionText,
      );
    }
  }

  Future<void> _shareToInstagram() async {
    final file = await _captureImage();
    if (file == null) {
      _showError('No se pudo generar la imagen para compartir.');
      return;
    }

    try {
      final uri = Uri.parse('instagram://');
      if (await canLaunchUrl(uri)) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: _captionText,
        );
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: _captionText,
        );
      }
    } catch (_) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _captionText,
      );
    }
  }

  Future<void> _shareToFacebook() async {
    final file = await _captureImage();
    if (file == null) {
      _showError('No se pudo generar la imagen para compartir.');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _captionText,
      );
    } catch (_) {
      _showError('No se pudo abrir Facebook.');
    }
  }

  Future<void> _shareGeneral() async {
    final file = await _captureImage();
    if (file == null) {
      _showError('No se pudo generar la imagen para compartir.');
      return;
    }

    await Share.shareXFiles(
      [XFile(file.path)],
      text: _captionText,
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partido;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera del diálogo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withAlpha(60),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded, color: Color(0xFF2DD4BF), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compartir Partido',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Elegí un diseño para tus redes sociales',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Selector de Diseño (3 opciones)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildDesignTab(0, '🌟 Match Day', 'Oscuro Pro'),
                    _buildDesignTab(1, '⚪ Clean', 'Minimalista'),
                    _buildDesignTab(2, '📱 Story', '9:16'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Área de Vista Previa (con RepaintBoundary)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _buildSelectedDesign(p),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Botones de acción directa para Redes Sociales
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // WhatsApp
                      _buildSocialButton(
                        label: 'WhatsApp',
                        icon: Icons.chat_bubble_rounded,
                        color: const Color(0xFF25D366),
                        onTap: _isGenerating ? null : _shareToWhatsApp,
                      ),
                      // Instagram
                      _buildSocialButton(
                        label: 'Instagram',
                        icon: Icons.camera_alt_rounded,
                        color: const Color(0xFFE1306C),
                        onTap: _isGenerating ? null : _shareToInstagram,
                      ),
                      // Facebook
                      _buildSocialButton(
                        label: 'Facebook',
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        onTap: _isGenerating ? null : _shareToFacebook,
                      ),
                      // Más opciones
                      _buildSocialButton(
                        label: 'Más...',
                        icon: Icons.more_horiz_rounded,
                        color: const Color(0xFF64748B),
                        onTap: _isGenerating ? null : _shareGeneral,
                      ),
                    ],
                  ),
                  if (_isGenerating) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignTab(int index, String title, String sub) {
    final isSelected = _selectedDesign == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDesign = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.white30,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(100), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // DISEÑOS DE PLACAS
  // ====================================================================

  Widget _buildSelectedDesign(Partido p) {
    switch (_selectedDesign) {
      case 1:
        return _buildCleanModernDesign(p);
      case 2:
        return _buildStoryDesign(p);
      case 0:
      default:
        return _buildMatchDayProDesign(p);
    }
  }

  // --------------------------------------------------------------------
  // DISEÑO 0: MATCH DAY PRO (Dark & Punchy)
  // --------------------------------------------------------------------
  Widget _buildMatchDayProDesign(Partido p) {
    final resColor = p.gano
        ? const Color(0xFF10B981)
        : p.empato
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      width: 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0B1120),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Torneo / Copa y Deporte
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sport.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      p.tipoPartido.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: resColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: resColor.withAlpha(120)),
                ),
                child: Text(
                  p.resultadoTexto.toUpperCase(),
                  style: TextStyle(
                    color: resColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Torneo o Copa
          Text(
            p.torneo.isNotEmpty ? p.torneo : 'Partido Oficial',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // Marcador Central de Estadio
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Row(
              children: [
                // Equipo local
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF0F766E),
                        child: Text(
                          p.equipo.isNotEmpty ? p.equipo.substring(0, 1).toUpperCase() : 'E',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.equipo,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Marcador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        '${p.scoreHijo} - ${p.scoreRival}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      if (p.scoreDetalle != null && p.scoreDetalle!.isNotEmpty) ...[
                        Text(
                          p.scoreDetalle!,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (p.penales) ...[
                        Text(
                          '(${p.scorePenalesEquipo}-${p.scorePenalesRival} pen.)',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),

                // Equipo rival
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE11D48),
                        child: Text(
                          p.rival.isNotEmpty ? p.rival.substring(0, 1).toUpperCase() : 'R',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.rival,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Foto del partido si existe
          if (p.foto != null && p.foto!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                p.foto!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Datos y Rendimiento del Jugador
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2DD4BF),
                  child: Text(
                    widget.jugador?.dorsal != null && widget.jugador!.dorsal.isNotEmpty
                        ? '#${widget.jugador!.dorsal}'
                        : '★',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nombreJugador,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (p.golesHijo > 0) ...[
                            Text(
                              '${sport.emoji} ${p.golesHijo} ${sport.labelAnotacionHijo}  ',
                              style: const TextStyle(
                                color: Color(0xFF2DD4BF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (p.asistencias > 0) ...[
                            Text(
                              '👟 ${p.asistencias} Asist.  ',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                          if (p.figuraPartido) ...[
                            const Text(
                              '⭐ Figura',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Footer branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p.fechaTexto,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Row(
                children: [
                  Icon(Icons.sports, color: Color(0xFF2DD4BF), size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Partidos Pro',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // DISEÑO 1: CLEAN & MINIMALISTA (Blanco / Light Card)
  // --------------------------------------------------------------------
  Widget _buildCleanModernDesign(Partido p) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera Minimalista
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p.fechaTexto,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.torneo.isNotEmpty ? p.torneo : p.tipoPartido,
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Marcador Central
          Text(
            '${p.scoreHijo} - ${p.scoreRival}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          if (p.scoreDetalle != null && p.scoreDetalle!.isNotEmpty) ...[
            Text(
              p.scoreDetalle!,
              style: const TextStyle(
                color: Color(0xFF0284C7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),

          // Equipos
          Text(
            '${p.equipo}  vs  ${p.rival}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Foto del partido si existe
          if (p.foto != null && p.foto!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                p.foto!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Desempeño
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${sport.emoji} ${p.golesHijo}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      sport.labelAnotacionHijo,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '👟 ${p.asistencias}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Asistencias',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      p.resultadoTexto,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: p.gano
                            ? const Color(0xFF059669)
                            : p.empato
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      'Resultado',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (p.cancha.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  p.cancha,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // DISEÑO 2: STORY DEPORTIVA (9:16 Vertical)
  // --------------------------------------------------------------------
  Widget _buildStoryDesign(Partido p) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF042F2E),
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticker Story Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '★ MATCH RECAP ★',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Foto o avatar grande
          if (p.foto != null && p.foto!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                p.foto!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF0F766E),
              child: Text(
                sport.emoji,
                style: const TextStyle(fontSize: 34),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Nombre Jugador
          Text(
            p.nombreJugador,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          Text(
            p.equipo,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 14),

          // Marcador gigante
          Text(
            '${p.scoreHijo} - ${p.scoreRival}',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          if (p.scoreDetalle != null && p.scoreDetalle!.isNotEmpty) ...[
            Text(
              p.scoreDetalle!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],

          Text(
            'vs ${p.rival}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // Badge Actuación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Column(
              children: [
                if (p.golesHijo > 0)
                  Text(
                    '🔥 ${p.golesHijo} ${sport.labelAnotacionHijo}',
                    style: const TextStyle(
                      color: Color(0xFF2DD4BF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (p.figuraPartido)
                  const Text(
                    '⭐ ¡FIGURA DEL PARTIDO!',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  p.torneo.isNotEmpty ? p.torneo : p.tipoPartido,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Footer
          const Text(
            '#PartidosPro',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
