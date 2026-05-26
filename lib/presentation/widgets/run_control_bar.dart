import 'package:flutter/material.dart';

/// Koşu başlat/durdur butonu.
class RunControlBar extends StatelessWidget {
  final bool isRunning;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RunControlBar({
    super.key,
    required this.isRunning,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : (isRunning ? onStop : onStart),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRunning ? Colors.red : Colors.green,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isRunning ? 'DURDUR' : 'BAŞLAT',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
      ),
    );
  }
}
