import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScannerOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const ScannerOverlay({super.key, required this.onClose});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.background,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scan QR Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _close,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.numpadButton,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Viewfinder
                Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    color: AppColors.scannerSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.pinBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Camera placeholder
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 44, color: AppColors.textMuted),
                            SizedBox(height: 10),
                            Text('Camera Preview', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Point at a QR code', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),

                      // Corner brackets
                      ..._buildCornerBrackets(scanAreaSize),

                      // Scan line
                      _ScanLine(areaSize: scanAreaSize),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Align QR code within the frame',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),

                const Spacer(flex: 1),

                // Upload button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Upload QR Image',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets(double size) {
    const bracketLength = 28.0;
    const bracketWidth = 3.0;
    const offset = -1.0;
    const color = AppColors.primary;

    return [
      const Positioned(top: offset, left: offset, child: _CornerBracket(length: bracketLength, width: bracketWidth, color: color, topLeft: true)),
      const Positioned(top: offset, right: offset, child: _CornerBracket(length: bracketLength, width: bracketWidth, color: color, topRight: true)),
      const Positioned(bottom: offset, left: offset, child: _CornerBracket(length: bracketLength, width: bracketWidth, color: color, bottomLeft: true)),
      const Positioned(bottom: offset, right: offset, child: _CornerBracket(length: bracketLength, width: bracketWidth, color: color, bottomRight: true)),
    ];
  }
}

class _CornerBracket extends StatelessWidget {
  final double length;
  final double width;
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _CornerBracket({
    required this.length,
    required this.width,
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(width: width, color: color, topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft, bottomRight: bottomRight),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double width;
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  _CornerPainter({required this.width, required this.color, required this.topLeft, required this.topRight, required this.bottomLeft, required this.bottomRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();

    if (topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (bottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanLine extends StatefulWidget {
  final double areaSize;
  const _ScanLine({required this.areaSize});

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _controller.value * (widget.areaSize - 4),
          left: 14,
          right: 14,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.secondary.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
