use serde::{Deserialize, Serialize};

/// Thresholds used for classification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Thresholds {
    /// Score below which behavior is considered suspicious
    pub suspicious_below: f64,
}

/// Server response with scoring results
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScoreResponse {
    /// Human-likeness score between 0.0 and 1.0
    pub score: f64,
    
    /// Classification label
    pub label: String,
    
    /// Additional hints about the analysis
    pub hints: Vec<String>,
    
    /// Thresholds used for classification
    pub thresholds: Thresholds,
}

impl ScoreResponse {
    /// Create a new response
    pub fn new(score: f64, suspicious_threshold: f64) -> Self {
        let label = if score >= suspicious_threshold {
            "likely_human".to_string()
        } else {
            "suspicious".to_string()
        };
        
        let hints = Self::generate_hints(score);
        
        Self {
            score,
            label,
            hints,
            thresholds: Thresholds {
                suspicious_below: suspicious_threshold,
            },
        }
    }
    
    /// Generate hints based on score
    fn generate_hints(score: f64) -> Vec<String> {
        let mut hints = Vec::new();
        
        if score >= 0.8 {
            hints.push("excellent_human_patterns".to_string());
        } else if score >= 0.6 {
            hints.push("good_human_patterns".to_string());
        } else if score >= 0.4 {
            hints.push("mixed_patterns".to_string());
        } else {
            hints.push("suspicious_patterns".to_string());
        }
        
        hints
    }
}

/// Health check response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub timestamp: i64,
    pub version: String,
}

impl HealthResponse {
    pub fn new() -> Self {
        Self {
            status: "healthy".to_string(),
            timestamp: chrono::Utc::now().timestamp_millis(),
            version: env!("CARGO_PKG_VERSION").to_string(),
        }
    }
}

/// Configuration response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigResponse {
    pub default_thresholds: Thresholds,
    pub feature_weights: crate::models::features::FeatureWeights,
    pub rate_limits: RateLimitConfig,
}

/// Rate limiting configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RateLimitConfig {
    pub requests_per_minute: u32,
    pub burst_size: u32,
}

impl Default for RateLimitConfig {
    fn default() -> Self {
        Self {
            requests_per_minute: 60,
            burst_size: 10,
        }
    }
}
