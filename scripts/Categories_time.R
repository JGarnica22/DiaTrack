# Function to obtain ranges of glucose data,
# time of the day and time of the week of time points

Categories_time <- function(fi, sl.th = 2, # threshold for glu falling or rising fast
                            time.bf = (90*60), #time analysis before event in minutes (1.5h)
                            time.af = (180*60)){ # time analysis after event in minuts (3h))
  fi <- fi %>% 
    arrange(time) %>% 
    mutate(Range = ifelse(glucose<55, "Very low",
                          ifelse(glucose<low, "Low",
                                 ifelse(glucose>=low &
                                          glucose< high, "In range",
                                        ifelse(glucose>=high &
                                                 glucose<= 240, "High",
                                               "Very high")))),
           Range = factor(Range,
                          levels=c("Very low", "Low",
                                   "In range", "High", "Very high")),
           time= as_datetime(lubridate::force_tz(lubridate::ymd_hms(time),
                                                 Sys.timezone()),
                             tz = Sys.timezone())
    )
  
  # premeal, postmeal or outmeal
  fi$meal_factor <- "outmeal"
  fi$mealtime <- NA
  i <- 1
  while(i <= nrow(fi)){
    if(!is.na(fi[i, "slope"])){
      if(fi[i, "slope"] > sl.th){
        fi[i,"meal_factor"] <- "meal"
        fi[i, "mealtime"] <- 0
        tb <- fi[i,"time"]
        fi[fi$time > (tb - time.bf) & fi$time < tb, "meal_factor"] <- "premeal"
        fi[fi$time > (tb - time.bf) & fi$time < tb, "mealtime"] <-
          (fi[fi$time > (tb - time.bf) & fi$time < tb, "time"] - tb)
        fi[fi$time < (tb + time.af) & fi$time > tb, "meal_factor"] <- "postmeal"
        fi[fi$time < (tb + time.af) & fi$time > tb, "mealtime"] <-
          (fi[fi$time < (tb + time.af) & fi$time > tb, "time"] - tb)
        i <- max(which(fi$time < (tb + time.af)))
      }
    }
    i <- i+1
  }
 
  
  # day of the week
  Sys.setlocale("LC_TIME", "English") # output weekdays in english
  fi <- fi %>% 
    mutate(weekday = factor(weekdays(fi$time),
                            levels=c("Monday", "Tuesday",
                                     "Wednesday", "Thursday",
                                     "Friday", "Saturday",
                                     "Sunday")),
           # time of day morning, midday, afternoon, evening, night
           timehour = as.numeric(format(fi$time, "%H")),
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
                                     "evening","night")),
           # Risk
           risk = 10*(1.509 * (log(glucose)^1.084 - 5.381))
    )
  
  
  return(fi)
}