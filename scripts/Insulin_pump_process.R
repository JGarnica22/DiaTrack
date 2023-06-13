library(tidyverse)
library(lubridate)
library(foreach)
library(doParallel)
source("scripts/Insulin_plasma.R")

# Load and process Insulin pump data

Insulin_process <- function(ins_path){
  if(insulin_source == "MiniMed"){
  ins <- read.csv2(ins_path, skip = 6, header = T) %>% 
    replace(.=="",NA) %>% 
    mutate(Index = as.numeric(Index),
           time2 = as_datetime(
             lubridate::force_tz(lubridate::ymd_hms(paste(Date, Time)),
                                 Sys.timezone()),
             tz = Sys.timezone()),
           time2 = floor_date(time2, "minute")) %>% 
    filter(!is.na(Index)) %>% 
    dplyr::select(-Index)
  
  # split dataset into bolus and basal data
  bas <- c("Basal.Rate..U.h.","Temp.Basal.Amount",
           "Temp.Basal.Type","Temp.Basal.Duration..h.mm.ss.")
  Basal <- ins[,c("time2", bas)] %>% rename(time = "time2")
  
  bol <- c("Bolus.Volume.Delivered..U.","Bolus.Type",
           "Bolus.Duration..h.mm.ss.")
  bolus <- ins[,c("time2", bol)] %>% rename(time = "time2") %>% 
    filter(!is.na(Bolus.Volume.Delivered..U.))
  }
  ##  define period to analyse
  from <- as_datetime(lubridate::force_tz(lubridate::ymd_hms(paste(from, "00:00:00")),
                                          Sys.timezone()),
                      tz = Sys.timezone())
  to <- as_datetime(lubridate::force_tz(lubridate::ymd_hms(paste(to, "00:00:00")),
                                        Sys.timezone()),
                    tz = Sys.timezone())
  
  time_range <- seq(from,to, 60) # create a dataset in minute sequence
  comb00 <- data.frame(time = time_range)
  comb0 <- comb00 %>% arrange(time) %>%
    mutate(
      Bolus_type = NA,
      Injec_bolus = 0, # Bolus delivered
    )
  
  # bolus insulin
  narows <- bolus[,-1] %>% 
    is.na() %>% 
    {rowSums(.) == ncol(.)}
  bolus <- bolus[narows == F,]
  comb <- left_join(comb0, bolus, by="time") %>% arrange(time)
  i <- 1
  bs <- NA
  while(i <= nrow(comb)){
    if (comb[i,"Bolus.Volume.Delivered..U."] == "" |
        is.null(comb[i,"Bolus.Volume.Delivered..U."]) |
        is.na(comb[i,"Bolus.Volume.Delivered..U."])){
      i <- i + 1 
    }
    else if(grepl("normal", comb[i,"Bolus.Type"], ignore.case = T)){
      comb[i,"Injec_bolus"] <- as.numeric(comb[i,"Bolus.Volume.Delivered..U."]) +
        comb[i,"Injec_bolus"]
      comb[i,"Bolus_type"] <- "Normal"
      i <- i + 1
    } else if(grepl("square", comb[i,"Bolus.Type"], ignore.case = T)){
      comb[i,"Bolus_type"] <- "End_Square"
      m <- hms(comb[i,]$Bolus.Duration..h.mm.ss.)
      m <- hour(m)*60 + minute(m)
      bsquare <- as.numeric(comb[i,"Bolus.Volume.Delivered..U."])/m
      for(o in 1:m){
        o <- i - o
        comb[o, "Injec_bolus"] <- comb[o, "Injec_bolus"] + bsquare
      }
      if(is.na(comb[o,"Bolus_type"])){
        comb[o,"Bolus_type"] <- "Start_Square"
      } else {comb[o+1,"Bolus_type"] <- "Start_Square"}
      i <- i +1
    }
    
  }
  
  comb_bolus <- comb %>% 
    dplyr::select(time, Bolus_type, Injec_bolus) %>% 
    distinct()

  
  # basal insulin
  comb0 <- comb00 %>% mutate(
    Action = NA, # Bolus, type of bolus, change reservoir
    Basal_rate = NA, # Basal rate/h
    Injec_basal = NA) # Basal insulin administered
  
  
  narows <- Basal[,-1] %>% 
    is.na() %>% 
    {rowSums(.) == ncol(.)}
  Basal <- Basal[narows == F,]
  comb <- left_join(comb0, Basal, by="time") %>% arrange(time) %>% 
    distinct()
  
  
  i <- 1
  bs <- NA
  while(i <= nrow(comb)){
    if((is.na(comb[i,"Basal.Rate..U.h."])|is.null(comb[i,"Basal.Rate..U.h."]))&
       is.na(comb[i,"Temp.Basal.Amount"]) == T){
      comb[i, "Basal_rate"] <- bs
      i <- i + 1
    } else if ((comb[i,"Temp.Basal.Amount"] == "" | is.na(comb[i,"Temp.Basal.Amount"]))&
               !is.na(comb[i,"Basal.Rate..U.h."]) == T){
      bs <- as.numeric(comb[i,"Basal.Rate..U.h."])
      comb[i, "Basal_rate"] <- bs
      i <- i+1
    } else if(comb[i,"Temp.Basal.Type"] == "Rate"){
      bst <- comb[i, "Temp.Basal.Amount"]
      m <- hms(comb[i,]$Temp.Basal.Duration..h.mm.ss.)
      m <- hour(m)*60 + minute(m)
      comb[i, "Action"] <- "Temporal_basal_start"
      for(o in 1:m){
        comb[i, "Basal_rate"] <- as.numeric(bst)
        i <- i + 1
        if(i > nrow(comb)){break}
      }
      comb[i, "Action"] <- "Temporal_basal_end"
    } else if(comb[i,"Temp.Basal.Type"] == "Percent"){
      m <- hms(comb[i,]$Temp.Basal.Duration..h.mm.ss.)
      m <- hour(m)*60 + minute(m)
      comb[i, "Action"] <- "Temporal_basal_start"
      f <- as.numeric(comb[i,"Temp.Basal.Amount"])/100
      bst <- f*as.numeric(comb[i-2,"Basal_rate"])
      for(o in 1:m){
        if(is.na(comb[i,"Basal.Rate..U.h."])){
          bst <- bst
        } else{
          bst <- f*as.numeric(comb[i,"Basal.Rate..U.h."])
        }
        comb[i, "Basal_rate"] <- as.numeric(bst)
        i <- i + 1
        if(i > nrow(comb)){break}
      }
      comb[i, "Action"] <- "Temporal_basal_end"
    }
  }
  
  comb_basal <- comb %>% 
    dplyr::select(time, Action, Basal_rate, Injec_basal) %>% 
    distinct() %>% 
    filter(!is.na(Basal_rate)) %>% 
    mutate(Injec_basal = Basal_rate/60)
  
  # join bolus and basal data
  tins <- full_join(comb_bolus, comb_basal, by="time") %>% distinct() %>% 
    filter(!is.na(time))
  
  print("Processing of insulin data completed")
  print("Starting insulin in plasma estimation")
  #############################################################
  # Estimate insulin in plasma

  nr <- which(tins$Injec_bolus > 0)
  names(nr) <- seq(1:length(nr))

  workers <- detectCores()-1
  cluster <- makeCluster(workers) 
  registerDoParallel(cluster)

  temp_bolus <- foreach(i = 1:length(nr)) %dopar% {
    bolus <- tins[nr[i],"Injec_bolus"]
    datetime <- tins[nr[i], "time"]
    source("scripts/Insulin_plasma.R")
    t <- iob(bolus, datetime)
  }
  stopCluster(cluster)
  
  res <- data.table::rbindlist(temp_bolus)
  
  temp_bolus <- res %>% group_by(time) %>% 
    summarize(Bolus_ActI = sum(actI))
  tins <- left_join(tins, temp_bolus, by="time")

  nr <- which(tins$Injec_basal > 0)
  names(nr) <- seq(1:length(nr))
  
  workers <- detectCores()-1
  cluster <- makeCluster(workers) 
  registerDoParallel(cluster)
  
  temp_basal <- foreach(i = 1:length(nr)) %dopar% {
    ba <- tins[nr[i],"Injec_basal"]
    datetime <- tins[nr[i], "time"]
    source("scripts/Insulin_plasma.R")
    t <- iob(ba, datetime)
    
  }
  stopCluster(cluster)

  res <- data.table::rbindlist(temp_basal)
  
  temp_basal <- res %>% group_by(time) %>% 
    summarize(Basal_ActI = sum(actI))
  tins <- left_join(tins, temp_basal, by="time")
  tins[is.na(tins$Bolus_ActI),"Bolus_ActI"] <- 0
  tins <- tins %>% mutate(Total_ActI=Bolus_ActI+Basal_ActI)
  
  return(tins)
}