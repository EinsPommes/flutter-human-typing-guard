use axum::{
    extract::State,
    response::Json,
};
use tracing::info;

use crate::{
    config::AppConfig,
    models::response::{ConfigResponse, RateLimitConfig, Thresholds},
};

/// Configuration endpoint
pub async fn config_handler(
    State(config): State<AppConfig>,
) -> Json<ConfigResponse> {
    info!("Configuration requested");
    
    let response = ConfigResponse {
        default_thresholds: Thresholds {
            suspicious_below: config.scoring.suspicious_threshold,
        },
        feature_weights: config.scoring.feature_weights,
        rate_limits: RateLimitConfig {
            requests_per_minute: config.rate_limit.requests_per_minute,
            burst_size: config.rate_limit.burst_size,
        },
    };
    
    Json(response)
}
