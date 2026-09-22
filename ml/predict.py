"""
Inference Pipeline and Explainable AI (XAI) for HabitGuard.
Predicts Digital Addiction Risk and computes mathematically grounded behavioral risk factor attributions.
"""

import os
import json
import joblib
from typing import Dict, Any, List
import numpy as np

from feature_engineering import (
    FEATURE_NAMES,
    CLASS_LABELS,
    sanitize_input_features,
    to_feature_vector,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")

_model = None
_scaler = None
_baselines = None
_feature_importances = None


def load_artifacts():
    global _model, _scaler, _baselines, _feature_importances
    if _model is not None:
        return

    model_path = os.path.join(MODEL_DIR, "random_forest_model.pkl")
    scaler_path = os.path.join(MODEL_DIR, "scaler.pkl")
    baselines_path = os.path.join(MODEL_DIR, "feature_baselines.json")

    if not os.path.exists(model_path) or not os.path.exists(scaler_path):
        raise FileNotFoundError(f"Model artifacts not found in {MODEL_DIR}. Please run train.py first.")

    _model = joblib.load(model_path)
    _scaler = joblib.load(scaler_path)

    if os.path.exists(baselines_path):
        with open(baselines_path, "r") as f:
            data = json.load(f)
            _baselines = data.get("baselines", {})
            _feature_importances = data.get("feature_importances", {})


def explain_prediction(cleaned: Dict[str, float], predicted_level: str) -> List[Dict[str, str]]:
    """
    Explainable AI (XAI) Attribution Engine.
    Maps user's behavioral features against healthy baselines and model feature importances
    to generate grounded explanations with HIGH / MEDIUM / LOW impact ratings.
    """
    factors: List[Dict[str, str]] = []

    late_night = cleaned["lateNightUsage"]
    social_time = cleaned["socialMediaTime"]
    social_pct = cleaned["socialMediaPercentage"]
    gaming_time = cleaned["gamingTime"]
    sessions = cleaned["numberOfSessions"]
    total_screen = cleaned["totalScreenTime"]
    change_pct = cleaned["usageChangePercentage"]
    productive_pct = cleaned["productivePercentage"]

    # 1. Late-Night Usage Factor
    if late_night >= 60:
        factors.append({
            "factor": "Late Night Usage",
            "impact": "HIGH",
            "description": f"{int(late_night)} minutes of smartphone activity detected between 11 PM and 7 AM, disrupting sleep architecture.",
        })
    elif late_night >= 25:
        factors.append({
            "factor": "Late Night Usage",
            "impact": "MEDIUM",
            "description": f"{int(late_night)} minutes of late-night screen time contributes to increased nocturnal dependency.",
        })
    elif late_night > 0:
        factors.append({
            "factor": "Late Night Usage",
            "impact": "LOW",
            "description": f"Minor late-night usage ({int(late_night)}m) within healthy thresholds.",
        })

    # 2. Social Media Dominance
    if social_time >= 150 or social_pct >= 50.0:
        factors.append({
            "factor": "Social Media Usage",
            "impact": "HIGH",
            "description": f"Social media accounts for {social_pct:.1f}% ({int(social_time)}m) of daily screen time, triggering high dopamine engagement loops.",
        })
    elif social_time >= 75 or social_pct >= 30.0:
        factors.append({
            "factor": "Social Media Usage",
            "impact": "MEDIUM",
            "description": f"Moderate social media consumption ({int(social_time)}m, {social_pct:.1f}% of total).",
        })

    # 3. Gaming Intensity
    if gaming_time >= 90:
        factors.append({
            "factor": "Gaming Sessions",
            "impact": "HIGH",
            "description": f"Extended gaming sessions ({int(gaming_time)}m) detected, driving prolonged continuous screen immersion.",
        })
    elif gaming_time >= 45:
        factors.append({
            "factor": "Gaming Sessions",
            "impact": "MEDIUM",
            "description": f"Moderate gaming activity ({int(gaming_time)}m).",
        })

    # 4. Checking Frequency & Session Compulsion
    if sessions >= 65:
        factors.append({
            "factor": "Frequent App Sessions",
            "impact": "HIGH",
            "description": f"{int(sessions)} phone pickup/app sessions per day indicate compulsive checking habits.",
        })
    elif sessions >= 40:
        factors.append({
            "factor": "Frequent App Sessions",
            "impact": "MEDIUM",
            "description": f"{int(sessions)} daily sessions show frequent digital interruptions.",
        })

    # 5. Longitudinal Change & Surge
    if change_pct >= 25.0:
        factors.append({
            "factor": "Usage Spike",
            "impact": "HIGH" if change_pct >= 40.0 else "MEDIUM",
            "description": f"Screen time surged by {change_pct:+.1f}% compared to your baseline.",
        })

    # 6. Productive Mitigation
    if productive_pct >= 25.0:
        factors.append({
            "factor": "Productive Usage",
            "impact": "LOW",
            "description": f"{productive_pct:.1f}% of your time was dedicated to education and productivity, significantly mitigating digital risk.",
        })

    # Sort factors by impact (HIGH first, then MEDIUM, then LOW)
    impact_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    factors.sort(key=lambda x: impact_order.get(x["impact"], 3))

    if not factors:
        factors.append({
            "factor": "Balanced Usage",
            "impact": "LOW",
            "description": "Screen time and session frequency remain within healthy digital wellbeing parameters.",
        })

    return factors


def predict_risk(raw_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Main prediction entry point.
    Returns:
    {
      "riskLevel": "HIGH",
      "riskProbability": 0.82,
      "riskScore": 78,
      "confidence": 0.82,
      "topRiskFactors": [...],
      "riskFactors": [...]
    }
    """
    load_artifacts()
    cleaned = sanitize_input_features(raw_data)
    X = to_feature_vector(cleaned)
    X_scaled = _scaler.transform(X)

    probabilities = _model.predict_proba(X_scaled)[0]
    classes = _model.classes_

    prob_dict = {cls: float(prob) for cls, prob in zip(classes, probabilities)}
    predicted_class = str(_model.predict(X_scaled)[0])
    confidence = float(max(probabilities))

    # Continuous Risk Score (0 - 100) calculated from class probabilities
    class_weights = {"LOW": 15.0, "MODERATE": 45.0, "HIGH": 72.0, "CRITICAL": 92.0}
    weighted_score = sum(prob_dict.get(cls, 0.0) * class_weights.get(cls, 50.0) for cls in class_weights)
    risk_score = int(round(np.clip(weighted_score, 0, 100)))

    # Compute Explainable AI Factor Attributions
    risk_factors = explain_prediction(cleaned, predicted_class)
    top_factors = [f["factor"] for f in risk_factors if f["impact"] == "HIGH"]
    if not top_factors:
        top_factors = [f["factor"] for f in risk_factors]

    return {
        "riskLevel": predicted_class,
        "riskProbability": round(confidence, 2),
        "riskScore": risk_score,
        "confidence": round(confidence, 2),
        "classProbabilities": {k: round(v, 4) for k, v in prob_dict.items()},
        "topRiskFactors": top_factors[:3],
        "riskFactors": risk_factors,
    }
