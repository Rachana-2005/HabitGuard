"""
Model Training Pipeline for HabitGuard.
Trains a scikit-learn RandomForestClassifier on behavioral smartphone usage features,
computes feature importances for Explainable AI (XAI), and serializes the production model artifacts.
"""

import os
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score

from feature_engineering import FEATURE_NAMES, CLASS_LABELS
from dataset.generate_dataset import generate_dataset

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, "dataset")
MODEL_DIR = os.path.join(BASE_DIR, "model")
CSV_PATH = os.path.join(DATASET_DIR, "smartphone_addiction_dataset.csv")


def load_or_create_dataset() -> pd.DataFrame:
    if not os.path.exists(CSV_PATH):
        print("Dataset not found locally, generating from research distributions...")
        os.makedirs(DATASET_DIR, exist_ok=True)
        df = generate_dataset(n_samples=3000, seed=42)
        df.to_csv(CSV_PATH, index=False)
    else:
        df = pd.read_csv(CSV_PATH)
    return df


def train():
    os.makedirs(MODEL_DIR, exist_ok=True)
    df = load_or_create_dataset()
    print(f"Loaded dataset: {len(df)} samples, {len(FEATURE_NAMES)} features.")

    X = df[FEATURE_NAMES].values
    y = df["riskLevel"].values
    scores = df["riskScore"].values

    # Train-test split (80% train, 20% test)
    X_train, X_test, y_train, y_test, s_train, s_test = train_test_split(
        X, y, scores, test_size=0.20, random_state=42, stratify=y
    )

    # Feature Scaling
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    # Initialize Random Forest Classifier
    rf_model = RandomForestClassifier(
        n_estimators=120,
        max_depth=12,
        min_samples_split=4,
        min_samples_leaf=2,
        random_state=42,
        class_weight="balanced",
        n_jobs=-1,
    )

    print("Training Random Forest Classifier...")
    rf_model.fit(X_train_scaled, y_train)

    # Cross-validation
    cv_scores = cross_val_score(rf_model, X_train_scaled, y_train, cv=5, scoring="f1_macro")
    print(f"5-Fold CV F1-Macro Score: {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")

    # Evaluation on Test set
    y_pred = rf_model.predict(X_test_scaled)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average="macro")
    print(f"Test Set Accuracy: {acc * 100:.2f}%")
    print(f"Test Set Macro F1: {f1:.4f}")
    print("\nClassification Report:\n", classification_report(y_test, y_pred))

    # Calculate Feature Importances for Explainable AI
    importances = rf_model.feature_importances_
    feat_importance_dict = {
        name: float(round(imp, 4))
        for name, imp in sorted(zip(FEATURE_NAMES, importances), key=lambda x: x[1], reverse=True)
    }
    print("\nFeature Importances for Explainable AI:")
    for feat, imp in feat_importance_dict.items():
        print(f"  - {feat:25s}: {imp:.4f}")

    # Compute baseline feature statistics for Healthy (LOW risk) archetype to ground XAI deviations
    low_mask = df["riskLevel"] == "LOW"
    baselines = {}
    for feat in FEATURE_NAMES:
        baselines[feat] = {
            "mean": float(round(df[feat].mean(), 2)),
            "std": float(round(df[feat].std(), 2)),
            "healthy_mean": float(round(df.loc[low_mask, feat].mean(), 2)),
            "healthy_std": float(round(df.loc[low_mask, feat].std(), 2)),
        }

    # Model Artifacts Persistence
    model_path = os.path.join(MODEL_DIR, "random_forest_model.pkl")
    scaler_path = os.path.join(MODEL_DIR, "scaler.pkl")
    features_path = os.path.join(MODEL_DIR, "feature_names.json")
    baselines_path = os.path.join(MODEL_DIR, "feature_baselines.json")
    metrics_path = os.path.join(MODEL_DIR, "training_metrics.json")

    joblib.dump(rf_model, model_path)
    joblib.dump(scaler, scaler_path)

    with open(features_path, "w") as f:
        json.dump(FEATURE_NAMES, f, indent=2)

    with open(baselines_path, "w") as f:
        json.dump({
            "baselines": baselines,
            "feature_importances": feat_importance_dict,
        }, f, indent=2)

    with open(metrics_path, "w") as f:
        json.dump({
            "accuracy": float(round(acc, 4)),
            "macro_f1": float(round(f1, 4)),
            "cv_f1_mean": float(round(cv_scores.mean(), 4)),
            "cv_f1_std": float(round(cv_scores.std(), 4)),
            "n_samples": len(df),
            "feature_names": FEATURE_NAMES,
            "classes": CLASS_LABELS,
        }, f, indent=2)

    print(f"\nModel artifacts successfully saved to {MODEL_DIR}")
    print(f"  -> {model_path}")
    print(f"  -> {scaler_path}")
    print(f"  -> {baselines_path}")


if __name__ == "__main__":
    train()
