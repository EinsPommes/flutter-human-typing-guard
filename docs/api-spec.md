# API Reference

REST API for our typing guard service. Send typing data, get human-likeness score.

## Base URL

```
https://your-typing-guard-service.com
```

## Authentication

We use HMAC-SHA256 signatures for request verification.

### Headers

```
X-Signature: sha256=<hmac_signature>
Content-Type: application/json
```

### How to Sign Requests

1. Create your JSON payload
2. Calculate HMAC-SHA256 of the payload using your secret key
3. Add signature to `X-Signature` header as `sha256=<signature>`

## Endpoints

### Health Check

```http
GET /healthz
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": 1736345678123,
  "version": "1.0.0"
}
```

### Get Configuration

```http
GET /config
```

**Response:**
```json
{
  "default_thresholds": {
    "suspicious_below": 0.4
  },
  "feature_weights": {
    "speed": 0.3,
    "variability": 0.25,
    "entropy": 0.2,
    "backspace": 0.15,
    "jitter": 0.1
  },
  "rate_limits": {
    "requests_per_minute": 60,
    "burst_size": 10
  }
}
```

### Score Typing Features

```http
POST /score
```

**Request:**
```json
{
  "session_id": "3b0a0c8f-1234-5678-9abc-def012345678",
  "ts": 1736345678123,
  "features": {
    "events": 72,
    "iki_mean": 145.3,
    "iki_std": 58.1,
    "iki_iqr": 41.7,
    "burstiness": 0.22,
    "entropy": 2.91,
    "backspace_per_100": 4.8,
    "paste_events": 0,
    "jitter_mad": 27.5,
    "outlier_ratio": 0.08
  },
  "meta": {
    "window_ms": 5000,
    "locale": "en_US",
    "platform": "flutter",
    "app_ver": "1.0.0"
  }
}
```

**Response:**
```json
{
  "score": 0.78,
  "label": "likely_human",
  "hints": ["healthy_variability", "some_backspaces"],
  "thresholds": {
    "suspicious_below": 0.4
  }
}
```

**Status Codes:**
- `200 OK`: Analysis completed successfully
- `400 Bad Request`: Invalid request payload
- `401 Unauthorized`: Invalid or missing HMAC signature
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

## Rate Limiting

- **Default**: 60 requests per minute per IP
- **Burst**: 10 requests in a short time window
- **Headers**: Rate limit information included in response headers

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1736345738
```

## CORS

- **Methods**: GET, POST
- **Headers**: Content-Type, X-Signature
- **Origins**: Configurable (default: all origins)

## Error Handling

**Error Response Format:**
```json
{
  "error": "Error type",
  "message": "Human-readable error message",
  "code": "ERROR_CODE"
}
```

**Common Error Codes:**
- `VALIDATION_ERROR`: Request payload validation failed
- `AUTHENTICATION_ERROR`: HMAC signature verification failed
- `RATE_LIMIT_EXCEEDED`: Rate limit exceeded
- `INTERNAL_ERROR`: Internal server error
- `SERVICE_UNAVAILABLE`: Service temporarily unavailable

## Examples

### cURL

```bash
curl -X POST https://your-service.com/score \
  -H "Content-Type: application/json" \
  -H "X-Signature: sha256=your_hmac_signature" \
  -d '{
    "session_id": "3b0a0c8f-1234-5678-9abc-def012345678",
    "ts": 1736345678123,
    "features": {
      "events": 72,
      "iki_mean": 145.3,
      "iki_std": 58.1,
      "burstiness": 0.22,
      "entropy": 2.91,
      "backspace_per_100": 4.8,
      "paste_events": 0,
      "jitter_mad": 27.5,
      "outlier_ratio": 0.08
    }
  }'
```

### JavaScript

```javascript
const response = await fetch('https://your-service.com/score', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Signature': 'sha256=' + await calculateHMAC(payload, secretKey)
  },
  body: JSON.stringify(payload)
});

const result = await response.json();
console.log('Score:', result.score);
```

## SDKs

### Dart/Flutter

```dart
final client = TypingGuardClient(
  config: TypingGuardConfig.withServer(
    serverUrl: Uri.parse('https://your-service.com'),
    hmacKeyProvider: () async => 'your-secret-key',
  ),
);

final result = await client.scoreFeatures(features);
```

### Rust

```rust
let payload = TypingFeaturePayload::new(features, None);
let response = client.post("/score").json(&payload).send().await?;
```

## Versioning

- **Major version**: Breaking changes
- **Minor version**: New features, backward compatible
- **Patch version**: Bug fixes, backward compatible

Current version: `1.0.0`

## Support

- **Documentation**: This specification
- **Issues**: GitHub issues
- **Examples**: See examples directory
- **SDKs**: Available for Dart and Rust
