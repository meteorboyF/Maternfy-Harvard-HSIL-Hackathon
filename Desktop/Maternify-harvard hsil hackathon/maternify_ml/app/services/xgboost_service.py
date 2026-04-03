"""
XGBoost risk scoring service — F6
Uses trained model + SHAP for top-3 feature explanations.
Falls back to rule-based stub if model not yet trained.
"""
import numpy as np
from app.schemas.vitals import RiskScoreRequest, RiskScoreResponse, ShapFeature
from app.services.model_loader import get_model

FEATURES = [
    'age', 'weeks_gestation', 'gravida', 'parity',
    'systolic_bp', 'diastolic_bp', 'weight_kg',
    'blood_glucose', 'kick_count',
]


async def predict(request: RiskScoreRequest) -> RiskScoreResponse:
    model = get_model('xgboost')
    label_encoder = get_model('xgboost_le')

    if model is None or label_encoder is None:
        return _rule_based_fallback(request)

    features = _extract_features(request)
    features_np = np.array([features])

    proba = model.predict_proba(features_np)[0]
    tier_idx = int(np.argmax(proba))
    tier = label_encoder.inverse_transform([tier_idx])[0]

    shap_features = _compute_shap(model, features_np, label_encoder.classes_)

    return RiskScoreResponse(
        patient_id=request.patient_id,
        risk_tier=tier,
        probability=float(proba[tier_idx]),
        shap_features=shap_features[:3],  # top 3 most impactful
    )


def _compute_shap(model, features_np, classes) -> list[ShapFeature]:
    try:
        import shap
        explainer = shap.TreeExplainer(model)
        shap_values = explainer.shap_values(features_np)  # shape: (n_classes, n_samples, n_features)

        # Use SHAP values for the predicted class
        pred_class = int(np.argmax(model.predict_proba(features_np)[0]))
        sv = shap_values[pred_class][0]  # feature impacts for this prediction

        impacts = [
            ShapFeature(feature=FEATURES[i], value=float(features_np[0][i]), impact=float(sv[i]))
            for i in range(len(FEATURES))
        ]
        # Sort by absolute impact descending
        return sorted(impacts, key=lambda x: abs(x.impact), reverse=True)
    except Exception:
        # SHAP failed — return features with zero impact
        return [
            ShapFeature(feature=f, value=float(features_np[0][i]), impact=0.0)
            for i, f in enumerate(FEATURES)
        ]


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
        request.age, request.weeks_gestation, request.gravida, request.parity,
        v.systolic_bp, v.diastolic_bp, v.weight_kg, v.blood_glucose, v.kick_count,
    ]
