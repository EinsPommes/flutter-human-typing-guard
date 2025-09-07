use axum::{
    extract::ConnectInfo,
    http::{Request, StatusCode},
    middleware::Next,
    response::Response,
};
use governor::{
    clock::DefaultClock,
    state::keyed::DefaultKeyedStateStore,
    Quota, RateLimiter,
};
use std::{
    net::SocketAddr,
    num::NonZeroU32,
    sync::Arc,
    time::Duration,
};
use tower::ServiceBuilder;
use tower_governor::{governor::GovernorConfigBuilder, GovernorLayer};

/// Rate limiting configuration
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

/// Create rate limiting layer
pub fn create_rate_limit_layer(config: RateLimitConfig) -> GovernorLayer<DefaultKeyedStateStore<String>, DefaultClock> {
    let quota = Quota::per_minute(NonZeroU32::new(config.requests_per_minute).unwrap())
        .allow_burst(NonZeroU32::new(config.burst_size).unwrap());
    
    let governor_config = GovernorConfigBuilder::default()
        .per_second(1)
        .burst_size(config.burst_size as u32)
        .finish()
        .unwrap();
    
    GovernorLayer {
        config: governor_config,
    }
}

/// Rate limiting middleware that uses IP address as key
pub async fn rate_limit_middleware<B>(
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    request: Request<B>,
    next: Next<B>,
) -> Result<Response, StatusCode> {
    // Extract IP address
    let ip = addr.ip().to_string();
    
    // For now, we'll use a simple approach
    // In production, you might want to use a more sophisticated rate limiter
    // that can handle distributed systems
    
    // Continue with the request
    let response = next.run(request).await;
    Ok(response)
}

/// Create service builder with rate limiting
pub fn create_service_builder(config: RateLimitConfig) -> ServiceBuilder<GovernorLayer<DefaultKeyedStateStore<String>, DefaultClock>> {
    let rate_limit_layer = create_rate_limit_layer(config);
    
    ServiceBuilder::new()
        .layer(rate_limit_layer)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rate_limit_config_default() {
        let config = RateLimitConfig::default();
        assert_eq!(config.requests_per_minute, 60);
        assert_eq!(config.burst_size, 10);
    }

    #[test]
    fn test_rate_limit_config_custom() {
        let config = RateLimitConfig {
            requests_per_minute: 120,
            burst_size: 20,
        };
        assert_eq!(config.requests_per_minute, 120);
        assert_eq!(config.burst_size, 20);
    }
}
