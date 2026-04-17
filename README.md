# Monday

**Monday** is an AI-powered GitHub assistant built with Flutter that acts as a developer teammate inside your pocket.

It helps you authenticate with GitHub, understand repositories, and (in future updates) manage code, branches, and reviews using AI.

---

## ⚠️ Project Status

🚧 **Early Development (WIP)**

### ✅ Completed
- Groq AI service integration (rate limiting + usage tracking)
- GitHub OAuth login (secure backend token exchange)

### ⏳ In Progress / Planned
- Repository browser (repos, branches, file tree)
- AI file explanation system
- Commit + diff viewer with AI review
- Branch workflow system (approve / reject / revise)
- Model switcher UI
- Usage dashboard

---

## ✨ Current Features

### 🤖 AI Service (Groq Integration)

Monday uses Groq-hosted LLMs for fast AI responses:

- `llama-3.1-8b-instant` (Fast)
- `llama-3.3-70b-versatile` (Smart)
- `llama-4-scout-17b-16e-instruct` (Balanced)

Includes:
- RPM / TPM rate limiting
- Usage tracking
- Safe request throttling (prevents quota abuse)

---

### 🔐 GitHub OAuth Authentication

Secure login system using GitHub OAuth with backend token exchange.

Flow:
1. User logs in via GitHub OAuth
2. Authorization code sent to backend
3. Backend exchanges code for access token
4. Token securely stored in device
5. App uses token for GitHub API requests

Security:
- Tokens stored using `flutter_secure_storage`
- Client secret never exposed in Flutter
- Scoped access only:
  - repo
  - read:user

---

## 🧱 Tech Stack

### Frontend (Flutter App)
- Flutter
- flutter_appauth
- flutter_secure_storage
- http
- shared_preferences

### AI Layer
- Groq API
  - llama-3.1-8b-instant
  - llama-3.3-70b-versatile
  - llama-4-scout-17b-16e-instruct

### Authentication
- GitHub OAuth (backend token exchange)
- Backend handles client secret securely
- repo + read:user scopes

### Backend (Required)
- Node.js / Express OR serverless functions (Vercel / Railway / Render)
- POST /auth/token
- POST /auth/revoke
- Stores client_secret securely (never in Flutter)

### External Services
- GitHub REST API
- Groq API

---

## 🔐 Security Rules

- No client secrets in Flutter
- No automatic commits or pushes
- Never touch main branch
- All GitHub actions require user approval
- Tokens stored only in secure storage
- Backend handles all sensitive operations

---

## 🌿 Git Workflow Rules

- One feature = one branch
- Never push to main
- Branch format:
  feat/description
  fix/description
  refactor/description
  perf/description
  chore/description
- Generated branch names are normalized to lowercase `type/description` before publish.
- If a branch already exists on GitHub at the same base commit, Monday reuses it instead of failing.
- No AI/bot/assistant naming in branches
- Every push requires explicit approval

---

## 🧭 Roadmap

Phase 1
- Groq AI service
- GitHub OAuth login

Phase 2
- Repo browser
- File tree viewer
- Branch listing

Phase 3
- AI file explanation
- Commit diff viewer
- Code review AI

Phase 4
- Branch workflow system
- Push approval gate

Phase 5
- Model switcher
- Usage tracking dashboard

---

## 💡 Vision

Monday is a fully interactive AI GitHub teammate inside Flutter.

It helps developers:
- understand code faster
- manage repositories safely
- automate thinking, not control
- keep full human approval over every action

---

## 📌 Philosophy

AI suggests. You decide. Nothing ships without you.

---

## 🛠 Setup

flutter pub get

Required packages:
- flutter_appauth
- flutter_secure_storage
- http
- shared_preferences

Backend required:
POST /auth/token
POST /auth/revoke

Client secret must never be in Flutter.

---

## 📄 License

Private / In Development

---

## 🤝 Status

Monday is actively being built into an AI-assisted GitHub workspace inside Flutter.