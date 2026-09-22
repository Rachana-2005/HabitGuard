"""
Feature Engineering and Data Preprocessing for HabitGuard ML Risk Prediction.
Ensures consistency between client-side BehavioralFeatures and Python model inference.
"""

from typing import Dict, List, Any, Tuple
import numpy as np
import pandas as pd

FEATURE_NAMES: List[str] = [
    "totalScreenTime",
    "socialMediaTime",
    "gamingTime",
    "entertainmentTime",
    "educationTime",
    "productivityTime",
    "numberOfSessions",
    "averageSessionDuration",
    "lateNightUsage",
    "earlyMorningUsage",
    "sevenDayAverage",
    "usageChangePercentage",
    "socialMediaPercentage",
    "gamingPercentage",
    "productivePercentage",
]

CLASS_LABELS: List[str] = ["LOW", "MODERATE", "HIGH", "CRITICAL"]


def sanitize_input_features(data: Dict[str, Any]) -> Dict[str, float]:
    """
    Validates, fills missing values, and calculates derived behavioral percentages
    if not explicitly provided in the request payload.
    """
    total = float(data.get("totalScreenTime", 0.0))
    social = float(data.get("socialMediaTime", 0.0))
    gaming = float(data.get("gamingTime", 0.0))
    entertainment = float(data.get("entertainmentTime", 0.0))
    education = float(data.get("educationTime", 0.0))
    productivity = float(data.get("productivityTime", 0.0))
    sessions = float(data.get("numberOfSessions", 0.0))
    
    if sessions <= 0:
        sessions = max(1.0, total / 15.0) if total > 0 else 1.0

    avg_duration = float(data.get("averageSessionDuration", total / sessions if sessions > 0 else 0.0))
    late_night = float(data.get("lateNightUsage", 0.0))
    early_morning = float(data.get("earlyMorningUsage", 0.0))
    seven_day_avg = float(data.get("sevenDayAverage", total))
    change_pct = float(data.get("usageChangePercentage", 0.0))

    safe_total = max(1.0, total)
    social_pct = float(data.get("socialMediaPercentage", (social / safe_total) * 100.0))
    gaming_pct = float(data.get("gamingPercentage", (gaming / safe_total) * 100.0))
    productive_pct = float(data.get("productivePercentage", ((education + productivity) / safe_total) * 100.0))

    return {
        "totalScreenTime": total,
        "socialMediaTime": social,
        "gamingTime": gaming,
        "entertainmentTime": entertainment,
        "educationTime": education,
        "productivityTime": productivity,
        "numberOfSessions": sessions,
        "averageSessionDuration": avg_duration,
        "lateNightUsage": late_night,
        "earlyMorningUsage": early_morning,
        "sevenDayAverage": seven_day_avg,
        "usageChangePercentage": change_pct,
        "socialMediaPercentage": social_pct,
        "gamingPercentage": gaming_pct,
        "productivePercentage": productive_pct,
    }


def to_feature_vector(cleaned_data: Dict[str, float]) -> np.ndarray:
    """Converts cleaned dictionary to a 2D numpy array aligned with FEATURE_NAMES."""
    vector = [cleaned_data[feature] for feature in FEATURE_NAMES]
    return np.array([vector], dtype=np.float32)


def score_to_class(score: int) -> str:
    """Maps 0-100 risk score to class label."""
    if score <= 30:
        return "LOW"
    elif score <= 60:
        return "MODERATE"
    elif score <= 80:
        return "HIGH"
    return "CRITICAL"
