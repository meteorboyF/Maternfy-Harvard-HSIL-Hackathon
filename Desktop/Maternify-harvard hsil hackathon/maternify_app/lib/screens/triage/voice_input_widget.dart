import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../blocs/triage/triage_bloc.dart';
import '../../services/api_service.dart';
import '../../services/firebase_service.dart';

/// F11 — Voice input widget. Hold button to record, release to transcribe via
/// Node API /triage/voice (Whisper small model). Injects transcription
/// into the triage chat as a message.
class VoiceInputButton extends StatefulWidget {
  final String patientId;
  const VoiceInputButton({super.key, required this.patientId});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _processing = false;
  String? _audioPath;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.stop();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    _audioPath = '${dir.path}/triage_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
      path: _audioPath!,
    );

    setState(() => _recording = true);
    _pulseCtrl.repeat(reverse: true);
  }

  Future<void> _stopAndTranscribe(BuildContext context) async {
    await _recorder.stop();
    _pulseCtrl.stop();
    setState(() { _recording = false; _processing = true; });

    try {
      final idToken = await FirebaseService.auth.currentUser?.getIdToken();
      final formData = FormData.fromMap({
        'patient_id': widget.patientId,
        'audio': await MultipartFile.fromFile(_audioPath!, filename: 'voice.wav'),
      });

      final response = await ApiService.client.post(
        '/triage/voice',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final transcription = response.data['transcription'] as String? ?? '';
      if (transcription.isNotEmpty && context.mounted) {
        context.read<TriageBloc>().add(TriageMessageSent(
          patientId: widget.patientId,
          text: transcription,
          lang: 'bn',
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice transcription failed: $e')),
        );
      }
    } finally {
      setState(() => _processing = false);
      if (_audioPath != null) File(_audioPath!).deleteSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(color: Color(0xFF993556), strokeWidth: 3),
      );
    }

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopAndTranscribe(context),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: _recording ? _pulseAnim.value : 1.0,
          child: child,
        ),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _recording ? Colors.red : const Color(0xFF993556),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _recording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
