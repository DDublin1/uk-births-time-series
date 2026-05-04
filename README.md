# UK Birth Rate Time Series Forecasting

Time series analysis and forecasting of UK vital statistics (births) using ARIMA, ETS models, ADF stationarity tests, and residual diagnostics. Includes trend decomposition and multi-horizon forecasting.

## Overview

This project analyzes historical trends and forecasts future birth rates in the United Kingdom using advanced time series methods. The analysis compares multiple forecasting approaches (ARIMA, ETS, linear trend) and selects the best-performing model for three-year ahead predictions.

## Dataset

**Source**: UK Office for National Statistics (ONS) Vital Statistics

- **Time Period**: Annual data spanning multiple decades
- **Frequency**: Annual observations
- **Metric**: Total number of live births (United Kingdom)
- **Quality**: Official government statistics

## Analysis Components

### 1. Data Preparation and Loading
- Reading Excel workbooks (births and deaths data)
- Cleaning and numeric conversion
- Time series object creation
- Summary statistics and exploratory inspection

### 2. Exploratory Data Analysis (EDA)
- **Raw Time Series Plot**: Historical births trajectory
- **LOESS Smoothing**: Long-term trend extraction
- **Moving Average Trend**: 7-year centered moving average
- **ACF/PACF Analysis**: Autocorrelation structure for model selection

### 3. Train-Test Split
- **Holdout Strategy**: Last 10 years reserved for testing
- **Training Set**: Full historical data minus test period
- **Test Set**: Recent 10-year period for out-of-sample validation

### 4. Time Series Models

#### Model 1: ARIMA
- Automatic specification using `auto.arima()`
- Selects optimal (p,d,q) parameters
- AIC-based model selection
- Residual diagnostics and white noise testing

#### Model 2: ETS (Exponential Smoothing)
- Error, Trend, Seasonal decomposition
- Automatic component selection
- Smoothing parameter optimization
- Suitable for trend-dominated series

#### Model 3: Linear Trend Regression
- Simple tslm with trend component
- Baseline model for comparison
- Interpretable parameter estimates
- Lower complexity alternative

### 5. Assumption Testing

- **Stationarity**: Augmented Dickey-Fuller (ADF) test
- **Residual Autocorrelation**: Ljung-Box test for white noise
- **Normality**: Shapiro-Wilk tests on residuals
- **Model Diagnostics**: Residual plots for each specification

### 6. Forecasting & Model Comparison

- **Accuracy Metrics**: RMSE and MAE on test set
- **Information Criteria**: AIC comparison across models
- **Best Model Selection**: Lowest test-set RMSE
- **Predicted vs Actual**: Visualization of fit quality

### 7. Final Forecasting

- **Refit to Full Series**: Best model refitted on complete data
- **3-Year Horizon**: Forward predictions with uncertainty bands
- **Prediction Intervals**: 80% and 95% confidence bands
- **Visualization**: Forecast plot with historical context

## Key Findings

1. **Historical Trend**:
   - Birth rate follows long-term demographic trends
   - Peaks align with known fertility rate changes
   - Recent decline consistent with lower birth rate statistics

2. **Model Comparison**:
   - ARIMA typically preferred for autocorrelated series
   - ETS effective for smooth, trend-dominated patterns
   - Linear trend serves as valuable baseline

3. **Stationarity**:
   - Series exhibits non-stationary behavior (expected for count data with trend)
   - Differencing or trend removal may be required for ARIMA

4. **Forecasting Accuracy**:
   - Test-set metrics (RMSE/MAE) guide model selection
   - Best model provides most reliable forward predictions
   - Uncertainty bands widen with forecast horizon

## Technologies

- **R 4.x**: Statistical computing and graphics
- **forecast**: ARIMA, ETS, and forecasting utilities
- **tseries**: Time series analysis (ADF tests)
- **ggplot2**: Publication-quality visualizations
- **dplyr**: Data wrangling and transformation
- **zoo**: Time series utilities (moving averages)
- **readxl**: Excel file input
- **knitr**: Table formatting

## File Structure

```
analysis/
└── uk_births_forecasting.R    # Main analysis script
```

## Running the Analysis

```r
# Load and execute the analysis script
source("analysis/uk_births_forecasting.R")
```

**Requirements**:
- Excel file: `Vital statistics in the UK.xlsx` (with "Birth" and "Death" sheets)
- All required R packages (see Technologies section)

## Output

The script produces:
- Data cleaning and structure summaries
- Exploratory time series visualizations
- Train/test split confirmation
- ARIMA, ETS, and linear trend model summaries
- Residual diagnostic plots and tests
- Model comparison tables
- Predicted vs actual plots
- Final 3-year forecast with prediction intervals
- Summary of findings and model selection rationale

## Methodology Notes

- **Frequency**: Annual data (frequency = 1)
- **Missing Values**: Filtered during data cleaning
- **Test Horizon**: 10 years for robust out-of-sample validation
- **Forecast Horizon**: 3 years (balance between precision and relevance)
- **Residual Assumptions**: White noise tested via Ljung-Box
- **Model Selection**: AIC and test RMSE used for objective comparison

## Interpretation Guide

### Reading Forecast Output
- **Point Forecast**: Most likely future value
- **80% PI**: Range containing 80% probability of actual value
- **95% PI**: Range containing 95% probability of actual value

### Model Selection Criteria
- Models with lower RMSE/MAE perform better on test data
- Lower AIC indicates better fit adjusted for complexity
- Residuals should approximate white noise (high Ljung-Box p-value)

## Author

Created as a professional time series analysis portfolio project.

## License

Proprietary - For portfolio and demonstration purposes.
