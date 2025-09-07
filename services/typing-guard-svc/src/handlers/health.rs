use axum::{
    extract::State,
    response::Json,
};
use tracing::info;

use crate::{
    config::AppConfig,
    models::response::HealthResponse,
};

/// Health check endpoint
pub async fn health_handler(
    State(_config): State<AppConfig>,
) -> Json<HealthResponse> {
    info!("Health check requested");
    Json(HealthResponse::new())
}
