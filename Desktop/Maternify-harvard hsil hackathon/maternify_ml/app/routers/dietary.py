from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()


class DietaryRequest(BaseModel):
    patient_id: str
    weeks_gestation: int
    query: str


class DietaryResponse(BaseModel):
    advice_bangla: str
    advice_english: str
    foods: list[str]


@router.post("/", response_model=DietaryResponse)
async def get_dietary_advice(request: DietaryRequest):
    """Bangladeshi dietary RAG pipeline — implemented in F18."""
    raise HTTPException(status_code=501, detail="Dietary advisor — implemented in F18")
