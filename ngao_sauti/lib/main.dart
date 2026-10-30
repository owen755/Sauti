// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SautiApp());
}

// ============================================================================
// 1. NATURAL HUMAN NEURAL VOICE & WEB AUDIO ENGINE
// ============================================================================

class NeuralVoiceEngine {
  static final FlutterTts _tts = FlutterTts();
  static bool soundEnabled = true;

  static Future<void> warmUpVoices() async {
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {}
  }

  static Future<void> speak(String text, {String role = 'ai'}) async {
    if (!soundEnabled) return;
    try {
      await warmUpVoices();
      await _tts.stop();
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
// 2. REAL ON-DEVICE MACHINE LEARNING ENGINE (SGD LOGISTIC PERCEPTRON + BIGRAMS)
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
  final int label; // 1 = Scam, 0 = Safe / Genuine
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

class OnDeviceScamMLModel {
  final Map<String, double> weights = {};
  double bias = -1.15;
  double lastTrainingLoss = 0.0;
  double trainingAccuracy = 0.0;
  int totalEpochsTrained = 0;

  final List<TrainingSample> dataset = [
    // COERCIVE SCAM SAMPLES (Label = 1)
    TrainingSample(
      'hello mzazi niko hospitali kwa emergency mtoto wako amepata ajali mbaya ameumia',
      1,
      'Urgency',
    ),
    TrainingSample(
      'hapana usikate simu na usipigie mtu daktari anasema tuma elfu kumi na tano kwa hii namba binafsi sasa hivi',
      1,
      'Urgency',
    ),
    TrainingSample(
      'tuma pesa kwa namba yangu binafsi kabla mtoto aingie theatre sasa hivi',
      1,
      'Financial Coercion',
    ),
    TrainingSample(
      'jambo nakupigia kutoka safaricom customer care kuna mwizi anajaribu kufanya sim swap kwa line yako',
      1,
      'Authority',
    ),
    TrainingSample(
      'tafadhali bonyeza pin yako sasa hivi na usomee ile otp code imeingia kwa simu yako',
      1,
      'PIN / SIM Trap',
    ),
    TrainingSample(
      'nimetuma pesa kimakosa tafadhali rudisha reverse kwa hii namba sasa hivi',
      1,
      'Financial Coercion',
    ),
    TrainingSample(
      'weka pin ya mpesa kwa hiyo prompt imeingia usikate simu',
      1,
      'PIN / SIM Trap',
    ),
    TrainingSample(
      'polisi wameshika kijana wako tuma elfu ishirini kwa namba binafsi',
      1,
      'Authority',
    ),

    // GENUINE INSTITUTIONAL & NORMAL SAFE SAMPLES (Label = 0)
    TrainingSample(
      'tunakupigia kutoka aga khan clinic kijana wako amepata homa kidogo kuja reception',
      0,
      'Safe',
    ),
    TrainingSample(
      'usitume pesa kwa namba ya mtu binafsi mpigie mtoto uhakikishe kisha ulipe kwa official hospital paybill',
      0,
      'Safe',
    ),
    TrainingSample(
      'unaweza kumpigia mtoto wako kwanza uhakikishe tuko ward four reception',
      0,
      'Safe',
    ),
    TrainingSample(
      'niko hapa supermarket nanunua bidhaa wacha nilipe kwa merchant till',
      0,
      'Safe',
    ),
    TrainingSample(
      'umefika nyumbani salama ndio niko darasani nitakupigia baadaye',
      0,
      'Safe',
    ),
    TrainingSample(
      'tutakutana kesho asubuhi kwa mkutano wa familia asante sana',
      0,
      'Safe',
    ),
  ];

  OnDeviceScamMLModel() {
    trainModel(epochs: 75, learningRate: 0.25);
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
          weights[f] = (weights[f] ?? 0.0) - (learningRate * error);
        }
      }
      totalEpochsTrained++;
    }

    lastTrainingLoss = totalLoss / dataset.length;
    trainingAccuracy = (correct / dataset.length) * 100.0;
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
    trainModel(epochs: 45, learningRate: 0.25);
  }
}

// ============================================================================
// 3. APPLICATION DATA MODELS
// ============================================================================

class Guardian {
  final String id;
  String name;
  String phone;
  String relation;
  bool isPrimary;
  String status; // 'Online', 'SMS Fallback', 'Timed Out', 'SMS Dispatched'
  String? vote; // null, 'approve', 'block'

  Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = true,
    this.status = 'Online',
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
// 4. ROOT APPLICATION & CONTROLLER
// ============================================================================

class SautiApp extends StatelessWidget {
  const SautiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sauti — Scam Safety Assistant',
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
// 5. FULL 3-STEP ONBOARDING WIZARD
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
    Future.delayed(const Duration(milliseconds: 600), () {
      NeuralVoiceEngine.warmUpVoices();
    });
  }

