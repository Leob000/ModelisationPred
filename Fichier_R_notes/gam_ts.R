rm(list=objects())
###############packages
library(mgcv)
library(yarrr)
library(magrittr)
library(forecast)
library(tidyverse)
source('R/score.R')

Data0 <- read_delim("Data/train.csv", delim=",")
Data1<- read_delim("Data/test.csv", delim=",")

range(Data0$Date)

Data0$Time <- as.numeric(Data0$Date)
Data1$Time <- as.numeric(Data1$Date)


sel_a <- which(Data0$Year<=2021)
sel_b <- which(Data0$Year>2021)


plot(Data0$Temp, Data0$Load)

par(mfrow=c(1,1))
g0 <- gam(Load~s(Temp, k=3, bs="cr"), data=Data0)
plot(g0, residuals=T)
summary(g0)
plot(Data0$Temp, g0$residuals, pch=16)

g_prov <- gam(g0$residuals~ s(Data0$Temp, k=5, bs="cr"))
summary(g_prov)

g1 <- gam(Load~s(Temp, k=10, bs="cr"), data=Data0)
summary(g1)
plot(Data0$Temp, g0$residuals, pch=16, col='grey')
points(Data0$Temp, g1$residuals, pch=16)

(g0$gcv.ubre-g1$gcv.ubre)/g0$gcv.ubre
sqrt(g0$gcv.ubre)
sqrt(g1$gcv.ubre)

g2 <- gam(Load~s(Temp, k=10, bs="cr", by=as.factor(WeekDays))+as.factor(WeekDays), data=Data0)
summary(g2)
plot(g2)

 # g1.forecast  <- predict(g1, newdata=Data1)
 # rmse.old(Data1$Load-g1.forecast)
plot(g1, residuals=T)



Nblock<-10
borne_block<-seq(1, nrow(Data0), length=Nblock+1)%>%floor
block_list<-list()
l<-length(borne_block)
for(i in c(2:(l-1)))
{
  block_list[[i-1]] <- c(borne_block[i-1]:(borne_block[i]-1))
}
block_list[[l-1]]<-c(borne_block[l-1]:(borne_block[l]))


############################################################################
##############GAM model considering all predictors
############################################################################

gam1<-gam(Load~s(as.numeric(Date), k=3,  bs='cr'),  data=Data0)
summary(gam1)
plot(gam1)

plot(Data0$toy, Data0$Load, pch=16)



gam1<-gam(Load~s(as.numeric(Date), k=3,  bs='cr')+s(toy,k=30, bs='cc')+s(Temp,k=10, bs='cr'), data=Data0)
summary(gam1)  
plot(gam1)


blockRMSE<-function(equation, block)
{
  g<- gam(as.formula(equation), data=Data0[-block,])
  forecast<-predict(g, newdata=Data0[block,])
  return(Data0[block,]$Load-forecast)
} 


#####model 1
equation <- Load~s(as.numeric(Date),k=3, bs='cr')+s(toy,k=30, bs='cr')+s(Temp,k=10, bs='cr')
Block_residuals<-lapply(block_list, blockRMSE, equation=equation)%>%unlist
rmseBloc1<-rmse.old(Block_residuals)
rmseBloc1

gam1<-gam(equation, data=Data0[sel_a,])
gam1$gcv.ubre%>%sqrt

boxplot(Block_residuals)
plot(Block_residuals, type='l')
hist(Block_residuals)

boxplot(Block_residuals~Data0$WeekDays)
plot(Data0$Temp, Block_residuals, pch=16)
plot(Data0$toy, Block_residuals, pch=16)
plot(Data0$Load.1, Block_residuals, pch=16)
rmse1 <- rmse.old(Block_residuals)
rmse1

gam1.forecast<-predict(gam1,  newdata= Data0[sel_b,])
rmse1.forecast <- rmse.old(Data0$Load[sel_b]-gam1.forecast)

#####model 2
equation <- Load~s(as.numeric(Date),k=3, bs='cr')+s(toy,k=30, bs='cc')+s(Temp,k=10, bs='cr')+as.factor(WeekDays)
Block_residuals<-lapply(block_list, blockRMSE, equation=equation)%>%unlist
hist(Block_residuals, breaks=20)
rmse2 <- rmse.old(Block_residuals)
rmse2
gam2<-gam(equation, data=Data0[sel_a,])
summary(gam2)

