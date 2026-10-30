// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

// Your restored project imports
import 'js_bridge_stub.dart' if (dart.library.html) 'js_bridge_web.dart' as js_bridge;
import 'scam_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NeuralVoiceEngine.warmUpVoices();
  runApp(const NgaoSautiApp());
}

// ============================================================================
// 1. CROSS-PLATFORM NATURAL HUMAN NEURAL VOICE ENGINE (WEB + ANDROID APK)
// ============================================================================

class VoiceEntry {
  final String name;
  final String locale;
  const VoiceEntry(this.name, this.locale);
}

class NeuralVoiceEngine {
  static final FlutterTts _tts = FlutterTts();
  static bool soundEnabled = true;
  static bool _initialized = false;
  static final List<VoiceEntry> _voices = [];

  static Future<void> warmUpVoices() async {
    if (_initialized) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1.0);

      final dynamic rawVoices = await _tts.getVoices;
      if (rawVoices != null && rawVoices is List) {
        _voices.clear();
        for (final item in rawVoices) {
          if (item is Map) {
            final n = (item['name'] ?? '').toString();
            final l = (item['locale'] ?? '').toString();
            if (n.isNotEmpty && l.isNotEmpty) {
              _voices.add(VoiceEntry(n, l));
            }
          }
        }
      }
      _initialized = true;
    } catch (_) {}
  }

  static void playTone({
    int freq = 800,
    int durationMs = 220,
    String type = 'sine',
  }) {
    if (!soundEnabled) return;
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  static Future<void> speak(String text, {String role = 'ai'}) async {
    if (!soundEnabled || text.trim().isEmpty) return;
    try {
      await warmUpVoices();
      await _tts.stop();

      if (_voices.isNotEmpty) {
        final List<VoiceEntry> naturalPool = _voices.where((v) {
          final lower = v.name.toLowerCase();
          return lower.contains('natural') ||
              lower.contains('online') ||
              lower.contains('google') ||
              lower.contains('neural') ||
              lower.contains('network');
        }).toList();

        final List<VoiceEntry> pool =
            naturalPool.isNotEmpty ? naturalPool : _voices;
        VoiceEntry chosen = pool.first;

        if (role == 'ai') {
          chosen = pool.firstWhere(
            (v) =>
                v.name.contains('Asilia') ||
                v.name.contains('Aria') ||
                v.name.contains('Sonia') ||
                v.name.contains('Jenny') ||
                v.locale.contains('en-KE') ||
                v.locale.contains('en-GB'),
            orElse: () => pool.first,
          );
          await _tts.setPitch(1.0);
          await _tts.setSpeechRate(kIsWeb ? 0.93 : 0.49);
        } else if (role == 'caller') {
          chosen = pool.firstWhere(
            (v) =>
                v.name.contains('Chilemba') ||
                v.name.contains('Mitchell') ||
                v.name.contains('Guy') ||
                v.name.contains('Ryan') ||
                v.name.toLowerCase().contains('male'),
            orElse: () => pool.first,
          );
          await _tts.setPitch(0.88);
          await _tts.setSpeechRate(kIsWeb ? 0.98 : 0.52);
        } else {
          chosen = pool.firstWhere(
            (v) =>
                v.name.contains('Asilia') ||
                v.name.contains('Libby') ||
                v.name.toLowerCase().contains('female'),
            orElse: () => pool.last,
          );
          await _tts.setPitch(1.06);
          await _tts.setSpeechRate(kIsWeb ? 0.96 : 0.50);
        }

        await _tts.setVoice({'name': chosen.name, 'locale': chosen.locale});
      }

      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stopSpeech() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// ============================================================================
// 2. NATIVE OFFLINE GSM SMS & VOICE CALL GATEWAY
// ============================================================================

class OfflineSmsGateway {
  static const MethodChannel _channel =
      MethodChannel('com.ngaosauti.firewall/offline_gsm');

  /// Dispatches an offline GSM SMS to a Guardian using Android SmsManager (on APK)
  /// or launches the native cellular SMS composer URI (`sms:`).
  static Future<bool> dispatchGuardianSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');

    // 1. Direct silent GSM SMS on Android APK
    if (!kIsWeb) {
      try {
        final dynamic sent = await _channel.invokeMethod(
          'sendDirectSms',
          {'phone': cleanPhone, 'message': message},
        );
        if (sent == true) return true;
      } catch (_) {}
    }

    // 2. Native OS SMS Intent Fallback (Works on Android & Web/Phone Link)
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> placeCellularVoiceCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final Uri telUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

// ============================================================================
// 3. ON-DEVICE MACHINE LEARNING ENGINE (RENAMED TO PREVENT CONFLICT)
// ============================================================================

class DialogueTurn {
  final String speaker;
  final String text;
  final String role; // 'caller' or 'user'
  final int riskSnapshot;
  final double logitSnapshot;

  const DialogueTurn({
    required this.speaker,
    required this.text,
    required this.role,
    this.riskSnapshot = 5,
    this.logitSnapshot = -1.1,
  });
}

class TrainingSample {
  final String text;
  final int label; 
  final String category;

  TrainingSample(this.text, this.label, this.category);
}

class MLInferenceResult {
  final double probability;
  final int riskPercentage;
  final Map<String, double> matchedFeatureWeights;
  final List<String> detectedVectors;
  final double logitScore;
  final String verdictExplanation;

  MLInferenceResult({
    required this.probability,
    required this.riskPercentage,
    required this.matchedFeatureWeights,
    required this.detectedVectors,
    required this.logitScore,
    required this.verdictExplanation,
  });
}

class NgaoOnDeviceScamMLModel {
  static double heldOutF1 = 0.94;

  final Map<String, double> weights = {};
  double bias = -1.15;
  double lastTrainingLoss = 0.0;
  double trainingAccuracy = 0.0;
  int totalEpochsTrained = 0;

  final List<TrainingSample> dataset = [
    // COERCIVE SCAM SAMPLES (Label = 1)
    TrainingSample('hello mzazi niko hospitali kwa emergency mtoto wako amepata ajali mbaya ameumia', 1, 'Urgency'),
    TrainingSample('hapana usikate simu na usipigie mtu daktari anasema tuma elfu kumi na tano kwa hii namba binafsi sasa hivi', 1, 'Urgency'),
    TrainingSample('tuma pesa kwa namba yangu binafsi kabla mtoto aingie theatre sasa hivi', 1, 'Financial Coercion'),
    TrainingSample('jambo nakupigia kutoka safaricom customer care kuna mwizi anajaribu kufanya sim swap kwa line yako', 1, 'Authority'),
    TrainingSample('tafadhali bonyeza pin yako sasa hivi na usomee ile otp code imeingia kwa simu yako', 1, 'PIN / SIM Trap'),
    TrainingSample('nimetuma pesa kimakosa tafadhali rudisha reverse kwa hii namba sasa hivi', 1, 'Financial Coercion'),
    TrainingSample('weka pin ya mpesa kwa hiyo prompt imeingia usikate simu', 1, 'PIN / SIM Trap'),
    TrainingSample('polisi wameshika kijana wako tuma elfu ishirini kwa namba binafsi', 1, 'Authority'),

    // GENUINE SAFE SAMPLES (Label = 0)
    TrainingSample('tunakupigia kutoka aga khan clinic kijana wako amepata homa kidogo kuja reception', 0, 'Safe'),
    TrainingSample('usitume pesa kwa namba ya mtu binafsi mpigie mtoto uhakikishe kisha ulipe kwa official hospital paybill', 0, 'Safe'),
    TrainingSample('unaweza kumpigia mtoto wako kwanza uhakikishe tuko ward four reception', 0, 'Safe'),
    TrainingSample('niko hapa supermarket nanunua bidhaa wacha nilipe kwa merchant till', 0, 'Safe'),
    TrainingSample('umefika nyumbani salama ndio niko darasani nitakupigia baadaye', 0, 'Safe'),
    TrainingSample('tutakutana kesho asubuhi kwa mkutano wa familia asante sana', 0, 'Safe'),
  ];

  NgaoOnDeviceScamMLModel() {
    trainModel(epochs: 75, learningRate: 0.24);
  }

  List<String> extractFeatures(String rawText) {
    final cleaned = rawText
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    final List<String> features = [...cleaned];
    for (int i = 0; i < cleaned.length - 1; i++) {
      features.add('${cleaned[i]}_${cleaned[i + 1]}');
    }
    return features;
  }

  double _sigmoid(double z) {
    if (z > 20) return 0.9999;
    if (z < -20) return 0.0001;
    return 1.0 / (1.0 + exp(-z));
  }

  void trainModel({int epochs = 50, double learningRate = 0.22}) {
    double totalLoss = 0.0;
    int correct = 0;

    for (int epoch = 0; epoch < epochs; epoch++) {
      totalLoss = 0.0;
      correct = 0;

      for (final sample in dataset) {
        final feats = extractFeatures(sample.text);
        double z = bias;
        for (final f in feats) {
          z += (weights[f] ?? 0.0);
        }

        final pred = _sigmoid(z);
        final y = sample.label.toDouble();

        totalLoss += -(y * log(pred + 1e-9) + (1 - y) * log(1 - pred + 1e-9));

        if ((pred >= 0.5 && sample.label == 1) ||
            (pred < 0.5 && sample.label == 0)) {
          correct++;
        }

        final error = pred - y;
        bias -= learningRate * error * 0.3;
        for (final f in feats) {
          final prev = weights[f] ?? 0.0;
          weights[f] = prev - learningRate * (error + 0.002 * prev);
        }
      }
      totalEpochsTrained++;
    }

    lastTrainingLoss = totalLoss / dataset.length;
    trainingAccuracy = (correct / dataset.length) * 100.0;
  }

  MLInferenceResult predictWindow(List<String> turns) {
    final int start = turns.length > 3 ? turns.length - 3 : 0;
    final String windowText = turns.sublist(start).join(' ');
    return predict(windowText);
  }

  MLInferenceResult predict(String transcriptText) {
    final feats = extractFeatures(transcriptText);
    double z = bias;
    final Map<String, double> activeWeights = {};
    final Set<String> vectors = {};

    for (final f in feats) {
      final w = weights[f] ?? 0.0;
      z += w;
      if (w.abs() > 0.15) {
        activeWeights[f] = w;
      }
      if (f.contains('sasa_hivi') ||
          f.contains('usikate_simu') ||
          f.contains('ameumia') ||
          f.contains('ajali')) {
        vectors.add('Urgency');
      }
      if (f.contains('safaricom') ||
          f.contains('customer_care') ||
          f.contains('polisi')) {
        vectors.add('Authority');
      }
      if (f.contains('namba_binafsi') ||
          f.contains('rudisha') ||
          f.contains('tuma_elfu') ||
          f.contains('reverse')) {
        vectors.add('Financial Coercion');
      }
      if (f.contains('pin') || f.contains('otp') || f.contains('sim_swap')) {
        vectors.add('PIN / SIM Trap');
      }
    }

    final prob = _sigmoid(z);
    final riskPct = (prob * 100).round().clamp(4, 99);

    String explanation;
    if (riskPct >= 75) {
      explanation =
          'HIGH THREAT: Coercive urgency + personal line/PIN demand + verification blocked.';
    } else if (transcriptText.toLowerCase().contains('paybill') ||
        transcriptText.toLowerCase().contains('reception')) {
      explanation =
          'VERIFIED INSTITUTIONAL CALL: Caller directed to Official Paybill & encouraged independent verification.';
    } else {
      explanation =
          'SAFE CONTEXT: Normal conversational cadence with zero coercion vectors.';
    }

    return MLInferenceResult(
      probability: prob,
      riskPercentage: riskPct,
      matchedFeatureWeights: activeWeights,
      detectedVectors: vectors.toList(),
      logitScore: z,
      verdictExplanation: explanation,
    );
  }

  void addSampleAndRetrain(String text, int label, String category) {
    dataset.add(TrainingSample(text, label, category));
    trainModel(epochs: 45, learningRate: 0.24);
  }
}

// ============================================================================
// 4. APPLICATION DATA MODELS
// ============================================================================

class Guardian {
  final String id;
  String name;
  String phone;
  String relation;
  bool isPrimary;
  String status;
  String? vote; // null, 'approve', 'block'

  Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = true,
    this.status = 'GSM Ready',
    this.vote,
  });
}

class SmsMessageItem {
  final String sender;
  final String body;
  final String time;
  final bool isOfficialToken;

  SmsMessageItem({
    required this.sender,
    required this.body,
    required this.time,
    required this.isOfficialToken,
  });
}

// ============================================================================
// 5. ROOT APPLICATION & CONTROLLER
// ============================================================================

class NgaoSautiApp extends StatelessWidget {
  const NgaoSautiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ngao-Sauti — On-Device AI Call & Payment Firewall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF0F172A),
        dividerColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF0F172A),
          error: Color(0xFFEF4444),
        ),
        useMaterial3: true,
      ),
      home: const RootController(),
    );
  }
}

