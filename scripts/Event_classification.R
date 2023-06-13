library(tidyverse)
library(lubridate)

# Classify events
# Create a new dataframe with the events in this period of time

vars <- c("Event_type", 
          "start", "end",
          "Event_subtype","extreme.value", "AUC_out_range",
          "Total_slope", "Diff_bolus", "Bolus_ActI",
          "Basal_ActI", "Total_ActI", "N_bolus", "Overcorrection")
events <- data.frame(matrix(nrow=0, ncol=length(vars)))
names(events) <- vars

# Classify events with integrated object of CGM and insulin data
Event_classification <- function(fi,
                                 sl.th = 2, # threshold for glu falling or rising fast
                                 time.bf = (90*60), #time analysis before event in minutes (1.5h)
                                 time.af = (180*60) # time analysis after event in minuts (3h)
                                 ) {
  #discard first values as we cannot get before data
  s <- min(fi$time) + time.bf
  loo <- which(fi$time > s & !is.na(fi$glucose))
  o <- 1
  done <- c()
  for(i in loo){
    if(!i %in% done){
      if(fi[i, "slope"] > sl.th){
        events[o,"Event_type"] <- "Meal"
        start <- fi[i, "time"]-time.bf
        end <- fi[i, "time"]+time.af
        events[o,"start"] <- start
        events[o,"end"] <- end
        # create temp dataframe with data
        tmp <- fi[fi$time >= start & fi$time <= end,]
        # distance with bolus
        earliest_bolus_time <- min(tmp$time[!is.na(tmp$Bolus_type)])
        events[o,"Diff_bolus"] <- abs(as.numeric(difftime(fi[i, "time"],
                                                          earliest_bolus_time,
                                                          units= "mins")))
        events[o, "N_bolus"] <- nrow(tmp[!is.na(tmp$Bolus_type),])
        
        if(length(tmp$glucose[tmp$glucose > high & !is.na(tmp$glucose)])>3){
          events[o,"Event_subtype"] <- "Hyperglycemia"
          out_thres <- which(tmp$glucose > high)
          #highest value
          extrem <- max(tmp$glucose[!is.na(tmp$glucose)])
          extrem_time <- min(tmp[tmp$glucose == extrem &
                                   !is.na(tmp$glucose),"time"])
          events[o, "extreme.value"] <- extrem
          
          # Total slope
          time_prev_max <- tmp %>% dplyr::filter(!is.na(glucose)) %>% 
            dplyr::filter(glucose < high) %>% 
            dplyr::filter(time < extrem_time) %>% 
            dplyr::pull(time) %>%  max()
          sslope <- min(tmp[tmp$time > start &
                              tmp$time < time_prev_max &
                              !is.na(tmp$glucose),"glucose"])
          difslope <- as.numeric(difftime(time_prev_max,
                                          min(tmp$time[tmp$glucose == sslope &
                                                         !is.na(tmp$glucose)]),
                                          units= "mins"))
          events[o, "Total_slope"] <- (events[o, "extreme.value"] - sslope) / 
            difslope
          
          time <- as.numeric(difftime(tmp$time[out_thres],
                                      tmp$time[out_thres][1],
                                      units="mins"))
          glu <- tmp$glucose[out_thres]
          glu <- ifelse(glu > high,
                        abs(glu - high),
                        0)
          interp <- approx(time, glu)
          auc <- DescTools::AUC(interp$x, interp$y)
          events[o, "AUC_out_range"] <- auc
          #ovecorrection
          if(length(tmp$glucose[tmp$glucose < low & !is.na(tmp$glucose)])>3){
            events[o,"Overcorrection"] <- "Yes"
          }
          
          # Active insulin
          if(!is.finite(time_prev_max)){
            for(a in c("Bolus_ActI",
                       "Basal_ActI", "Total_ActI")){
              events[o,a] <- tmp[tmp$glucose > high, a][1]
            }
          } else {
            for(a in c("Bolus_ActI",
                       "Basal_ActI", "Total_ActI")){
              events[o,a] <- tmp[tmp$time == time_prev_max, a][1]
            }
          }
          
        } else if(length(tmp$glucose[tmp$glucose < low & !is.na(tmp$glucose)])>3){
          events[o,"Event_subtype"] <- "Hypoglycemia"
          out_thres <- which(tmp$glucose < low)
          #lowest value
          extrem <- min(tmp$glucose[!is.na(tmp$glucose)])
          extrem_time <- min(tmp[tmp$glucose == extrem &
                                   !is.na(tmp$glucose),"time"])
          events[o, "extreme.value"] <- extrem
          
          # Total slope
          time_prev_max <- tmp %>% dplyr::filter(!is.na(glucose)) %>% 
            dplyr::filter(glucose > low) %>% 
            dplyr::filter(time < extrem_time) %>% 
            dplyr::pull(time) %>%  min()
          sslope <- min(tmp[tmp$time > start &
                              tmp$time < time_prev_max &
                              !is.na(tmp$glucose),"glucose"])
          difslope <- as.numeric(difftime(time_prev_max,
                                          min(tmp[tmp$glucose == sslope &
                                                    !is.na(tmp$glucose), "time"]),
                                          units= "mins"))
          events[o, "Total_slope"] <- (events[o, "extreme.value"] - sslope) / 
            difslope
          
          time <- as.numeric(difftime(tmp$time[out_thres],
                                      tmp$time[out_thres][1],
                                      units="mins"))
          glu <- tmp$glucose[out_thres]
          glu <- ifelse(glu < low,
                        abs(glu - low),
                        0)
          interp <- approx(time, glu)
          auc <- DescTools::AUC(interp$x, interp$y)
          events[o, "AUC_out_range"] <- auc
          #ovecorrection
          if(length(tmp$glucose[tmp$glucose > high & !is.na(tmp$glucose)])>3){
            events[o,"Overcorrection"] <- "Yes"
          }
          # Active insulin
          if(!is.finite(time_prev_max)){
            for(a in c("Bolus_ActI",
                       "Basal_ActI", "Total_ActI")){
              events[o,a] <- tmp[tmp$glucose < low, a][1]
            }
          } else {
            for(a in c("Bolus_ActI",
                       "Basal_ActI", "Total_ActI")){
              events[o,a] <- tmp[tmp$time == time_prev_max, a][1]
            }
          }
          
        } else {
          events[o,c("extreme.value", "AUC_out_range",
                     "Total_slope", "Diff_bolus")] <- NA
          events[o,"Event_subtype"] <- "Normoglycemia"
        }
        done <- append(done, as.numeric(rownames(tmp)))
        o <- o +1
      }
    }
  }
  
  for(i in loo[!loo %in% done]){
    if(!i %in% done){
      if(length(fi[i:(i+4), "glucose"][fi[i:(i+4), "glucose"] > high &
                                        !is.na(fi[i:(i+4), "glucose"])])>3){
        events[o,"Event_type"] <- "No_Meal"
        start <- fi[i, "time"]-time.bf
        end <- fi[i, "time"]+time.af
        events[o,"start"] <- start
        events[o,"end"] <- end
        # create temp dataframe with data
        tmp <- fi[fi$time >= start & fi$time <= end,]
        # distance with bolus
        earliest_bolus_time <- min(tmp[!is.na(tmp$Bolus_type), "time"])
        events[o,"Diff_bolus"] <- abs(as.numeric(difftime(fi[i, "time"],
                                                          earliest_bolus_time,
                                                          units= "mins")))
        events[o, "N_bolus"] <- nrow(tmp[!is.na(tmp$Bolus_type),])
        events[o,"Event_subtype"] <- "Hyperglycemia"
        out_thres <- which(tmp$glucose > high)
        #highest value
        extrem <- max(tmp$glucose[!is.na(tmp$glucose)])
        extrem_time <- min(tmp[tmp$glucose == extrem &
                                 !is.na(tmp$glucose),"time"])
        events[o, "extreme.value"] <- extrem
        
        # Total slope
        time_prev_max <- tmp %>% dplyr::filter(!is.na(glucose)) %>% 
          dplyr::filter(glucose < high) %>% 
          dplyr::filter(time < extrem_time) %>% 
          dplyr::pull(time) %>%  max()
        sslope <- min(tmp[tmp$time > start &
                            tmp$time < time_prev_max &
                            !is.na(tmp$glucose),"glucose"])
        difslope <- as.numeric(difftime(time_prev_max,
                                        min(tmp[tmp$glucose == sslope &
                                                  !is.na(tmp$glucose), "time"]),
                                        units= "mins"))
        events[o, "Total_slope"] <- (events[o, "extreme.value"] - sslope) / 
          difslope
        
        time <- as.numeric(difftime(tmp$time[out_thres],
                                    tmp$time[out_thres][1],
                                    units="mins"))
        glu <- tmp$glucose[out_thres]
        glu <- ifelse(glu > high,
                      abs(glu - high),
                      0)
        interp <- approx(time, glu)
        auc <- DescTools::AUC(interp$x, interp$y)
        events[o, "AUC_out_range"] <- auc
        if(length(fi[i:(i+4), "glucose"][fi[i:(i+4), "glucose"] < low &
                                          !is.na(fi[i:(i+4), "glucose"])])>3){
          events[o, "Overcorrection"] <- "Yes"
        }
        
        # Active insulin
        if(!is.finite(time_prev_max)){
          for(a in c("Bolus_ActI",
                     "Basal_ActI", "Total_ActI")){
            events[o,a] <- tmp[tmp$glucose > high, a][1]
          }
        } else {
          for(a in c("Bolus_ActI",
                     "Basal_ActI", "Total_ActI")){
            events[o,a] <- tmp[tmp$time == time_prev_max, a][1]
          }
        }
        done <- append(done, as.numeric(rownames(tmp)))
        o <- o +1
      } else if(length(fi[i:(i+4), "glucose"][fi[i:(i+4), "glucose"] < low &
                                               !is.na(fi[i:(i+4), "glucose"])])>3){
        events[o,"Event_type"] <- "No_Meal"
        start <- fi[i, "time"]-time.bf
        end <- fi[i, "time"]+time.af
        events[o,"start"] <- start
        events[o,"end"] <- end
        # create temp dataframe with data
        tmp <- fi[fi$time >= start & fi$time <= end,]
        # distance with bolus
        earliest_bolus_time <- min(tmp[!is.na(tmp$Bolus_type), "time"])
        events[o,"Diff_bolus"] <- abs(as.numeric(difftime(fi[i, "time"],
                                                          earliest_bolus_time,
                                                          units= "mins")))
        events[o, "N_bolus"] <- nrow(tmp[!is.na(tmp$Bolus_type),])
        events[o,"Event_subtype"] <- "Hypoglycemia"
        out_thres <- which(tmp$glucose < low)
        #lowest value
        extrem <- min(tmp$glucose[!is.na(tmp$glucose)])
        extrem_time <- min(tmp[tmp$glucose == extrem &
                                 !is.na(tmp$glucose),"time"])
        events[o, "extreme.value"] <- extrem
        
        # Total slope
        time_prev_max <- tmp %>% dplyr::filter(!is.na(glucose)) %>% 
          dplyr::filter(glucose > low) %>% 
          dplyr::filter(time < extrem_time) %>% 
          dplyr::pull(time) %>%  min()
        sslope <- min(tmp[tmp$time > start &
                            tmp$time < time_prev_max &
                            !is.na(tmp$glucose),"glucose"])
        difslope <- as.numeric(difftime(time_prev_max,
                                        min(tmp[tmp$glucose == sslope &
                                                  !is.na(tmp$glucose), "time"]),
                                        units= "mins"))
        events[o, "Total_slope"] <- (events[o, "extreme.value"] - sslope) / 
          difslope
        
        time <- as.numeric(difftime(tmp$time[out_thres],
                                    tmp$time[out_thres][1],
                                    units="mins"))
        glu <- tmp$glucose[out_thres]
        glu <- ifelse(glu < low,
                      abs(glu - low),
                      0)
        interp <- approx(time, glu)
        auc <- DescTools::AUC(interp$x, interp$y)
        events[o, "AUC_out_range"] <- auc
        if(length(fi[i:(i+4), "glucose"][fi[i:(i+4), "glucose"] > high &
                                          !is.na(fi[i:(i+4), "glucose"])])>3){
          events[o, "Overcorrection"] <- "Yes"
        }
        
        # Active insulin
        if(!is.finite(time_prev_max)){
          for(a in c("Bolus_ActI",
                     "Basal_ActI", "Total_ActI")){
            events[o,a] <- tmp[tmp$glucose < low, a][1]
          }
        } else {
          for(a in c("Bolus_ActI",
                     "Basal_ActI", "Total_ActI")){
            events[o,a] <- tmp[tmp$time == time_prev_max, a][1]
          }
        }
        done <- append(done, as.numeric(rownames(tmp)))
        o <- o +1
      }
      
    }
  }
  
  events$Total_ActI <- ifelse(is.na(events$Total_ActI),
                              events$Basal_ActI,
                              events$Total_ActI)
  events$Overcorrection[is.na(events$Overcorrection)] <- "No"
  
  #############################################################################
  # time of the day and time of the week of time points events
  Sys.setlocale("LC_TIME", "English") # output weekdays in english
  events <- events %>% 
    mutate(start = as_datetime(start,tz = Sys.timezone()),
           end = as_datetime(end,tz = Sys.timezone()),
           weekday = factor(weekdays(start),
                            levels=c("Monday", "Tuesday",
                                     "Wednesday", "Thursday",
                                     "Friday", "Saturday",
                                     "Sunday")
                            ),
           # time of day morning, midday, afternoon, evening, night
           timehour = as.numeric(format(start, "%H")),
           timeday = ifelse(timehour >= morning[1] & timehour <= morning[2],
                            "morning",
                            ifelse(timehour >= midday[1] & timehour <= midday[2],
                                   "midday",
                                   ifelse(timehour >= afternoon[1] & timehour <= afternoon[2],
                                          "afternoon",
                                          ifelse(timehour >= evening[1] & timehour <= evening[2],
                                                 "evening",
                                                 ifelse(timehour >= nigth[1] & timehour <= nigth[2],
                                                        "night", NA)
                                          )))),
           timeday = factor(timeday,
                            levels=c("morning","midday", "afternoon",
                                     "evening","night")))

return(events)

}