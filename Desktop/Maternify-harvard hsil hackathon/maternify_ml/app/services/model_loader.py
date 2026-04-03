import joblib
import os
import logging

logger = logging.getLogger(__name__)

_models = {}

MODEL_DIR = os.path.join(os.path.dirname(__file__), '../../saved_models')


async def load_models():
    """Load all serialized models from saved_models/ on startup."""

    # XGBoost
    xgb_path = os.path.join(MODEL_DIR, 'xgboost_risk.pkl')
    le_path  = os.path.join(MODEL_DIR, 'xgboost_label_encoder.pkl')
    if os.path.exists(xgb_path) and os.path.exists(le_path):
        _models['xgboost']    = joblib.load(xgb_path)
        _models['xgboost_le'] = joblib.load(le_path)
        logger.info("XGBoost model + label encoder loaded")
    else:
        logger.warning("XGBoost model not found — rule-based fallback active (run training/train_xgboost.py)")

    # LSTM
    lstm_keras = os.path.join(MODEL_DIR, 'lstm_anomaly.keras')
    lstm_meta  = os.path.join(MODEL_DIR, 'lstm_threshold.pkl')
    if os.path.exists(lstm_keras) and os.path.exists(lstm_meta):
        try:
            import tensorflow as tf
            _models['lstm']      = tf.keras.models.load_model(lstm_keras)
            _models['lstm_meta'] = joblib.load(lstm_meta)
            logger.info("LSTM model + threshold meta loaded")
        except ImportError:
            logger.warning("TensorFlow not installed — LSTM threshold fallback active")
    else:
        logger.warning("LSTM model not found — threshold fallback active (run training/train_lstm.py)")


def get_model(name: str):
    return _models.get(name)
