# HabitGuard Machine Learning & Explainable AI Service

HabitGuard's Machine Learning service predicts smartphone addiction and digital wellbeing risk using multi-dimensional behavioral features.

## Architecture

1. **Behavioral Feature Input:** Accepts raw and derived usage metrics (`totalScreenTime`, `socialMediaTime`, `lateNightUsage`, `numberOfSessions`, `productivePercentage`, etc.).
2. **Model:** `RandomForestClassifier` (120 estimators, balanced class weights) trained on behavioral distributions grounded in digital wellbeing literature (Kwon et al. SAS-SV & Rozgonjuk et al.).
3. **Target Classes:**
   - `LOW` (0–30)
   - `MODERATE` (31–60)
   - `HIGH` (61–80)
   - `CRITICAL` (81–100)
4. **Explainable AI (XAI):** Calculates feature attributions (HIGH / MEDIUM / LOW impact) explaining why the model assigned a risk classification.

## Directory Structure

```text
ml/
├── dataset/
│   ├── generate_dataset.py
│   └── smartphone_addiction_dataset.csv
├── notebooks/
│   └── model_development.ipynb
├── model/
│   ├── random_forest_model.pkl
│   ├── scaler.pkl
│   ├── feature_baselines.json
│   ├── feature_names.json
│   └── training_metrics.json
├── api/
│   └── main.py
├── feature_engineering.py
├── train.py
├── predict.py
├── requirements.txt
└── tests/
    └── test_ml.py
```

## Quickstart

### 1. Install Dependencies
Using `uv`:
```bash
uv venv ml/.venv --python 3.12
uv pip install -r ml/requirements.txt --python ml/.venv/Scripts/python.exe
```

### 2. Train Model
```bash
ml\.venv\Scripts\python.exe ml/train.py
```

### 3. Run Unit Tests
```bash
ml\.venv\Scripts\python.exe -m pytest ml/tests -v
```

### 4. Start FastAPI Server
```bash
ml\.venv\Scripts\python.exe -m uvicorn api.main:app --app-dir ml --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

### `GET /health`
Returns service status and whether the ML model is loaded.

### `POST /predict-risk`
Payload:
```json
{
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
  "usageChangePercentage": 29
}
```

Response:
```json
{
  "riskLevel": "HIGH",
  "riskProbability": 0.82,
  "riskScore": 78,
  "confidence": 0.82,
  "topRiskFactors": ["Late Night Usage", "Social Media Usage", "Frequent App Sessions"],
  "riskFactors": [
    {
      "factor": "Late Night Usage",
      "impact": "HIGH",
      "description": "84 minutes of smartphone activity detected past 11 PM."
    },
    {
      "factor": "Social Media Usage",
      "impact": "HIGH",
      "description": "Social media accounts for 45.2% (168m) of daily screen time."
    },
    {
      "factor": "Frequent App Sessions",
      "impact": "MEDIUM",
      "description": "47 phone pickup sessions per day indicate frequent digital interruptions."
    }
  ]
}
```
