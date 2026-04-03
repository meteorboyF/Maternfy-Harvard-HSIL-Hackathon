from fastapi import APIRouter, HTTPException
from app.schemas.vitals import RiskScoreRequest, RiskScoreResponse
from app.services import xgboost_service

router = APIRouter()


@router.post("/", response_model=RiskScoreResponse)
async def get_risk_score(request: RiskScoreRequest):
    """
    XGBoost risk stratification — returns green/yellow/red + SHAP top-3 features.
    Full implementation in F6.
    """
    try:
        return await xgboost_service.predict(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
