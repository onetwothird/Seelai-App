// File: lib/shared/widgets/call_rating_dialog.dart

import 'package:flutter/material.dart';

class CallRatingDialog extends StatefulWidget {
  final VoidCallback onDismissed;

  const CallRatingDialog({super.key, required this.onDismissed});

  @override
  State<CallRatingDialog> createState() => _CallRatingDialogState();
}

class _CallRatingDialogState extends State<CallRatingDialog> {
  int _selectedStars = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          // Matches the dark slate blue/navy background from your screenshot
          color: const Color(0xFF1A2232), 
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How was the quality of your call?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStars = index + 1;
                    });

                    final navigator = Navigator.of(context);

                    // Close after short delay so they can see their selection
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (!mounted) return;

                      navigator.pop();
                      widget.onDismissed();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star_rounded,
                      color: index < _selectedStars
                          ? Colors.white
                          : Colors.grey.shade600,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF334155), // Lighter grey-blue for the button
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDismissed();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Not now',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}