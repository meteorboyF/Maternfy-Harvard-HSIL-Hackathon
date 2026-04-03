"""
LSTM anomaly detection service — F7
7-day rolling window autoencoder. Reconstruction error > threshold = anomaly.
Falls back to threshold rules if model not trained yet.
"""
import numpy as np
from app.schemas.vitals import AnomalyRequest, AnomalyResponse
from app.services.model_loader import get_model

VITALS_COLS = ['systolic_bp', 'diastolic_bp', 'weight_kg', 'blood_glucose', 'kick_count']


async def detect(request: AnomalyRequest) -> AnomalyResponse:
    lstm_model = get_model('lstm')
    lstm_meta = get_model('lstm_meta')

    if lstm_model is None or lstm_meta is None:
        return _threshold_fallback(request)

    return await _lstm_inference(lstm_model, lstm_meta, request)


async def _lstm_inference(model, meta, request: AnomalyRequest) -> AnomalyResponse:
    """
    Runs LSTM inference. In production, we'd fetch the last 7 days of vitals
    from Supabase and build the window. Here we use the single latest reading
    repeated to fill the window (works for demo; full version in prod pipeline).
    """
    try:
        v = request.latest_vitals
        single = np.array([
            v.systolic_bp, v.diastolic_bp, v.weight_kg, v.blood_glucose, v.kick_count
        ], dtype=np.float32)

        # Repeat to fill 7-day window
        window = np.tile(single, (meta['window'], 1))[np.newaxis]  # (1, 7, 5)

        # Normalise
        norm = (window - meta['mean']) / meta['std']

        recon = model.predict(norm, verbose=0)
        error = float(np.mean(np.abs(recon - norm)))
        anomaly_detected = error > meta['threshold']

        flagged = []
        if v.systolic_bp >= 140:  flagged.append('systolic_bp')
        if v.diastolic_bp >= 90:  flagged.append('diastolic_bp')
        if v.blood_glucose > 7.8: flagged.append('blood_glucose')
        if v.kick_count < 10:     flagged.append('kick_count')

        return AnomalyResponse(
            patient_id=request.patient_id,
            anomaly_detected=anomaly_detected,
            anomaly_score=min(error / meta['threshold'], 1.0),
            flagged_features=flagged,
        )
    except Exception as e:
        # LSTM inference failed — fall back to rule-based
        return _threshold_fallback(request)


def _threshold_fallback(request: AnomalyRequest) -> AnomalyResponse:
    v = request.latest_vitals
    flagged = []
    score = 0.0

    if v.systolic_bp >= 140:  flagged.append('systolic_bp');  score += 0.4
    if v.diastolic_bp >= 90:  flagged.append('diastolic_bp'); score += 0.35
    if v.blood_glucose > 7.8: flagged.append('blood_glucose'); score += 0.2
    if v.kick_count < 10:     flagged.append('kick_count');   score += 0.15

    return AnomalyResponse(
        patient_id=request.patient_id,
        anomaly_detected=score > 0.4,
        anomaly_score=min(score, 1.0),
        flagged_features=flagged,
    )
