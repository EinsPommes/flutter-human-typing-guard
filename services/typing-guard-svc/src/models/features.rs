use serde::{Deserialize, Serialize};

/// Typing features extracted from client-side analysis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TypingFeatures {
    /// Number of events in the analysis window
    pub events: u32,
    
    /// Mean inter-key interval in milliseconds
    pub iki_mean: f64,
    
    /// Standard deviation of inter-key intervals
    pub iki_std: f64,
    
    /// Interquartile range of inter-key intervals
    pub iki_iqr: f64,
    
    /// Burstiness measure: (σ - μ) / (σ + μ)
    pub burstiness: f64,
    
    /// Local entropy of interval distribution
    pub entropy: f64,
    
    /// Backspace rate per 100 keystrokes
    pub backspace_per_100: f64,
    
    /// Number of paste events
    pub paste_events: u32,
    
    /// Mean absolute deviation of consecutive IKI differences
    pub jitter_mad: f64,
    
    /// Ratio of outlier intervals (> 3σ from mean)
    pub outlier_ratio: f64,
}

impl TypingFeatures {
    /// Calculate human-likeness score based on features
    pub fn calculate_score(&self, weights: &FeatureWeights) -> f64 {
        let speed_score = self.normalize_speed();
        let variability_score = self.normalize_variability();
        let entropy_score = self.normalize_entropy();
        let backspace_score = self.normalize_backspace();
        let jitter_score = self.normalize_jitter();

        let score = (speed_score * weights.speed) +
                   (variability_score * weights.variability) +
                   (entropy_score * weights.entropy) +
                   (backspace_score * weights.backspace) +
                   (jitter_score * weights.jitter);

        score.clamp(0.0, 1.0)
    }

    /// Normalize speed (IKI mean) to 0-1 score
    fn normalize_speed(&self) -> f64 {
        // Human typing typically 100-300ms, optimal around 150ms
        if self.iki_mean < 50.0 {
            return 0.0; // Too fast (bot-like)
        }
        if self.iki_mean > 1000.0 {
            return 0.0; // Too slow (suspicious)
        }
        if self.iki_mean >= 100.0 && self.iki_mean <= 300.0 {
            return 1.0; // Optimal range
        }
        if self.iki_mean < 100.0 {
            return self.iki_mean / 100.0; // Linear scaling for fast typing
        }
        (1.0 - (self.iki_mean - 300.0) / 700.0).max(0.0) // Linear scaling for slow typing
    }

    /// Normalize variability to 0-1 score
    fn normalize_variability(&self) -> f64 {
        // Humans have moderate variability, bots are either too consistent or too random
        let std_score = (self.iki_std / 100.0).clamp(0.0, 1.0);
        let burst_score = (self.burstiness + 1.0) / 2.0; // Convert from [-1,1] to [0,1]
        (std_score + burst_score) / 2.0
    }

    /// Normalize entropy to 0-1 score
    fn normalize_entropy(&self) -> f64 {
        // Optimal entropy around 2.5-3.5 for human typing
        if self.entropy < 1.0 {
            return 0.0; // Too low (bot-like)
        }
        if self.entropy > 4.0 {
            return 0.0; // Too high (random)
        }
        if self.entropy >= 2.0 && self.entropy <= 3.5 {
            return 1.0; // Optimal range
        }
        self.entropy / 3.5 // Linear scaling
    }

    /// Normalize backspace rate to 0-1 score
    fn normalize_backspace(&self) -> f64 {
        // Humans make some mistakes, but not too many
        if self.backspace_per_100 < 1.0 {
            return 0.5; // Very few mistakes (suspicious)
        }
        if self.backspace_per_100 > 20.0 {
            return 0.0; // Too many mistakes
        }
        if self.backspace_per_100 >= 2.0 && self.backspace_per_100 <= 10.0 {
            return 1.0; // Optimal range
        }
        1.0 - (self.backspace_per_100 - 10.0) / 10.0 // Linear scaling
    }

    /// Normalize jitter to 0-1 score
    fn normalize_jitter(&self) -> f64 {
        // Some jitter is human-like, too much or too little is suspicious
        if self.jitter_mad < 5.0 {
            return 0.3; // Too consistent
        }
        if self.jitter_mad > 100.0 {
            return 0.0; // Too erratic
        }
        if self.jitter_mad >= 10.0 && self.jitter_mad <= 50.0 {
            return 1.0; // Optimal range
        }
        self.jitter_mad / 50.0 // Linear scaling
    }
}

/// Feature weights for scoring algorithm
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeatureWeights {
    pub speed: f64,
    pub variability: f64,
    pub entropy: f64,
    pub backspace: f64,
    pub jitter: f64,
}

impl Default for FeatureWeights {
    fn default() -> Self {
        Self {
            speed: 0.3,
            variability: 0.25,
            entropy: 0.2,
            backspace: 0.15,
            jitter: 0.1,
        }
    }
}

impl FeatureWeights {
    /// Validate that weights sum to approximately 1.0
    pub fn validate(&self) -> Result<(), String> {
        let sum = self.speed + self.variability + self.entropy + self.backspace + self.jitter;
        if (sum - 1.0).abs() > 0.01 {
            return Err(format!("Feature weights must sum to approximately 1.0, got {}", sum));
        }
        Ok(())
    }
}
