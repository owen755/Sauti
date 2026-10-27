// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NeuralVoiceEngine.initVoices();
  runApp(const NgaoSautiApp());
}

// ============================================================================
// NATURAL HUMAN NEURAL VOICE & AUDIO ENGINE (POWERED BY MICROSOFT EDGE TTS)
// ============================================================================

class NeuralVoiceEngine {
  static bool soundEnabled = true;

  /// Initializes Microsoft Edge's built-in Natural Neural Voices
  static void initVoices() {
    try {
      js.context.callMethod('eval', [
        '''
        window.speechSynthesis.getVoices();
        window.speechSynthesis.onvoiceschanged = function() {
          window.speechSynthesis.getVoices();
        };
        '''
      ]);
    } catch (_) {}
  }

  /// Plays realistic phone ringtone or alert chime using Web Audio API
  static void playTone({int freq = 800, int durationMs = 200, String type = 'sine'}) {
    if (!soundEnabled) return;
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          const AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (!window._ngaoAudioCtx) window._ngaoAudioCtx = new AudioCtx();
          const ctx = window._ngaoAudioCtx;
          if (ctx.state === 'suspended') ctx.resume();
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = '$type';
          osc.frequency.setValueAtTime($freq, ctx.currentTime);
          gain.gain.setValueAtTime(0.08, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + (${durationMs / 1000}));
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + (${durationMs / 1000}));
        })();
        '''
      ]);
    } catch (_) {}
  }

  /// Speaks text using Microsoft Edge's most natural human neural voice
  /// role: 'caller' (male/deeper), 'user' (conversational), 'ai' (warm natural assistant)
  static void speak(String text, {String role = 'ai'}) {
    if (!soundEnabled) return;
    final cleanText = text.replaceAll("'", "").replaceAll('"', '');
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          if (!('speechSynthesis' in window)) return;
          window.speechSynthesis.cancel();
          const u = new SpeechSynthesisUtterance('$cleanText');
          const voices = window.speechSynthesis.getVoices();

          // Prioritize Microsoft Edge "Natural" Neural Voices & Kenyan/Swahili voices
          let selected = null;
          if ('$role' === 'ai') {
            selected = voices.find(v => v.name.includes('Natural') && (v.lang.includes('KE') || v.name.includes('Aria') || v.name.includes('Sonia') || v.name.includes('Asilia')))
                    || voices.find(v => v.name.includes('Natural'))
                    || voices.find(v => v.lang.includes('en-GB') || v.lang.includes('en-US'));
            u.pitch = 1.02;
            u.rate = 0.98;
          } else if ('$role' === 'caller') {
            selected = voices.find(v => v.name.includes('Natural') && (v.name.includes('Chilemba') || v.name.includes('Mitchell') || v.name.includes('Guy') || v.name.includes('Ryan')))
                    || voices.find(v => v.name.includes('Natural'))
                    || voices[0];
            u.pitch = 0.90;
            u.rate = 1.03;
          } else {
            // 'user' replying on the call
            selected = voices.find(v => v.name.includes('Natural') && (v.name.includes('Asilia') || v.name.includes('Jenny') || v.name.includes('Libby')))
                    || voices.find(v => v.name.includes('Natural'))
                    || voices[1] || voices[0];
            u.pitch = 1.06;
            u.rate = 1.0;
          }

          if (selected) u.voice = selected;
          window.speechSynthesis.speak(u);
        })();
        '''
      ]);
    } catch (_) {}
  }

  static void stopSpeech() {
    try {
      js.context.callMethod('eval', ['window.speechSynthesis.cancel();']);
    } catch (_) {}
  }
}

// ============================================================================
// REAL ON-DEVICE MACHINE LEARNING ENGINE (CONTEXT-AWARE SGD PERCEPTRON)
// ============================================================================

class DialogueTurn {
  final String speaker; // 'Caller' or 'You (User)'
  final String text;
  final String role; // 'caller' or 'user'

  const DialogueTurn(this.speaker, this.text, this.role);
}

class TrainingSample {
  final String text;
  final int label; // 1 = Scam, 0 = Safe / Genuine Emergency
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
  double bias = -1.1;
  double lastTrainingLoss = 0.0;
  double trainingAccuracy = 0.0;
  int totalEpochsTrained = 0;

