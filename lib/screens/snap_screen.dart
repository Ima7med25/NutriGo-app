import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/foods.dart';
import '../l10n/strings.dart';
import '../services/backend.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'adjust_screen.dart';
import 'confirm_screen.dart';

/// 04 · Snap – live camera with frame guides, gallery upload, or pick from list.
class SnapScreen extends StatefulWidget {
  const SnapScreen({super.key});

  @override
  State<SnapScreen> createState() => _SnapScreenState();
}

enum _Mode { upload, camera, list }

class _SnapScreenState extends State<SnapScreen> with WidgetsBindingObserver {
  final _picker = ImagePicker();
  CameraController? _controller;
  bool _initializing = true;
  String? _cameraError;
  bool _flash = false;
  bool _busy = false;
  _Mode _mode = _Mode.camera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (c == null) return;
      setState(() => _controller = null);
      c.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _cameraError = tr('No camera found on this device.');
        });
        return;
      }
      final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(_flash ? FlashMode.always : FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('AccessDenied') ||
          e.code.contains('Restricted') ||
          e.code.contains('permission');
      setState(() {
        _initializing = false;
        _cameraError = denied
            ? tr('Camera access is off. Allow it in Settings, or upload a photo from your gallery.')
            : tr('Could not open the camera.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = tr('Could not open the camera.');
      });
    }
  }

  Future<void> _toggleFlash() async {
    setState(() => _flash = !_flash);
    try {
      await _controller?.setFlashMode(
          _flash ? FlashMode.always : FlashMode.off);
    } on CameraException catch (_) {
      // Device without flash – keep the toggle state only.
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (_busy) return;
    if (c == null || !c.value.isInitialized) {
      // No live camera: fall back to the gallery.
      return _pickFromGallery();
    }
    if (c.value.isTakingPicture) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      if (!mounted) return;
      _goConfirm(file.path);
    } on CameraException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Could not take the photo. Try again.'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (x == null || !mounted) return;
      _goConfirm(x.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Could not open the gallery.'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goConfirm(String path) {
    AppScope.read(context).setPhoto(path);
    // Pause the live preview while the user is on the next screens.
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      c.pausePreview().catchError((_) {});
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ConfirmScreen()))
        .then((_) {
      final c2 = _controller;
      if (mounted && c2 != null && c2.value.isInitialized &&
          c2.value.isPreviewPaused) {
        c2.resumePreview().catchError((_) {});
      }
    });
  }

  Future<void> _pickFromList() async {
    final food = await showFoodSearch(context);
    if (!mounted) return;
    setState(() => _mode = _Mode.camera);
    if (food == null) return;
    AppScope.read(context).startMeal(food);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdjustScreen()));
  }

  void _onMode(_Mode m) {
    setState(() => _mode = m);
    if (m == _Mode.upload) {
      _pickFromGallery().whenComplete(() {
        if (mounted) setState(() => _mode = _Mode.camera);
      });
    } else if (m == _Mode.list) {
      _pickFromList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final live = c != null && c.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // ---- Camera feed ----
          Positioned.fill(
            child: live
                ? _FullScreenPreview(controller: c)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.1),
                        radius: 0.9,
                        colors: [Color(0xFF3A3F47), Color(0xFF0D1117)],
                      ),
                    ),
                  ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: kPagePad.copyWith(top: 16),
                  child: Row(
                    children: [
                      const BackCircleButton(onDark: true),
                      const Spacer(),
                      _pill(tr('Step {a} of 4 · {name}',
                          {'a': 1, 'name': tr('Snap')})),
                      const Spacer(),
                      CircleIconButton(
                        icon: _flash
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onDark: true,
                        semanticLabel: tr('Flash'),
                        onTap: live ? _toggleFlash : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: kPagePad.copyWith(top: 17),
                  child: const FlowSteps(current: 1, onDark: true),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 317,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _statusPill(live),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 317,
                          height: 317,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!live && !_initializing)
                                const MealIllustration(size: 263),
                              Positioned.fill(
                                child: CustomPaint(painter: _FrameGuides()),
                              ),
                              if (_busy || _initializing)
                                const SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 4),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 23),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _cameraError ??
                                tr('Center your meal in the frame'),
                            textAlign: TextAlign.center,
                            style: AppText.body(14.2,
                                color: Colors.white, weight: FontWeight.w600),
                          ),
                        ),
                        if (_cameraError != null) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _initCamera,
                            child: Text(tr('Try again'),
                                style: AppText.body(14.2,
                                    color: AppColors.greenLight,
                                    weight: FontWeight.w700)),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _Controls(
                  mode: _mode,
                  onMode: _onMode,
                  onShutter: _capture,
                  onGallery: _pickFromGallery,
                  onList: _pickFromList,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(bool live) {
    final text = live ? tr('Camera ready') : tr('Camera off');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: live ? AppColors.greenLight : AppColors.orange,
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Text(text,
              style: AppText.body(14.2,
                  color: Colors.white, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: AppText.body(14.2,
                color: Colors.white, weight: FontWeight.w700)),
      );
}

/// Camera preview scaled to cover the whole screen.
class _FullScreenPreview extends StatelessWidget {
  const _FullScreenPreview({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // previewSize is reported in landscape (width > height).
      final p = controller.value.previewSize;
      final previewW = p == null ? box.maxWidth : p.height;
      final previewH = p == null ? box.maxHeight : p.width;
      return ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewW,
              height: previewH,
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    });
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.mode,
    required this.onMode,
    required this.onShutter,
    required this.onGallery,
    required this.onList,
  });

  final _Mode mode;
  final ValueChanged<_Mode> onMode;
  final VoidCallback onShutter;
  final VoidCallback onGallery;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget modeTab(_Mode m, String label) {
      final sel = m == mode;
      return GestureDetector(
        onTap: () => onMode(m),
        child: Column(
          children: [
            Text(label,
                style: AppText.body(14.2,
                    weight: FontWeight.w700,
                    color: sel
                        ? AppColors.greenLight
                        : Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? AppColors.greenLight : Colors.transparent,
              ),
            ),
          ],
        ),
      );
    }

    Widget side(IconData icon, String label, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 90,
            child: Column(
              children: [
                Container(
                  width: 57,
                  height: 57,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 14),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(12,
                        color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 25, 24, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              modeTab(_Mode.upload, tr('Upload')),
              const SizedBox(width: 34),
              modeTab(_Mode.camera, tr('Camera')),
              const SizedBox(width: 28),
              modeTab(_Mode.list, tr('From list')),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              side(Icons.image_outlined, tr('Gallery'), onGallery),
              Semantics(
                button: true,
                label: tr('Take photo'),
                child: GestureDetector(
                  onTap: onShutter,
                  child: Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
              side(Icons.format_list_bulleted_rounded, tr('Pick from list'),
                  onList),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrameGuides extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 37.0, r = 14.0;
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    canvas.drawPath(
        Path()
          ..moveTo(0, len)
          ..lineTo(0, r)
          ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
          ..lineTo(len, 0),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(w - len, 0)
          ..lineTo(w - r, 0)
          ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
          ..lineTo(w, len),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(w, h - len)
          ..lineTo(w, h - r)
          ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
          ..lineTo(w - len, h),
        p);
    canvas.drawPath(
        Path()
          ..moveTo(len, h)
          ..lineTo(r, h)
          ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
          ..lineTo(0, h - len),
        p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom sheet to search the food list. Returns the picked food.
Future<Food?> showFoodSearch(BuildContext context) {
  return showModalBottomSheet<Food>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FoodSearchSheet(),
  );
}

class _FoodSearchSheet extends StatefulWidget {
  const _FoodSearchSheet();

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  String _q = '';
  List<Food> _foods = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The 101 dishes from the server.
  Future<void> _load() async {
    try {
      final list = await Backend.foods();
      if (!mounted) return;
      setState(() {
        _foods = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = tr(Backend.describe(e));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final results = _foods
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            tr(f.name).toLowerCase().contains(q))
        .toList();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Padding(
          padding: kPagePad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Search foods'), style: AppText.sectionTitle),
              const SizedBox(height: 12),
              AppTextField(
                icon: Icons.search_rounded,
                hint: tr('e.g. burger, koshari…'),
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(color: AppColors.green),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                      '$_error\n${tr('Showing the offline demo list.')}',
                      style: AppText.body(12.5, color: AppColors.orange)),
                ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(tr('No foods match "{q}"', {'q': _q}),
                            style: AppText.label))
                    : ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final f = results[i];
                          return MealTile(
                            title: tr(f.name),
                            subtitle: tr(f.category),
                            kcal: f.kcal,
                            onTap: () => Navigator.pop(context, f),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
