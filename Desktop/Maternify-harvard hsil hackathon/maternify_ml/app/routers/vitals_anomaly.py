from fastapi import APIRouter, HTTPException
from app.schemas.vitals import AnomalyRequest, AnomalyResponse
from app.services import lstm_service

router = APIRouter()


@router.post("/", response_model=AnomalyResponse)
async def detect_anomaly(request: AnomalyRequest):
    """
    LSTM anomaly detection on 7-day rolling vitals window.
    Full implementation in F7.
    """
    try:
        return await lstm_service.detect(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