boxplot(Block_residuals~Data0$WeekDays)

plot(Data0$Time, Block_residuals, type='l')

plot(Data0$Temp, Block_residuals, pch=16)
plot(Data0$Load.1, Block_residuals, pch=16)
plot(Data0$Load.1, Data0$Load, pch=16)


gam2.forecast<-predict(gam2,  newdata= Data0[sel_b,])
rmse2.forecast <- rmse.old(Data0[sel_b,]$Load-gam2.forecast)


#####model 3
equation <- Load~s(as.numeric(Date),k=3, bs='cr')+s(toy,k=30, bs='cc')+s(Temp,k=10, bs='cr')+
  s(Load.1, bs='cr')+as.factor(WeekDays)
Block_residuals<-lapply(block_list, blockRMSE, equation=equation)%>%unlist
rmse3 <- rmse.old(Block_residuals)
rmse3
gam3<-gam(equation, data=Data0[sel_a,])
summary(gam3)
plot(gam3, select=4)

hist(Block_residuals, breaks=20)
plot(Block_residuals,  type='l')
boxplot(Block_residuals~Data0$WeekDays)
Acf(Block_residuals)
plot(Data0$Load.7, Block_residuals, pch=16)
cor(Data0$Load.7,Block_residuals)

gam3.forecast<-predict(gam3,  newdata= Data0[sel_b,])
rmse3.forecast <- rmse.old(Data0[sel_b,]$Load-gam3.forecast)


#####model 4
equation <- Load~s(as.numeric(Date),k=3,  bs='cr')+s(toy,k=30, bs='cc')+s(Temp,k=10, bs='cr') + s(Load.1, bs='cr')+ s(Load.7, bs='cr') + as.factor(WeekDays)
Block_residuals<-lapply(block_list, blockRMSE, equation=equation)%>%unlist
rmse4 <- rmse.old(Block_residuals)
rmse4
gam4<-gam(equation, data=Data0[sel_a,])
summary(gam4)
plot(gam4)

plot(Data0$Date, Block_residuals, type='l')

boxplot(Block_residuals~Data0$BH)

boxplot(Block_residuals~Data0$Christmas_break)
boxplot(Block_residuals~Data0$Summer_break)

gam4.forecast<-predict(gam4,  newdata= Data0[sel_b,])
rmse4.forecast <- rmse.old(Data0[sel_b,]$Load-gam4.forecast)


#####model 5
equation <- Load~s(as.numeric(Date),k=3, bs='cr') + s(toy,k=30, bs='cc') + s(Temp,k=10, bs='cr') + s(Load.1, bs='cr')+ 
  s(Load.7, bs='cr') + as.factor(WeekDays) +BH
Block_residuals<-lapply(block_list, blockRMSE, equation=equation)%>%unlist
rmse5 <- rmse.old(Block_residuals)
#rmse5 <- rmse.old.old(Block_residuals)
rmse5
gam5<-gam(equation, data=Data0[sel_a,])
summary(gam5)
plot(Data0$Date, Block_residuals, type='l')

plot(Data0$Temp_s95, Block_residuals, pch=16)
test <- gam(Block_residuals~s(Data0$Temp_s95))
summary(test)

plot(Data0$Temp_s99, Block_residuals, pch=16)
test <- gam(Block_residuals~s(Data0$Temp_s99))
summary(test)

sqrt(gam5$gcv.ubre)

gam5.forecast<-predict(gam5,  newdata= Data0[sel_b,])
rmse5.forecast <- rmse.old(Data0[sel_b,]$Load-gam5.forecast)

#####model 6
equation <- Load~s(as.numeric(Date),k=3, bs='cr') + s(toy,k=30, bs='cc') + s(Temp,k=10, bs='cr') + s(Load.1, bs='cr')+ s(Load.7, bs='cr') +
  s(Temp_s99,k=10, bs='cr') + as.factor(WeekDays) +BH
Block_residuals<-lapply(block_list, blockRMSE, equation=equation)%>%unlist
rmse6 <- rmse.old(Block_residuals)
rmse6
gam6<-gam(equation, data=Data0[sel_a,])
sqrt(gam6$gcv.ubre)
summary(gam6)

