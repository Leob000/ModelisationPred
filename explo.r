rm(list = objects())
graphics.off()
source("R/score.R")
library(tidyverse)

set.seed(42)
GRAPH <- TRUE

df_train_val <- read_csv("Data/train.csv")
df_test <- read_csv("Data/test.csv")

# On veut joindre les deux datasets pour faire les transformations de données directement sur les deux
# On drop "Load","Solar_power","Wind_power" du dataset train, qui ne sont pas présentes dans le dataset test
df_train_val <- df_train_val %>% select(-Load, -Solar_power, -Wind_power)
# On drop "Id" et "Usage" du test set
df_test <- df_test %>% select(-Id, -Usage)

# Concaténation des deux jeux de données
df_full <- bind_rows(df_train_val, df_test)
# Check NaNs in df_full
na_counts <- sapply(df_full, function(x) sum(is.na(x)))
print(na_counts)

# Problème avec Nebulosity, non stabilisé pré 2018
plot(df_full$Date, df_full$Nebulosity)
names(df_full)
# Stabilisation de Nebulosity
years <- 2013:2017
seuil_bas <- 58
seuil_haut <- 96
for (year in years) {
  idx <- which(df_full$Year == year)
  col <- df_full$Nebulosity[idx]
  df_full$Nebulosity[idx] <- seuil_bas + (col - min(col)) / (max(col) - min(col)) * (seuil_haut - seuil_bas)
}
plot(df_full$Date, df_full$Nebulosity)

# Idem pour Nebulosity_weighted
plot(df_full$Nebulosity_weighted)
seuil_bas <- 65
seuil_haut <- 96
for (year in years) {
  idx <- which(df_full$Year == year)
  col <- df_full$Nebulosity_weighted[idx]
  df_full$Nebulosity_weighted[idx] <- seuil_bas + (col - min(col)) / (max(col) - min(col)) * (seuil_haut - seuil_bas)
}
plot(df_full$Date, df_full$Nebulosity_weighted)

# On transforme Nebulosity_weighted et Wind_weighted en ratio avec les non weighted
df_full$Nebulosity_weighted <- df_full$Nebulosity_weighted / df_full$Nebulosity
df_full <- df_full %>% rename(Nebulosity_weighted_ratio = Nebulosity_weighted)
df_full$Wind_weighted <- df_full$Wind_weighted / df_full$Wind
df_full <- df_full %>% rename(Wind_weighted_ratio = Wind_weighted)

# Matrice de corrélation des variables
library(corrplot)
correlation_matrix <- cor(df_full %>% select(-Date, -Year, -Month, -Holiday, -Holiday_zone_a, -Holiday_zone_b, -Holiday_zone_c, -toy, -BH_before, -BH, -BH_after, -WeekDays, -DLS, -Summer_break, -Christmas_break, -BH_Holiday) %>% na.omit())
corrplot(correlation_matrix, method = "color", type = "upper", tl.col = "black", tl.srt = 45)

# Ajout de la feature "Net_demand.1_trend" qui prend la moyenne des 7 dernières valeurs
df_full <- df_full %>%
  arrange(Date) %>%
  mutate(Net_demand.1_trend = zoo::rollapply(Net_demand.1, width = 7, FUN = mean, align = "right", fill = NA))
# On rempli les NaN du début
for (i in 1:6) {
  df_full$Net_demand.1_trend[i] <- df_full$Net_demand.1_trend[7]
}
plot(df_full$Date, df_full$Net_demand)
lines(df_full$Date, df_full$Net_demand.1_trend, col = "red")

# Feature engineering sur les dates
# Weekdays en facteur
df_full$WeekDays <- as.factor(df_full$WeekDays) # 0 = Lundi, 6 = Dimanche
boxplot(Net_demand ~ WeekDays, data = df_full)

# Séparation des trois jeux de données: train, val, test
range(df_train_val$Date)
idx_train <- which(df_full$Date <= "2021-09-01")
idx_val <- which((df_full$Date > "2021-09-01") & (df_full$Date <= "2022-09-01"))
idx_test <- which(df_full$Date > "2022-09-01")
df_train <- df_full[idx_train, ]
df_val <- df_full[idx_val, ]
df_test <- df_full[idx_test, ]
range(df_train$Date)
range(df_val$Date)
range(df_test$Date)




# fonction pour transformer en trigo
transformation_trigo = function (data,nbr_class) {
  x=cos(2*pi*(data))/nbr_class
  y=sin(2*pi*(data))/nbr_class
  return (list(x,y))
}
# creation des variables wkd et coeur de la semaine (si les 2 == 0 => lundi vendredi)                  
Data0$WeekDays2 <- weekdays(Data0$Date)
Data0$WeekDays <- forcats::fct_recode(Data0$WeekDays2, 'WorkDay'='mardi' ,'WorkDay'='mercredi', 'WorkDay' = 'jeudi')
Data0$WeekendDays <- forcats::fct_recode(Data0$WeekDays2, 'WorkDay'='dimanche' ,'WorkDay'='samedi')
# transformation des jours de la semaine en coordonnées trigonométriques            
semaine_trigo=transformation_trigo(Data0$WeekDays,7)
Data0$WeekDaystrigo_x=semaine_trigo[1]
Data0$WeekDaystrigo_y=semaine_trigo[2]
