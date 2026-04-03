"""
LSTM anomaly detection service.
Stub implementation — full LSTM training built in F7.
"""
from app.schemas.vitals import AnomalyRequest, AnomalyResponse
from app.services.model_loader import get_model


async def detect(request: AnomalyRequest) -> AnomalyResponse:
    model = get_model('lstm')

    if model is None:
        return _threshold_fallback(request)

    # Full LSTM inference implemented in F7
    return _threshold_fallback(request)


def _threshold_fallback(request: AnomalyRequest) -> AnomalyResponse:
    v = request.latest_vitals
    flagged = []
    score = 0.0

    if v.systolic_bp >= 140:
        flagged.append('systolic_bp')
        score += 0.4
    if v.diastolic_bp >= 90:
        flagged.append('diastolic_bp')
        score += 0.35
    if v.blood_glucose > 7.8:
        flagged.append('blood_glucose')
        score += 0.2
    if v.kick_count < 10:
        flagged.append('kick_count')
        score += 0.15

    return AnomalyResponse(
        patient_id=request.patient_id,
        anomaly_detected=score > 0.4,
        anomaly_score=min(score, 1.0),
        flagged_features=flagged,
    )
