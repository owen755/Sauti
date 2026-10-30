import json, math
from scam_lib import *
from split import get_split

ch=json.load(open("out/chosen.json")); THR=ch["thr"]; HP=ch["hp"]
SHIFT=math.log(0.75/0.25)-math.log(THR/(1-THR))     # makes p=0.55 display as 75%
res=json.load(open("out/results.json"))
d=load()
m=Model(tokens_final).fit([(t,y) for t,y,_ in d],**HP)

def shown(text): return sig(m.z(text)+SHIFT)

W="\n".join(f"  '{k}': {v!r}," for k,v in sorted(m.w.items()))
DATA="\n".join(f"  TrainingSample(r\"{t}\", {y}, '{c}')," for t,y,c in d)

DART=r'''// GENERATED FILE - produced by ml_pipeline/export_dart.py. Re-run the script instead of hand-editing weights.
//
// On-device scam model for Ngao-Sauti.
//   - logistic regression trained with SGD (L2 regularised, shuffled), same maths as before
//   - features: word + word-pair presence, numbers -> "num", ALL words kept (dropping function words hurt in testing),
//     plus 6 hand-written "signal" features (asks-for-PIN, warns-about-PIN, forbids-verification,
//     official-channel, pay-to-this-number, pay-urgently) that get their own learned weights
//   - pretrained on @@N@@ hand-written Kenyan scam / genuine sentences (synthetic; see dataset.csv)
//   - the displayed risk % is shifted so the validated decision point (p = @@THR@@) shows as 75%,
//     which is the line the UI uses to lock M-Pesa.
import 'dart:math';

class TrainingSample {
  final String text;
  final int label; // 1 = scam, 0 = safe / genuine
  final String category;
  const TrainingSample(this.text, this.label, this.category);
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

const double kPretrainedBias = @@BIAS@@;

const Map<String, double> kPretrainedWeights = {
@@WEIGHTS@@
};

const List<TrainingSample> kTrainingData = [
@@DATA@@
];


final RegExp _digitComma = RegExp(r'(\d),(\d)');
final RegExp _digits = RegExp(r'[0-9]+');
final RegExp _notLetters = RegExp(r'[^a-z\s]');
final RegExp _spaces = RegExp(r'\s+');

final RegExp _secret = RegExp(r"\b(pin|otp|password|nambari ya siri|namba ya siri|siri ya|msimbo|code)\b");
final RegExp _ask = RegExp(r"\b(tupe|nipe|tusomee|usomee|soma|read|give|confirm|weka|bonyeza|press|enter|thibitisha|provide|tuma|send)\b");
final RegExp _warn = RegExp(r"\b(kamwe|never|usimpe|hatuombi|haitakuomba|haitaomba|hatutaki|do not share|don.?t share|ignore)\b");
final RegExp _isolate = RegExp(r"\b(usikate|usipigie|usimpigie|usipige|usiseme|usimwambie|don.?t hang up|don.?t call|don.?t tell|do not tell|do not call)\b");
final RegExp _official = RegExp(r"\b(rasmi|official|reception|cashier|branch|tawi|hakuna cha kulipa|no payment|no action|hakuna haja)\b");
final RegExp _payVerb = RegExp(r"\b(tuma|send|lipa|pay|deposit|rudisha|return|nirudishie)\b");
final RegExp _thisNum = RegExp(r"\b(hii namba|hii number|hiyo namba|namba hii|nambari hii|this number|this mpesa number|namba binafsi|personal number|namba yangu|number yangu|my number)\b");
final RegExp _urgent = RegExp(r"\b(sasa hivi|haraka|immediately|right now|urgent|urgently|fasta|leo tu|today|before|kabla)\b");

/// The six hand-written signal features. Public so you can unit-test them.
List<String> signalFlags(String text) {
  final t = text.toLowerCase();
  final flags = <String>[];
  final secret = _secret.hasMatch(t);
  final warn = _warn.hasMatch(t);
  if (secret && _ask.hasMatch(t) && !warn) flags.add('SIG_SECRET_ASK');
  if (secret && warn) flags.add('SIG_SECRET_WARN');
  if (_isolate.hasMatch(t)) flags.add('SIG_ISOLATE');
  if (_official.hasMatch(t)) flags.add('SIG_OFFICIAL');
  if (_payVerb.hasMatch(t) && _thisNum.hasMatch(t)) flags.add('SIG_PAY_TO_NUMBER');
  if (_payVerb.hasMatch(t) && _urgent.hasMatch(t)) flags.add('SIG_PAY_URGENT');
  return flags;
}

class OnDeviceScamMLModel {
  /// Probability at/above which a call is treated as a scam (validated by cross-validation).
  static const double decisionThreshold = @@THR@@;

  /// Added to the raw logit before display, so decisionThreshold shows as 75%.
  static const double displayShift = @@SHIFT@@;

  // Honest, held-out numbers (see ml_pipeline/REPORT.md). NOT training accuracy.
  static const int heldOutTestSize = @@TESTN@@;
  static const double heldOutPrecision = @@P@@;
  static const double heldOutRecall = @@R@@;
  static const double heldOutF1 = @@F@@;
  static const double crossValidatedF1 = @@CVF1@@; // out-of-fold F1 at the chosen threshold on the train+val sentences

  final Map<String, double> weights = Map<String, double>.of(kPretrainedWeights);
  double bias = kPretrainedBias;
  double lastTrainingLoss = 0.0;
  double trainingAccuracy = 0.0; // accuracy on its own training data - for the Studio only, never quote it
  int totalEpochsTrained = 0;

  final List<TrainingSample> dataset = List<TrainingSample>.of(kTrainingData);

  OnDeviceScamMLModel() {
    _refreshTrainingStats();
  }

  List<String> extractFeatures(String rawText) {
    var t = rawText.toLowerCase();
    t = t.replaceAllMapped(_digitComma, (m) => '${m[1]}${m[2]}');
    t = t.replaceAllMapped(_digitComma, (m) => '${m[1]}${m[2]}');
    t = t.replaceAll(_digits, ' num ');
    t = t.replaceAll(_notLetters, ' ');
    final words = t
        .split(_spaces)
        .where((w) => w.length > 1)
        .toList();
    final feats = <String>{...words};
    for (int i = 0; i < words.length - 1; i++) {
      feats.add('${words[i]}_${words[i + 1]}');
    }
    feats.addAll(signalFlags(rawText));
    return feats.toList();
  }

  double _sigmoid(double z) {
    if (z > 20) return 0.9999;
    if (z < -20) return 0.0001;
    return 1.0 / (1.0 + exp(-z));
  }

  /// Score the last [window] turns of a call together (default 3).
  MLInferenceResult predictWindow(List<String> turns, {int window = 3}) {
    final start = max(0, turns.length - window);
    return predict(turns.sublist(start).join(' '));
  }

  MLInferenceResult predict(String transcriptText) {
    final feats = extractFeatures(transcriptText);
    double z = bias;
    final Map<String, double> activeWeights = {};
    for (final f in feats) {
      final w = weights[f] ?? 0.0;
      z += w;
      if (w.abs() > 0.15) activeWeights[f] = w;
    }
    final shownLogit = z + displayShift;
    final prob = _sigmoid(shownLogit);
    final riskPct = (prob * 100).round().clamp(1, 99).toInt();

    // Manipulation "vector" chips: exact feature matches, not substring matches.
    final Set<String> featSet = feats.toSet();
    final Set<String> vectors = {};
    if (featSet.any(const {'sasa_hivi', 'haraka', 'usikate_simu', 'ajali', 'ameumia', 'SIG_ISOLATE', 'SIG_PAY_URGENT'}.contains)) {
      vectors.add('Urgency');
    }
    if (featSet.any(const {'safaricom', 'customer_care', 'polisi', 'kra', 'ntsa', 'dci', 'afisa', 'inspekta'}.contains)) {
      vectors.add('Authority');
    }
    if (featSet.any(const {'SIG_PAY_TO_NUMBER', 'rudisha', 'reverse', 'kimakosa', 'namba_binafsi', 'by_mistake'}.contains)) {
      vectors.add('Financial Coercion');
    }
    if (featSet.any(const {'SIG_SECRET_ASK', 'sim_swap'}.contains)) {
      vectors.add('PIN / SIM Trap');
    }

    String explanation;
    if (riskPct >= 75) {
      explanation =
          'HIGH THREAT: scam pattern detected (${vectors.isEmpty ? "multiple weak signals" : vectors.join(" + ")}).';
    } else if (featSet.contains('SIG_OFFICIAL') || featSet.contains('SIG_SECRET_WARN')) {
      explanation =
          'VERIFIED INSTITUTIONAL CALL: official channel mentioned / caller warns against sharing secrets.';
    } else {
      explanation =
          'SAFE CONTEXT: no strong scam signals in the recent conversation.';
    }

    return MLInferenceResult(
      probability: prob,
      riskPercentage: riskPct,
      matchedFeatureWeights: activeWeights,
      detectedVectors: vectors.toList(),
      logitScore: shownLogit,
      verdictExplanation: explanation,
    );
  }

  void _refreshTrainingStats() {
    double loss = 0.0;
    int correct = 0;
    for (final s in dataset) {
      final p = _sigmoid(_rawLogit(s.text));
      final y = s.label.toDouble();
      loss += -(y * log(p + 1e-9) + (1 - y) * log(1 - p + 1e-9));
      if ((p >= decisionThreshold) == (s.label == 1)) correct++;
    }
    lastTrainingLoss = loss / dataset.length;
    trainingAccuracy = correct / dataset.length * 100.0;
  }

  double _rawLogit(String text) {
    double z = bias;
    for (final f in extractFeatures(text)) {
      z += weights[f] ?? 0.0;
    }
    return z;
  }

  /// Warm-start SGD: continues from the current weights on the full dataset, shuffled each epoch.
  void trainModel({int epochs = 15, double learningRate = 0.05, double l2 = @@L2@@}) {
    final rng = Random(3 + totalEpochsTrained);
    final prepared = dataset
        .map((s) => MapEntry<List<String>, int>(extractFeatures(s.text), s.label))
        .toList();
    for (int epoch = 0; epoch < epochs; epoch++) {
      prepared.shuffle(rng);
      for (final item in prepared) {
        double z = bias;
        for (final f in item.key) {
          z += weights[f] ?? 0.0;
        }
        final double err = _sigmoid(z) - item.value;
        bias -= learningRate * err;
        for (final f in item.key) {
          final double w = weights[f] ?? 0.0;
          weights[f] = w - learningRate * (err + l2 * w);
        }
      }
      totalEpochsTrained++;
    }
    _refreshTrainingStats();
  }

  void addSampleAndRetrain(String text, int label, String category) {
    dataset.add(TrainingSample(text, label, category));
    trainModel(epochs: 15, learningRate: 0.05);
  }
}
'''
DART=(DART.replace("@@N@@",str(len(d))).replace("@@THR@@",str(THR)).replace("@@BIAS@@",repr(m.b))
      .replace("@@SHIFT@@",repr(SHIFT)).replace("@@WEIGHTS@@",W).replace("@@DATA@@",DATA)
      .replace("@@P@@",f"{res['test_final']['precision']:.4f}").replace("@@R@@",f"{res['test_final']['recall']:.4f}")
      .replace("@@F@@",f"{res['test_final']['f1']:.4f}").replace("@@TESTN@@",str(res["test_n"])).replace("@@CVF1@@",f"{ch['cv_f1']:.2f}").replace("@@L2@@",repr(HP["l2"])))
open("out/scam_model.dart","w",encoding="utf-8").write(DART)

# ---- golden values for the Dart unit test + JS parity check
extra=["Please pay Ksh 5,000,000 now to this number","  M-Pesa PIN?? Don't share it, EVER!!  ","*544# bundle expires; ng'ambo job",
 "Nimetuma pesa kimakosa, tafadhali rudisha sasa hivi kwa hii namba","Safaricom haitaomba kamwe PIN yako",
 "Hello this is Equity Bank security, read me the OTP right now","Mama nimeishiwa, tuma elfu mbili ya fare","",
 "Dad it's me I have been arrested please don't tell anybody just send money to this number now"]
cases=[t for t,_,_ in d[::13]]+extra
golden=[{"text":t,"features":sorted(tokens_final(t)),"prob":shown(t),"risk":int(max(1,min(99,round(shown(t)*100))))} for t in cases]
json.dump(golden,open("out/golden.json","w"),indent=1)
json.dump({"all_text":[t for t,_,_ in d]+extra,"weights":m.w,"bias":m.b,"shift":SHIFT},open("out/model.json","w"))
print("dart bytes:",len(DART),"| features:",len(m.w),"| bias",round(m.b,4),"| shift",round(SHIFT,4),"| golden cases:",len(golden))
