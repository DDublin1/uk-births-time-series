# =============================================================================
# UK Vital Statistics: Birth Rate Time Series Forecasting
# Time series modelling and forecasting of UK birth statistics
# using ARIMA, ETS, and trend decomposition methods.
# =============================================================================

# 0. LOAD LIBRARIES -----------------------------------------------------------

library(forecast)   # ARIMA, ETS, tslm, forecast, checkresiduals
library(tseries)    # adf.test
library(ggplot2)    # visualisations
library(readxl)     # Excel import
library(dplyr)      # data wrangling
library(knitr)      # kable tables
library(zoo)        # moving averages for trend smoothing

set.seed(123)       # reproducibility for any random components

cat("=== UK VITAL STATISTICS TIME SERIES ANALYSIS (BIRTHS) ===\n\n")


# =============================================================================
# 1. DATA LOADING AND PREPARATION
# =============================================================================

cat("1. DATA LOADING AND PREPARATION\n")
cat("================================\n\n")

# 1.1 Load births and deaths sheets ------------------------------------------

vs_file <- "Vital statistics in the UK.xlsx"

cat("Available sheets in workbook:\n")
print(readxl::excel_sheets(vs_file))
cat("\n")

birth_data <- read_excel(vs_file, sheet = "Birth",  skip = 5)  # row 6 = header
death_data <- read_excel(vs_file, sheet = "Death",  skip = 5)

cat("Births data columns:\n")
print(names(birth_data))
cat("\nDeaths data columns:\n")
print(names(death_data))
cat("\n")

# 1.2 Clean births: United Kingdom -------------------------------------------

births_uk <- birth_data %>%
  dplyr::select(
    Year,
    Births_UK_raw = `Number of live births: United Kingdom`
  ) %>%
  dplyr::mutate(
    Year       = as.integer(Year),
    Births_UK  = gsub("[^0-9]", "", Births_UK_raw),
    Births_UK  = as.numeric(Births_UK)
  ) %>%
  dplyr::filter(!is.na(Year), !is.na(Births_UK)) %>%
  dplyr::arrange(Year)

cat("Head of cleaned UK births data:\n")
print(head(births_uk, 5))
cat("\nTail of cleaned UK births data:\n")
print(tail(births_uk, 5))
cat("\n")

# RESULT SCREENSHOT: Appendix T1.1 – Cleaned UK Births Data (Head/Tail)
# Table T1.1: First and last 5 rows of cleaned annual births for the UK.


# 1.3 (Optional) Clean deaths: United Kingdom ---------------------------------

deaths_uk <- death_data %>%
  dplyr::select(
    Year,
    Deaths_UK_raw = `Number of deaths: United Kingdom`
  ) %>%
  dplyr::mutate(
    Year      = as.integer(Year),
    Deaths_UK = gsub("[^0-9]", "", Deaths_UK_raw),
    Deaths_UK = as.numeric(Deaths_UK)
  ) %>%
  dplyr::filter(!is.na(Year), !is.na(Deaths_UK)) %>%
  dplyr::arrange(Year)

cat("Head of cleaned UK deaths data (for context only):\n")
print(head(deaths_uk, 5))
cat("\n")

# RESULT SCREENSHOT: Appendix T1.2 – Cleaned UK Deaths Data (Head)
# Table T1.2: First 5 rows of cleaned annual deaths for the UK (used descriptively).


# 1.4 Create time series objects ---------------------------------------------

births_ts <- ts(
  births_uk$Births_UK,
  start     = min(births_uk$Year),
  frequency = 1        # annual data
)

cat("Summary of UK births time series:\n")
print(summary(births_ts))
cat("\n")

# RESULT SCREENSHOT: Appendix O1.3 – Time Series Summary Output
# Output O1.3: Summary statistics (min, max, mean) for UK births time series.


# =============================================================================
# 2. EXPLORATORY DATA ANALYSIS
# =============================================================================

cat("2. EXPLORATORY DATA ANALYSIS\n")
cat("================================\n\n")

# 2.1 Raw time series plot ----------------------------------------------------

