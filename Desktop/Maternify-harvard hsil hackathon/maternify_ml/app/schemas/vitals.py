from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class VitalsEntry(BaseModel):
    systolic_bp: int = Field(..., ge=60, le=250)
    diastolic_bp: int = Field(..., ge=40, le=150)
    weight_kg: float = Field(..., gt=0)
    blood_glucose: float = Field(..., gt=0)
    kick_count: int = Field(..., ge=0)
    logged_at: Optional[datetime] = None


class RiskScoreRequest(BaseModel):
    patient_id: str
    age: int
    weeks_gestation: int
    gravida: int
    parity: int
    vitals: VitalsEntry


class ShapFeature(BaseModel):
    feature: str
    value: float
    impact: float


class RiskScoreResponse(BaseModel):
    patient_id: str
    risk_tier: str  # green | yellow | red
    probability: float
    shap_features: list[ShapFeature]


class AnomalyRequest(BaseModel):
    patient_id: str
    latest_vitals: VitalsEntry


class AnomalyResponse(BaseModel):
    patient_id: str
    anomaly_detected: bool
    anomaly_score: float
    flagged_features: list[str]
