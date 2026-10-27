# 🛡️ Ngao-Sauti OS — On-Device AI Call & Mobile Money Firewall

> **"People First, AI Second"** — A 100% On-Device Machine Learning Voice & Financial Firewall built in Flutter (Dart) to protect Kenyan mobile money users from coercive phone scams, fake emergency panic calls, SIM-swap traps, and spoofed M-Pesa reversal texts—even with **0 MB mobile data**.

---

## 👥 Core Team
* **Owen Mwangi** — Lead Full-Stack & Systems Architect (Context-Aware STK/USSD Firewall, Neural Voice Bridge, UI/UX)
* **Muhammed Hassan** — Security & Consensus Workflow Lead (2-of-N Family Guardian Network, Offline GSM SMS Escalation)
* **Collins Mundia** — Machine Learning Lead (On-Device SGD Logistic Perceptron, Bigram NLU, Continuous Retraining Studio)

---

## 🚀 Key Innovations (Why Ngao-Sauti Wins)

### 1. Context-Aware Payment Shield (Zero False Positives at the Supermarket)
Traditional security apps annoy users by blocking normal payments. Ngao-Sauti’s STK & USSD (`*100#`) firewall stays asleep during normal daily life (paying at a supermarket till, hospital paybill, or checking airtime) and **ONLY** activates a selective lock when **two conditions occur simultaneously**:
1. The user is on an active phone call (or just received a spoofed reversal SMS).
2. The On-Device ML Classifier scores the live conversation above **75% Scam Probability**.

### 2. True Emergency vs. Fake Emergency Differentiation
What if a real hospital or school calls a parent?
* **Scam Emergency Call:** Combines panic with demands to send money to a **personal phone number** (`07xx`) and forbids hanging up to verify. Our ML model assigns high positive weights ($+w_i$) to these coercive bigrams and freezes M-Pesa.
* **Genuine Hospital Call:** Directs the parent to an **Official Hospital Paybill** and encourages calling the child to verify. Our ML model assigns negative weights ($-w_i$) to institutional verification phrases, keeping the risk score low so the parent can pay seamlessly.

### 3. 100% Offline On-Device Machine Learning (`OnDeviceScamMLModel`)
* Runs a mathematical **Stochastic Gradient Descent (SGD) Logistic Perceptron** with Unigram + Bigram feature extraction directly inside Dart:
  $$P(\text{Scam} \mid \mathbf{x}) = \frac{1}{1 + e^{-(\mathbf{w}^T \mathbf{x} + b)}}$$
* Requires **0 MB internet data** and never uploads private family phone calls to external cloud servers.
* Includes a live **On-Device ML Studio (Tab 4)** where new Swahili/Sheng phrases can be labeled and trained live on stage.

### 4. 2-of-N Family Guardian Consensus & Calm-Voice Safe Phrase
* When M-Pesa is paused, normal voice calls remain **100% open** so the user can call family directly.
* Pings registered Family Guardians (Owen, Muhammed, Collins). Any **2 approvals** unlock M-Pesa immediately; **2 blocks** blacklist the scammer.
* Includes a **90-second offline GSM SMS fallback** and a **Calm-Voice Safe-Phrase Override** (`"Nyumba Salama"`) if all guardians are unreachable.

---

## 📂 Project Structure

```text
ngao_sauti/
├── lib/
│   └── main.dart          # Complete App: Onboarding, Call/STK Shield, SMS Guard, Guardians & ML Studio
├── pubspec.yaml           # Pure Dart/Flutter configuration (Zero external package failures)
└── README.md              # Team Architecture & Live Demo Guide