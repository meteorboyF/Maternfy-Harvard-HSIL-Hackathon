from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.routers import risk_score, vitals_anomaly, dietary


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load ML models on startup."""
    from app.services.model_loader import load_models
    await load_models()
    yield


app = FastAPI(
    title="Maternify ML Service",
    description="XGBoost risk scoring + LSTM anomaly detection for maternal health",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)

app.include_router(risk_score.router, prefix="/risk-score", tags=["Risk Score"])
app.include_router(vitals_anomaly.router, prefix="/vitals-anomaly", tags=["Anomaly"])
app.include_router(dietary.router, prefix="/dietary", tags=["Dietary"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "maternify-ml"}