  // Trained on BOTH Scam Calls AND Genuine Emergencies so the AI knows the difference!
  final List<TrainingSample> dataset = [
    // SCAM SAMPLES (Label = 1: Personal numbers, PIN/OTP requests, secrecy, refusal to verify)
    TrainingSample('niko hospitali mtoto ameumia tuma pesa kwa hii namba binafsi sasa hivi', 1, 'Urgency'),
    TrainingSample('usipigie mtu mwingine usikate simu tuma elfu kumi na tano sasa hivi', 1, 'Urgency'),
    TrainingSample('daktari anasema tuma pesa kwa namba yangu kabla aingie theatre', 1, 'Money'),
    TrainingSample('nakupigia kutoka safaricom customer care kuna mwizi anafanya sim swap', 1, 'Authority'),
    TrainingSample('tafadhali bonyeza pin yako na usomee ile otp imeingia sasa hivi', 1, 'PIN/SIM'),
    TrainingSample('nimetuma pesa kimakosa tafadhali rudisha reverse kwa hii namba', 1, 'Money'),
    TrainingSample('weka pin ya mpesa kwa hiyo prompt imeingia usikate simu', 1, 'PIN/SIM'),
    TrainingSample('polisi wameshika kijana wako tuma elfu ishirini kwa namba binafsi', 1, 'Authority'),

    // GENUINE EMERGENCY & SAFE SAMPLES (Label = 0: Official Paybill, verification encouraged, shopping)
    TrainingSample('hapa ni aga khan hospitali kuja reception uongee na daktari', 0, 'Safe'),
    TrainingSample('usitume pesa kwa namba ya mtu binafsi lipa kwa official paybill ya hospitali', 0, 'Safe'),
    TrainingSample('unaweza kumpigia mtoto wako kwanza uhakikishe tuko ward four', 0, 'Safe'),
    TrainingSample('sasa owen uko wapi niko naivas supermarket nanunua maziwa', 0, 'Safe'),
    TrainingSample('wacha nilipe na mpesa stk push hapa kwa till ya naivas', 0, 'Safe'),
    TrainingSample('umefika shule salama ndio mum niko darasani moringa', 0, 'Safe'),
    TrainingSample('asante sana nimeona ujumbe wako nitakupigia baadaye', 0, 'Safe'),
  ];

