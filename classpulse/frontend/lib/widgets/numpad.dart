import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Numpad extends StatelessWidget {
  final Function(int) onNumberPressed;
  final VoidCallback onDeletePressed;

  const Numpad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow([1, 2, 3]),
          const SizedBox(height: 14),
          _buildRow([4, 5, 6]),
          const SizedBox(height: 14),
          _buildRow([7, 8, 9]),
          const SizedBox(height: 14),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _NumpadButton(
        label: n.toString(),
        onTap: () => onNumberPressed(n),
      )).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Empty spacer — same size as a button for alignment
        const SizedBox(width: 68, height: 68),

        // 0 — centered under 8
        _NumpadButton(
          label: '0',
          onTap: () => onNumberPressed(0),
        ),

        // Delete — aligned under 9
        _NumpadButton(
          icon: Icons.backspace_outlined,
          onTap: onDeletePressed,
          isDelete: true,
        ),
      ],
    );
  }
}

class _NumpadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDelete;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: widget.isDelete ? Colors.transparent : AppColors.numpadButton,
            borderRadius: BorderRadius.circular(34), // perfectly circular
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(
                    widget.icon,
                    color: AppColors.textSecondary,
                    size: 24,
                  )
                : Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: AppColors.numpadText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
