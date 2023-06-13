library(tidyverse)
library(lubridate)

# Load and process CGM data
CGM_process <- function(glupath){
  # Process xDrip or Freestyle CGM data into Posict format
  # also remove NAs
  if (glucose_source == "freestyle"){
    #Import freestyle
    #Start with a raw CSV file, as downloaded from the [Libreview](https://libreview.com) web application
    #Load data
    freestyler <- read.csv(glu_path, skip = 1)
    #keep only date, time and glucose (mg.dL)
    libre_raw <- freestyler[,c("Device.Timestamp","Historic.Glucose.mg.dL")]
    libre_raw <- na.omit(libre_raw)
    libre_raw$Device.Timestamp <- lubridate::force_tz(lubridate::dmy_hm(libre_raw$Device.Timestamp),
                                                      Sys.timezone())
    libre_raw$Device.Timestamp <- as_datetime(libre_raw$Device.Timestamp,
                                              tz = Sys.timezone())
    glucose <- data.frame(time=as_datetime(libre_raw$Device.Timestamp),
                          glucose=libre_raw$Historic.Glucose.mg.dL)
    glucose <- glucose %>% filter(!is.na(glucose))
  } else if (glucose_source == "xdrip"){
    xdrip <- read.csv(glu_path, sep = ";")
    glucose <- data.frame(time=paste(xdrip$DAY, xdrip$TIME),
                          glucose = xdrip$UDT_CGMS)
    glucose$time <- lubridate::force_tz(lubridate::dmy_hm(glucose$time),
                                        Sys.timezone())
    glucose$time <- as_datetime(glucose$time, tz = Sys.timezone())
    glucose <- glucose %>% filter(!is.na(glucose))
  } 
  
  # Compute glucose slope between time points
  glucose$slope <- NA
  for(i in 2:nrow(glucose)){
    glucose[i,"slope"] <- (glucose[i,"glucose"] - glucose[(i-1),"glucose"])/
      as.numeric(glucose[i,"time"] - glucose[(i-1),"time"])
  }
  
  glucose$slope15 <- NA
  i <- 4
  while(i <= nrow(glucose)){
    glucose[i,"slope15"] <- (glucose[i,"glucose"] - glucose[(i-3),"glucose"])/
      as.numeric(glucose[i,"time"] - glucose[(i-3),"time"])
    i <- i + 3
  }
  
  return(glucose)
}