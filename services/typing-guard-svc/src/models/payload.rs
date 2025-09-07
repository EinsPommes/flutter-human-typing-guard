use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::features::TypingFeatures;

/// Metadata about the typing session
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypingMeta {
    /// Analysis window size in milliseconds
    pub window_ms: u32,
    
    /// Locale of the user
    pub locale: String,
    
    /// Platform (android, ios, web, etc.)
    pub platform: String,
    
    /// Application version
    pub app_ver: String,
}

/// Payload sent from client to server for scoring
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypingFeaturePayload {
    /// Session identifier (UUID4)
    pub session_id: Uuid,
    
    /// Timestamp when payload was created
    pub ts: i64,
    
    /// Extracted typing features
    pub features: TypingFeatures,
    
    /// Optional metadata
    pub meta: Option<TypingMeta>,
}

impl TypingFeaturePayload {
    /// Create a new payload with current timestamp
    pub fn new(features: TypingFeatures, meta: Option<TypingMeta>) -> Self {
        Self {
            session_id: Uuid::new_v4(),
            ts: chrono::Utc::now().timestamp_millis(),
            features,
            meta,
        }
    }

    /// Validate the payload
    pub fn validate(&self) -> Result<(), String> {
        if self.features.events == 0 {
            return Err("No events in features".to_string());
        }
        
        if self.features.iki_mean <= 0.0 {
            return Err("Invalid IKI mean".to_string());
        }
        
        if self.features.iki_std < 0.0 {
            return Err("Invalid IKI standard deviation".to_string());
        }
        
        if self.features.burstiness < -1.0 || self.features.burstiness > 1.0 {
            return Err("Invalid burstiness value".to_string());
        }
        
        if self.features.entropy < 0.0 {
            return Err("Invalid entropy value".to_string());
        }
        
        if self.features.backspace_per_100 < 0.0 {
            return Err("Invalid backspace rate".to_string());
        }
        
        if self.features.jitter_mad < 0.0 {
            return Err("Invalid jitter MAD".to_string());
        }
        
        if self.features.outlier_ratio < 0.0 || self.features.outlier_ratio > 1.0 {
            return Err("Invalid outlier ratio".to_string());
        }
        
        Ok(())
    }
}
