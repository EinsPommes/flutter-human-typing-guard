# How We Detect Human Typing

The math behind our bot detection system.

## The Big Picture

We analyze typing patterns using key metrics that humans and bots do differently. It's statistics applied to keystroke timing.

## Core Metrics

### 1. Inter-Key Intervals (IKI)

Time between consecutive keystrokes in milliseconds.

**Humans**: 100-300ms between keys, lots of variation
**Bots**: Too consistent (metronome) or completely random

```
IKI[i] = timestamp[i+1] - timestamp[i]
```

### 2. Burstiness

Measures how "bursty" typing patterns are.

```
B = (σ - μ) / (σ + μ)
```

**Humans**: Moderate burstiness (0.1 to 0.4)
**Bots**: Too consistent or too random

### 3. Entropy

Measures randomness/unpredictability of typing patterns.

```
H = -Σ(p[i] * log₂(p[i]))
```

**Humans**: 2.0-3.5 (optimal range)
**Bots**: Too predictable (< 1.0) or too random (> 4.0)

### 4. Backspace Rate

Percentage of backspace/delete events per 100 keystrokes.

**Humans**: 2-10% (natural error correction)
**Bots**: Too perfect (< 1%) or too many (> 20%)

### 5. Cadence Jitter

Mean Absolute Deviation of consecutive IKI differences.

**Humans**: 10-50ms (natural rhythm variations)
**Bots**: Too consistent (< 5ms) or too erratic (> 100ms)

### 6. Outlier Ratio

Percentage of IKI values > 3σ from mean.

**Humans**: 5-15% (natural pauses)
**Bots**: Too consistent (< 2%) or too erratic (> 30%)

## Scoring Algorithm

Final score combines weighted metrics:

```
Score = Σ(w[i] * normalize(metric[i]))
```

### Default Weights:
- Speed: 30%
- Variability: 25%
- Entropy: 20%
- Backspace: 15%
- Jitter: 10%

### Normalization:
- **Speed**: 100-300ms = optimal (1.0)
- **Variability**: Moderate variation = optimal
- **Entropy**: 2.0-3.5 = optimal
- **Backspace**: 2-10% = optimal
- **Jitter**: 10-50ms = optimal

## Limitations

### Assumptions:
- Average typing skill (not professional typists)
- English/Latin character sets
- Keyboard input (not touch/voice)

### False Positives:
- Professional typists
- Users with disabilities
- Non-native speakers
- Slow connections

### False Negatives:
- Advanced bots
- Bots using human data
- Sophisticated automation

## Configuration

```dart
TypingGuardConfig(
  featureWeights: {
    'speed': 0.3,
    'variability': 0.25,
    'entropy': 0.2,
    'backspace': 0.15,
    'jitter': 0.1,
  },
  localThreshold: 0.6,
  windowMs: 5000,
  minEvents: 20,
)
```

## Privacy

- **No Personal Data**: Only aggregated metrics
- **No Biometric ID**: Cannot identify individuals
- **Local Analysis**: Processing happens locally
- **Session-based**: No persistent tracking
- **Opt-in Server**: Server analysis is optional
