use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use serde_json::json;
use tower::ServiceExt;

use typing_guard_svc::{
    config::AppConfig,
    models::{payload::TypingFeaturePayload, features::TypingFeatures},
};

#[tokio::test]
async fn test_score_endpoint_success() {
    let config = AppConfig::default();
    let app = typing_guard_svc::create_app(config);

    let features = TypingFeatures {
        events: 20,
        iki_mean: 150.0,
        iki_std: 50.0,
        iki_iqr: 40.0,
        burstiness: 0.2,
        entropy: 2.8,
        backspace_per_100: 5.0,
        paste_events: 0,
        jitter_mad: 25.0,
        outlier_ratio: 0.1,
    };

    let payload = TypingFeaturePayload::new(features, None);

    let request = Request::builder()
        .uri("/score")
        .method("POST")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&payload).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let response_json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    
    assert!(response_json["score"].is_number());
    assert!(response_json["label"].is_string());
    assert!(response_json["hints"].is_array());
}

#[tokio::test]
async fn test_score_endpoint_invalid_payload() {
    let config = AppConfig::default();
    let app = typing_guard_svc::create_app(config);

    let invalid_payload = json!({
        "session_id": "invalid-uuid",
        "ts": 1234567890,
        "features": {
            "events": 0,  // Invalid: no events
            "iki_mean": -1.0,  // Invalid: negative mean
            "iki_std": 50.0,
            "iki_iqr": 40.0,
            "burstiness": 0.2,
            "entropy": 2.8,
            "backspace_per_100": 5.0,
            "paste_events": 0,
            "jitter_mad": 25.0,
            "outlier_ratio": 0.1,
        }
    });

    let request = Request::builder()
        .uri("/score")
        .method("POST")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&invalid_payload).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn test_health_endpoint() {
    let config = AppConfig::default();
    let app = typing_guard_svc::create_app(config);

    let request = Request::builder()
        .uri("/healthz")
        .method("GET")
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let response_json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    
    assert_eq!(response_json["status"], "healthy");
    assert!(response_json["timestamp"].is_number());
    assert!(response_json["version"].is_string());
}

#[tokio::test]
async fn test_config_endpoint() {
    let config = AppConfig::default();
    let app = typing_guard_svc::create_app(config);

    let request = Request::builder()
        .uri("/config")
        .method("GET")
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let response_json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    
    assert!(response_json["default_thresholds"].is_object());
    assert!(response_json["feature_weights"].is_object());
    assert!(response_json["rate_limits"].is_object());
}
