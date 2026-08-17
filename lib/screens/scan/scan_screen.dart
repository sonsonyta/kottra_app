import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/app_localizations.dart';
import 'attendance_qr.dart';

/// Full-screen QR scanner for attendance. Opens the camera, and pops with the
/// raw scanned payload (a `String`) once a code matching [expectedStoreId] is
/// read. Mismatched or unrelated codes are rejected inline so the employee can
/// keep scanning; backing out returns `null`.
///
/// Push it and await the result:
/// ```dart
/// final payload = await Navigator.of(context).push<String>(
///   MaterialPageRoute(builder: (_) => ScanScreen(
///     expectedStoreId: storeId, title: l.scanToCheckIn)),
/// );
/// ```
class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.expectedStoreId,
    required this.title,
  });

  final String expectedStoreId;
  final String title;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// True once we've accepted a valid code and are popping — stops any further
  /// detections from firing a second pop.
  bool _handled = false;

  /// The inline error to show under the scan window (wrong store / invalid),
  /// cleared shortly after so the employee can retry.
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;

    final l = AppLocalizations.of(context)!;
    switch (validateAttendanceQr(raw, widget.expectedStoreId)) {
      case AttendanceQrResult.valid:
        _handled = true;
        _controller.stop();
        Navigator.of(context).pop(raw!.trim());
      case AttendanceQrResult.wrongStore:
        _showError(l.qrWrongStore);
      case AttendanceQrResult.invalid:
        _showError(l.qrInvalidCode);
    }
  }

  void _showError(String message) {
    if (_error == message) return;
    setState(() => _error = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_handled) setState(() => _error = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(
              message: error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? l.cameraPermissionRequired
                  : error.errorDetails?.message ?? error.errorCode.name,
            ),
          ),
          _ScannerOverlay(error: _error),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              _error ?? l.scanQrInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _error != null ? const Color(0xFFFF6B6B) : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dimmed backdrop with a transparent, rounded scan window in the centre.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final windowSize = size.width * 0.68;
    final borderColor = error != null ? const Color(0xFFFF6B6B) : Colors.white;

    return IgnorePointer(
      child: Center(
        child: Container(
          width: windowSize,
          height: windowSize,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 3),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded,
                  color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
