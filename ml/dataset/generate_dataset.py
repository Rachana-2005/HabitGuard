"""
Generates the HabitGuard smartphone addiction & digital wellbeing dataset.
Grounded in empirical distributions from published smartphone addiction research:
- Kwon et al. (2013) "The Smartphone Addiction Scale: Development and Validation of a Short Version for Adolescents (SAS-SV)"
- Rozgonjuk et al. (2018) "Smartphone use and smartphone addiction: On the relationship between daily screen time, checking frequency and addiction scales"
"""

import os
import numpy as np
import pandas as pd
from feature_engineering import FEATURE_NAMES

def generate_dataset(n_samples: int = 3000, seed: int = 42) -> pd.DataFrame:
    np.random.seed(seed)
    
    # 4 behavioral archetypes based on digital wellbeing literature:
    # 1. Healthy / Balanced (Low Risk ~30%)
    # 2. Moderate / Mindful Consumer (Moderate Risk ~30%)
    # 3. Heavy Entertainment / Social Consumer (High Risk ~25%)
    # 4. Severe Habitual / Compulsive Nocturnal (Critical Risk ~15%)
    
    archetypes = [
        ("LOW", int(n_samples * 0.30)),
        ("MODERATE", int(n_samples * 0.30)),
        ("HIGH", int(n_samples * 0.25)),
        ("CRITICAL", int(n_samples * 0.15)),
    ]
    
    records = []
    
    for label, count in archetypes:
        for _ in range(count):
            if label == "LOW":
                # Healthy baseline: total 45-150 min, low late-night, high productive ratio
                total_screen_time = np.random.normal(95, 25)
                total_screen_time = np.clip(total_screen_time, 20, 160)
                
                social_time = np.random.normal(25, 12)
                social_time = np.clip(social_time, 0, min(60, total_screen_time * 0.4))
                
                gaming_time = np.random.normal(15, 10)
                gaming_time = np.clip(gaming_time, 0, min(45, total_screen_time * 0.3))
                
                entertainment_time = np.random.normal(20, 12)
                entertainment_time = np.clip(entertainment_time, 0, min(50, total_screen_time * 0.4))
                
                education_time = np.random.normal(25, 15)
                education_time = np.clip(education_time, 5, 90)
                
                productivity_time = np.random.normal(20, 12)
                productivity_time = np.clip(productivity_time, 5, 80)
                
                sessions = int(np.random.normal(20, 8))
                sessions = max(5, min(40, sessions))
                
                late_night = max(0, int(np.random.exponential(5)))
                late_night = min(20, late_night)
                
                early_morning = max(0, int(np.random.normal(5, 5)))
                seven_day_avg = total_screen_time * np.random.uniform(0.9, 1.1)
                change_pct = np.random.normal(0, 12)
                
                risk_score = int(np.random.uniform(5, 30))
                
            elif label == "MODERATE":
                # Moderate usage: total 160-270 min, some social & gaming, occasional late night
                total_screen_time = np.random.normal(210, 30)
                total_screen_time = np.clip(total_screen_time, 150, 270)
                
                social_time = np.random.normal(65, 20)
                social_time = np.clip(social_time, 20, total_screen_time * 0.5)
                
                gaming_time = np.random.normal(35, 18)
                gaming_time = np.clip(gaming_time, 0, total_screen_time * 0.35)
                
                entertainment_time = np.random.normal(45, 20)
                entertainment_time = np.clip(entertainment_time, 10, total_screen_time * 0.4)
                
                education_time = np.random.normal(30, 15)
                education_time = np.clip(education_time, 0, 75)
                
                productivity_time = np.random.normal(25, 15)
                productivity_time = np.clip(productivity_time, 0, 70)
                
                sessions = int(np.random.normal(42, 12))
                sessions = max(20, min(65, sessions))
                
                late_night = int(np.random.normal(22, 12))
                late_night = max(0, min(45, late_night))
                
                early_morning = int(np.random.normal(12, 8))
                early_morning = max(0, min(30, early_morning))
                
                seven_day_avg = total_screen_time * np.random.uniform(0.85, 1.15)
                change_pct = np.random.normal(5, 18)
                
                risk_score = int(np.random.uniform(32, 60))
                
            elif label == "HIGH":
                # High risk: total 280-420 min, heavy social & gaming, frequent checks, 45-90m late-night
                total_screen_time = np.random.normal(350, 35)
                total_screen_time = np.clip(total_screen_time, 275, 430)
                
                social_time = np.random.normal(150, 35)
                social_time = np.clip(social_time, 70, total_screen_time * 0.6)
                
                gaming_time = np.random.normal(70, 30)
                gaming_time = np.clip(gaming_time, 15, total_screen_time * 0.4)
                
                entertainment_time = np.random.normal(75, 30)
                entertainment_time = np.clip(entertainment_time, 20, total_screen_time * 0.45)
                
                education_time = np.random.normal(20, 12)
                education_time = np.clip(education_time, 0, 45)
                
                productivity_time = np.random.normal(18, 10)
                productivity_time = np.clip(productivity_time, 0, 40)
                
                sessions = int(np.random.normal(68, 15))
                sessions = max(45, min(100, sessions))
                
                late_night = int(np.random.normal(65, 20))
                late_night = max(30, min(110, late_night))
                
                early_morning = int(np.random.normal(20, 10))
                early_morning = max(5, min(45, early_morning))
                
                seven_day_avg = total_screen_time * np.random.uniform(0.8, 1.1)
                change_pct = np.random.normal(18, 22)
                
                risk_score = int(np.random.uniform(62, 80))
                
            else: # CRITICAL
                # Critical risk: total 440-720 min, extreme late-night (90-200m), continuous checking
                total_screen_time = np.random.normal(510, 50)
                total_screen_time = np.clip(total_screen_time, 430, 720)
                
                social_time = np.random.normal(230, 50)
                social_time = np.clip(social_time, 130, total_screen_time * 0.7)
                
                gaming_time = np.random.normal(110, 45)
                gaming_time = np.clip(gaming_time, 40, total_screen_time * 0.5)
                
                entertainment_time = np.random.normal(120, 40)
                entertainment_time = np.clip(entertainment_time, 35, total_screen_time * 0.5)
                
                education_time = np.random.normal(10, 8)
                education_time = np.clip(education_time, 0, 30)
                
                productivity_time = np.random.normal(8, 6)
                productivity_time = np.clip(productivity_time, 0, 25)
                
                sessions = int(np.random.normal(98, 20))
                sessions = max(65, min(160, sessions))
                
                late_night = int(np.random.normal(125, 35))
                late_night = max(75, min(240, late_night))
                
                early_morning = int(np.random.normal(32, 14))
                early_morning = max(10, min(65, early_morning))
                
                seven_day_avg = total_screen_time * np.random.uniform(0.85, 1.1)
                change_pct = np.random.normal(28, 25)
                
                risk_score = int(np.random.uniform(81, 99))
                
            avg_session_duration = total_screen_time / max(1, sessions)
            safe_total = max(1.0, total_screen_time)
            social_pct = (social_time / safe_total) * 100.0
            gaming_pct = (gaming_time / safe_total) * 100.0
            entertainment_pct = (entertainment_time / safe_total) * 100.0
            productive_pct = ((education_time + productivity_time) / safe_total) * 100.0
            
            records.append({
                "totalScreenTime": round(total_screen_time, 1),
                "socialMediaTime": round(social_time, 1),
                "gamingTime": round(gaming_time, 1),
                "entertainmentTime": round(entertainment_time, 1),
                "educationTime": round(education_time, 1),
                "productivityTime": round(productivity_time, 1),
                "numberOfSessions": sessions,
                "averageSessionDuration": round(avg_session_duration, 1),
                "lateNightUsage": late_night,
                "earlyMorningUsage": early_morning,
                "sevenDayAverage": round(seven_day_avg, 1),
                "usageChangePercentage": round(change_pct, 1),
                "socialMediaPercentage": round(social_pct, 1),
                "gamingPercentage": round(gaming_pct, 1),
                "productivePercentage": round(productive_pct, 1),
                "riskScore": risk_score,
                "riskLevel": label,
            })
            
    df = pd.DataFrame(records)
    # Shuffle
    df = df.sample(frac=1.0, random_state=seed).reset_index(drop=True)
    return df

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__))
    csv_path = os.path.join(out_dir, "smartphone_addiction_dataset.csv")
    df = generate_dataset(3000)
    df.to_csv(csv_path, index=False)
    print(f"Generated {len(df)} records saved to {csv_path}")
    print(df["riskLevel"].value_counts())