  OnDeviceScamMLModel() {
    trainModel(epochs: 70, learningRate: 0.25);
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

  void trainModel({int epochs = 50, double learningRate = 0.2}) {
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

        if ((pred >= 0.5 && sample.label == 1) || (pred < 0.5 && sample.label == 0)) {
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
      if (f.contains('sasa_hivi') || f.contains('usikate_simu') || f.contains('ameumia')) {
        vectors.add('Urgency');
      }
      if (f.contains('safaricom') || f.contains('customer_care') || f.contains('polisi')) {
        vectors.add('Authority');
      }
      if (f.contains('namba_binafsi') || f.contains('rudisha') || f.contains('tuma_elfu')) {
        vectors.add('Money');
      }
      if (f.contains('pin') || f.contains('otp') || f.contains('sim_swap')) {
        vectors.add('PIN/SIM');
      }
    }

    final prob = _sigmoid(z);
    final riskPct = (prob * 100).round().clamp(4, 99);

    String explanation;
    if (riskPct >= 75) {
      explanation = 'SCAM PATTERN: Coercive urgency + personal line/PIN demand + refusal to allow verification.';
    } else if (transcriptText.toLowerCase().contains('paybill') || transcriptText.toLowerCase().contains('reception')) {
      explanation = 'VERIFIED GENUINE CALL: Caller directed to official Hospital Paybill/Reception & encouraged verification.';
    } else {
      explanation = 'SAFE CONVERSATION: Normal conversational cadence with zero financial coercion.';
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
    trainModel(epochs: 40, learningRate: 0.25);
  }
}

// ============================================================================
// APP STATE MODELS
// ============================================================================

class Guardian {
  final String id;
  String name;
  String phone;
  String relation;
  bool isPrimary;
  String status;
  String? vote;

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
// ROOT APPLICATION
// ============================================================================

class NgaoSautiApp extends StatelessWidget {
  const NgaoSautiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ngao-Sauti — Natural Voice & On-Device ML Firewall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090B10),
        primaryColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFF121621),
        dividerColor: const Color(0xFF22293A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF121621),
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
// 1. FIRST-TIME USER ONBOARDING WIZARD
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
  final String _gRelation = 'Son / Daughter';
  final bool _gIsPrimary = true;
  final List<Guardian> _draftGuardians = [];

  bool _permDialer = true;
  bool _permAccessibility = true;
  bool _permOfflineSms = true;
  bool _permLocalModelLoaded = true;

  void _loadDemoPreset() {
    setState(() {
      _nameCtrl.text = 'Mama Njeri';
      _phoneCtrl.text = '0722109482';
      _phraseCtrl.text = 'Nyumba Salama';
      _draftGuardians.clear();
      _draftGuardians.addAll([
        Guardian(id: '1', name: 'Owen Mwangi', phone: '0711 223 344', relation: 'Son (Primary)', isPrimary: true),
        Guardian(id: '2', name: 'Muhammed Hassan', phone: '0722 556 677', relation: 'Brother (Primary)', isPrimary: true),
        Guardian(id: '3', name: 'Collins Mundia', phone: '0733 889 900', relation: 'Nephew (Primary)', isPrimary: true),
        Guardian(id: '4', name: 'Grace Wanjiku', phone: '0744 111 222', relation: 'Neighbor (SMS Backup)', isPrimary: false, status: 'SMS Fallback'),
      ]);
    });
    NeuralVoiceEngine.speak(
      'Karibu Mama Njeri. Owen, Muhammed, and Collins have been loaded as your family guardians.',
      role: 'ai',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loaded Team Demo Preset (Owen, Muhammed, Collins) + Neural Voice Test!')),
    );
  }

  void _addGuardianToList() {
    final name = _gNameCtrl.text.trim();
    final phone = _gPhoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) return;
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
          const SnackBar(content: Text('Enter your name & phone number, or tap "Quick-Fill Demo" at top right.')),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_draftGuardians.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least 2 Family Guardians for consensus security.')),
        );
        return;
      }
      setState(() => _step = 2);
    } else {
      widget.onCompleted(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        safePhrase: _phraseCtrl.text.trim(),
        guardians: _draftGuardians,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121621),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF06B6D4), size: 22),
            SizedBox(width: 10),
            Text('Ngao-Sauti Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _loadDemoPreset,
            icon: const Icon(Icons.bolt, size: 16, color: Color(0xFF06B6D4)),
            label: const Text('Quick-Fill Demo', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStepBadge(0, '1. User Profile'),
                    const SizedBox(width: 8),
                    _buildStepBadge(1, '2. Family Guardians'),
                    const SizedBox(width: 8),
                    _buildStepBadge(2, '3. Local ML & Voice'),
                  ],
                ),
                const SizedBox(height: 24),
                if (_step == 0) _buildStep1(),
                if (_step == 1) _buildStep2(),
                if (_step == 2) _buildStep3(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_step > 0)
                      OutlinedButton(onPressed: () => setState(() => _step--), child: const Text('Back'))
                    else
                      const SizedBox(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: _nextStep,
                      icon: Icon(_step == 2 ? Icons.check_circle_outline : Icons.arrow_forward, size: 18),
                      label: Text(_step == 2 ? 'Launch Ngao-Sauti Shield' : 'Continue'),
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

  Widget _buildStepBadge(int idx, String title) {
    final active = _step == idx;
    final done = _step > idx;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6).withOpacity(0.18) : const Color(0xFF121621),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? const Color(0xFF3B82F6)
                : done
                    ? const Color(0xFF10B981)
                    : const Color(0xFF22293A),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : done ? const Color(0xFF10B981) : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22293A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Register Protected User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Ngao-Sauti runs a trained On-Device Machine Learning model to analyze two-way call conversations and distinguish real emergencies from scams.',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Full Name',
              hintText: 'e.g. Mama Njeri',
              filled: true,
              fillColor: Color(0xFF090B10),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Your M-Pesa Phone Number',
              hintText: 'e.g. 0722 109 482',
              filled: true,
              fillColor: Color(0xFF090B10),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phraseCtrl,
            decoration: const InputDecoration(
              labelText: 'Calm-Voice Safe Phrase (Offline Self-Override)',
              filled: true,
              fillColor: Color(0xFF090B10),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22293A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Trusted Family Guardians', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'If an emergency call is ambiguous, Ngao-Sauti pauses M-Pesa and asks your Family Guardians to verify if the emergency is true or a scam.',
            style: TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Name',
                    filled: true,
                    fillColor: Color(0xFF090B10),
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
                    fillColor: Color(0xFF090B10),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
                onPressed: _addGuardianToList,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._draftGuardians.map(
            (g) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user, color: Color(0xFF06B6D4), size: 18),
              title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${g.phone} • ${g.relation}'),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                onPressed: () => setState(() => _draftGuardians.remove(g)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121621),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22293A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('On-Device Machine Learning & Natural Neural Voice', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _permLocalModelLoaded,
            onChanged: (v) => setState(() => _permLocalModelLoaded = v),
            title: const Text('On-Device Neural Logistic + Bigram ML Classifier'),
            subtitle: const Text('Distinguishes coercive scams from genuine hospital/family emergencies (0 MB Data).'),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permDialer,
            onChanged: (v) => setState(() => _permDialer = v),
            title: const Text('Natural Human Neural Voice Synthesis'),
            subtitle: const Text('Uses Microsoft Edge Natural Neural Voices for realistic call playback & warnings.'),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permAccessibility,
            onChanged: (v) => setState(() => _permAccessibility = v),
            title: const Text('Context-Aware Supermarket STK & *100# Shield'),
            subtitle: const Text('Allows normal shopping STK pushes; freezes PIN entry during scam calls.'),
            activeColor: const Color(0xFF10B981),
          ),
          SwitchListTile(
            value: _permOfflineSms,
            onChanged: (v) => setState(() => _permOfflineSms = v),
            title: const Text('Offline GSM SMS Guardian Consensus'),
            subtitle: const Text('Pings Guardians via standard SMS when mobile data is unavailable.'),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. MAIN APPLICATION SHELL (WITH SPOKEN 2-WAY CALLS & TRUE vs SCAM AI)
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
  bool _isOfflineNoDataMode = true;
  bool _audioMuted = false;

  final OnDeviceScamMLModel _mlModel = OnDeviceScamMLModel();

  bool _isRinging = false;
  bool _isCallActive = false;
  bool _isFinancialLocked = false;
  int _riskScore = 5;
  double _lastLogit = -1.1;
  String _verdictExplanation = 'SAFE: Monitoring standby.';
  Map<String, double> _lastMatchedWeights = {};

  String _activeCallerName = 'Standby';
  String _activeCallerNumber = 'No active call';
  String _pendingScenario = 'hospital_scam';
  int _callSeconds = 0;
  String _accumulatedCallText = '';

  Timer? _ringTimer;
  Timer? _callTimer;
  Timer? _scriptTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 900;

  final Set<String> _triggeredCategories = {};
  final List<String> _liveTranscript = [
    '[ON-DEVICE ML ENGINE] Ready. Click any "Ring" button above to hear the live two-way conversation!',
  ];
  final List<String> _systemLogs = [
    '[ML BOOT] Trained on-device SGD classifier on Scam vs. True Emergency dataset.',
    '[VOICE ENGINE] Microsoft Edge Natural Neural Voice synthesizer linked.',
  ];

  late List<Guardian> _guardians;
  final TextEditingController _customSpeechCtrl = TextEditingController();
  final TextEditingController _ussdCtrl = TextEditingController(text: '*100#');
  final TextEditingController _trainSentenceCtrl = TextEditingController();
  int _trainLabel = 1;

  final List<SmsMessageItem> _smsInbox = [
    SmsMessageItem(
      sender: '+254719882341',
      body:
          'UBA45X9K2L Confirmed. You have received Ksh15,000.00 from JOHN KAMAU 0719882341 on 27/10/26 at 9:10 AM. New M-PESA balance is Ksh63,200.00.',
      time: '9:10 AM',
      isOfficialToken: false,
    ),
    SmsMessageItem(
      sender: 'MPESA',
      body:
          'UAY12P4L9M Confirmed. Ksh1,450.00 paid to NAIVAS SUPERMARKET WESTLANDS on 27/10/26 at 8:15 AM.',
      time: '8:15 AM',
      isOfficialToken: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _guardians = List.from(widget.initialGuardians);
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _callTimer?.cancel();
    _scriptTimer?.cancel();
    _cooldownTimer?.cancel();
    _customSpeechCtrl.dispose();
    _ussdCtrl.dispose();
    _trainSentenceCtrl.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _systemLogs.insert(0, '[$timeStr] $msg');
    });
  }

  // ==========================================================================
  // SPOKEN TWO-WAY CALL ENGINE (SCAM vs TRUE EMERGENCY)
  // ==========================================================================

  void _ringIncomingCall(String scenario) {
    _resetCallState();
    setState(() {
      _pendingScenario = scenario;
      _isRinging = true;
      if (scenario == 'hospital_scam') {
        _activeCallerName = 'Unknown Number (Hospital Scam)';
        _activeCallerNumber = '+254 724 889 102';
      } else if (scenario == 'true_hospital') {
        _activeCallerName = 'Aga Khan Clinic Desk (Genuine)';
        _activeCallerNumber = '+254 20 374 0000';
      } else {
        _activeCallerName = 'Unverified Line (SIM-Swap Scam)';
        _activeCallerNumber = '+254 710 442 991';
      }
    });

    // Play realistic phone ringtone out loud
    NeuralVoiceEngine.playTone(freq: 840, durationMs: 280, type: 'square');
    _ringTimer?.cancel();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!_isRinging) {
        _ringTimer?.cancel();
        return;
      }
      NeuralVoiceEngine.playTone(freq: 840, durationMs: 280, type: 'square');
    });

    _addLog('[INCOMING CALL] Ringing from $_activeCallerNumber ($_activeCallerName).');
  }

  void _answerCall() {
    _ringTimer?.cancel();
    setState(() {
      _isRinging = false;
      _isCallActive = true;
      _callSeconds = 0;
      _accumulatedCallText = '';
      _liveTranscript.clear();
      _liveTranscript.add('[ON-DEVICE AI] Listening to two-way conversation (Caller + Your Reply)...');
    });

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _callSeconds++);
    });

    // Two-Way Realistic Conversations (Caller speaks -> You reply -> Caller responds)
    final Map<String, List<DialogueTurn>> dialogues = {
      'hospital_scam': [
        const DialogueTurn(
          'Caller',
          'Hello mzazi! Niko hapa hospitali kwa emergency, mtoto wako amepata ajali mbaya na ameumia!',
          'caller',
        ),
        DialogueTurn(
          'You (${widget.userName})',
          'Mungu wangu! Wacha nimpigie mtoto wangu simu sasa hivi nihakikishe!',
          'user',
        ),
        const DialogueTurn(
          'Caller',
          'Usikate simu na usipigie mtu! Daktari anasema tuma elfu kumi na tano kwa hii namba binafsi sasa hivi!',
          'caller',
        ),
      ],
      'true_hospital': [
        DialogueTurn(
          'Clinic Reception',
          'Hello ${widget.userName}, tunakupigia kutoka Aga Khan Clinic. Kijana wako amepata homa kidogo.',
          'caller',
        ),
        DialogueTurn(
          'You (${widget.userName})',
          'Je, ni kweli? Nilipe pesa kwa namba gani ama nije hapo?',
          'user',
        ),
        const DialogueTurn(
          'Clinic Reception',
          'Usitume pesa kwa namba ya mtu binafsi. Unaweza kumpigia mtoto wako uhakikishe, kisha ulipe kwa Official Hospital Paybill ukifika reception.',
          'caller',
        ),
      ],
      'safaricom_scam': [
        const DialogueTurn(
          'Caller',
          'Jambo, nakupigia kutoka Safaricom Customer Care. Kuna mwizi anajaribu kufanya SIM swap kwa line yako.',
          'caller',
        ),
        DialogueTurn(
          'You (${widget.userName})',
          'Sasa nifanye nini ndio line yangu isifungwe?',
          'user',
        ),
        const DialogueTurn(
          'Caller',
          'Tafadhali bonyeza PIN yako sasa hivi na usomee ile OTP code imeingia kwa simu yako!',
          'caller',
        ),
      ],
    };

    final turns = dialogues[_pendingScenario] ?? dialogues['hospital_scam']!;
    int idx = 0;

    // Speak first turn immediately
    _processDialogueTurn(turns[0]);
    idx = 1;

    _scriptTimer?.cancel();
    _scriptTimer = Timer.periodic(const Duration(milliseconds: 5200), (timer) {
      if (!_isCallActive || idx >= turns.length) {
        timer.cancel();
        return;
      }
      _processDialogueTurn(turns[idx]);
      idx++;
    });
  }

  void _processDialogueTurn(DialogueTurn turn) {
    // Speak the line out loud using Edge's Natural Neural Voice
    NeuralVoiceEngine.speak(turn.text, role: turn.role);

    _accumulatedCallText = '$_accumulatedCallText ${turn.text}'.trim();
    final result = _mlModel.predict(_accumulatedCallText);

    setState(() {
      _riskScore = result.riskPercentage;
      _lastLogit = result.logitScore;
      _verdictExplanation = result.verdictExplanation;
      _lastMatchedWeights = result.matchedFeatureWeights;
      _triggeredCategories.addAll(result.detectedVectors);
      _liveTranscript.add(
        '🎙️ ${turn.speaker}: "${turn.text}"\n   ↳ [AI Risk: ${result.riskPercentage}% | Logit z=${result.logitScore.toStringAsFixed(2)} | ${result.verdictExplanation}]',
      );
    });

    if (_riskScore >= 75 && !_isFinancialLocked) {
      // Wait 3.2 seconds so the caller finishes speaking their sentence, then Ngao-Sauti's human voice intervenes!
      Future.delayed(const Duration(milliseconds: 3200), () {
        if (!mounted || !_isCallActive) return;
        _triggerSelectiveFinancialLock(
          reason:
              'On-Device ML detected ${result.riskPercentage}% Scam Probability (${result.verdictExplanation}).',
        );
      });
    }
  }

  void _triggerSelectiveFinancialLock({required String reason}) {
    setState(() {
      _isFinancialLocked = true;
      _cooldownSeconds = 900;
    });

    // Natural Human Assistant Warning Voice
    NeuralVoiceEngine.speak(
      'Attention ${widget.userName}. Ngao Sauti has detected high-pressure scam manipulation on this call. Outgoing M-Pesa transfers and SIM swap codes are paused for your protection. Please call your family directly or wait for two family guardians to verify.',
      role: 'ai',
    );

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cooldownSeconds > 0) setState(() => _cooldownSeconds--);
    });

    _addLog('[ML CIRCUIT BREAKER] $reason Outgoing M-Pesa, *100# & STK frozen.');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F14),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ngao-Sauti AI Circuit Breaker',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF090B10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ What if this Emergency is TRUE?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Normal voice calls stay 100% OPEN so you can call your child directly.\n'
                    '2. Your Family Guardians (Owen, Muhammed, Collins) have been pinged—if the emergency is real, 2 taps of "Approve Safe" unlock M-Pesa immediately!',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
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
            child: const Text('Guardian Votes (2-of-N)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              _placeDirectFamilyCall();
            },
            child: const Text('Call Family Directly'),
          ),
        ],
      ),
    );
  }

  void _placeDirectFamilyCall() {
    final firstGuardian = _guardians.isNotEmpty ? _guardians.first.name : 'Family Member';
    NeuralVoiceEngine.speak('Dialing $firstGuardian directly on a verified voice line.', role: 'ai');
    _addLog('[SAFE DIALER] Placed direct verification voice call to $firstGuardian.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF065F46),
        content: Text('Dialing $firstGuardian... Standard voice calls are never blocked!'),
      ),
    );
  }

  void _testContextAwareStkPush() {
    if (_isFinancialLocked) {
      NeuralVoiceEngine.speak(
        'Warning! M-Pesa STK prompt blocked because you are on an unverified scam call. Do not enter your PIN.',
        role: 'ai',
      );
      _addLog('[STK FIREWALL] Blocked STK Push PIN entry during active scam lock.');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F14),
          title: const Text('🛑 STK Push Blocked!', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 16)),
          content: const Text(
            'Ngao-Sauti blocked this M-Pesa STK prompt because the internal ML classifier detected an active scam session.\n\nEntering your PIN always SENDS money out—it never receives money!',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kill Fraudulent STK'),
            ),
          ],
        ),
      );
      return;
    }

    NeuralVoiceEngine.speak('Context verified safe. Naivas Supermarket payment allowed.', role: 'ai');
    _addLog('[CONTEXT-AWARE STK] Allowed Naivas Supermarket / Official Paybill STK Push (Risk is low: $_riskScore%).');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1912),
        title: const Text('✅ Legitimate STK Push Allowed', style: TextStyle(color: Color(0xFF10B981), fontSize: 16)),
        content: const Text(
          'Pay Ksh 1,850.00 to OFFICIAL TILL / PAYBILL?\n\n(Allowed seamlessly because internal AI verified this session is safe!)',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Enter PIN & Pay'),
          ),
        ],
      ),
    );
  }

  void _runUssdCode() {
    final code = _ussdCtrl.text.trim();
    if (_isFinancialLocked) {
      NeuralVoiceEngine.speak('USSD code blocked during active scam alert.', role: 'ai');
      _addLog('[USSD FIREWALL] Blocked $code during active threat.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: const Color(0xFF991B1B), content: Text('Blocked $code: Active scam threat detected!')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF121621),
        title: Text('Safaricom USSD ($code)', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 15)),
        content: const Text('1. My Account & Balance\n2. Data Deals\n3. M-PESA\n4. SIM Swap Check\n\n(Works normally when safe!)'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
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
      _verdictExplanation = 'SAFE: Monitoring standby.';
      _lastMatchedWeights = {};
      _accumulatedCallText = '';
      _activeCallerName = 'Standby';
      _activeCallerNumber = 'No active call';
      _triggeredCategories.clear();
      _liveTranscript.clear();
      _liveTranscript.add('[ON-DEVICE ML ENGINE] Ready. Click any "Ring" button above to hear the spoken conversation.');
      for (final g in _guardians) {
        g.vote = null;
        g.status = g.isPrimary ? 'Online' : 'SMS Fallback';
      }
    });
  }

  // ==========================================================================
  // BUILD SHELL
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final approvals = _guardians.where((g) => g.vote == 'approve').length;
    final blocks = _guardians.where((g) => g.vote == 'block').length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121621),
        title: Row(
          children: [
            const Icon(Icons.shield, color: Color(0xFF06B6D4), size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NGAO-SAUTI ML OS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                Text(
                  'User: ${widget.userName} • ML Acc: ${_mlModel.trainingAccuracy.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Neural Voice Audio',
            onPressed: () {
              setState(() {
                _audioMuted = !_audioMuted;
                NeuralVoiceEngine.soundEnabled = !_audioMuted;
              });
              if (!_audioMuted) {
                NeuralVoiceEngine.speak('Natural neural voice enabled.', role: 'ai');
              } else {
                NeuralVoiceEngine.stopSpeech();
              }
            },
            icon: Icon(_audioMuted ? Icons.volume_off : Icons.volume_up, color: const Color(0xFF06B6D4)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => setState(() => _isOfflineNoDataMode = !_isOfflineNoDataMode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  children: [
                    Icon(_isOfflineNoDataMode ? Icons.airplanemode_active : Icons.wifi, size: 14, color: const Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      _isOfflineNoDataMode ? 'ON-DEVICE ML (0 DATA)' : 'HYBRID ML',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(onPressed: widget.onReopenOnboarding, icon: const Icon(Icons.manage_accounts_outlined, size: 20)),
          IconButton(onPressed: _resetCallState, icon: const Icon(Icons.refresh, size: 20)),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab,
            children: [
              _buildTab1CallShield(),
              _buildTab2SmsGuard(),
              _buildTab3Guardians(approvals, blocks),
              _buildTab4MLStudio(),
            ],
          ),
          if (_isRinging) _buildIncomingCallOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF121621),
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.phone_in_talk_outlined), label: 'Call & Voice AI'),
          NavigationDestination(icon: Icon(Icons.sms_outlined), label: 'SMS Spoof Guard'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Guardians (2-of-N)'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), label: 'On-Device ML Studio'),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: SPOKEN TWO-WAY CALLS & TRUE vs SCAM DIFFERENTIATION
  // ==========================================================================

  Widget _buildTab1CallShield() {
    final Color statusColor = _riskScore >= 75
        ? const Color(0xFFEF4444)
        : _riskScore >= 40
            ? Colors.amber
            : const Color(0xFF10B981);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  children: [
                    Icon(_isFinancialLocked ? Icons.lock : Icons.verified_user, color: statusColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isFinancialLocked
                                ? 'SCAM INTERCEPTED: M-PESA & *100# PAUSED (P(Scam) = $_riskScore%)'
                                : 'SHIELD ARMED: M-PESA & OFFICIAL PAYBILLS ALLOWED (P(Scam) = $_riskScore%)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _verdictExplanation,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                '1. Trigger Spoken 2-Way Call Scenarios (Compare SCAM vs. TRUE Emergency with Sound!)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF991B1B), foregroundColor: Colors.white),
                    onPressed: () => _ringIncomingCall('hospital_scam'),
                    icon: const Icon(Icons.volume_up, size: 17),
                    label: const Text('1. Ring: FAKE Hospital Scam (Blocks)'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF065F46), foregroundColor: Colors.white),
                    onPressed: () => _ringIncomingCall('true_hospital'),
                    icon: const Icon(Icons.verified_outlined, size: 17),
                    label: const Text('2. Ring: TRUE Hospital Call (Allows Paybill!)'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A3412), foregroundColor: Colors.white),
                    onPressed: () => _ringIncomingCall('safaricom_scam'),
                    icon: const Icon(Icons.sim_card_alert_outlined, size: 17),
                    label: const Text('3. Ring: Safaricom SIM-Swap Scam'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Live Conversation Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121621),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22293A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Live 2-Way Audio Stream: $_activeCallerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('ML Risk: $_riskScore%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _riskScore / 100.0,
                      minHeight: 7,
                      backgroundColor: const Color(0xFF22293A),
                      color: statusColor,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 155,
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090B10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _liveTranscript.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _liveTranscript[i],
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70, height: 1.35),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Reply / Speak into Conversation
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customSpeechCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Speak/Reply on Call (e.g. "Tuma pesa kwa namba binafsi" or "Lipa kwa official paybill")...',
                              filled: true,
                              fillColor: Color(0xFF090B10),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (v) {
                              if (v.trim().isNotEmpty) {
                                _processDialogueTurn(DialogueTurn('Live Input', v.trim(), 'caller'));
                                _customSpeechCtrl.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_customSpeechCtrl.text.trim().isNotEmpty) {
                              _processDialogueTurn(DialogueTurn('Live Input', _customSpeechCtrl.text.trim(), 'caller'));
                              _customSpeechCtrl.clear();
                            }
                          },
                          icon: const Icon(Icons.record_voice_over, size: 16),
                          label: const Text('Speak & Analyze'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      onPressed: _testContextAwareStkPush,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text('Test Naivas / Official Hospital STK Push'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                      onPressed: _runUssdCode,
                      icon: const Icon(Icons.dialpad, size: 18),
                      label: const Text('Dial *100# USSD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: SMS SPOOF GUARD
  // ==========================================================================

  Widget _buildTab2SmsGuard() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _smsInbox.length,
      itemBuilder: (ctx, i) {
        final sms = _smsInbox[i];
        final isSpoof = !sms.isOfficialToken;
        return Card(
          color: const Color(0xFF121621),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Sender: ${sms.sender}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(sms.body),
                const SizedBox(height: 6),
                Text(
                  isSpoof ? '⚠️ SPOOFED SENDER: Personal 07xx line disguising as MPESA' : '✓ Official Alphanumeric MPESA Token',
                  style: TextStyle(color: isSpoof ? Colors.amber : const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: isSpoof
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() => _riskScore = 96);
                      _triggerSelectiveFinancialLock(reason: 'Spoofed M-Pesa reversal SMS from ${sms.sender}.');
                    },
                    child: const Text('Block Reversal'),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ==========================================================================
  // TAB 3: FAMILY GUARDIANS (VERIFY TRUE EMERGENCY vs BLOCK SCAM)
  // ==========================================================================

  Widget _buildTab3Guardians(int approvals, int blocks) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Family Guardian Consensus Pool (Approvals: $approvals/2 • Blocks: $blocks/2)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'If a call is a TRUE family emergency that triggered the safety lock, any 2 Guardians can tap "Approve Safe" to unlock M-Pesa immediately.',
          style: TextStyle(fontSize: 12.5, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        ..._guardians.map(
          (g) => Card(
            color: const Color(0xFF121621),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text('${g.name} (${g.relation})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${g.phone} • Status: ${g.status}'),
              trailing: g.vote == null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() => g.vote = 'block');
                            if (_guardians.where((x) => x.vote == 'block').length >= 2) {
                              NeuralVoiceEngine.speak(
                                'Two family guardians confirmed this is a scam. Caller number blacklisted.',
                                role: 'ai',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: Color(0xFF991B1B), content: Text('2 Guardians Blocked Scam! Caller blacklisted.')),
                              );
                            }
                          },
                          child: const Text('Block Scam'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
                          onPressed: () {
                            setState(() => g.vote = 'approve');
                            if (_guardians.where((x) => x.vote == 'approve').length >= 2) {
                              _resetCallState();
                              NeuralVoiceEngine.speak(
                                'Two family guardians verified the emergency is genuine. M-Pesa is now unlocked.',
                                role: 'ai',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(backgroundColor: Color(0xFF065F46), content: Text('2 Guardians Approved! True Emergency Verified — M-Pesa Unlocked.')),
                              );
                            }
                          },
                          child: const Text('Approve Safe'),
                        ),
                      ],
                    )
                  : Text(g.vote!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF06B6D4))),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 4: ON-DEVICE MACHINE LEARNING STUDIO
  // ==========================================================================

  Widget _buildTab4MLStudio() {
    final sortedWeights = _mlModel.weights.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'On-Device Machine Learning Studio (SGD Logistic Perceptron + Bigram NLU)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Notice how Scam features have positive weights (+w_i) while Genuine Emergency features (like "official_paybill", "reception") have negative weights (-w_i) so true emergencies are not blocked!',
                style: TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('Training Accuracy', '${_mlModel.trainingAccuracy.toStringAsFixed(1)}%', const Color(0xFF10B981))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Cross-Entropy Loss', _mlModel.lastTrainingLoss.toStringAsFixed(4), const Color(0xFF06B6D4))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard('Learned N-Grams', '${_mlModel.weights.length} features', Colors.amber)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121621),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22293A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live On-Device Continuous Learning (Add Sample & Update Weights)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _trainSentenceCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter new Swahili/Sheng phrase to train on-device...',
                        filled: true,
                        fillColor: Color(0xFF090B10),
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
                            ButtonSegment(value: 0, label: Text('Label: GENUINE / SAFE (0)')),
                          ],
                          selected: {_trainLabel},
                          onSelectionChanged: (s) => setState(() => _trainLabel = s.first),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
                          onPressed: () {
                            final txt = _trainSentenceCtrl.text.trim();
                            if (txt.isEmpty) return;
                            setState(() {
                              _mlModel.addSampleAndRetrain(txt, _trainLabel, _trainLabel == 1 ? 'Urgency' : 'Safe');
                              _trainSentenceCtrl.clear();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Retrained On-Device Model via SGD! Weights updated.')),
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
              const Text('Top Learned Feature Weights (+Scam vs -Genuine/Safe)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121621),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22293A)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedWeights.take(20).map((e) {
                    final isScamWeight = e.value > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isScamWeight ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isScamWeight ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                      ),
                      child: Text(
                        '${e.key}: ${e.value >= 0 ? "+" : ""}${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121621),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF22293A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: color)),
        ],
      ),
    );
  }

  Widget _buildIncomingCallOverlay() {
    return Container(
      color: const Color(0xFF090B10).withOpacity(0.96),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 20),
          Column(
            children: [
              const Icon(Icons.phone_in_talk, size: 54, color: Color(0xFF3B82F6)),
              const SizedBox(height: 14),
              Text(_activeCallerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_activeCallerNumber, style: const TextStyle(fontSize: 16, color: Colors.white60, fontFamily: 'monospace')),
              const SizedBox(height: 12),
              const Text(
                'Click Answer to hear the live spoken two-way conversation!',
                style: TextStyle(fontSize: 13, color: Color(0xFF06B6D4)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'dec',
                backgroundColor: const Color(0xFFEF4444),
                onPressed: () {
                  _ringTimer?.cancel();
                  setState(() => _isRinging = false);
                },
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
              FloatingActionButton(
                heroTag: 'ans',
                backgroundColor: const Color(0xFF10B981),
                onPressed: _answerCall,
                child: const Icon(Icons.call, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}