plot(Data0$Date, Block_residuals, pch=16)
Acf(Block_residuals)
plot(Data0$Temp, Block_residuals, pch=16)

plot(Data0$Temp_s95_max, Block_residuals, pch=16)

test <- gam(Block_residuals~s(Data0$Temp_s95_max))
summary(test)
test <- gam(Block_residuals~s(Data0$Temp_s99_max))
summary(test)

test <- gam(Block_residuals~te(Data0$Temp_s95_max, Data0$Temp_s99_max))
summary(test)

gam6.forecast<-predict(gam6,  newdata= Data0[sel_b,])
rmse6.forecast <- rmse.old(Data0[sel_b,]$Load-gam6.forecast)

par(mfrow=c(2,2))
plot(gam6, select=c(2), scale=0, residuals=T, shade=TRUE, shade.col="pink", col='red', lwd=2, rug=F, pch=20, cex=0.01)
plot(gam6, select=3, scale=0, residuals=T, shade=TRUE, shade.col="lightblue", col='blue', lwd=2, rug=F, pch=20, cex=0.01)
plot(gam6, select=4, scale=0, residuals=T, shade=TRUE, shade.col="seagreen1", col='darkolivegreen2', lwd=2, rug=F, pch=20, cex=0.01)
plot(gam6, select=5, scale=0, residuals=T, shade=TRUE, shade.col="thistle3", col='violetred1', lwd=2, rug=F, pch=20, cex=0.01)


####################################################################################################
######################### residual correction
####################################################################################################

# transformation en time series object, frequency= preiode de serie temporelle ici hebdomadaire
Block_residuals.ts <- ts(Block_residuals, frequency=7)

# autoarima => automatique mais on peut lui donner des paramètres,p q P Q 
fit.arima.res <- auto.arima(Block_residuals.ts,max.p=3,max.q=4, max.P=2, max.Q=2, trace=T,ic="aic", method="CSS")
#Best model: ARIMA(3,0,4)(1,0,0)[7] with zero mean   
#saveRDS(fit.arima.res, "Results/tif.arima.res.RDS")

ts_res_forecast <- ts(c(Block_residuals.ts, Data0[sel_b,]$Load-gam6.forecast),  frequency= 7)
refit <- Arima(ts_res_forecast, model=fit.arima.res)
prevARIMA.res <- tail(refit$fitted, nrow(Data0[sel_b,]))

rmse6.arima <- rmse.old(fit.arima.res$residuals)

gam6.arima.forecast <- gam6.forecast + prevARIMA.res



rmse.old(Data0[sel_b,]$Load-gam6.forecast)
rmse.old(Data0[sel_b,]$Load-gam6.arima.forecast)
mape(Data0[sel_b,]$Load, gam6.arima.forecast)

rmse6.arima.forecast <- rmse.old(Data0[sel_b,]$Load-gam6.arima.forecast)


par(mfrow=c(1,2))
acf(gam6$residuals, lag.max=7*3)
pacf(gam6$residual, lag.max=7*3)


# autocorellograme residus 
# on veut voir si decroit rapidement vers 0, pas vraiment le cas ici, il reste un signal de basse fréquence qu'onb a pas bien modélisé
# dut a cross val biais de tendance ce truc => on pourrait avoir envie de differencier 
# ou on pourrait dire que c'est du bruit de fond non significatif et l'ignorer et dire qu'il y a une saisonalité dans les données d'ordre 7
# on voit vague = saisonalité => bruit de fond du a saisonalité

# autocor partielle = on aurait envuie de modeliser jusqu'a l'ordre 7

# max.p=7 maxq4 maxp 2 maxQ3
# marche bien il trouve que modèle optimal = (2 0 1) ordre 2 ordre 1 moyenne mobile (2 0 0) ordre2 pr moyenne saisonnière
# ce modèle là améliore le gam (1101 ->979) en rmse 
# bruit de fond a disparu quand on regarde les residus d'aprentissage car on a pas inclus les problème d'interpolations
# autocorr partioelle valeurs très differentes aussi

