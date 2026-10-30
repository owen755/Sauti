#!/usr/bin/env bash
# Re-runs the whole ML pipeline from scratch (about 5-10 minutes).
# Needs: python3 + scikit-learn (pip install scikit-learn). Node.js is optional (Dart-parity check).
# If you ADD your own rows to out/dataset.csv, comment out the first two lines (they rebuild the CSV from the built-in lists).
set -e
cd "$(dirname "$0")"; mkdir -p out
python3 build_dataset.py       # batch 1 -> out/dataset_v1.csv  (202 sentences)
python3 build_dataset2.py      # batch 2 -> out/dataset_v2_new.csv and merged out/dataset.csv  (382 sentences)
python3 fresh_test.py          # frozen batch-1 model scored on never-seen batch 2
python3 compare_recipes.py     # 4 recipes, cross-validation on everything
python3 ablation.py            # which preprocessing choices matter (train+val only)
python3 tune_final.py          # training settings + alert threshold (train+val only)  -> out/chosen.json
python3 final_eval.py          # ONE-TIME exam on the locked test set + unseen-family test -> out/results.json
python3 dialogues.py           # whole-call scoring (smoke test)
python3 checks.py              # length drift + live retraining safety
python3 export_dart.py         # -> out/scam_model.dart
python3 gen_test.py            # -> out/scam_model_test.dart
python3 - <<'PY'
import json
from scam_lib import *
mj=json.load(open("out/model.json"))
json.dump({t:sorted(tokens_final(t)) for t in mj["all_text"]},open("out/py_features.json","w"))
PY
if command -v node >/dev/null; then node parity.js | head -3; fi
echo "Done. Copy out/scam_model.dart -> lib/   and   out/scam_model_test.dart -> test/"
