rm(list = objects())
graphics.off()
source("R/score.R")
library(tidyverse)

set.seed(42)

df_full <- read_csv("Data/treated_data.csv")

# On doit remettre en facteur à cause du csv
df_full$WeekDays <- as.factor(df_full$WeekDays) # 0 = Lundi, 6 = Dimanche
df_full$BH_Holiday <- as.factor(df_full$BH_Holiday)
# increment <- 1:nrow(df_full)
# df_full$minmax_increment <- (increment - min(increment)) / (max(increment) - min(increment))

# doy <- as.numeric(format(as.Date(df_full$Date), "%j"))
# df_full$minmax_dayofyear <- (doy - min(doy)) / (max(doy) - min(doy))

# df_full$weekend <- as.numeric((df_full$WeekDays == 5) | (df_full$WeekDays == 6))

# Normalisation de Net_demand et laggées, en conservant la moyenne et l'écart type pour faire la transformation inverse sur les prédictions
idx_train_val <- which(df_full$Date <= "2022-09-01")
df_train_val <- df_full[idx_train_val, ]
Net_demand_mean <- mean(df_train_val$Net_demand)
Net_demand_sd <- sd(df_train_val$Net_demand)

df_full$Net_demand <- (df_full$Net_demand - Net_demand_mean) / Net_demand_sd
df_full$Net_demand.1 <- (df_full$Net_demand.1 - Net_demand_mean) / Net_demand_sd
df_full$Net_demand.7 <- (df_full$Net_demand.7 - Net_demand_mean) / Net_demand_sd

# On fera une validation sur la dernière année du jeu train
# Création des jeux de données train, val, test; et un jeu qui combine train et val
idx_train <- which(df_full$Date <= "2021-09-01")
idx_val <- which((df_full$Date > "2021-09-01") & (df_full$Date <= "2022-09-01"))
idx_train_val <- which(df_full$Date <= "2022-09-01")
idx_test <- which(df_full$Date > "2022-09-01")
df_train <- df_full[idx_train, ]
df_val <- df_full[idx_val, ]
df_train_val <- df_full[idx_train_val, ]
df_test <- df_full[idx_test, ]

### Models
target_col <- "Net_demand"
features_col <- setdiff(names(df_full), target_col)
features_col <- setdiff(features_col, "Date")
features_col <- setdiff(features_col, "incr")
# features_col <- setdiff(features_col, "WeekDays")
# features_col <- setdiff(features_col, "lundi_vendredi")
features_col

library(randomForest)
# RandomForest basique
CHEAT <- TRUE
# Après essait de toutes les valeurs possibles de mtry (1:39), l'erreur OOB (0.02185) est minimisée pour mtry = 20 (pb 637)

rf_model <- randomForest(as.formula(paste(target_col, "~ .")), data = df_train_val[, c(features_col, target_col)], importance = TRUE, ntree = 500, mtry = 20)
print(rf_model)
predictions_test <- (predict(rf_model, df_test[, features_col]) * Net_demand_sd) + Net_demand_mean
predictions_train <- (predict(rf_model, df_train_val[, features_col]) * Net_demand_sd) + Net_demand_mean

truth_train <- (df_train_val$Net_demand * Net_demand_sd) + Net_demand_mean

err_OOB <- rf_model$mse[rf_model$ntree]
print(paste("OOB error (non déstandardisée):", err_OOB))
err_pinball_train <- pinball_loss(truth_train, predictions_train, 0.8)
print(paste("Pinball on train set:", err_pinball_train))
err_rmse_train <- sqrt(mean((truth_train - predictions_train)^2))
print(paste("RMSE on train set:", err_rmse_train))

if (CHEAT) {
    truth_test <- read.csv("Data/test_better.csv")$Net_demand
    err_pinball_test <- pinball_loss(truth_test, predictions_test, 0.8)
    print(paste("Pinball on cheat set:", err_pinball_test))
    err_rmse_test <- sqrt(mean((truth_test - predictions_test)^2))
    print(paste("RMSE on cheat set:", err_rmse_test))

    plot(df_test$Date, truth_test, type = "l", col = "blue", lwd = 2, ylab = "Net Demand", xlab = "Date", main = "Predictions vs Ground Truth (Cheat 2022)")
    lines(df_test$Date, predictions_test, col = "red", lwd = 2)
    legend("topright", legend = c("Ground Truth", "Predictions"), col = c("blue", "red"), lwd = 2)
} else {
    plot(df_test$Date, predictions_test, type = "l", col = "red", lwd = 2, ylab = "Net Demand", xlab = "Date", main = "Predictions (2022)")
    legend("topright", legend = c("Predictions"), col = c("red"), lwd = 2)
}
plot(rf_model)
importance <- importance(rf_model)
varImpPlot(rf_model)

write_csv(as.data.frame(predictions_test), "Data/preds_rf_test.csv")
write_csv(as.data.frame(predictions_train), "Data/preds_rf_train.csv")