##### générer arima pour 1 an attention de bien faire (sinon correction arima ->0) 
# la bonne manière de faire (ARIMA=court terme (info recente decroit a vitesse exp par def))
# autre bonne manière = boucle 
# ts_res_forecast <- ts(c(Block_residuals.ts, Data0[sel_b,]$Load-gam6.forecast),  frequency= 7)
# refit <- Arima(ts_res_forecast, model=fit1)
# prevARIMA.res2 <- tail(refit$fitted, nrow(Data0[sel_b,]))

# modèle trop paramètre opn risque de surestimer les dependances (où ça aucune idée mais par ici dans le code)

# pas stationnaire => il faut differencier 
par(mfrow=c(1,2))
acf(Block_residuals.ts, lag.max=7*6)
pacf(Block_residuals.ts, lag.max=7*6)

# on voit que stationnaire, decroit vite vers 0, on s'est ramené à un process MA (on voudrait mettre d'ordre 2)
# il reste une partie saisonnière (pas visible dans autocorr partielle) on voit une deuxième saisonalité => mettre 2
# partie autoregressive => 3 valeurs significatives
par(mfrow=c(1,2))
acf(diff(Block_residuals.ts))
pacf(diff(Block_residuals.ts))


par(mfrow=c(1,2))
acf(diff(diff(ts), lag=52), lag.max=20)
pacf(diff(diff(ts), lag=52), lag.max=20)


fit1 <- Arima(Block_residuals.ts, order=c(7,1,2), seasonal=c(1,0,0), method=c("CSS"))
ts_res_forecast <- ts(c(Block_residuals.ts, Data0[sel_b,]$Load-gam6.forecast),  frequency= 7)
refit <- Arima(ts_res_forecast, model=fit1)
# ecart type très faible on a l'impression que tt les coeff sont significatifs 
# ar5 coeff 0.0034 sd 0.001 => coeff non significatif (sd trop grd par rapport à valeur)=> test student ou en tt cas se poser la question de l'utilité de ce coeff
# saisonnière ordre 2 n'a pas la'ir non plus significative 
# attention on peut pas forcer à 0 les coeff dans ce type de modèles 
summary(fit1)
prevARIMA.res2 <- tail(refit$fitted, nrow(Data0[sel_b,]))
gam6.arima.forecast2 <- gam6.forecast + prevARIMA.res2
rmse6.arima.forecast <- rmse.old(Data0[sel_b,]$Load-gam6.arima.forecast)
rmse6.arima.forecast
# légèrement meilleur 974 979

# ci dessus = partie modèle ARIMA permet de bien comprendre si notre modèle a été bien estimé ou pas 

# truc pvalue= pvalue test student  => on voit que 4eme et 5eme et sar2 pas significatif 
################"test de box pierce (cf photo 19fevrier )
# voir autocorrel des residus
# test significativité montre que residus modèle à l'air bruit blanc donc cool ça a marché

# qqnorm(fit1$residuals) # pas top s'éloigne un peu loi normale
# bof car variance supposé cst au cours du temps par arima alors que pas le cas 

################################################################################
##########synthèse
################################################################################

rmseCV <- c(rmse1, rmse2, rmse3, rmse4, rmse5, rmse6, rmse6.arima)
rmse.old.forecast<- c(rmse1.forecast, rmse2.forecast, rmse3.forecast, rmse4.forecast, rmse5.forecast, rmse6.forecast, 
                   rmse6.arima.forecast)
rgcv <- c(gam1$gcv.ubre, gam2$gcv.ubre, gam3$gcv.ubre, gam4$gcv.ubre, gam5$gcv.ubre, gam6$gcv.ubre)%>%sqrt
 
par(mfrow=c(1,1))
plot(rmseCV, type='b', pch=20, ylim=range(rmseCV, rmse.old.forecast))
lines(rmse.old.forecast, type='b', pch=20, col='blue')
lines(rgcv, col='red', type='b', pch=20)
points(7, rmse6.arima.forecast)
points(7, rmse6.arima)
legend("topright", col=c("red","black","blue"), c("gcv","blockCV","test"), pch=20, ncol=1, bty='n', lty=1)




