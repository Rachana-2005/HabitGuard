"""
Unit Tests for HabitGuard Python Machine Learning Pipeline.
Tests feature engineering, artifact loading, prediction schema, and edge cases.
"""

import pytest
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from feature_engineering import sanitize_input_features, to_feature_vector, FEATURE_NAMES
from predict import predict_risk, explain_prediction


def test_sanitize_input_features():
    raw = {
        "totalScreenTime": 300,
        "socialMediaTime": 150,
        "gamingTime": 60,
    }
    cleaned = sanitize_input_features(raw)
    assert cleaned["totalScreenTime"] == 300.0
    assert cleaned["socialMediaTime"] == 150.0
    assert cleaned["socialMediaPercentage"] == 50.0
    assert cleaned["gamingPercentage"] == 20.0
    assert cleaned["numberOfSessions"] > 0
    assert "lateNightUsage" in cleaned


def test_to_feature_vector_shape():
    raw = {k: 10.0 for k in FEATURE_NAMES}
    cleaned = sanitize_input_features(raw)
    vector = to_feature_vector(cleaned)
    assert vector.shape == (1, len(FEATURE_NAMES))


def test_explain_prediction_factors():
    # Simulated high late night + heavy social
    cleaned = {
        "totalScreenTime": 360.0,
        "socialMediaTime": 180.0,
        "gamingTime": 30.0,
        "entertainmentTime": 40.0,
        "educationTime": 10.0,
        "productivityTime": 10.0,
        "numberOfSessions": 70.0,
        "averageSessionDuration": 5.1,
        "lateNightUsage": 90.0,
        "earlyMorningUsage": 15.0,
        "sevenDayAverage": 280.0,
        "usageChangePercentage": 28.0,
        "socialMediaPercentage": 50.0,
        "gamingPercentage": 8.3,
        "productivePercentage": 5.5,
    }
    factors = explain_prediction(cleaned, "HIGH")
    assert len(factors) >= 2
    factor_names = [f["factor"] for f in factors]
    assert "Late Night Usage" in factor_names
    assert "Social Media Usage" in factor_names
    
    # Check impact rating
    late_factor = next(f for f in factors if f["factor"] == "Late Night Usage")
    assert late_factor["impact"] == "HIGH"


def test_predict_risk_runs():
    payload = {
        "totalScreenTime": 372,
        "socialMediaTime": 168,
        "gamingTime": 66,
        "entertainmentTime": 52,
        "educationTime": 35,
        "productivityTime": 25,
        "numberOfSessions": 47,
        "averageSessionDuration": 7.9,
        "lateNightUsage": 84,
        "earlyMorningUsage": 15,
        "sevenDayAverage": 288,
        "usageChangePercentage": 29,
    }
    res = predict_risk(payload)
    assert "riskLevel" in res
    assert "riskScore" in res
    assert 0 <= res["riskScore"] <= 100
    assert res["riskLevel"] in ["LOW", "MODERATE", "HIGH", "CRITICAL"]
    assert len(res["riskFactors"]) > 0
