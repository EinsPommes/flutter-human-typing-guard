use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::Json,
    Json as AxumJson,
};
use tracing::{info, warn};

use crate::{
    config::AppConfig,
    models::{payload::TypingFeaturePayload, response::ScoreResponse},
    middleware::hmac::verify_hmac_signature,
};

/// The main endpoint - analyze typing features and give a score
pub async fn score_handler(
    State(config): State<AppConfig>,
    headers: HeaderMap,
    AxumJson(payload): AxumJson<TypingFeaturePayload>,
) -> Result<Json<ScoreResponse>, StatusCode> {
    // Check if the data looks valid
    if let Err(e) = payload.validate() {
        warn!("Invalid payload: {}", e);
        return Err(StatusCode::BAD_REQUEST);
    }

    // Verify request signature if HMAC is enabled
    if config.security.require_hmac {
        if let Err(e) = verify_hmac_signature(&headers, &payload, &config.security.hmac_key) {
            warn!("HMAC verification failed: {}", e);
            return Err(StatusCode::UNAUTHORIZED);
        }
    }

    // Do the actual scoring
    let score = payload.features.calculate_score(&config.scoring.feature_weights);
    
    // Package up the response
    let response = ScoreResponse::new(score, config.scoring.suspicious_threshold);
    
    info!(
        "Scored session {}: score={:.3}, label={}",
        payload.session_id, score, response.label
    );

    Ok(Json(response))
}
