import joblib
import os
import logging

logger = logging.getLogger(__name__)

# Global model registry
_models = {}


async def load_models():
    """Load serialized models from saved_models/ on startup."""
    model_dir = os.path.join(os.path.dirname(__file__), '../../saved_models')

    xgb_path = os.path.join(model_dir, 'xgboost_risk.pkl')
    if os.path.exists(xgb_path):
        _models['xgboost'] = joblib.load(xgb_path)
        logger.info("XGBoost model loaded")
    else:
        logger.warning("XGBoost model not found — will use stub predictions (train in F6)")

    lstm_path = os.path.join(model_dir, 'lstm_anomaly.pkl')
    if os.path.exists(lstm_path):
        _models['lstm'] = joblib.load(lstm_path)
        logger.info("LSTM model loaded")
    else:
        logger.warning("LSTM model not found — will use stub predictions (train in F7)")


def get_model(name: str):
    return _models.get(name)
