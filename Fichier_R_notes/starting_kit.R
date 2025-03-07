rm(list=objects())
library(tidyverse)
library(ranger)
train <- read_csv('Data/net-load-forecasting-during-the-soberty-period/train.csv')
test <- read_csv('Data/net-load-forecasting-during-the-soberty-period/test.csv')
source("R/score.R")
names(train)
names(test)

range(train$Date)
range(test$Date)

# on charge les données
###############################################################################################################################################################################
Data0 <- train
Data0$Time  <- as.numeric(Data0$Date)
Data1<- test
Data1$Time  <- as.numeric(Data1$Date)

equation <- Net_demand ~  Time + toy + Temp + Net_demand.1 + Net_demand.7 + Temp_s99 + WeekDays + BH + Temp_s95_max + Temp_s99_max + Summer_break  + Christmas_break + 
  Temp_s95_min +Temp_s99_min + DLS 

set.seed(50)
rf <- ranger::ranger(equation, data=Data0, importance =  'permutation', quantreg = TRUE)
rf$r.squared


rf.forecast <- predict(rf, data=Data1, quantiles = 0.8, type = "quantiles")$predictions

# ici foret aleatoire, prevision, à remplacer par notre modèle
# on change netdemand par notre prédiction
# on upload et on voit ce que ça fait

#####sur la plateforme
submit <- read_delim( file="Data/sample_submission.csv", delim=",")
submit$Net_demand <- rf.forecast
write.table(submit, file="Data/submission_rf_08.csv", quote=F, sep=",", dec='.',row.names = F)











