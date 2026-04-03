"""
XGBoost risk scoring service.
Stub implementation — full training + SHAP integration built in F6.
"""
import numpy as np
from app.schemas.vitals import RiskScoreRequest, RiskScoreResponse, ShapFeature
from app.services.model_loader import get_model


async def predict(request: RiskScoreRequest) -> RiskScoreResponse:
    model = get_model('xgboost')

    if model is None:
        # Stub: rule-based fallback until F6 trains the real model
        return _rule_based_fallback(request)

    features = _extract_features(request)
    proba = model.predict_proba([features])[0]
    tier_idx = int(np.argmax(proba))
    tier = ['green', 'yellow', 'red'][tier_idx]

    return RiskScoreResponse(
        patient_id=request.patient_id,
        risk_tier=tier,
        probability=float(proba[tier_idx]),
        shap_features=[],  # SHAP values added in F6
    )


def _rule_based_fallback(request: RiskScoreRequest) -> RiskScoreResponse:
    v = request.vitals
    if v.systolic_bp >= 160 or v.diastolic_bp >= 110:
        tier, prob = 'red', 0.9
    elif v.systolic_bp >= 140 or v.diastolic_bp >= 90:
        tier, prob = 'yellow', 0.6
    else:
        tier, prob = 'green', 0.85

    return RiskScoreResponse(
        patient_id=request.patient_id,
        risk_tier=tier,
        probability=prob,
        shap_features=[
            ShapFeature(feature='systolic_bp', value=float(v.systolic_bp), impact=0.4),
            ShapFeature(feature='diastolic_bp', value=float(v.diastolic_bp), impact=0.35),
            ShapFeature(feature='weeks_gestation', value=float(request.weeks_gestation), impact=0.15),
        ],
    )


def _extract_features(request: RiskScoreRequest) -> list:
    v = request.vitals
    return [
        request.age,
        request.weeks_gestation,
        request.gravida,
        request.parity,
        v.systolic_bp,
        v.diastolic_bp,
        v.weight_kg,
        v.blood_glucose,
        v.kick_count,
    ]
