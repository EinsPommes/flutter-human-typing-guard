use serde::{Deserialize, Serialize};
use std::env;

use crate::models::features::FeatureWeights;

/// Application configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    /// Server configuration
    pub server: ServerConfig,
    
    /// Security configuration
    pub security: SecurityConfig,
    
    /// Scoring configuration
    pub scoring: ScoringConfig,
    
    /// Rate limiting configuration
    pub rate_limit: RateLimitConfig,
}

/// Server configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    /// Host to bind to
    pub host: String,
    
    /// Port to bind to
    pub port: u16,
    
    /// CORS allowed origins
    pub cors_origins: Vec<String>,
}

/// Security configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    /// HMAC key for request signing
    pub hmac_key: String,
    
    /// Whether to require HMAC signatures
    pub require_hmac: bool,
}

/// Scoring configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScoringConfig {
    /// Default threshold for suspicious behavior
    pub suspicious_threshold: f64,
    
    /// Feature weights for scoring
    pub feature_weights: FeatureWeights,
}

/// Rate limiting configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RateLimitConfig {
    /// Requests per minute per IP
    pub requests_per_minute: u32,
    
    /// Burst size for rate limiting
    pub burst_size: u32,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            server: ServerConfig::default(),
            security: SecurityConfig::default(),
            scoring: ScoringConfig::default(),
            rate_limit: RateLimitConfig::default(),
        }
    }
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: "0.0.0.0".to_string(),
            port: 8080,
            cors_origins: vec!["*".to_string()],
        }
    }
}

impl Default for SecurityConfig {
    fn default() -> Self {
        Self {
            hmac_key: "default-key-change-in-production".to_string(),
            require_hmac: false,
        }
    }
}

impl Default for ScoringConfig {
    fn default() -> Self {
        Self {
            suspicious_threshold: 0.4,
            feature_weights: FeatureWeights::default(),
        }
    }
}

impl Default for RateLimitConfig {
    fn default() -> Self {
        Self {
            requests_per_minute: 60,
            burst_size: 10,
        }
    }
}

impl AppConfig {
    /// Load configuration from environment variables and config file
    pub fn load() -> Result<Self, config::ConfigError> {
        let mut settings = config::Config::builder()
            .add_source(config::File::with_name("config/default").required(false))
            .add_source(config::File::with_name("config/local").required(false))
            .add_source(config::Environment::with_prefix("TYPING_GUARD"));

        // Override with environment variables
        if let Ok(host) = env::var("HOST") {
            settings = settings.set_override("server.host", host)?;
        }
        if let Ok(port) = env::var("PORT") {
            settings = settings.set_override("server.port", port.parse::<u16>().unwrap_or(8080))?;
        }
        if let Ok(hmac_key) = env::var("HMAC_KEY") {
            settings = settings.set_override("security.hmac_key", hmac_key)?;
        }
        if let Ok(require_hmac) = env::var("REQUIRE_HMAC") {
            settings = settings.set_override("security.require_hmac", require_hmac.parse::<bool>().unwrap_or(false))?;
        }
        if let Ok(threshold) = env::var("SUSPICIOUS_THRESHOLD") {
            settings = settings.set_override("scoring.suspicious_threshold", threshold.parse::<f64>().unwrap_or(0.4))?;
        }

        let config = settings.build()?;
        config.try_deserialize()
    }

    /// Validate configuration
    pub fn validate(&self) -> Result<(), String> {
        if self.server.port == 0 {
            return Err("Port must be greater than 0".to_string());
        }
        
        if self.security.hmac_key.is_empty() {
            return Err("HMAC key cannot be empty".to_string());
        }
        
        if self.scoring.suspicious_threshold < 0.0 || self.scoring.suspicious_threshold > 1.0 {
            return Err("Suspicious threshold must be between 0.0 and 1.0".to_string());
        }
        
        self.scoring.feature_weights.validate()?;
        
        if self.rate_limit.requests_per_minute == 0 {
            return Err("Rate limit requests per minute must be greater than 0".to_string());
        }
        
        Ok(())
    }
}