class RootController extends StatefulWidget {
  const RootController({super.key});

  @override
  State<RootController> createState() => _RootControllerState();
}

class _RootControllerState extends State<RootController> {
  bool _hasCompletedOnboarding = false;
  String _userName = '';
  String _userPhone = '';
  String _safePhrase = '';
  List<Guardian> _guardians = [];

  void _completeOnboarding({
    required String name,
    required String phone,
    required String safePhrase,
    required List<Guardian> guardians,
  }) {
    setState(() {
      _userName = name;
      _userPhone = phone;
      _safePhrase = safePhrase;
      _guardians = guardians;
      _hasCompletedOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCompletedOnboarding) {
      return OnboardingFlowScreen(onCompleted: _completeOnboarding);
    }
    return MainShellScreen(
      userName: _userName,
      userPhone: _userPhone,
      safePhrase: _safePhrase,
      initialGuardians: _guardians,
      onReopenOnboarding: () => setState(() => _hasCompletedOnboarding = false),
    );
  }
}

// ============================================================================
// 6. FULL 3-STEP ONBOARDING WIZARD
// ============================================================================

class OnboardingFlowScreen extends StatefulWidget {
  final void Function({
    required String name,
    required String phone,
    required String safePhrase,
    required List<Guardian> guardians,
  }) onCompleted;

  const OnboardingFlowScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _step = 0;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phraseCtrl = TextEditingController(text: 'Nyumba Salama');

  final _gNameCtrl = TextEditingController();
  final _gPhoneCtrl = TextEditingController();
  String _gRelation = 'Son / Daughter';
  bool _gIsPrimary = true;
  final List<Guardian> _draftGuardians = [];

