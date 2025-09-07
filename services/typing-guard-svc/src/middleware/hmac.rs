use axum::http::HeaderMap;
use hmac::{Hmac, Mac};
use serde::Serialize;
use sha2::Sha256;
use thiserror::Error;

type HmacSha256 = Hmac<Sha256>;

#[derive(Error, Debug)]
pub enum HmacError {
    #[error("Missing signature header")]
    MissingSignature,
    
    #[error("Invalid signature format")]
    InvalidFormat,
    
    #[error("Signature verification failed")]
    VerificationFailed,
    
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

/// Verify HMAC signature in request headers
pub fn verify_hmac_signature<T: Serialize>(
    headers: &HeaderMap,
    payload: &T,
    secret: &str,
) -> Result<(), HmacError> {
    // Get signature from header
    let signature_header = headers
        .get("X-Signature")
        .ok_or(HmacError::MissingSignature)?
        .to_str()
        .map_err(|_| HmacError::InvalidFormat)?;

    // Parse signature format: "sha256=<hash>"
    let signature = signature_header
        .strip_prefix("sha256=")
        .ok_or(HmacError::InvalidFormat)?;

    // Serialize payload
    let body = serde_json::to_string(payload)?;

    // Calculate expected signature
    let expected_signature = calculate_hmac(&body, secret);

    // Compare signatures
    if signature == expected_signature {
        Ok(())
    } else {
        Err(HmacError::VerificationFailed)
    }
}

/// Calculate HMAC-SHA256 signature
pub fn calculate_hmac(body: &str, secret: &str) -> String {
    let mut mac = HmacSha256::new_from_slice(secret.as_bytes())
        .expect("HMAC can take key of any size");
    
    mac.update(body.as_bytes());
    let result = mac.finalize();
    hex::encode(result.into_bytes())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde::{Deserialize, Serialize};

    #[derive(Serialize, Deserialize)]
    struct TestPayload {
        message: String,
        timestamp: i64,
    }

    #[test]
    fn test_hmac_calculation() {
        let body = r#"{"message":"hello","timestamp":1234567890}"#;
        let secret = "test-secret";
        let signature = calculate_hmac(body, secret);
        
        // Verify signature is not empty and has correct length (64 hex chars)
        assert_eq!(signature.len(), 64);
        assert!(!signature.is_empty());
    }

    #[test]
    fn test_hmac_verification_success() {
        let payload = TestPayload {
            message: "hello".to_string(),
            timestamp: 1234567890,
        };
        let secret = "test-secret";
        let body = serde_json::to_string(&payload).unwrap();
        let signature = calculate_hmac(&body, secret);
        
        let mut headers = HeaderMap::new();
        headers.insert("X-Signature", format!("sha256={}", signature).parse().unwrap());
        
        let result = verify_hmac_signature(&headers, &payload, secret);
        assert!(result.is_ok());
    }

    #[test]
    fn test_hmac_verification_failure() {
        let payload = TestPayload {
            message: "hello".to_string(),
            timestamp: 1234567890,
        };
        let secret = "test-secret";
        let wrong_secret = "wrong-secret";
        
        let mut headers = HeaderMap::new();
        headers.insert("X-Signature", "sha256=invalid".parse().unwrap());
        
        let result = verify_hmac_signature(&headers, &payload, secret);
        assert!(result.is_err());
    }

    #[test]
    fn test_missing_signature_header() {
        let payload = TestPayload {
            message: "hello".to_string(),
            timestamp: 1234567890,
        };
        let secret = "test-secret";
        
        let headers = HeaderMap::new();
        
        let result = verify_hmac_signature(&headers, &payload, secret);
        assert!(matches!(result, Err(HmacError::MissingSignature)));
    }
}
