# Events summarize 
##  define period to analyse


Summary_diabetes_measures <- function(glucose, fi, events){
  # define time range
  from <- as_datetime(lubridate::force_tz(lubridate::ymd_hms(paste(from, "00:00:00")),
                                          Sys.timezone()),
                      tz = Sys.timezone())
  to <- as_datetime(lubridate::force_tz(lubridate::ymd_hms(paste(to, "00:00:00")),
                                        Sys.timezone()),
                    tz = Sys.timezone())
  ## Sensor coverage and days of analyssis
  sensor_not_coverage <- 0
  for(i in 2:nrow(glucose)){
    if(!is.na(glucose[i-1,"glucose"]-glucose[i,"glucose"])){
      d <- abs(as.numeric(glucose[i-1,"time"]-glucose[i,"time"]))
      if(!is.na(d)){
        if(d>5){
          sensor_not_coverage <- sensor_not_coverage + (d-5)
        }
      }
    }
  }
  sensor_coverage <-  round(100*(as.numeric(to - from)*24 - sensor_not_coverage/60)/
                              (as.numeric(to - from)*24),1)
  N_days_analysis <- floor(as.numeric(to - from))
  
  df1 <- data.frame(Stat=c("Days of analysis", "Sensor coverage"),
                    Value=c(N_days_analysis, sensor_coverage))
  #############################################################################
  ## summarize values
  glu.mes.global <-
    fi %>%
    summarize(`SG mean & SD` = paste0(round(mean(glucose,na.rm = T),1),
                                      " \u00B1 ",
                                      round(sd(glucose, na.rm=T),1)),
              `SG mean & SD (premeal)` = paste0(round(mean(glucose[meal_factor == "premeal"],
                                                           na.rm = T),1),
                                                " \u00B1 ",
                                                round(sd(glucose[meal_factor == "premeal"],
                                                         na.rm=T),1)),
              `SG mean & SD (postmeal)` = paste0(round(mean(glucose[meal_factor == "postmeal"],
                                                            na.rm = T),1),
                                                 " \u00B1 ",
                                                 round(sd(glucose[meal_factor == "postmeal"],
                                                          na.rm=T),1)),
              `SG mean & SD (outmeal)` = paste0(round(mean(glucose[meal_factor == "outmeal"],
                                                           na.rm = T),1),
                                                " \u00B1 ",
                                                round(sd(glucose[meal_factor == "outmeal"],
                                                         na.rm=T),1)),
              CV = round(sd(glucose, na.rm=T)/mean(glucose,na.rm = T) * 100,2),
              `CV (premeal)` = round(sd(glucose[meal_factor == "premeal"], na.rm=T)/
                                       mean(glucose[meal_factor == "premeal"],na.rm = T) * 100,2),
              `CV (postmeal)` = round(sd(glucose[meal_factor == "postmeal"], na.rm=T)/
                                        mean(glucose[meal_factor == "postmeal"],na.rm = T) * 100,2),
              `CV (outmeal)` = round(sd(glucose[meal_factor == "outmeal"], na.rm=T)/
                                       mean(glucose[meal_factor == "outmeal"],na.rm = T) * 100,2),
              GMI = round(3.31+0.02392*mean(glucose,na.rm = T),2),
              
              BGRI = round(mean(risk[risk < 0],na.rm = T),1)+
                round(mean(risk[risk > 0],na.rm = T),1),
              LBGI = paste0(-round(mean(risk[risk < 0],na.rm = T),1),
                            " \u00B1 ",
                            round(sd(risk[risk < 0],na.rm = T),1)),
              `CV LBGI` = round(sd(risk[risk < 0],na.rm = T)/
                                  -mean(risk[risk < 0],na.rm = T) * 100,2),
              HBGI = paste0(round(mean(risk[risk > 0],na.rm = T),1),
                            " \u00B1 ",
                            round(sd(risk[risk > 0],na.rm = T),1)),
              `CV HBGI` = round(sd(risk[risk > 0],na.rm = T)/
                                  mean(risk[risk > 0],na.rm = T) * 100,2),
              `BGRI (premeal)` = round(mean(risk[risk < 0 & meal_factor == "premeal"],
                                            na.rm = T),1)+
                round(mean(risk[risk > 0 & meal_factor == "premeal"],na.rm = T),1),
              `LBGI (premeal)` = paste0(-round(mean(risk[risk < 0 & meal_factor == "premeal"],
                                                    na.rm = T),1),
                                        " \u00B1 ",
                                        round(sd(risk[risk < 0 & meal_factor == "premeal"],na.rm = T),1))
              ,
              `HBGI (premeal)` = paste0(round(mean(risk[risk > 0 & meal_factor == "premeal"],
                                                   na.rm = T),1),
                                        " \u00B1 ",
                                        round(sd(risk[risk > 0 & meal_factor == "premeal"],na.rm = T),1)),
              `BGRI (postmeal)` = round(mean(risk[risk < 0 & meal_factor == "postmeal"],
                                             na.rm = T),1)+
                round(mean(risk[risk > 0 & meal_factor == "postmeal"],na.rm = T),1),
              `LBGI (postmeal)` = paste0(-round(mean(risk[risk < 0 & meal_factor == "postmeal"],
                                                     na.rm = T),1),
                                         " \u00B1 ",
                                         round(sd(risk[risk < 0 & meal_factor == "postmeal"],na.rm = T),1))
              ,
              `HBGI (postmeal)` = paste0(round(mean(risk[risk > 0 & meal_factor == "postmeal"],
                                                    na.rm = T),1),
                                         " \u00B1 ",
                                         round(sd(risk[risk > 0 & meal_factor == "postmeal"],na.rm = T),1)),
              `BGRI (outmeal)` = round(mean(risk[risk < 0 & meal_factor == "outmeal"],
                                            na.rm = T),1)+
                round(mean(risk[risk > 0 & meal_factor == "outmeal"],na.rm = T),1),
              `LBGI (outmeal)` = paste0(-round(mean(risk[risk < 0 & meal_factor == "outmeal"],
                                                    na.rm = T),1),
                                        " \u00B1 ",
                                        round(sd(risk[risk < 0 & meal_factor == "outmeal"],na.rm = T),1))
              ,
              `HBGI (outmeal)` = paste0(round(mean(risk[risk > 0 & meal_factor == "outmeal"],
                                                   na.rm = T),1),
                                        " \u00B1 ",
                                        round(sd(risk[risk > 0 & meal_factor == "outmeal"],na.rm = T),1)),
              `SD Rate of Change (RoC)` = round(sd(slope, na.rm=T),2),
              `% offvalues [-2,2] RoC` = 100*round((length(slope[slope>quan95(slope) &
                                                                   !is.na(slope)]) +
                                                      length(slope[slope<quan5(slope)&
                                                                     !is.na(slope)])) /
                                                     length(slope[!is.na(slope)]),3),
              `Time in range` = round(100*length(Range[Range == "In range"&
                                                         !is.na(Range)])/
                                        length(Range[!is.na(Range)]),1),
              `Time in hyperglycemia` = round(100*length(Range[Range == "High"&
                                                                 !is.na(Range)])/
                                                length(Range[!is.na(Range)]),1),
              `Time in extreme hyperglycemia` = round(100*length(Range[Range == "Very high"&
                                                                         !is.na(Range)])/
                                                        length(Range[!is.na(Range)]),1),
              `Time in hypoglycemia` = round(100*length(Range[Range == "Low"&
                                                                !is.na(Range)])/
                                               length(Range[!is.na(Range)]),1),
              `Time in extreme hypoglycemia` = round(100*length(Range[Range == "Very low"&
                                                                        !is.na(Range)])/
                                                       length(Range[!is.na(Range)]),1),
    ) %>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column("Stat") %>% rename(Value="V1")
  
  df1 <- rbind(df1, glu.mes.global)
  
  ##########################################################################
  # Summarize by the day of the week and time day
  timeday <- fi %>% group_by(timeday) %>% 
    summarize(TIR = length(Range[Range == "In range" & !is.na(Range)])/
                length(Range[!is.na(Range)]),
              HBGI = round(mean(risk[risk > 0],na.rm = T),4),
              LBGI = -round(mean(risk[risk < 0],na.rm = T),4)
    )
  weekday <- fi %>% group_by(weekday) %>% 
    summarize(TIR = length(Range[Range == "In range" & !is.na(Range)])/
                length(Range[!is.na(Range)]),
              HBGI = round(mean(risk[risk > 0],na.rm = T),4),
              LBGI = -round(mean(risk[risk < 0],na.rm = T),4)
    )
  
  sum2 <- data.frame(Stat = c("Week day with worst TIR",
                              "Week day with highest HBGI",
                              "Week day with highest LBGI",
                              "Time of day with worst TIR",
                              "Time of day with highest HBGI",
                              "Time of day with highest LBGI"),
                     Value = c(paste(as.character(weekday$weekday[weekday$TIR == min(weekday$TIR)]),
                                     collapse=", "),
                               paste(as.character(weekday$weekday[weekday$HBGI == max(weekday$HBGI)]),
                                     collapse=", "),
                               paste(as.character(weekday$weekday[weekday$LBGI == max(weekday$LBGI)]),
                                     collapse=", "),
                               paste(timeday$timeday[timeday$TIR == min(timeday$TIR)],
                                     collapse=", "),
                               paste(timeday$timeday[timeday$HBGI == max(timeday$HBGI)],
                                     collapse=", "),
                               paste(timeday$timeday[timeday$LBGI == max(timeday$LBGI)],
                                     collapse=", ")
                     ))
  df1 <- rbind(df1, sum2)
  
  #############################################################################
  ## Glucose events summarizing
  ### events summarize
  hyper_hypo <- events %>%
    group_by(Event_subtype) %>% 
    summarize(Value = round(n()/as.numeric(to - from),2),
    ) %>%
    filter(Event_subtype != "Normoglycemia") %>% 
    mutate(Stat = c("N hyperglycemia/day",
                    "N hypoglycemia/day")) %>% 
    select(-Event_subtype)
  df1 <- rbind(df1, hyper_hypo)  
  
  overcor <- events %>%
    group_by(Event_subtype) %>% 
    summarize(Value = round(length(Overcorrection[Overcorrection=="Yes"])/
                              length(Overcorrection),2)
    ) %>%
    filter(Event_subtype != "Normoglycemia") %>% 
    mutate(Stat = c("% hypoglycemia overcorrection",
                    "% hyperglycemia overcorrection")) %>% 
    select(-Event_subtype)
  
  df1 <- rbind(df1, overcor)
  
  #############################################################################
  #############################################################################
  ## summarize insulin
  ins.mes.global <-
    fi %>%
    summarize(`Total Insulin/day` = round((sum(Injec_bolus) + sum(Basal_rate*(5/60))) /
                                            as.numeric(to - from),1),
              `Total bolus insulin/day` = round(sum(Injec_bolus) /as.numeric(to - from),1),
              `Total basal insulin/day` = round(sum(Basal_rate*(5/60)) /as.numeric(to - from),1),
              `N bolus/day` = round(length(Bolus_type[!is.na(Bolus_type)])/as.numeric(to - from),1),
              `Mean basal rate` = round(mean(Basal_rate, na.rm=T),1),
              `CV basal rate` = round(sd(Basal_rate, na.rm=T)/
                                        mean(Basal_rate,na.rm = T) * 100,1),
              `Normal bolus size` = paste0(round(mean(Injec_bolus[Bolus_type == "Normal"],
                                                      na.rm=T),1),
                                           " \u00B1 ",
                                           round(sd(Injec_bolus[Bolus_type == "Normal"],
                                                    na.rm=T),1)),
              `N temporal basal/day` = round(length(Action[Action == "Temporal_basal_start" &
                                                             !is.na(Action)])/
                                               as.numeric(to - from),1),
              `N 0 basal/day` = round(length(Action[Action=="Temporal_basal_start" &
                                                      Basal_rate == 0 & !is.na(Action)])/
                                        as.numeric(to - from),1)
    )%>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column("Stat") %>% rename(Value="V1")
  
  #############################################################################
  # Insulin events summarize
  ev.sum <- events %>% 
    summarize(`N bolus/meal` = paste0(round(mean(N_bolus[Event_type == "Meal"], na.rm=T),1),
                                      " \u00B1 ",
                                      round(sd(N_bolus[Event_type == "Meal"],na.rm=T),1)),
              `N bolus outmeal/day` = paste0(round(mean(N_bolus[Event_type == "No_Meal"], na.rm=T),1),
                                             " \u00B1 ",
                                             round(sd(N_bolus[Event_type == "No_Meal"],na.rm=T),1)),
              `N detected meals/day` = round(length(Event_type[Event_type == "Meal"])/
                                               as.numeric(to - from),1)
    )%>% 
    t() %>% as.data.frame() %>% 
    rownames_to_column("Stat") %>% rename(Value="V1")
  
  df2 <- rbind(ins.mes.global, ev.sum)
  
  li <- list(df1, df2)
  names(li) <- c("Glucose_measures", "Insulin_measures")
  return(li)
}