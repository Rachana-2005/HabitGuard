"""
HabitGuard Machine Learning Risk Prediction REST API.
Built with FastAPI to serve real-time predictions and Explainable AI factors to the Flutter client.
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import os
import sys

# Ensure ml directory is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from predict import predict_risk, load_artifacts

app = FastAPI(
    title="HabitGuard ML Service",
    description="Machine Learning Risk Prediction & Explainable AI API for Smartphone Addiction Prevention",
    version="1.0.0",
)

# Enable CORS for Flutter mobile emulator (10.0.2.2), local web, and physical devices
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class BehavioralFeaturesRequest(BaseModel):
    totalScreenTime: float = Field(..., description="Total screen time in minutes")
    socialMediaTime: Optional[float] = Field(0.0, description="Social media time in minutes")
    gamingTime: Optional[float] = Field(0.0, description="Gaming time in minutes")
    entertainmentTime: Optional[float] = Field(0.0, description="Entertainment/streaming minutes")
    educationTime: Optional[float] = Field(0.0, description="Educational minutes")
    productivityTime: Optional[float] = Field(0.0, description="Productivity minutes")
    communicationTime: Optional[float] = Field(0.0, description="Communication minutes")
    otherTime: Optional[float] = Field(0.0, description="Other minutes")
    numberOfSessions: Optional[float] = Field(None, description="App launch / pickup count")
    averageSessionDuration: Optional[float] = Field(None, description="Minutes per session")
    lateNightUsage: Optional[float] = Field(0.0, description="Usage past 11 PM in minutes")
    earlyMorningUsage: Optional[float] = Field(0.0, description="Usage before 7 AM in minutes")
    sevenDayAverage: Optional[float] = Field(None, description="Rolling 7-day average minutes")
    usageChangePercentage: Optional[float] = Field(0.0, description="Change vs baseline percentage")
    socialMediaPercentage: Optional[float] = Field(None, description="Social media percentage")
    gamingPercentage: Optional[float] = Field(None, description="Gaming percentage")
    productivePercentage: Optional[float] = Field(None, description="Productive percentage")
    isWeekend: Optional[int] = Field(0, description="1 if weekend, 0 otherwise")


class RiskFactorResponse(BaseModel):
    factor: str
    impact: str
    description: str


class PredictionResponse(BaseModel):
    riskLevel: str
    riskProbability: float
    riskScore: int
    confidence: float
    topRiskFactors: List[str]
    riskFactors: List[RiskFactorResponse]
    classProbabilities: Optional[Dict[str, float]] = None


@app.on_event("startup")
def startup_event():
    try:
        load_artifacts()
        print("HabitGuard ML model artifacts loaded successfully.")
    except Exception as e:
        print(f"Notice: Model artifacts could not be loaded on startup: {e}")


@app.get("/")
def read_root():
    return {
        "service": "HabitGuard ML Prediction Service",
        "model": "Random Forest Classifier",
        "status": "ready",
        "version": "1.0.0",
        "docs": "/docs",
    }


@app.get("/health")
def health_check():
    try:
        load_artifacts()
        return {
            "status": "healthy",
            "model_loaded": True,
            "model_type": "RandomForestClassifier",
        }
    except Exception as e:
        return {
            "status": "degraded",
            "model_loaded": False,
            "error": str(e),
        }


@app.post("/predict-risk", response_model=PredictionResponse)
def api_predict_risk(payload: BehavioralFeaturesRequest):
    try:
        data = payload.dict()
        result = predict_risk(data)
        return result
    except FileNotFoundError as e:
        raise HTTPException(
            status_code=503,
            detail="ML Model not yet trained or artifacts missing. Run train.py to initialize.",
        )
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Prediction error: {str(e)}",
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