################################################################################
##########NetDemand
################################################################################
#####
equation <- Net_demand ~ s(as.numeric(Date),k=3, bs='cr') + s(toy,k=30, bs='cc') + s(Temp,k=10, bs='cr') + s(Temp_s99,k=10, bs='cr') + WeekDays +BH 
gam_net0 <- gam(equation,  data=Data0[sel_a,])
summary(gam_net0)         
sqrt(gam_net0$gcv.ubre)
gam_net0.forecast<-predict(gam_net0,  newdata= Data0[sel_b,])
rmse_net0.forecast <- rmse(Data0[sel_b,]$Net_demand, gam_net0.forecast)
res <- Data0$Net_demand[sel_b] - gam_net0.forecast
quant <- qnorm(0.8, mean= mean(res), sd= sd(res))
pinball_loss(y=Data0$Net_demand[sel_b], gam_net0.forecast+quant, quant=0.8, output.vect=FALSE)


#####

equation <- Net_demand ~ s(as.numeric(Date),k=3, bs='cr') + s(toy,k=30, bs='cc') + s(Temp,k=10, bs='cr') + s(Load.1, bs='cr')+ s(Load.7, bs='cr') +
  s(Temp_s99,k=10, bs='cr') + WeekDays +BH +
  s(Wind) + s(Nebulosity)
gam_net1 <- gam(equation,  data=Data0[sel_a,])
summary(gam_net1)         
sqrt(gam_net1$gcv.ubre)
gam_net1.forecast<-predict(gam_net1,  newdata= Data0[sel_b,])
mape(Data0[sel_b,]$Net_demand, gam_net1.forecast)
rmse_net1.forecast <- rmse(Data0[sel_b,]$Net_demand, gam_net1.forecast)
res <- Data0$Net_demand[sel_b] - gam_net1.forecast
quant <- qnorm(0.8, mean= mean(res), sd= sd(res))
pinball_loss(y=Data0$Net_demand[sel_b], gam_net1.forecast+quant, quant=0.8, output.vect=FALSE)


#####
equation <- Net_demand ~ s(as.numeric(Date),k=3, bs='cr') + s(toy,k=30, bs='cc') + s(Temp,k=10, bs='cr') + s(Load.1, bs='cr')+ s(Load.7, bs='cr') +
  s(Temp_s99,k=10, bs='cr') + WeekDays +BH +
  s(Wind) + te(as.numeric(Date), Nebulosity, k=c(4,10))
gam_net2 <- gam(equation,  data=Data0[sel_a,])
summary(gam_net2)         
sqrt(gam_net2$gcv.ubre)
gam_net2.forecast<-predict(gam_net2,  newdata= Data0[sel_b,])
rmse_net2.forecast <- rmse(Data0[sel_b,]$Net_demand, gam_net2.forecast)
res <- Data0$Net_demand[sel_b] - gam_net2.forecast
quant <- qnorm(0.8, mean= mean(res), sd= sd(res))
pinball_loss(y=Data0$Net_demand[sel_b], gam_net2.forecast+quant, quant=0.8, output.vect=FALSE)


#####
equation <- Net_demand ~ s(as.numeric(Date),k=3, bs='cr') + s(toy,k=30, bs='cc') + s(Temp,k=10, bs='cr') + s(Load.1, bs='cr')+ s(Load.7, bs='cr')  +
  s(Temp_s99,k=10, bs='cr') + WeekDays +BH +
  s(Wind) + te(as.numeric(Date), Nebulosity, k=c(4,10)) +
  s(Net_demand.1, bs='cr') +  s(Net_demand.7, bs='cr')

gam_net3 <- gam(equation,  data=Data0[sel_a,])
sqrt(gam_net3$gcv.ubre)
gam_net3.forecast<-predict(gam_net3,  newdata= Data0[sel_b,])
rmse_net3.forecast <- rmse(Data0[sel_b,]$Net_demand, gam_net3.forecast)
res <- Data0$Net_demand[sel_b] - gam_net3.forecast
quant <- qnorm(0.8, mean= mean(res), sd= sd(res))
pinball_loss(y=Data0$Net_demand[sel_b], gam_net3.forecast+quant, quant=0.8, output.vect=FALSE)

mean(Data0[sel_b,]$Net_demand<gam_net3.forecast+quant)



hist(gam_net3$residuals, breaks=50)


#################gamlss