p_births <- ggplot(births_uk, aes(x = Year, y = Births_UK)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue", size = 1.8) +
  labs(
    title = "Annual UK Live Births",
    x     = "Year",
    y     = "Number of births"
  ) +
  theme_minimal()

print(p_births)

# RESULT SCREENSHOT: Appendix F2.1 – Annual UK Births Time Series
# Figure F2.1: Long-run trend in UK births, showing historical peaks and recent declines.


# 2.2 Smoothed trend using LOESS ---------------------------------------------

p_births_smooth <- ggplot(births_uk, aes(x = Year, y = Births_UK)) +
  geom_line(alpha = 0.4) +
  geom_smooth(method = "loess", span = 0.2, se = FALSE, linewidth = 1.1) +
  labs(
    title = "Smoothed Trend in UK Live Births (LOESS)",
    x     = "Year",
    y     = "Number of births"
  ) +
  theme_minimal()

print(p_births_smooth)

# RESULT SCREENSHOT: Appendix F2.2 – LOESS-Smoothed Births Trend
# Figure F2.2: Smoothed trajectory highlighting long-term decline and structural changes.


# 2.3 Moving-average trend decomposition -------------------------------------

births_uk <- births_uk %>%
  mutate(
    Births_MA7 = zoo::rollmean(Births_UK, k = 7, fill = NA, align = "center"),
    Remainder  = Births_UK - Births_MA7
  )

p_ma <- ggplot(births_uk, aes(x = Year)) +
  geom_line(aes(y = Births_UK), alpha = 0.4) +
  geom_line(aes(y = Births_MA7), color = "darkred", linewidth = 1.1) +
  labs(
    title = "UK Births: Observed vs 7-Year Moving Average Trend",
    x     = "Year",
    y     = "Number of births"
  ) +
  theme_minimal()

print(p_ma)

# RESULT SCREENSHOT: Appendix F2.3 – Moving Average Trend Decomposition
# Figure F2.3: Moving-average trend line showing smoothed long-term pattern in births.


# 2.4 ACF and PACF plots -----------------------------------------------------

par(mfrow = c(1, 2))
acf(births_ts, main = "ACF of UK Births")
pacf(births_ts, main = "PACF of UK Births")
par(mfrow = c(1, 1))

# RESULT SCREENSHOT: Appendix F2.4 – ACF and PACF of UK Births
# Figure F2.4: Autocorrelation patterns informing ARIMA model specification.


# =============================================================================
# 3. TRAIN–TEST SPLIT (10-YEAR TEST SET)
# =============================================================================

cat("3. TRAIN–TEST SPLIT (10-YEAR TEST SET)\n")
cat("=======================================\n\n")

# 3.1 Define split: last 10 years as test ------------------------------------

max_year   <- max(births_uk$Year)
split_year <- max_year - 9   # last 10 observations reserved for testing

train_births <- window(births_ts, end   = split_year)
test_births  <- window(births_ts, start = split_year + 1)

test_start_year <- split_year + 1
test_end_year   <- max_year

cat("Training period  :", start(train_births)[1], "to", end(train_births)[1], "\n")
cat("Test period      :", test_start_year, "to", test_end_year, "\n\n")
cat("Length of train :", length(train_births), "\n")
cat("Length of test  :", length(test_births), "\n\n")

# RESULT SCREENSHOT: Appendix O3.1 – Train/Test Split Output
# Output O3.1: Confirmation of training and testing periods (last 10 years held out).


# =============================================================================
# 4. TIME SERIES MODELLING
# =============================================================================

cat("4. TIME SERIES MODELLING\n")
cat("================================\n\n")

# 4.1 MODEL 1: ARIMA (auto.arima) --------------------------------------------

cat("4.1 MODEL 1: AUTO ARIMA\n")
cat("------------------------\n")

arima_model <- auto.arima(train_births)
print(arima_model)

# RESULT SCREENSHOT: Appendix O4.1 – ARIMA Model Summary
# Output O4.1: ARIMA specification, AIC, and parameter estimates for training data.

cat("\nARIMA residual diagnostics:\n")
checkresiduals(arima_model)

# RESULT SCREENSHOT: Appendix F4.1 – ARIMA Residual Diagnostics
# Figure F4.1: Residual plots and ACF for ARIMA, assessing remaining structure.


# 4.2 MODEL 2: ETS -----------------------------------------------------------

cat("\n4.2 MODEL 2: ETS (Exponential Smoothing)\n")
cat("----------------------------------------\n")

ets_model <- ets(train_births)
print(ets_model)

# RESULT SCREENSHOT: Appendix O4.2 – ETS Model Summary
# Output O4.2: ETS configuration and smoothing parameters for trend/level.

cat("\nETS residual diagnostics:\n")
checkresiduals(ets_model)

# RESULT SCREENSHOT: Appendix F4.2 – ETS Residual Diagnostics
# Figure F4.2: Residual plots and ACF for ETS model.


# 4.3 MODEL 3: Linear Trend (tslm) -------------------------------------------

cat("\n4.3 MODEL 3: LINEAR REGRESSION WITH TREND\n")
cat("------------------------------------------\n")

trend_model <- tslm(train_births ~ trend)
print(summary(trend_model))

# RESULT SCREENSHOT: Appendix O4.3 – Linear Trend Model Summary
# Output O4.3: Trend model coefficients, R-squared, and significance.

cat("\nTrend model residual diagnostics:\n")
checkresiduals(trend_model)

# RESULT SCREENSHOT: Appendix F4.3 – Linear Trend Residual Diagnostics
# Figure F4.3: Residual plots for linear trend model.


# =============================================================================
# 5. ASSUMPTION TESTING
# =============================================================================

cat("\n5. ASSUMPTION TESTING\n")
cat("================================\n\n")

# 5.1 Stationarity (ADF test) -------------------------------------------------

cat("5.1 Augmented Dickey–Fuller (ADF) Test for Stationarity:\n")
adf_test <- adf.test(train_births)
print(adf_test)
cat("\n")

# RESULT SCREENSHOT: Appendix O5.1 – ADF Test Output
# Output O5.1: Evidence on stationarity/non-stationarity of the training series.


# 5.2 Residual autocorrelation (Ljung–Box) -----------------------------------

cat("5.2 Ljung–Box Tests for Residual Autocorrelation:\n")

ljung_box_arima <- Box.test(residuals(arima_model), type = "Ljung-Box")
ljung_box_ets   <- Box.test(residuals(ets_model),   type = "Ljung-Box")
ljung_box_trend <- Box.test(residuals(trend_model), type = "Ljung-Box")

cat("ARIMA residuals p-value :", ljung_box_arima$p.value, "\n")
cat("ETS residuals p-value   :", ljung_box_ets$p.value, "\n")
cat("Trend residuals p-value :", ljung_box_trend$p.value, "\n\n")

# RESULT SCREENSHOT: Appendix O5.2 – Ljung–Box Test Output
# Output O5.2: p-values indicating whether residuals approximate white noise.


# 5.3 Normality of residuals (Shapiro–Wilk) ----------------------------------

cat("5.3 Shapiro–Wilk Normality Tests for Residuals:\n")

shapiro_arima <- shapiro.test(residuals(arima_model))
shapiro_ets   <- shapiro.test(residuals(ets_model))
shapiro_trend <- shapiro.test(residuals(trend_model))

cat("ARIMA residuals normality p-value :", shapiro_arima$p.value, "\n")
cat("ETS residuals normality p-value   :", shapiro_ets$p.value, "\n")
cat("Trend residuals normality p-value :", shapiro_trend$p.value, "\n\n")

# RESULT SCREENSHOT: Appendix O5.3 – Shapiro–Wilk Residual Normality Tests
# Output O5.3: Normality assessment for ARIMA, ETS and trend model residuals.


# =============================================================================
# 6. FORECASTING AND MODEL COMPARISON
# =============================================================================

cat("6. FORECASTING AND MODEL COMPARISON\n")
cat("====================================\n\n")

# 6.1 Forecast over test horizon ---------------------------------------------

h_test <- length(test_births)

arima_forecast <- forecast(arima_model, h = h_test)
ets_forecast   <- forecast(ets_model,   h = h_test)
trend_forecast <- forecast(trend_model, h = h_test)

# Accuracy metrics on test data
arima_accuracy <- accuracy(arima_forecast, test_births)
ets_accuracy   <- accuracy(ets_forecast,   test_births)
trend_accuracy <- accuracy(trend_forecast, test_births)

cat("Forecast accuracy on held-out test data:\n")
cat("ARIMA  RMSE:", arima_accuracy[2, "RMSE"], " MAE:", arima_accuracy[2, "MAE"], "\n")
cat("ETS    RMSE:", ets_accuracy[2, "RMSE"],   " MAE:", ets_accuracy[2, "MAE"],   "\n")
cat("Trend  RMSE:", trend_accuracy[2, "RMSE"], " MAE:", trend_accuracy[2, "MAE"], "\n\n")

# RESULT SCREENSHOT: Appendix T6.1 – Test-set Accuracy Metrics
# Table T6.1: RMSE and MAE for ARIMA, ETS and trend models on test data.


# 6.2 Comparison table (AIC + test RMSE) -------------------------------------

comparison_table <- data.frame(
  Model     = c("ARIMA", "ETS", "Linear Trend"),
  AIC       = c(arima_model$aic, ets_model$aic, AIC(trend_model)),
  Test_RMSE = c(arima_accuracy[2, "RMSE"],
                ets_accuracy[2, "RMSE"],
                trend_accuracy[2, "RMSE"])
)

cat("Model comparison (AIC and test RMSE):\n")
print(kable(comparison_table, format = "simple"))
cat("\n")

# RESULT SCREENSHOT: Appendix T6.2 – Model Comparison Table
# Table T6.2: AIC and test RMSE highlighting the best-performing model.


# 6.3 Predicted vs Actual plot for best model ---------------------------------

best_model_name <- comparison_table$Model[which.min(comparison_table$Test_RMSE)]
cat("Best performing model on test RMSE:", best_model_name, "\n\n")

if (best_model_name == "ARIMA") {
  best_forecast <- arima_forecast
} else if (best_model_name == "ETS") {
  best_forecast <- ets_forecast
} else {
  best_forecast <- trend_forecast
}

pred_vs_actual_df <- data.frame(
  Year      = seq(from = test_start_year, to = test_end_year, by = 1),
  Actual    = as.numeric(test_births),
  Predicted = as.numeric(best_forecast$mean)
)

p_pred <- ggplot(pred_vs_actual_df, aes(x = Actual, y = Predicted)) +
  geom_point(color = "darkblue", size = 2.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    title = paste0("Predicted vs Actual UK Births (", best_model_name, " Model)"),
    x     = "Actual births",
    y     = "Predicted births"
  ) +
  theme_minimal()

print(p_pred)

# RESULT SCREENSHOT: Appendix F6.3 – Predicted vs Actual Plot
# Figure F6.3: Alignment of predictions and actual values for the best model.


# =============================================================================
# 7. FINAL 3-YEAR FORECAST
# =============================================================================

cat("7. FINAL 3-YEAR FORECAST\n")
cat("================================\n\n")

# Refit best model on full series --------------------------------------------

if (best_model_name == "ARIMA") {
  final_model <- auto.arima(births_ts)
} else if (best_model_name == "ETS") {
  final_model <- ets(births_ts)
} else {
  final_model <- tslm(births_ts ~ trend)
}

final_forecast <- forecast(final_model, h = 3)

cat("3-year forecast for UK live births:\n")
print(final_forecast)
cat("\n")

# RESULT SCREENSHOT: Appendix T7.1 – 3-Year Forecast Output
# Table T7.1: Point forecasts and prediction intervals for the next three years.

plot(final_forecast,
     main = "UK Live Births Forecast (Next 3 Years)",
     xlab = "Year",
     ylab = "Number of births")
grid()

# RESULT SCREENSHOT: Appendix F7.2 – Final Forecast Plot
# Figure F7.2: Forecasted births with 80% and 95% prediction intervals.


# =============================================================================
# 8. SUMMARY OF FINDINGS
# =============================================================================

cat("8. SUMMARY OF FINDINGS\n")
cat("================================\n\n")

cat("Model comparison summary:\n")
print(comparison_table)
cat("\nBest model based on test RMSE:", best_model_name, "\n")

cat("The analysis evaluated ARIMA, ETS and a linear trend model. Model comparison showed that ",
    best_model_name,
    " achieved the lowest test-set RMSE, and was therefore selected for final forecasting.\n")

