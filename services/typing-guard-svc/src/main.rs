use axum::{
    extract::State,
    http::Method,
    response::Json,
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::{
    cors::{Any, CorsLayer},
    trace::TraceLayer,
};
use tracing::{info, Level};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod handlers;
mod middleware;
mod models;

/// Set up our API routes and middleware
pub fn create_app(config: AppConfig) -> Router {
    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST])
        .allow_headers(Any)
        .allow_origin(Any);

    let rate_limit_layer = middleware::rate_limit::create_service_builder(config.rate_limit.clone());

    Router::new()
        .route("/healthz", get(health_handler))
        .route("/config", get(config_handler))
        .route("/score", post(score_handler))
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(cors)
                .layer(rate_limit_layer)
        )
        .with_state(config)
}

use config::AppConfig;
use handlers::{config_handler, health_handler, score_handler};
use middleware::rate_limit::create_service_builder;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Set up logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "typing_guard_svc=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load and validate config
    let config = AppConfig::load()?;
    config.validate()?;

    info!("Starting Typing Guard Service v{}", env!("CARGO_PKG_VERSION"));
    info!("Configuration: {:?}", config);

    // Build the app
    let app = create_app(config);

    // Start the server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    info!("Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::Body,
        http::{Request, StatusCode},
    };
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_health_endpoint() {
        let config = AppConfig::default();
        let app = Router::new()
            .route("/healthz", get(health_handler))
            .with_state(config);

        let request = Request::builder()
            .uri("/healthz")
            .method("GET")
            .body(Body::empty())
            .unwrap();

        let response = app.oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn test_config_endpoint() {
        let config = AppConfig::default();
        let app = Router::new()
            .route("/config", get(config_handler))
            .with_state(config);

        let request = Request::builder()
            .uri("/config")
            .method("GET")
            .body(Body::empty())
            .unwrap();

        let response = app.oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }
}
