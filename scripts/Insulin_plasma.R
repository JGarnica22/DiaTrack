library(tidyverse)
library(lubridate)

# Estimation of insulin in plasma function

insulin_duration <- 6*60 # 5 hours of duration
delay <- 7.6 # delay in first compartment, t
abs1 <- 0.0034 # absorbance rate from compartment 1 to plasma, ka1
abs2 <- 0.028 # absorbance rate from compartment 1 to 2, kd
abs3 <- 0.014 # absorbance rate from compartment 2 to plasma ka2
clear <- 0.124 # plasma clearance, ke
V1 <- 0.126 # L/kg
time_fractions <- 1

# precompute repeated calculations
abs1_abs2_tf <- (abs1 + abs2)*time_fractions
abs1_tf <- abs1 * time_fractions
abs3_tf <- abs3 * time_fractions
abs2_tf <- abs2 * time_fractions
clear_tf <- clear* time_fractions
start_plasma <- ceiling(delay)
time_after_bolus <- seq(0, insulin_duration, by = time_fractions)

iob <- function(bolus, datetime){
  
  time <- seq(datetime, datetime+insulin_duration*60, by=time_fractions*60)
  ins1 <- numeric(length(time_after_bolus))
  ins2 <- numeric(length(time_after_bolus))
  insP <- numeric(length(time_after_bolus))
  
  # initialize values until delay
  ins1[1:(start_plasma-1)] <- bolus
  ins2[1:(start_plasma-1)] <- 0
  insP[1:(start_plasma-1)] <- 0
  
  for(i in start_plasma:length(time_after_bolus)){    
    ins1[i] <- -abs1_abs2_tf*ins1[i-1] + ins1[i-1]
    ins2[i] <- -abs3_tf*ins2[i-1]+
      abs2_tf*ins1[i-1] + ins2[i-1]
    insP[i] <- -clear_tf*insP[i-1] +
      abs1_tf*ins1[i-1] +
      abs3_tf*ins2[i-1] + insP[i-1]
  }
  
  dfn <- data.frame(time = time, actI=insP/V1)
  
  
  return(dfn)
}