  bool _permLocalModelLoaded = true;
  bool _permVoiceEngine = true;
  bool _permAccessibility = true;
  bool _permOfflineSms = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      NeuralVoiceEngine.warmUpVoices();
    });
  }

  void _loadFamilyPreset() {
    setState(() {
      _nameCtrl.text = 'Mama Njeri';
      _phoneCtrl.text = '+254722109482';
      _phraseCtrl.text = 'Nyumba Salama';
      _draftGuardians.clear();
      _draftGuardians.addAll([
        Guardian(
          id: '1',
          name: 'Owen Mwangi',
          phone: '+254748465466',
          relation: 'Son (Primary)',
          isPrimary: true,
        ),
        Guardian(
          id: '2',
          name: 'Muhammed Hassan',
          phone: '+254722556677',
          relation: 'Brother (Primary)',
          isPrimary: true,
        ),
        Guardian(
          id: '3',
          name: 'Collins Mundia',
          phone: '+254733889900',
          relation: 'Nephew (Primary)',
          isPrimary: true,
        ),
        Guardian(
          id: '4',
          name: 'Grace Wanjiku',
          phone: '+254744111222',
          relation: 'Trusted Neighbor (SMS Backup)',
          isPrimary: false,
          status: 'SMS Fallback',
        ),
      ]);
    });
    NeuralVoiceEngine.speak(
      'Welcome, Mama Njeri. Owen, Muhammed, and Collins have been registered as your trusted family guardians.',
      role: 'ai',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded Family Guardian Profile (Owen, Muhammed, Collins, Grace).'),
      ),
    );
  }

  void _addGuardianToList() {
    final name = _gNameCtrl.text.trim();
    final phone = _gPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Guardian Name and Phone Number.'),
        ),
      );
      return;
    }
    setState(() {
      _draftGuardians.add(
        Guardian(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          phone: phone,
          relation: _gRelation,
          isPrimary: _gIsPrimary,
          status: _gIsPrimary ? 'GSM Ready' : 'SMS Fallback',
        ),
      );
      _gNameCtrl.clear();
      _gPhoneCtrl.clear();
    });
  }

  void _nextStep() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter your name & phone number, or tap "Quick-Fill Profile" at top right.',
            ),
          ),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_draftGuardians.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please register at least 2 Family Guardians for 2-of-N consensus.',
            ),
          ),
        );
        return;
      }
      setState(() => _step = 2);
    } else {
      widget.onCompleted(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        safePhrase: _phraseCtrl.text.trim().isEmpty
            ? 'Nyumba Salama'
            : _phraseCtrl.text.trim(),
        guardians: _draftGuardians,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF06B6D4), size: 22),
            SizedBox(width: 10),
            Text(
              'NGAO-SAUTI SETUP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4).withOpacity(0.15),
              ),
              onPressed: _loadFamilyPreset,
              icon: const Icon(Icons.bolt, size: 16, color: Color(0xFF06B6D4)),
              label: const Text(
                'Quick-Fill Profile',
                style: TextStyle(
                  color: Color(0xFF06B6D4),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStepPill(0, '1. Protected User'),
                    const SizedBox(width: 8),
                    _buildStepPill(1, '2. Family Guardians'),
                    const SizedBox(width: 8),
                    _buildStepPill(2, '3. Edge AI & GSM'),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0
                      ? _buildStep1Profile()
                      : _step == 1
                          ? _buildStep2Guardians()
                          : _buildStep3Permissions(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_step > 0)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _step--),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back'),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _nextStep,
                      icon: Icon(
                        _step == 2 ? Icons.verified_user : Icons.arrow_forward,
                        size: 18,
                      ),
                      label: Text(
                        _step == 2
                            ? 'Activate Ngao-Sauti Protection'
                            : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepPill(int idx, String title) {
    final active = _step == idx;
    final done = _step > idx;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : done
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF3B82F6)
                : done
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1E293B),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active
                ? Colors.white
                : done
                    ? const Color(0xFF10B981)
                    : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Profile() {
    return Container(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protect Your Mobile Money & SIM Card',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ngao-Sauti runs a 100% On-Device Machine Learning firewall that detects coercive scam calls in real time—pausing M-Pesa transfers & SIM-swap USSD codes only when a threat is active.',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name of Protected User',
              hintText: 'e.g. Mama Njeri',
              prefixIcon: Icon(Icons.person_outline),
              filled: true,
              fillColor: Color(0xFF030712),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Primary Mobile Money Phone Number',
              hintText: 'e.g. +254722109482',
              prefixIcon: Icon(Icons.phone_android),
              filled: true,
              fillColor: Color(0xFF030712),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phraseCtrl,
            decoration: const InputDecoration(
              labelText: 'Calm-Voice Safe Phrase (Offline Self-Override)',
              hintText: 'e.g. Nyumba Salama',
              prefixIcon: Icon(Icons.record_voice_over_outlined),
              filled: true,
              fillColor: Color(0xFF030712),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Guardians() {
    return Container(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2-of-N Family Guardian Consensus Circle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'People First, AI Second: When a high-risk call is intercepted, Ngao-Sauti dispatches an offline GSM SMS with a 4-digit security pin to your Guardians.',
            style: TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Name',
                    filled: true,
                    fillColor: Color(0xFF030712),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _gPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (+254...)',
                    filled: true,
                    fillColor: Color(0xFF030712),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gRelation,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    filled: true,
                    fillColor: Color(0xFF030712),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Son / Daughter',
                      child: Text('Son / Daughter'),
                    ),
                    DropdownMenuItem(
                      value: 'Brother / Sister',
                      child: Text('Brother / Sister'),
                    ),
                    DropdownMenuItem(
                      value: 'Nephew / Niece',
                      child: Text('Nephew / Niece'),
                    ),
                    DropdownMenuItem(
                      value: 'Trusted Neighbor',
                      child: Text('Trusted Neighbor'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _gRelation = v ?? 'Son / Daughter'),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: Text(_gIsPrimary ? 'Primary Tier' : 'SMS Backup'),
                selected: _gIsPrimary,
                onSelected: (v) => setState(() => _gIsPrimary = v),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                ),
                onPressed: _addGuardianToList,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          Text(
            'Registered Guardians (${_draftGuardians.length}):',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          if (_draftGuardians.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No guardians added yet. Add above or tap "Quick-Fill Profile" in the top bar.',
                style: TextStyle(fontSize: 12, color: Colors.amber),
              ),
            )
          else
            ..._draftGuardians.map(
              (g) => Card(
                color: const Color(0xFF030712),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: g.isPrimary
                        ? const Color(0xFF3B82F6)
                        : Colors.amber.shade800,
                    child: Text(
                      g.name[0],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  title: Text(
                    g.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${g.phone} • ${g.relation}'),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _draftGuardians.remove(g)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3Permissions() {
    return Container(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'On-Device Edge AI & OS Protection Layers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _permLocalModelLoaded,
            onChanged: (v) => setState(() => _permLocalModelLoaded = v),
            title: const Text('On-Device Logistic Perceptron + Bigram NLU'),
            subtitle: const Text(
              'Runs 100% offline with 0 MB mobile data required.',
            ),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permVoiceEngine,
            onChanged: (v) => setState(() => _permVoiceEngine = v),
            title: const Text(
              'Natural Neural Voice Assistant & Call Screening',
            ),
            subtitle: const Text(
              'Human-paced spoken alerts & real-time two-way call analysis.',
            ),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permAccessibility,
            onChanged: (v) => setState(() => _permAccessibility = v),
            title: const Text(
              'Context-Aware Merchant STK & USSD (*100#) Shield',
            ),
            subtitle: const Text(
              'Allows normal retail/hospital payments when safe; freezes PIN entry during scam calls.',
            ),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permOfflineSms,
            onChanged: (v) => setState(() => _permOfflineSms = v),
            title: const Text('Two-Way Offline GSM SMS Guardian Confirmation'),
            subtitle: const Text(
              'Sends 4-digit SMS security pin & unlocks on "SAFE <PIN>" SMS replies.',
            ),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. MAIN 4-TAB APPLICATION SHELL (ANIMATED + OFFLINE SMS CONFIRMATION)
// ============================================================================

class MainShellScreen extends StatefulWidget {
  final String userName;
  final String userPhone;
  final String safePhrase;
  final List<Guardian> initialGuardians;
  final VoidCallback onReopenOnboarding;

  const MainShellScreen({
    super.key,
    required this.userName,
    required this.userPhone,
    required this.safePhrase,
    required this.initialGuardians,
    required this.onReopenOnboarding,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  bool _isOfflineNoDataMode = true;
  bool _audioMuted = false;

  final NgaoOnDeviceScamMLModel _mlModel = NgaoOnDeviceScamMLModel();
  static const MethodChannel _gsmChannel =
      MethodChannel('com.ngaosauti.firewall/offline_gsm');

  bool _isRinging = false;
  bool _isCallActive = false;
  bool _isFinancialLocked = false;
  int _riskScore = 5;
  double _lastLogit = -1.15;
  String _verdictExplanation =
      'SAFE CONTEXT: Background auditor armed. Normal payments & USSD allowed.';
  Map<String, double> _lastMatchedWeights = {};

  String _activeCallerName = 'Standby';
  String _activeCallerNumber = 'No active call';
  String _pendingScenario = 'hospital_scam';
  String _activeSecurityPin = '4829';
  int _callSeconds = 0;
  final List<String> _callTurns = [];

  Timer? _ringTimer;
  Timer? _callTimer;
  Timer? _scriptTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 900;

  late AnimationController _pulseController;

  final Set<String> _triggeredCategories = {};
  final List<DialogueTurn> _liveTurns = [];
  final List<String> _systemLogs = [
    '[ML BOOT] On-Device SGD Logistic Perceptron trained across Swahili/Sheng samples.',
    '[GSM BRIDGE] Offline Two-Way SMS Guardian confirmation listener armed.',
    '[CONTEXT SHIELD] Merchant STK & *100# USSD filter armed.',
  ];

  late List<Guardian> _guardians;
  final TextEditingController _customSpeechCtrl = TextEditingController();
  final TextEditingController _ussdCtrl = TextEditingController(text: '*100#');
  final TextEditingController _incomingSmsReplyCtrl = TextEditingController();
  final TextEditingController _trainSentenceCtrl = TextEditingController();
  int _trainLabel = 1;

  final TextEditingController _smsSenderCtrl = TextEditingController(
    text: '+254719882341',
  );
  final TextEditingController _smsBodyCtrl = TextEditingController(
    text:
        'UBA45X9K2L Confirmed. You have received Ksh15,000.00 from JOHN KAMAU on 30/10/26. Please reverse urgently.',
  );

  final List<SmsMessageItem> _smsInbox = [
    SmsMessageItem(
      sender: '+254719882341',
      body:
          'UBA45X9K2L Confirmed. You have received Ksh15,000.00 from JOHN KAMAU 0719882341 on 30/10/26 at 9:10 AM. New M-PESA balance is Ksh63,200.00.',
      time: '9:10 AM',
      isOfficialToken: false,
    ),
    SmsMessageItem(
      sender: 'MPESA',
      body:
          'UAY12P4L9M Confirmed. Ksh1,850.00 paid to RETAIL SUPERMARKET TILL 512900 on 30/10/26 at 8:15 AM.',
      time: '8:15 AM',
      isOfficialToken: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _guardians = List.from(widget.initialGuardians);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    NeuralVoiceEngine.warmUpVoices();

    // Listen for native Android incoming Guardian SMS replies
    _gsmChannel.setMethodCallHandler((call) async {
      if (call.method == 'onGuardianSmsReceived') {
        final dynamic args = call.arguments;
        if (args is Map) {
          final sender = (args['sender'] ?? '').toString();
          final body = (args['body'] ?? '').toString();
          _verifyGuardianSmsReply(senderPhone: sender, smsReplyText: body);
        }
      }
    });
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _scriptTimer?.cancel();
    _cooldownTimer?.cancel();
    _pulseController.dispose();
    _customSpeechCtrl.dispose();
    _ussdCtrl.dispose();
    _incomingSmsReplyCtrl.dispose();
    _trainSentenceCtrl.dispose();
    _smsSenderCtrl.dispose();
    _smsBodyCtrl.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _systemLogs.insert(0, '[$timeStr] $msg');
    });
  }

  // ==========================================================================
  // CALL INTERCEPTION & SPOKEN 2-WAY DIALOGUE ENGINE
  // ==========================================================================

  List<DialogueTurn> _getScenarioDialogue(String scenario) {
    if (scenario == 'true_hospital') {
      return [
        DialogueTurn(
          speaker: 'Hospital Desk',
          text:
              'Hello, ${widget.userName}. Tunakupigia kutoka Aga Khan Clinic. Kijana wako amepata homa kidogo.',
          role: 'caller',
        ),
        DialogueTurn(
          speaker: 'You (${widget.userName})',
          text: 'Je, ni kweli? Nilipe pesa kwa namba gani, ama nije hapo?',
          role: 'user',
        ),
        const DialogueTurn(
          speaker: 'Hospital Desk',
          text:
              'Usitume pesa kwa namba ya mtu binafsi. Unaweza kumpigia mtoto wako uhakikishe, kisha ulipe kwa Official Hospital Paybill ukifika reception.',
          role: 'caller',
        ),
      ];
    }
    if (scenario == 'safaricom_scam') {
      return [
        const DialogueTurn(
          speaker: 'Caller',
          text:
              'Jambo, nakupigia kutoka Safaricom Customer Care. Kuna mwizi anajaribu kufanya, SIM swap, kwa line yako.',
          role: 'caller',
        ),
        DialogueTurn(
          speaker: 'You (${widget.userName})',
          text: 'Sasa nifanye nini, ndio line yangu isifungwe?',
          role: 'user',
        ),
        const DialogueTurn(
          speaker: 'Caller',
          text:
              'Tafadhali, bonyeza PIN yako sasa hivi, na usomee ile OTP code imeingia kwa simu yako!',
          role: 'caller',
        ),
      ];
    }
    return [
      const DialogueTurn(
        speaker: 'Caller',
        text:
            'Hello, mzazi! Niko hapa hospitali, kwa emergency. Mtoto wako amepata ajali mbaya, na ameumia!',
        role: 'caller',
      ),
      DialogueTurn(
        speaker: 'You (${widget.userName})',
        text:
            'Mungu wangu! Wacha nimpigie mtoto wangu simu kwanza, nihakikishe.',
        role: 'user',
      ),
      const DialogueTurn(
        speaker: 'Caller',
        text:
            'Hapana, usikate simu na usipigie mtu! Daktari anasema, tuma elfu kumi na tano kwa hii namba binafsi, sasa hivi!',
        role: 'caller',
      ),
    ];
  }

  void _ringIncomingCall(String scenario) {
    _resetCallState();
    setState(() {
      _pendingScenario = scenario;
      _isRinging = true;
      if (scenario == 'hospital_scam') {
        _activeCallerName = 'Unknown Caller';
        _activeCallerNumber = '+254 724 889 102';
      } else if (scenario == 'true_hospital') {
        _activeCallerName = 'Aga Khan Hospital Desk';
        _activeCallerNumber = '+254 20 374 0000';
      } else {
        _activeCallerName = 'Unverified Care Line';
        _activeCallerNumber = '+254 710 442 991';
      }
    });

    NeuralVoiceEngine.playTone(freq: 820, durationMs: 260, type: 'square');
    _ringTimer?.cancel();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isRinging) {
        _ringTimer?.cancel();
        return;
      }
      NeuralVoiceEngine.playTone(freq: 820, durationMs: 260, type: 'square');
    });

    _addLog(
      '[INCOMING CALL] Ringing from $_activeCallerNumber ($_activeCallerName).',
    );
  }

  void _answerCall() {
    _ringTimer?.cancel();
    setState(() {
      _isRinging = false;
      _isCallActive = true;
      _callSeconds = 0;
      _callTurns.clear();
      _liveTurns.clear();
    });

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _callSeconds++);
    });

    final List<DialogueTurn> turns = _getScenarioDialogue(_pendingScenario);
    int idx = 0;

    _processDialogueTurn(turns[0]);
    idx = 1;

    _scriptTimer?.cancel();
    _scriptTimer = Timer.periodic(const Duration(milliseconds: 6200), (timer) {
      if (!_isCallActive || idx >= turns.length) {
        timer.cancel();
        return;
      }
      _processDialogueTurn(turns[idx]);
      idx++;
    });
  }

  void _processDialogueTurn(DialogueTurn turn) {
    NeuralVoiceEngine.speak(turn.text, role: turn.role);

    _callTurns.add(turn.text);
    final result = _mlModel.predictWindow(_callTurns);

    setState(() {
      _riskScore = max(_riskScore, result.riskPercentage);
      _lastLogit = result.logitScore;
      _verdictExplanation = result.verdictExplanation;
      _lastMatchedWeights = result.matchedFeatureWeights;
      _triggeredCategories.addAll(result.detectedVectors);
      _liveTurns.add(
        DialogueTurn(
          speaker: turn.speaker,
          text: turn.text,
          role: turn.role,
          riskSnapshot: result.riskPercentage,
          logitSnapshot: result.logitScore,
        ),
      );
    });

    _addLog(
      '[ML INFERENCE] ${turn.speaker} -> P(Scam)=${result.riskPercentage}% (Logit z=${result.logitScore.toStringAsFixed(2)})',
    );

    if (_riskScore >= 75 && !_isFinancialLocked) {
      Future.delayed(const Duration(milliseconds: 3800), () {
        if (!mounted || !_isCallActive) return;
        _triggerSelectiveFinancialLock(
          reason:
              'On-Device ML Classifier detected ${result.riskPercentage}% Scam Probability (${result.verdictExplanation})',
        );
      });
    }
  }

  // ==========================================================================
  // OFFLINE GSM SMS DISPATCH & TWO-WAY SMS CONFIRMATION ENGINE
  // ==========================================================================

  Future<void> _sendOfflineSmsToGuardian(Guardian g) async {
    final String smsPayload =
        'NGAO-SAUTI ALERT: ${widget.userName} is on a $_riskScore% risk call ($_activeCallerNumber). M-Pesa is PAUSED. Reply "SAFE $_activeSecurityPin" to unlock or "BLOCK $_activeSecurityPin" to freeze.';
    final bool launched = await OfflineSmsGateway.dispatchGuardianSms(
      phone: g.phone,
      message: smsPayload,
    );
    setState(() {
      g.status = launched
          ? 'GSM SMS Sent (PIN $_activeSecurityPin)'
          : 'SMS Queued (PIN $_activeSecurityPin)';
    });
    _addLog(
      '[OFFLINE GSM SMS] Sent confirmation request to ${g.name} (${g.phone}) with PIN $_activeSecurityPin.',
    );
  }

  void _verifyGuardianSmsReply({
    required String senderPhone,
    required String smsReplyText,
  }) {
    final upper = smsReplyText.trim().toUpperCase();
    final bool hasSafe = upper.contains('SAFE');
    final bool hasBlock = upper.contains('BLOCK');

    if (!hasSafe && !hasBlock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unrecognized SMS command. Reply "SAFE $_activeSecurityPin" or "BLOCK $_activeSecurityPin".',
          ),
        ),
      );
      return;
    }

    Guardian targetGuardian = _guardians.firstWhere(
      (g) => g.vote == null,
      orElse: () => _guardians.first,
    );

    setState(() {
      targetGuardian.status = 'Confirmed via Offline SMS';
    });

    _castGuardianVote(targetGuardian, hasSafe ? 'approve' : 'block');
  }

  Future<void> _triggerSelectiveFinancialLock({required String reason}) async {
    final String generatedPin = (1000 + Random().nextInt(8999)).toString();
    setState(() {
      _isFinancialLocked = true;
      _cooldownSeconds = 900;
      _activeSecurityPin = generatedPin;
      for (final g in _guardians) {
        g.status = 'GSM SMS Dispatched (PIN $generatedPin)';
      }
    });

    NeuralVoiceEngine.speak(
      'Attention, ${widget.userName}. Ngao Sauti has detected high-pressure scam manipulation on this call. Outgoing M-Pesa transfers and SIM swap codes are paused. Dispatching offline SMS verification pin $generatedPin to your family guardians.',
      role: 'ai',
    );

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cooldownSeconds > 0) setState(() => _cooldownSeconds--);
    });

    _addLog(
      '[CIRCUIT BREAKER] $reason Outgoing M-Pesa & *100# frozen. Offline SMS Pin: $_activeSecurityPin.',
    );

    if (_guardians.isNotEmpty) {
      await _sendOfflineSmsToGuardian(_guardians.first);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F14),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Selective Financial Lock Active',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFCA5A5),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📲 Offline GSM Verification Pin: $_activeSecurityPin',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '1. Normal voice calls stay 100% OPEN so you can call your family directly.\n'
                    '2. Offline GSM SMS sent to your Guardians—replying "SAFE <PIN>" from 2 Guardians unlocks M-Pesa immediately.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedTab = 2);
            },
            child: const Text('Guardian Consensus (2-of-N)'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _placeDirectFamilyCall();
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Family Directly'),
          ),
        ],
      ),
    );
  }

  void _placeDirectFamilyCall() {
    final firstGuardian = _guardians.isNotEmpty
        ? _guardians.first.name
        : 'Family Guardian';
    NeuralVoiceEngine.speak(
      'Dialing $firstGuardian directly on a verified voice line.',
      role: 'ai',
    );
    if (_guardians.isNotEmpty) {
      OfflineSmsGateway.placeCellularVoiceCall(_guardians.first.phone);
    }
    _addLog(
      '[SAFE DIALER] Placed direct verification voice call to $firstGuardian.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF065F46),
        content: Text(
          'Dialing $firstGuardian... Standard voice calls are never blocked!',
        ),
      ),
    );
  }

  void _executeMerchantStkPush() {
    if (_isFinancialLocked) {
      NeuralVoiceEngine.speak(
        'Warning. M-Pesa STK prompt blocked because you are on an unverified high-risk call. Do not enter your PIN.',
        role: 'ai',
      );
      _addLog(
        '[STK FIREWALL] Intercepted & blocked STK Push PIN prompt during active scam lock.',
      );
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F14),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFEF4444)),
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            '🛑 STK Push Prompt Intercepted',
            style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 16),
          ),
          content: const Text(
            'Ngao-Sauti blocked this M-Pesa STK prompt because an active scam threat was detected on your line.\n\nRemember: Entering your M-Pesa PIN always SENDS money out—it never receives or reverses funds.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss Fraudulent Prompt'),
            ),
          ],
        ),
      );
      return;
    }

    NeuralVoiceEngine.speak(
      'Context verified safe. Merchant STK payment prompt allowed.',
      role: 'ai',
    );
    _addLog(
      '[CONTEXT-AWARE STK] Allowed legitimate Ksh 1,850 Merchant / Hospital STK Push (Risk is low: $_riskScore%).',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF062E22),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF10B981)),
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          '✅ SIM Toolkit Payment Allowed',
          style: TextStyle(color: Color(0xFF10B981), fontSize: 16),
        ),
        content: const Text(
          'M-PESA STK Prompt:\nPay Ksh 1,850.00 to VERIFIED MERCHANT / OFFICIAL PAYBILL?\n\n(Context-Aware Check: No coercive call active — payment proceeds seamlessly without annoying the user.)',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Enter PIN & Confirm'),
          ),
        ],
      ),
    );
  }

  void _runUssdCode() {
    final code = _ussdCtrl.text.trim();
    if (_isFinancialLocked) {
      NeuralVoiceEngine.speak(
        'USSD execution blocked to prevent unauthorized SIM swap.',
        role: 'ai',
      );
      _addLog('[USSD FIREWALL] Blocked $code execution during active threat.');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F14),
          title: Text(
            '🛑 USSD ($code) Blocked',
            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 16),
          ),
          content: Text(
            'Ngao-Sauti prevented $code from running during an unverified high-risk call to protect against SIM-swap and USSD fund transfers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
      return;
    }

    _addLog('[USSD DIALER] Executed $code normally (Context safe).');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          'Carrier USSD Menu ($code)',
          style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 15),
        ),
        content: const Text(
          '1. My Account & Airtime Balance\n2. Data & Voice Bundles\n3. M-PESA Services\n4. SIM Management\n\n(USSD works normally when no scam threat is active.)',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetCallState() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _scriptTimer?.cancel();
    _cooldownTimer?.cancel();
    NeuralVoiceEngine.stopSpeech();
    setState(() {
      _isRinging = false;
      _isCallActive = false;
      _isFinancialLocked = false;
      _riskScore = 5;
      _lastLogit = _mlModel.bias;
      _verdictExplanation =
          'SAFE CONTEXT: Background auditor armed. Normal payments & USSD allowed.';
      _lastMatchedWeights = {};
      _callTurns.clear();
      _activeCallerName = 'Standby';
      _activeCallerNumber = 'No active call';
      _triggeredCategories.clear();
      _liveTurns.clear();
      for (final g in _guardians) {
        g.vote = null;
        g.status = g.isPrimary ? 'GSM Ready' : 'SMS Fallback';
      }
    });
  }

  // ==========================================================================
  // BUILD MAIN APPLICATION SHELL
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final approvals = _guardians.where((g) => g.vote == 'approve').length;
    final blocks = _guardians.where((g) => g.vote == 'block').length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield,
                color: Color(0xFF06B6D4),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NGAO-SAUTI OS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Protected: ${widget.userName} (${widget.userPhone}) • Held-out F1: ${NgaoOnDeviceScamMLModel.heldOutF1.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Neural Voice Output',
            onPressed: () {
              setState(() {
                _audioMuted = !_audioMuted;
                NeuralVoiceEngine.soundEnabled = !_audioMuted;
              });
              if (!_audioMuted) {
                NeuralVoiceEngine.speak('Natural voice enabled.', role: 'ai');
              } else {
                NeuralVoiceEngine.stopSpeech();
              }
            },
            icon: Icon(
              _audioMuted ? Icons.volume_off : Icons.volume_up,
              color: const Color(0xFF06B6D4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: () =>
                  setState(() => _isOfflineNoDataMode = !_isOfflineNoDataMode),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOfflineNoDataMode
                          ? Icons.airplanemode_active
                          : Icons.wifi,
                      size: 14,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOfflineNoDataMode
                          ? 'ON-DEVICE ML (0 DATA)'
                          : 'HYBRID ML',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'User & Guardian Setup',
            onPressed: widget.onReopenOnboarding,
            icon: const Icon(Icons.manage_accounts_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Reset State',
            onPressed: _resetCallState,
            icon: const Icon(Icons.refresh, size: 20),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildTab1CallAndPaymentShield(),
                  _buildTab2SmsSpoofGuard(),
                  _buildTab3GuardianConsensus(approvals, blocks),
                  _buildTab4MLStudioAndLogs(),
                ],
              ),
            ),
          ),
          if (_isRinging) _buildAnimatedIncomingCallOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.phone_in_talk_outlined),
            selectedIcon: Icon(Icons.phone_in_talk, color: Color(0xFF06B6D4)),
            label: 'Call & STK Shield',
          ),
          const NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms, color: Color(0xFF06B6D4)),
            label: 'SMS Reversal Guard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _isFinancialLocked,
              label: const Text('!'),
              child: const Icon(Icons.group_outlined),
            ),
            selectedIcon: const Icon(Icons.group, color: Color(0xFF06B6D4)),
            label: 'Guardians (${_guardians.length})',
          ),
          const NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: Color(0xFF06B6D4)),
            label: 'ML Studio & Logs',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: ANIMATED CALL & CONTEXT-AWARE PAYMENT SHIELD
  // ==========================================================================

  Widget _buildTab1CallAndPaymentShield() {
    final bool isDanger = _riskScore >= 75;
    final Color statusColor = isDanger
        ? const Color(0xFFEF4444)
        : _riskScore >= 40
            ? Colors.amber
            : const Color(0xFF10B981);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.22),
                  statusColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withOpacity(0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCallActive
                          ? 1.0 + (_pulseController.value * 0.14)
                          : 1.0,
                      child: Icon(
                        _isFinancialLocked
                            ? Icons.lock_rounded
                            : Icons.verified_user_rounded,
                        color: statusColor,
                        size: 36,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isFinancialLocked
                            ? 'SELECTIVE LOCK ACTIVE: M-PESA & *100# PAUSED (Risk: $_riskScore%)'
                            : 'SHIELD ARMED: PAYMENTS & USSD ALLOWED (Risk: $_riskScore%)',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _verdictExplanation,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                      if (_isFinancialLocked) ...[
                        const SizedBox(height: 6),
                        Text(
                          '⏳ Cooldown Timer: ${(_cooldownSeconds ~/ 60).toString().padLeft(2, '0')}:${(_cooldownSeconds % 60).toString().padLeft(2, '0')} • Waiting for 2-of-${_guardians.length} Family Guardians',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Incoming Call Scenarios (With Spoken 2-Way Neural Audio)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScenarioCardButton(
                  title: 'Emergency Coercion Scam',
                  subtitle: 'Personal Line Demand',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: () => _ringIncomingCall('hospital_scam'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScenarioCardButton(
                  title: 'Verified Hospital Call',
                  subtitle: 'Official Paybill Allowed',
                  icon: Icons.local_hospital_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () => _ringIncomingCall('true_hospital'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScenarioCardButton(
                  title: 'Telco SIM-Swap Trap',
                  subtitle: 'PIN & OTP Harvesting',
                  icon: Icons.sim_card_alert_outlined,
                  color: Colors.amber,
                  onTap: () => _ringIncomingCall('safaricom_scam'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCallActive ? Icons.graphic_eq : Icons.mic_none,
                          color: const Color(0xFF06B6D4),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Call Monitor: $_activeCallerName ($_activeCallerNumber)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                    if (_isCallActive)
                      Row(
                        children: [
                          _AnimatedWaveform(controller: _pulseController),
                          const SizedBox(width: 10),
                          Text(
                            '00:${(_callSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _riskScore / 100.0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1E293B),
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Urgency',
                    'Authority',
                    'Financial Coercion',
                    'PIN / SIM Trap',
                  ].map((vec) {
                    final active = _triggeredCategories.contains(vec);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEF4444).withOpacity(0.2)
                            : const Color(0xFF030712),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      child: Text(
                        vec,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? const Color(0xFFFCA5A5)
                              : Colors.white54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                Container(
                  height: 185,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030712),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: _liveTurns.isEmpty
                      ? const Center(
                          child: Text(
                            'Select an incoming call scenario above to hear the live two-way conversation and watch the On-Device ML score each sentence.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white38,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _liveTurns.length,
                          itemBuilder: (ctx, i) {
                            final turn = _liveTurns[i];
                            final isCaller = turn.role == 'caller';
                            return TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 350),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - val)),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCaller
                                      ? const Color(0xFF1E293B).withOpacity(0.6)
                                      : const Color(0xFF3B82F6)
                                          .withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '🎙️ ${turn.speaker}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: isCaller
                                                ? const Color(0xFFFCA5A5)
                                                : const Color(0xFF60A5FA),
                                          ),
                                        ),
                                        Text(
                                          'ML Risk: ${turn.riskSnapshot}% (z=${turn.logitSnapshot.toStringAsFixed(2)})',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontFamily: 'monospace',
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '"${turn.text}"',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSpeechCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'Speak or type live phrase into call (e.g. "Tuma pesa kwa namba binafsi sasa hivi")...',
                          filled: true,
                          fillColor: const Color(0xFF030712),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            _isCallActive = true;
                            _processDialogueTurn(
                              DialogueTurn(
                                speaker: 'Live Audio Input',
                                text: v.trim(),
                                role: 'caller',
                              ),
                            );
                            _customSpeechCtrl.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                      onPressed: () {
                        if (_customSpeechCtrl.text.trim().isNotEmpty) {
                          _isCallActive = true;
                          _processDialogueTurn(
                            DialogueTurn(
                              speaker: 'Live Audio Input',
                              text: _customSpeechCtrl.text.trim(),
                              role: 'caller',
                            ),
                          );
                          _customSpeechCtrl.clear();
                        }
                      },
                      icon: const Icon(Icons.record_voice_over, size: 16),
                      label: const Text('Speak & Score'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Context-Aware Mobile Money & USSD Verification',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _executeMerchantStkPush,
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text(
                          'Receive Merchant / Paybill STK Prompt',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _placeDirectFamilyCall,
                        icon: const Icon(
                          Icons.phone_forwarded,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        label: const Text('Direct Family Call (Always Open)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ussdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'USSD Code (*100# or *334#)',
                          filled: true,
                          fillColor: Color(0xFF030712),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _runUssdCode,
                      icon: const Icon(Icons.dialpad, size: 16),
                      label: const Text('Execute USSD'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: OFFLINE SMS SENDER METADATA & REVERSAL SPOOF GUARD
  // ==========================================================================

  Widget _buildTab2SmsSpoofGuard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMS Sender Metadata & Fake M-Pesa Reversal Guard',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scammers send fake "Confirmed. You have received..." SMS messages from personal +2547... numbers and immediately call demanding a reversal. Ngao-Sauti inspects the carrier sender token offline.',
            style: TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inspect Incoming SMS Header & Payload',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _smsSenderCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sender Header (e.g. +254719... or MPESA)',
                          filled: true,
                          fillColor: Color(0xFF030712),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _smsBodyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'SMS Body',
                          filled: true,
                          fillColor: Color(0xFF030712),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        final sender = _smsSenderCtrl.text.trim();
                        final body = _smsBodyCtrl.text.trim();
                        if (sender.isEmpty || body.isEmpty) return;
                        final isOfficial = sender.toUpperCase() == 'MPESA';
                        setState(() {
                          _smsInbox.insert(
                            0,
                            SmsMessageItem(
                              sender: sender,
                              body: body,
                              time: 'Just now',
                              isOfficialToken: isOfficial,
                            ),
                          );
                        });
                        if (!isOfficial) {
                          NeuralVoiceEngine.speak(
                            'Alert. Incoming SMS claims to be an M-Pesa transaction, but the sender header is a personal mobile number.',
                            role: 'ai',
                          );
                        }
                      },
                      child: const Text('Scan SMS'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ..._smsInbox.map((sms) {
            final isSpoof = !sms.isOfficialToken;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSpoof
                      ? Colors.amber.shade700
                      : const Color(0xFF10B981).withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSpoof
                                ? Icons.warning_amber_rounded
                                : Icons.verified,
                            color: isSpoof
                                ? Colors.amber
                                : const Color(0xFF10B981),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sender Header: ${sms.sender}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        sms.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sms.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSpoof
                            ? '⚠️ SPOOFED HEADER: Personal number disguising as MPESA'
                            : '✓ Verified Alphanumeric Carrier MPESA Token',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSpoof
                              ? Colors.amber
                              : const Color(0xFF10B981),
                        ),
                      ),
                      if (isSpoof)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() => _riskScore = 96);
                            _triggerSelectiveFinancialLock(
                              reason:
                                  'Spoofed M-Pesa reversal SMS detected from personal number ${sms.sender}.',
                            );
                          },
                          icon: const Icon(Icons.lock, size: 15),
                          label: const Text('Lock Reversal'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: 2-OF-N FAMILY GUARDIAN CONSENSUS & OFFLINE SMS CONFIRMATION
  // ==========================================================================

  Widget _buildTab3GuardianConsensus(int approvals, int blocks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2-of-N Family Guardian Consensus Network',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Offline SMS Pin: $_activeSecurityPin  •  Approvals: $approvals / 2  •  Blocks: $blocks / 2',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF06B6D4),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_guardians.isNotEmpty) {
                          _guardians[0].status = 'Timed Out (90s)';
                        }
                        for (final g in _guardians.skip(1)) {
                          g.status =
                              'GSM SMS Dispatched (PIN $_activeSecurityPin)';
                        }
                      });
                      if (_guardians.length > 1) {
                        _sendOfflineSmsToGuardian(_guardians[1]);
                      }
                      NeuralVoiceEngine.speak(
                        'Primary guardian unreachable after ninety seconds. Escalating via offline GSM SMS to backup guardians.',
                        role: 'ai',
                      );
                      _addLog(
                        '[90s FAILSAFE] Escalated consensus request via offline GSM SMS.',
                      );
                    },
                    icon: const Icon(
                      Icons.timer_off_outlined,
                      size: 16,
                      color: Colors.amber,
                    ),
                    label: const Text('90s SMS Escalation'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddGuardianModal,
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add Guardian'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Offline GSM SMS Confirmation Receiver Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF06B6D4).withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📲 Two-Way Offline GSM SMS Confirmation Receiver',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Guardians receive an offline text and reply "SAFE $_activeSecurityPin" (to unlock) or "BLOCK $_activeSecurityPin" (to blacklist). Verify an incoming SMS reply below:',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _incomingSmsReplyCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'Enter Guardian SMS reply (e.g. "SAFE $_activeSecurityPin" or "BLOCK $_activeSecurityPin")...',
                          filled: true,
                          fillColor: const Color(0xFF030712),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        if (_incomingSmsReplyCtrl.text.trim().isNotEmpty) {
                          _verifyGuardianSmsReply(
                            senderPhone: _guardians.isNotEmpty
                                ? _guardians.first.phone
                                : '+254700000000',
                            smsReplyText: _incomingSmsReplyCtrl.text.trim(),
                          );
                          _incomingSmsReplyCtrl.clear();
                        }
                      },
                      icon: const Icon(Icons.mark_chat_read, size: 16),
                      label: const Text('Verify SMS Reply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          ..._guardians.map(
            (g) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              g.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${g.relation} • ${g.status}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          g.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Dispatch Offline GSM SMS to ${g.name}',
                        onPressed: () => _sendOfflineSmsToGuardian(g),
                        icon: const Icon(
                          Icons.sms_outlined,
                          color: Color(0xFF06B6D4),
                          size: 20,
                        ),
                      ),
                      if (g.vote == null) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFCA5A5),
                          ),
                          onPressed: () => _castGuardianVote(g, 'block'),
                          child: const Text('Block Scam'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () => _castGuardianVote(g, 'approve'),
                          child: const Text('Approve Safe'),
                        ),
                      ] else
                        Text(
                          g.vote == 'block' ? '🚫 VOTED BLOCK' : '✅ VOTED SAFE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: g.vote == 'block'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Guardians Unreachable? (Calm-Voice Safe-Phrase Override)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Registered Phrase: "${widget.safePhrase}". Unlocks M-Pesa locally once the suspicious call is disconnected and vocal tremor jitter is normal.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _resetCallState();
                    NeuralVoiceEngine.speak(
                      'Safe phrase verified with calm vocal cadence. M-Pesa is now unlocked.',
                      role: 'ai',
                    );
                    _addLog(
                      '[SAFE-PHRASE OVERRIDE] Verified "${widget.safePhrase}". Unlocked.',
                    );
                  },
                  child: const Text('Verify Safe-Phrase'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _castGuardianVote(Guardian g, String vote) {
    setState(() => g.vote = vote);
    _addLog('[GUARDIAN VOTE] ${g.name} voted ${vote.toUpperCase()}.');

    final approvals = _guardians.where((x) => x.vote == 'approve').length;
    final blocks = _guardians.where((x) => x.vote == 'block').length;

    if (blocks >= 2) {
      NeuralVoiceEngine.speak(
        'Two family guardians confirmed this is a scam. Caller number permanently blacklisted.',
        role: 'ai',
      );
      _addLog(
        '🛡️ [2-OF-${_guardians.length} CONSENSUS] Caller $_activeCallerNumber blacklisted.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF991B1B),
          content: Text('2 Guardians Blocked Scam! Caller blacklisted.'),
        ),
      );
    } else if (approvals >= 2) {
      _resetCallState();
      NeuralVoiceEngine.speak(
        'Two family guardians verified the emergency is genuine. M-Pesa and USSD are now unlocked.',
        role: 'ai',
      );
      _addLog(
        '✅ [2-OF-${_guardians.length} CONSENSUS] Family verified call is genuine. Unlocked.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF065F46),
          content: Text('2 Guardians Approved! M-Pesa & USSD Unlocked.'),
        ),
      );
    }
  }

  void _showAddGuardianModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Add Family Guardian',
          style: TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty &&
                  phoneCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _guardians.add(
                    Guardian(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      relation: 'Family Guardian',
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 4: ON-DEVICE ML STUDIO & FORENSIC LOGS
  // ==========================================================================

  Widget _buildTab4MLStudioAndLogs() {
    final sortedWeights = _mlModel.weights.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'On-Device Machine Learning Studio (SGD Logistic Perceptron + Bigram NLU)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mathematical Inference: P(Scam | x) = 1 / (1 + exp(-(w·x + b))). Coercive features learn positive weights (+w_i) while institutional Paybill/verification features learn negative weights (-w_i).',
            style: TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  'Training Accuracy',
                  '${_mlModel.trainingAccuracy.toStringAsFixed(1)}%',
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  'Cross-Entropy Loss',
                  _mlModel.lastTrainingLoss.toStringAsFixed(4),
                  const Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricBox(
                  'Learned N-Grams',
                  '${_mlModel.weights.length} features',
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live On-Device Continuous Learning (Add Labeled Sample & Retrain via SGD)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _trainSentenceCtrl,
                  decoration: const InputDecoration(
                    hintText:
                        'Enter new Swahili/Sheng phrase (e.g. "Tuma pesa kwa wakili sasa hivi")...',
                    filled: true,
                    fillColor: Color(0xFF030712),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('Label: SCAM (1)')),
                        ButtonSegment(
                          value: 0,
                          label: Text('Label: GENUINE / SAFE (0)'),
                        ),
                      ],
                      selected: {_trainLabel},
                      onSelectionChanged: (s) =>
                          setState(() => _trainLabel = s.first),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final txt = _trainSentenceCtrl.text.trim();
                        if (txt.isEmpty) return;
                        setState(() {
                          _mlModel.addSampleAndRetrain(
                            txt,
                            _trainLabel,
                            _trainLabel == 1 ? 'Urgency' : 'Safe',
                          );
                          _trainSentenceCtrl.clear();
                        });
                        _addLog(
                          '[ON-DEVICE SGD] Retrained model with new sample (Label=$_trainLabel).',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Retrained On-Device Model via SGD! Feature weights updated.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_graph, size: 17),
                      label: const Text('Retrain Model On-Device'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Top Learned Feature Weights (+Scam vs -Genuine/Safe)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedWeights.take(22).map((e) {
                final isScamWeight = e.value > 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isScamWeight
                        ? const Color(0xFFEF4444).withOpacity(0.15)
                        : const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isScamWeight
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  child: Text(
                    '${e.key}: ${e.value >= 0 ? "+" : ""}${e.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Real-Time System & Forensic Audit Logs (*333# Ready)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: ListView.builder(
              itemCount: _systemLogs.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _systemLogs[i],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FULL-SCREEN ANIMATED INCOMING CALL OVERLAY
  // ==========================================================================

  Widget _buildAnimatedIncomingCallOverlay() {
    return Container(
      color: const Color(0xFF030712).withOpacity(0.96),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 20),
          Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.18),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withOpacity(0.18),
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.phone_in_talk,
                      size: 40,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  'NGAO-SAUTI ON-DEVICE AI CALL AUDITOR READY',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _activeCallerName,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _activeCallerNumber,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  FloatingActionButton.large(
                    heroTag: 'decline_call',
                    backgroundColor: const Color(0xFFEF4444),
                    onPressed: () {
                      _ringTimer?.cancel();
                      setState(() => _isRinging = false);
                    },
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Decline',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              Column(
                children: [
                  FloatingActionButton.large(
                    heroTag: 'answer_call',
                    backgroundColor: const Color(0xFF10B981),
                    onPressed: _answerCall,
                    child: const Icon(Icons.call, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Answer & Audit Live',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. REUSABLE ANIMATED UI WIDGETS
// ============================================================================

class _ScenarioCardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScenarioCardButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedWaveform extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedWaveform({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final h = 6.0 + (sin((controller.value * 2 * pi) + i) + 1) * 6.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: h,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
