import 'package:flutter/material.dart';
import 'package:seelai_app/themes/constants.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    this.isTransparent = false,
    required this.text,
    this.isLarge = false,
    this.onPressed,
  });

  final bool isTransparent;
  final bool isLarge;
  final String text;
  final void Function()? onPressed;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          height: 62,
          width: widget.isLarge ? double.infinity : 170,
          decoration: BoxDecoration(
            gradient: widget.isTransparent ? null : primaryGradient,
            borderRadius: BorderRadius.circular(radiusLarge),
            border: widget.isTransparent
                ? Border.all(
                    color: primary,
                    width: 2.5,
                  )
                : Border.all(
                    color: widget.isTransparent ? Colors.transparent : white.withOpacity(0.2),
                    width: 1,
                  ),
            boxShadow: widget.isTransparent || _isPressed 
                ? [] 
                : [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: secondary.withOpacity(0.2),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                      spreadRadius: -4,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(radiusLarge),
              splashColor: white.withOpacity(0.1),
              highlightColor: white.withOpacity(0.05),
              child: Center(
                child: Text(
                  widget.text,
                  style: h3.copyWith(
                    color: widget.isTransparent ? primary : white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.controller,
  });

  final String hint;
  final bool isPassword;
  final TextEditingController? controller;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        boxShadow: _isFocused ? mediumShadow : softShadow,
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        style: body.copyWith(
          fontSize: 16,
          color: black,
          fontWeight: FontWeight.w500,
        ),
        onTap: () => setState(() => _isFocused = true),
        onTapOutside: (_) => setState(() => _isFocused = false),
        decoration: InputDecoration(
          fillColor: white,
          filled: true,
          hintText: widget.hint,
          hintStyle: body.copyWith(
            color: greyLight.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: greyLight,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide(color: greyLighter, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide(color: greyLighter, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            borderSide: BorderSide(color: primary, width: 2.5),
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatefulWidget {
  const SocialButton({
    super.key,
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            boxShadow: _isHovered ? mediumShadow : softShadow,
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          child: Material(
            color: white,
            borderRadius: BorderRadius.circular(radiusLarge),
            child: InkWell(
              onTap: widget.onPressed,
              onHover: (hovering) => setState(() => _isHovered = hovering),
              borderRadius: BorderRadius.circular(radiusLarge),
              splashColor: primary.withOpacity(0.1),
              highlightColor: primary.withOpacity(0.05),
              child: Container(
                height: 64,
                width: 96,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isHovered ? primary.withOpacity(0.4) : greyLighter,
                    width: _isHovered ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(radiusLarge),
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: _isHovered ? primary : grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}