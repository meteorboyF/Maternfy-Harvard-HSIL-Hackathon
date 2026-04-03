# Maternify

> Maternal health ecosystem for Bangladesh — Harvard HSIL Hackathon @ UIU

## Architecture

| Service | Tech | Directory |
|---------|------|-----------|
| Mobile App | Flutter (Dart) | `maternify_app/` |
| Clinical Dashboard | Next.js 14 + Tailwind | `maternify_dashboard/` |
| Orchestration API | Node.js + Express | `maternify_api/` |
| ML Service | FastAPI + Python | `maternify_ml/` |

## Quick Start

### Node API
```bash
cd maternify_api
cp .env.example .env   # fill in secrets
npm install
npm run dev            # :3000
```

### ML Service
```bash
cd maternify_ml
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

### Dashboard
```bash
cd maternify_dashboard
cp .env.local.example .env.local   # fill in secrets
npm install
npm run dev   # :3001
```

### Flutter App
```bash
cd maternify_app
flutter pub get
flutter run
```

## Feature Progress
See [PROGRESS.md](PROGRESS.md) for current build status.
