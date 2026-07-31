import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/breath_log.dart';
import '../state/aura_scope.dart';

class BreathworkScreen extends StatefulWidget {
  const BreathworkScreen({super.key});

  @override
  State<BreathworkScreen> createState() => _BreathworkScreenState();
}

class _BreathworkScreenState extends State<BreathworkScreen> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  late AnimationController _rotationController;

  bool _isActive = false;
  int _selectedMinutes = 1;
  int _secondsRemaining = 0;
  Timer? _sessionTimer;
  Timer? _hapticTimer;

  // 4 saniye nefes al, 6 saniye nefes ver (toplam 10 sn)
  final int _inhaleDuration = 4;
  final int _exhaleDuration = 6;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleDuration + _exhaleDuration),
    );

    // Büyüme ve küçülme (TweenSequence ile 4 sn büyü, 6 sn küçül)
    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: _inhaleDuration.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: _exhaleDuration.toDouble(),
      ),
    ]).animate(_breathController);

    // Sürekli yavaş dönüş
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isActive) {
          _breathController.forward(from: 0.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotationController.dispose();
    _sessionTimer?.cancel();
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isActive = true;
      _secondsRemaining = _selectedMinutes * 60;
    });

    _breathController.forward(from: 0.0);
    _startHapticFeedback();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _endSession();
      }
    });
  }

  void _endSession() {
    _sessionTimer?.cancel();
    _hapticTimer?.cancel();
    _breathController.stop();
    setState(() {
      _isActive = false;
    });
    
    // Veritabanına kaydet
    final controller = AuraScope.of(context);
    controller.addBreathLog(BreathLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      durationMinutes: _selectedMinutes,
    ));

    // Tebrik Mesajı
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Harika!', textAlign: TextAlign.center),
        content: Text(
          '$_selectedMinutes dakikalık farkındalık seansını tamamladın. Zihnini dinlendirdiğin için kendine teşekkür et.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Ekrana geri dön
              },
              child: const Text('Bitir'),
            ),
          )
        ],
      ),
    );
  }

  void _startHapticFeedback() {
    // Nefes alırken her saniye ufak bir titreşim vererek 
    // kullanıcıya ekrana bakmadan da büyüme hissini yaşatırız.
    _hapticTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentSecond = _breathController.value * (_inhaleDuration + _exhaleDuration);
      if (currentSecond <= _inhaleDuration) {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    _hapticTimer?.cancel();
    _breathController.stop();
    _breathController.value = 0.0;
    setState(() {
      _isActive = false;
    });
  }

  String get _instructionText {
    if (!_isActive) return 'Başlamak için dokun';
    final currentSecond = _breathController.value * (_inhaleDuration + _exhaleDuration);
    if (currentSecond <= _inhaleDuration) {
      return 'Nefes Al...';
    } else {
      return 'Nefes Ver...';
    }
  }

  String get _formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sysColors = Theme.of(context).colorScheme;
    final isTr = AuraScope.of(context).languageCode == 'tr';

    return Scaffold(
      backgroundColor: _isActive ? Colors.black : sysColors.surface,
      appBar: _isActive
          ? null // Tam ekran zen modu
          : AppBar(
              backgroundColor: Colors.transparent,
              title: Text(isTr ? 'Farkındalık' : 'Mindfulness'),
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isActive) ...[
              const SizedBox(height: 24),
              Text(
                isTr ? 'Süreyi Seçin' : 'Select Duration',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3, 5].map((min) {
                  final selected = _selectedMinutes == min;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$min ${isTr ? 'dk' : 'min'}'),
                      selected: selected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedMinutes = min);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
            
            Expanded(
              child: GestureDetector(
                onTap: _isActive ? null : _startSession,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animasyonlu Çiçek
                      AnimatedBuilder(
                        animation: Listenable.merge([_breathController, _rotationController]),
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                alignment: Alignment.center,
                                children: List.generate(6, (index) {
                                  // Apple vari iç içe yapraklar
                                  final angle = (index * math.pi * 2) / 6;
                                  
                                  // Nefes aldıkça yapraklar dışarı açılır ve büyür
                                  final expand = _breathAnimation.value;
                                  final offset = 40.0 * expand;
                                  
                                  return Transform.translate(
                                    offset: Offset(
                                      math.cos(angle) * offset,
                                      math.sin(angle) * offset,
                                    ),
                                    child: Transform.scale(
                                      scale: 1.0 + (expand * 1.5),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: sysColors.primary.withValues(alpha: 0.4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: sysColors.primary.withValues(alpha: 0.2),
                                              blurRadius: 20,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        },
                      ),

                      // Ortadaki Yönerge Yazısı
                      AnimatedBuilder(
                        animation: _breathController,
                        builder: (context, child) {
                          return Text(
                            _instructionText,
                            style: TextStyle(
                              color: _isActive ? Colors.white.withValues(alpha: 0.8) : sysColors.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (_isActive) ...[
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _stopSession,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                ),
                child: Text(isTr ? 'Bitir' : 'Stop'),
              ),
              const SizedBox(height: 48),
            ] else ...[
              const SizedBox(height: 48),
            ],
          ],
        ),
      ),
    );
  }
}