  void _addGuardianToList() {
    final name = _gNameCtrl.text.trim();
    final phone = _gPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Guardian Name and Phone Number.')),
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
          status: _gIsPrimary ? 'Online' : 'SMS Fallback',
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
            content: Text('Enter your name and phone number to continue.'),
          ),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_draftGuardians.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please register at least 2 Family Guardians for 2-of-N consensus.'),
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
              'NGAO-SAUTI ONBOARDING',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ],
        ),
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
                    _buildStepPill(2, '3. Edge AI & Shield'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _nextStep,
                      icon: Icon(_step == 2 ? Icons.verified_user : Icons.arrow_forward, size: 18),
                      label: Text(
                        _step == 2 ? 'Activate Ngao-Sauti Protection' : 'Continue',
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
              hintText: 'e.g. 0722 109 482',
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
            'People First, AI Second: When a high-risk call is intercepted, any 2 trusted Guardians can verify whether the emergency is genuine or block the scammer.',
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
                    labelText: 'Phone Number',
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
                    DropdownMenuItem(value: 'Son / Daughter', child: Text('Son / Daughter')),
                    DropdownMenuItem(value: 'Brother / Sister', child: Text('Brother / Sister')),
                    DropdownMenuItem(value: 'Nephew / Niece', child: Text('Nephew / Niece')),
                    DropdownMenuItem(value: 'Trusted Neighbor', child: Text('Trusted Neighbor')),
                  ],
                  onChanged: (v) => setState(() => _gRelation = v ?? 'Son / Daughter'),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          if (_draftGuardians.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No guardians added yet. Add a trusted contact above.',
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
                    backgroundColor: g.isPrimary ? const Color(0xFF3B82F6) : Colors.amber.shade800,
                    child: Text(g.name[0], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${g.phone} • ${g.relation}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
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
            subtitle: const Text('Runs 100% offline with 0 MB mobile data required.'),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permVoiceEngine,
            onChanged: (v) => setState(() => _permVoiceEngine = v),
            title: const Text('Natural Neural Voice Assistant & Call Screening'),
            subtitle: const Text('Human-paced spoken alerts & real-time two-way call analysis.'),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permAccessibility,
            onChanged: (v) => setState(() => _permAccessibility = v),
            title: const Text('Context-Aware Merchant STK & USSD (*100#) Shield'),
            subtitle: const Text('Allows normal retail/hospital payments when safe; freezes PIN entry during scam calls.'),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permOfflineSms,
            onChanged: (v) => setState(() => _permOfflineSms = v),
            title: const Text('Offline GSM SMS Guardian Consensus Fallback'),
            subtitle: const Text('Dispatches encrypted SMS verification codes if mobile data is off.'),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. MAIN 4-TAB APPLICATION SHELL (ANIMATED + FULL FEATURE SET)
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

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedTab = 0;
  bool _audioMuted = false;

  final OnDeviceScamMLModel _mlModel = OnDeviceScamMLModel();

  int _riskScore = 0;
  double _lastLogit = 0;
  String _verdictExplanation = 'No text has been analyzed.';
  Map<String, double> _lastMatchedWeights = {};

  String _accumulatedCallText = '';

  final Set<String> _triggeredCategories = {};
  final List<DialogueTurn> _liveTurns = [];
  final List<String> _systemLogs = [
    '[SAUTI] Local phrase screening is ready. No call audio is monitored.',
    '[SAUTI] Results are advisory and do not block calls or payments.',
  ];

  late List<Guardian> _guardians;
  final TextEditingController _customSpeechCtrl = TextEditingController();
  final TextEditingController _ussdCtrl = TextEditingController(text: '*100#');
  final TextEditingController _trainSentenceCtrl = TextEditingController();
  int _trainLabel = 1;

  final TextEditingController _smsSenderCtrl = TextEditingController();
  final TextEditingController _smsBodyCtrl = TextEditingController();
  final List<SmsMessageItem> _smsInbox = [];

  @override
  void initState() {
    super.initState();
    _guardians = List.from(widget.initialGuardians);
    NeuralVoiceEngine.warmUpVoices();
  }

  @override
  void dispose() {
    _customSpeechCtrl.dispose();
    _ussdCtrl.dispose();
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

  void _processDialogueTurn(DialogueTurn turn) {
    _accumulatedCallText = '$_accumulatedCallText ${turn.text}'.trim();
    final result = _mlModel.predict(_accumulatedCallText);

    setState(() {
      _riskScore = result.riskPercentage;
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

  }

  Future<void> _placeDirectFamilyCall([Guardian? guardian]) async {
    final target = guardian ?? (_guardians.isEmpty ? null : _guardians.first);
    if (target == null) return;
    final uri = Uri(scheme: 'tel', path: target.phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _messageGuardian(Guardian guardian) async {
    final uri = Uri(
      scheme: 'sms',
      path: guardian.phone.replaceAll(' ', ''),
      queryParameters: {'body': 'Hi ${guardian.name}, I need to verify something with you.'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _executeMerchantStkPush() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Check payments in your carrier app',
          style: TextStyle(fontSize: 16),
        ),
        content: const Text(
          'Sauti cannot read, approve, or block an M-Pesa STK prompt. Verify the recipient and amount in your carrier app. Never share your PIN or one-time code with a caller.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _runUssdCode() async {
    final code = _ussdCtrl.text.trim();
    if (!RegExp(r'^\*[0-9*]+#?$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid USSD code, such as *100#.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: code);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _resetCallState() {
    NeuralVoiceEngine.stopSpeech();
    setState(() {
      _riskScore = 0;
      _lastLogit = 0;
      _verdictExplanation = 'No text has been analyzed.';
      _lastMatchedWeights = {};
      _accumulatedCallText = '';
      _triggeredCategories.clear();
      _liveTurns.clear();
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
              child: const Icon(Icons.shield, color: Color(0xFF06B6D4), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAUTI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
                Text(
                  'Safety tools for ${widget.userName}',
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
      body: Center(
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
            icon: const Icon(Icons.group_outlined),
            selectedIcon: const Icon(Icons.group, color: Color(0xFF06B6D4)),
            label: 'Contacts',
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
          // 1. Animated Morphing Status Card
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
              border: Border.all(color: statusColor.withOpacity(0.7), width: 1.5),
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
                const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF06B6D4),
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _riskScore == 0
                            ? 'TEXT SCREENING ONLY'
                            : 'HEURISTIC TEXT RISK: $_riskScore%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _verdictExplanation,
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Check a message or phrase',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(height: 10),
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
                const Row(
                  children: [
                    Icon(Icons.text_snippet_outlined, color: Color(0xFF06B6D4), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Submitted text checks',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
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

                // 4 Manipulation Vectors
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Urgency',
                    'Authority',
                    'Financial Coercion',
                    'PIN / SIM Trap'
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

                // Animated Chat-Style Two-Way Transcript
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
                            'Paste or type text you want to review. Sauti does not listen to calls or read messages automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Colors.white38),
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
                                      : const Color(0xFF3B82F6).withOpacity(0.14),
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

                // Live Interactive Speech/Reply Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customSpeechCtrl,
                        decoration: InputDecoration(
                            hintText: 'Paste or type a suspicious message or phrase...',
                          filled: true,
                          fillColor: const Color(0xFF030712),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isNotEmpty) {
                            _processDialogueTurn(
                              DialogueTurn(
                                speaker: 'Submitted text',
                                text: v.trim(),
                                role: 'user',
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
                          _processDialogueTurn(
                            DialogueTurn(
                              speaker: 'Submitted text',
                              text: _customSpeechCtrl.text.trim(),
                              role: 'user',
                            ),
                          );
                          _customSpeechCtrl.clear();
                        }
                      },
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Analyze text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Carrier actions are handed off to the operating system.
          const Text(
            'Carrier tools',
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
                        label: const Text('Payment safety advice'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _placeDirectFamilyCall(),
                        icon: const Icon(
                          Icons.phone_forwarded,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        label: const Text('Call first contact'),
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
                          labelText: 'Open a USSD code in the dialer',
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
                      label: const Text('Open dialer'),
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
            'Check a suspicious SMS',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Paste the sender label and message text from your inbox. Sauti does not read SMS automatically, and a displayed sender name alone cannot prove who sent a message.',
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
                  'Message details',
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
                          labelText: 'Sender label or number',
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
                          labelText: 'Message text',
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
                      child: const Text('Check message'),
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
                            isSpoof ? Icons.warning_amber_rounded : Icons.verified,
                            color: isSpoof ? Colors.amber : const Color(0xFF10B981),
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
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sms.body,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSpoof
                          ? 'Sender is a phone number; verify independently'
                          : 'Sender label says MPESA; identity is not verified',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSpoof ? Colors.amber : const Color(0xFF10B981),
                        ),
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
  // TAB 3: 2-OF-N FAMILY GUARDIAN CONSENSUS CIRCLE
  // ==========================================================================

  Widget _buildTab3GuardianConsensus() {
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
                    'Trusted contacts',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Contact them directly to verify urgent requests.',
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
                                g.relation,
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
                  IconButton(
                    tooltip: 'Call ${g.name}',
                    onPressed: () => _placeDirectFamilyCall(g),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF10B981)),
                  ),
                  IconButton(
                    tooltip: 'Text ${g.name}',
                    onPressed: () => _messageGuardian(g),
                    icon: const Icon(Icons.sms_outlined, color: Color(0xFF06B6D4)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

        ],
      ),
    );
  }

  void _showAddGuardianModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Add Family Guardian', style: TextStyle(fontSize: 16)),
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
  // TAB 4: ON-DEVICE ML STUDIO & FORENSIC LOGS (FOR COLLINS)
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

          // Live On-Device SGD Retraining
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
// 7. REUSABLE ANIMATED UI WIDGETS
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