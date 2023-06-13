library(tidyverse)
library(lubridate)

# Plots function for DiaTrack

# Definie colors for rangers of glucose
colrange <- c("Very low" = "black",
              "Low" = "red",
              "In range" = "green",
              "High" = "yellow3",
              "Very high" = "orange")
colrisk <- c("Hypoglycemia risk" = "red",
             "Hyperglycemia risk" = "yellow3")
# Define colors and transparency for source of insulin
colins <- c("Bolus" = "cornflowerblue",
            "Basal" = "deeppink",
            "Total" = "dimgray")
alins <- c("Bolus" = 0.9,
           "Basal" = 0.2,
           "Total" = 0.3)
colins2 <- c("Bolus" = "cornflowerblue",
             "Basal rate" = "deeppink")
alins2 <- c("Bolus" = 1,
            "Basal rate" = 0.45)

# Define timepoints
from <- as_datetime(lubridate::force_tz(lubridate::ymd_hms(paste(from, "00:00:00")),
                                        Sys.timezone()),
                    tz = Sys.timezone())
to <- as_datetime(lubridate::force_tz(lubridate::ymd_hms(paste(to, "00:00:00")),
                                      Sys.timezone()),
                  tz = Sys.timezone())
span_days <- round(as.numeric(to - from))

###############################################################################
# Gluplot for events
# declare an event as `e`
gluplot <- function(e, fi=fi){
    the <- theme(legend.position = "bottom")
  # extract info from minute-wise dataframe
  df <- fi[fi$time >= e$start & fi$time <= e$end,] %>%
    mutate(risk.range = ifelse(risk > 0,
                               "Hyperglycemia risk",
                               "Hypoglycemia risk"))
  
  
  
  pointplot <- df %>% filter(!is.na(glucose)) %>% 
    ggplot(aes(x=time ,y=glucose)) + 
    geom_point(size=1, aes(color = Range), show.legend= T, alpha=0.65) +
    scale_color_manual(values= colrange,  name = "Glucose Range") +
    guides(color = guide_legend(override.aes = list(size = 4)))+
    labs(title = paste0("Glucose reading on ",
                        min(format(df$time, "%Y-%m-%d" )),
                        "\n", e$Event_type, " - ", e$Event_subtype)) +
    geom_hline(yintercept = c(low,high), linetype = "dashed")+
    theme(plot.title = element_text(size=18,hjust = 0.5))+ 
    ylab("glucose (mg/dL)") + theme_bw() + xlab("Time")+
    scale_x_datetime(date_labels = "%H:%M",
                     date_breaks = "30 mins",
                     expand = c(0.01,0.01))+
    scale_y_continuous(breaks = c(55,70,100,140,180, 240,300)) +
    the
  
  riskplot <- df %>% filter(!is.na(risk)) %>% 
    ggplot(aes(x=time ,y=risk)) + 
    geom_col(size=1, aes(fill = risk.range), show.legend= T, alpha=0.65) +
    scale_fill_manual(values= colrisk,  name = "Glucose Risk") +
    guides(color = guide_legend(override.aes = list(size = 4)))+
    ylab("glycemic risk") + theme_bw() + xlab("Time")+
    scale_x_datetime(date_labels = "%H:%M",
                     date_breaks = "30 mins",
                     expand = c(0.01,0.01)) +
    the
  
  acti <- df %>% select(time, Bolus_ActI, Basal_ActI, Total_ActI) %>% 
    pivot_longer(-time, names_to = "Insulin_source",
                 values_to = "Active insulin") %>% 
    mutate(Insulin_source = factor(Insulin_source,
                                   levels=c("Bolus_ActI", "Basal_ActI", "Total_ActI"),
                                   labels=c("Bolus", "Basal", "Total"))) %>% 
    ggplot(aes(time, `Active insulin`,
               fill=Insulin_source))+
    geom_area(aes(alpha=Insulin_source), position="identity")+
    scale_fill_manual(values = colins, name = "Insulin source")+
    scale_alpha_manual(values= alins, guide="none")+
    ylab("Insulin in plasma (U)") + theme_bw() + xlab("Time")+
    scale_x_datetime(date_labels = "%H:%M",
                     date_breaks = "30 mins",
                     expand = c(0.01,0.01))+
    labs(title = "Insulin in plasma (U/L/Kg)")+
    the
  
  evs <- df %>% select(time, Bolus_type, Injec_bolus, Action, Basal_rate) %>% 
    pivot_longer(-c(time, Bolus_type, Action), names_to = "Insulin_source",
                 values_to = "Insulin") %>% 
    mutate(Insulin_source = factor(Insulin_source,
                                   levels=c("Injec_bolus", "Basal_rate"),
                                   labels=c("Bolus", "Basal rate"))) %>%
    ggplot(aes(time, Insulin, fill=Insulin_source))+
    geom_col(aes(alpha= Insulin_source), stat="identity",position = "identity")+
    geom_text(aes(y = max(Insulin)/2, label=Action),
              angle=90, size=4, color="blue")+
    geom_text(aes(y = max(Insulin)/2, label=Bolus_type),
              angle=90, size=4)+
    scale_fill_manual(values = colins2, name = "Insulin source")+
    scale_alpha_manual(values= alins2, guide="none")+
    ylab("Insulin injected (U)") + theme_bw() + xlab("Time")+
    scale_x_datetime(date_labels = "%H:%M",
                     date_breaks = "30 mins",
                     expand = c(0.01,0.01))+
    labs(title = "Insulin injected")+
    the
  
  # merge all plots
  require(ggpubr)
  plotlist <- list(pointplot, riskplot, acti, evs)
  pl <- ggarrange(plotlist=plotlist, ncol=1,
                  heights = c(5,4,4,4))
  
  return(pl)
}

###############################################################################
# Percentile plots
perplot <- function(fi, subtit="", tx="20 mins"){
  # define time range
  the <- theme_bw() +
    theme(legend.position = "bottom",
          legend.title = element_text(size=18, face = "bold"),
          legend.text = element_text(size=17),
          plot.title = element_text(size=25, face="bold"),
          axis.title =element_text(size=18),
          axis.text = element_text(size=16))
  allgluplot <- 
    fi %>% filter(!is.na(glucose)) %>% 
    mutate(hoursmin = as.POSIXct(format(time,"%H:%M"),format="%H:%M"),
           tenmin = as.POSIXct(format(round_date(time, tx),"%H:%M"),
                               format="%H:%M")) %>% 
    ggplot(aes(x=hoursmin ,y=glucose)) +
    stat_summary(aes(tenmin, fill = "coral1"), fun.min = quan5,
                 fun.max = quan95, geom = "ribbon", alpha = 0.15)+
    stat_summary(aes(tenmin, fill = "chocolate4"), fun.min = quan25,
                 fun.max = quan75, geom = "ribbon", alpha = 0.5)+
    stat_summary(fun=median, aes(tenmin, linetype = "Median"),
                 geom="line", color = "coral4", size = 1.5)+
    scale_linetype_manual("", values=1)+
    scale_fill_manual(name = "", values= c("chocolate4","coral1"),
                      label = c("75% values", "95% values"))+
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Glucose sensor readings")) +
    geom_hline(yintercept = c(low,high), linetype = "dashed")+
    theme(plot.title = element_text(size=14,hjust = 0.5))+ 
    xlab("Time of the day")+
    ylab("glucose (mg/dL)") +
    scale_x_datetime(date_labels = "%H",date_breaks = "1 hour",
                     expand = c(0.01,0.01))+
    scale_y_continuous(breaks = c(55,70,100,140,180, 240,300)) +
    the
  
  allriskplot <- 
    fi %>% 
    mutate(hoursmin = as.POSIXct(format(time,"%H:%M"),format="%H:%M"),
           tenmin = as.POSIXct(format(round_date(time, tx),"%H:%M"),
                               format="%H:%M")) %>% 
    ggplot(aes(x=hoursmin ,y=risk)) +
    stat_summary(aes(tenmin, fill = "lightsalmon"), fun.min = quan5,
                 fun.max = quan95, geom = "ribbon", alpha = 0.3)+
    stat_summary(aes(tenmin, fill = "lightpink1"), fun.min = quan25,
                 fun.max = quan75, geom = "ribbon", alpha = 0.5)+
    stat_summary(fun=median, aes(tenmin, linetype = "Median"),
                 geom="line", colour = "lightpink4", size = 1.5)+
    scale_linetype_manual("", values=1)+
    scale_fill_manual(name = "", values= c("lightpink1","lightpink4"),
                      label = c("75% values", "95% values"))+
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Risk")) +
    geom_hline(yintercept = c(-2.5,5), linetype = "dashed")+
    xlab("Time of the day")+
    ylab("Risk") +
    scale_x_datetime(date_labels = "%H",date_breaks = "1 hour",
                     expand = c(0.01,0.01))+
    the
  
  allinsplot <- 
    fi %>% 
    select(time, Bolus_ActI, Basal_ActI, Total_ActI) %>%
    pivot_longer(-time, names_to = "Insulin_source",
                 values_to = "Active insulin") %>% 
    mutate(`Insulin source` = factor(Insulin_source,
                                     levels=c("Bolus_ActI", "Basal_ActI", "Total_ActI"),
                                     labels=c("Bolus", "Basal", "Total")),
           hoursmin = as.POSIXct(format(time,"%H:%M"),format="%H:%M"),
           tenmin = as.POSIXct(format(round_date(time, tx),"%H:%M"),
                               format="%H:%M")) %>%
    ggplot(aes(x=hoursmin, y=`Active insulin`)) +
    stat_summary(aes(tenmin, fill = `Insulin source`), fun.min = quan25,
                 fun.max = quan75, geom = "ribbon", alpha = 0.6)+
    stat_summary(fun=median, aes(tenmin, linetype = "Median",
                                 color=`Insulin source`),
                 geom="line", size = 1.5)+
    scale_linetype_manual("", values=1)+
    scale_fill_identity(name = "", label = "75% values", guide="legend") +
    scale_fill_manual(values= colins)+
    scale_color_manual(values=colins) +
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Insulin in plasma"))+ 
    xlab("Time of the day")+
    ylab("Insulin in plasma (U/L/Kg)") +
    scale_x_datetime(date_labels = "%H",date_breaks = "1 hour",
                     expand = c(0.01,0.01))+
    the 
  
  alleveplot <- 
    fi %>% 
    select(time, Bolus_type, Action) %>%
    pivot_longer(-time, names_to = "Event",
                 values_to = "Type") %>% 
    filter(Type %in% c("Normal", "Temporal_basal_start")) %>% 
    mutate(hoursmin = as.POSIXct(format(time,"%H:%M"),format="%H:%M"),
           tenmin = as.POSIXct(format(round_date(time, tx),"%H:%M"),
                               format="%H:%M"),
           Type = factor(Type,
                         labels=c("Bolus", "Temporal basal (start)"))) %>%
    ggplot(aes(x=hoursmin)) +
    geom_bar(aes(fill=Type)) +
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Events"))+ 
    xlab("Time of the day")+
    ylab("Number of events") +
    scale_x_datetime(date_labels = "%H",date_breaks = "1 hour", expand = c(0.01,0.01))+
    the
  
  # merge all plots
  require(ggpubr)
  plotlist <- list(allgluplot, allriskplot,
                   allinsplot, alleveplot)
  pl <- ggarrange(plotlist=plotlist, ncol=1,
                  heights = c(4.5,4,4,4)) 
  pl <- annotate_figure(pl,
                        top = text_grob(paste0("Data from ",
                                               min(format(fi$time, "%Y-%m-%d" )),
                                               " to ",
                                               max(format(fi$time, "%Y-%m-%d")), ": ",
                                               span_days, " days.       ",
                                               subtit), 
                                        color = "black", face = "bold", size = 20))
  
  return(pl)
}


###############################################################################
# Percentile meal plot
mealplot <- function(fi, subtit="", tx=10){
  the <- theme_bw() +
    theme(legend.position = "bottom",
          legend.title = element_text(size=18, face = "bold"),
          legend.text = element_text(size=17),
          plot.title = element_text(size=25, face="bold"),
          axis.title =element_text(size=18),
          axis.text = element_text(size=16))
  allgluplot <- 
    fi %>% filter(!is.na(glucose)) %>% 
    filter(meal_factor != "outmeal") %>% 
    mutate(tenmin = plyr::round_any(mealtime,tx)) %>% 
    ggplot(aes(x=mealtime ,y=glucose)) +
    stat_summary(aes(tenmin, fill = "coral1"), fun.min = quan5,
                 fun.max = quan95, geom = "ribbon", alpha = 0.15)+
    stat_summary(aes(tenmin, fill = "chocolate4"), fun.min = quan25,
                 fun.max = quan75, geom = "ribbon", alpha = 0.5)+
    stat_summary(fun=median, aes(tenmin, linetype = "Median"),
                 geom="line", color = "coral4", size = 1.5)+
    scale_linetype_manual("", values=1)+
    scale_fill_manual(name = "", values= c("chocolate4","coral1"),
                      label = c("75% values", "95% values"))+
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Glucose sensor readings")) +
    geom_hline(yintercept = c(low,high), linetype = "dashed")+
    theme(plot.title = element_text(size=18,hjust = 0.5))+ 
    xlab("Time around meal (min)")+
    ylab("glucose (mg/dL)") +
    scale_y_continuous(breaks = c(55,70,100,140,180, 240,300)) +
    scale_x_continuous(expand = c(0.01,0.01))+
    geom_vline(xintercept = 0, linetype = "twodash", color="purple4")+
    the
  
  allriskplot <- 
    fi %>% 
    filter(meal_factor != "outmeal") %>% 
    mutate(tenmin = plyr::round_any(mealtime,tx)) %>% 
    ggplot(aes(x=mealtime ,y=risk)) +
    stat_summary(aes(tenmin, fill = "lightsalmon"), fun.min = quan5,
                 fun.max = quan95, geom = "ribbon", alpha = 0.3)+
    stat_summary(aes(tenmin, fill = "lightpink1"), fun.min = quan25,
                 fun.max = quan75, geom = "ribbon", alpha = 0.5)+
    stat_summary(fun=median, aes(tenmin, linetype = "Median"),
                 geom="line", colour = "lightpink4", size = 1.5)+
    scale_linetype_manual("", values=1)+
    scale_fill_manual(name = "", values= c("lightpink1","lightpink4"),
                      label = c("75% values", "95% values"))+
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Risk")) +
    geom_hline(yintercept = c(-2.5,5), linetype = "dashed")+
    scale_x_continuous(expand = c(0.01,0.01))+
    geom_vline(xintercept = 0, linetype = "twodash", color="purple4")+ 
    xlab("Time around meal (min)")+
    ylab("Risk") +
    the
  
  allinsplot <- 
    fi %>% 
    filter(meal_factor != "outmeal") %>%
    select(mealtime, Bolus_ActI, Basal_ActI, Total_ActI) %>%
    pivot_longer(-mealtime, names_to = "Insulin_source",
                 values_to = "Active insulin") %>% 
    mutate(tenmin = plyr::round_any(mealtime,tx),
           `Insulin source` = factor(Insulin_source,
                                     levels=c("Bolus_ActI", "Basal_ActI", "Total_ActI"),
                                     labels=c("Bolus", "Basal", "Total"))) %>%
    ggplot(aes(x=mealtime, y=`Active insulin`)) +
    stat_summary(aes(tenmin, fill = `Insulin source`), fun.min = quan25,
                 fun.max = quan75, geom = "ribbon", alpha = 0.6)+
    stat_summary(fun=median, aes(tenmin, linetype = "Median",
                                 color=`Insulin source`),
                 geom="line", size = 1.5)+
    scale_linetype_manual("", values=1)+
    scale_fill_identity(name = "", label = "75% values", guide="legend") +
    scale_fill_manual(values= colins)+
    scale_color_manual(values=colins) +
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Insulin in plasma"))+
    scale_x_continuous(expand = c(0.01,0.01))+
    geom_vline(xintercept = 0, linetype = "twodash", color="purple4")+
    xlab("Time around meal (min)")+
    ylab("Insulin in plasma (U)") +
    the 
  
  alleveplot <- 
    fi %>% 
    filter(meal_factor != "outmeal") %>%
    select(mealtime, Bolus_type, Action) %>%
    pivot_longer(-mealtime, names_to = "Event",
                 values_to = "Type") %>% 
    filter(Type %in% c("Normal", "Temporal_basal_start")) %>% 
    mutate(tenmin = plyr::round_any(mealtime,tx),
           Type = factor(Type,
                         labels=c("Bolus", "Temporal basal (start)"))) %>%
    ggplot(aes(x=mealtime)) +
    geom_bar(aes(fill=Type)) +
    guides(color = guide_legend(override.aes = list(size = 6)),
           fill = guide_legend(override.aes = list(size = 6)))+
    labs(title = paste0("Events"))+ 
    xlab("Time around meal (min)")+
    ylab("Number of events") +
    scale_x_continuous(expand = c(0.01,0.01))+
    geom_vline(xintercept = 0, linetype = "twodash", color="purple4")+
    the
  
  # merge all plots
  require(ggpubr)
  plotlist <- list(allgluplot, allriskplot,
                   allinsplot, alleveplot)
  pl <- ggarrange(plotlist=plotlist, ncol=1,
                  heights = c(4.5,4,4,4)) 
  pl <- annotate_figure(pl,
                        top = text_grob(paste0("Data from ",
                                               min(format(fi$time, "%Y-%m-%d" )),
                                               " to ",
                                               max(format(fi$time, "%Y-%m-%d")), ": ",
                                               span_days, " days.       ",
                                               subtit), 
                                        color = "black", face = "bold", size = 32))
  
  return(pl)
}




###############################################################################
# TIR plot
TIR_plot <- function(fi, subset=NULL){
  if(is.null(subset)){
  tb <- fi %>% 
    with(table(Range)) %>% prop.table() %>% 
    as.data.frame() %>%
    mutate(Freq = round(100*Freq),
           Freqann = paste0(Freq, "%"))
  tir <- tb %>% 
    ggplot(aes(y=Freq, x="",
               fill=Range, label=Freqann)) +
    geom_bar(stat="identity") +
    scale_fill_manual("", values=colrange)+
    ggrepel::geom_label_repel(aes(color=Range,fontface=2),
                              size = 4, face="bold", fill="grey65",
                              position = position_stack(vjust = 0.5),
                              show.legend = F)+
    scale_color_manual("", values=colrange)+
    theme_void() +
    coord_flip()+
    theme(legend.position = "bottom")
  } else if(subset == "weekday"){
    tb <- fi %>% 
      filter(!is.na(Range)) %>% 
      group_by(weekday, Range) %>% 
      summarize(Freq0 = n()) %>%
      as.data.frame() %>% 
      group_by(weekday) %>% 
      summarize(Freq = Freq0/sum(Freq0), Range= Range) %>% 
      mutate(Freq = round(100*Freq),
             Freqann = paste0(Freq, "%")) 
    tir <- tb %>% 
      ggplot(aes(y=Freq, x="",
                 fill=Range, label=Freqann)) +
      geom_bar(stat="identity") +
      scale_fill_manual("", values=colrange)+
      ggrepel::geom_label_repel(aes(color=Range,fontface=2),
                                size = 4, face="bold", fill="grey65",
                                position = position_stack(vjust = 0.5),
                                show.legend = F)+
      scale_color_manual("", values=colrange)+
      theme_void() +
      coord_flip()+
      theme(legend.position = "bottom")+
      facet_wrap(~weekday, ncol=4)
    
  } else if(subset == "timeday"){
    tb <- fi %>% 
      filter(!is.na(Range)) %>% 
      group_by(timeday, Range) %>% 
      summarize(Freq0 = n()) %>% as.data.frame() %>% 
      group_by(timeday) %>% 
      summarize(Freq = Freq0/sum(Freq0), Range= Range) %>% 
      mutate(Freq = round(100*Freq),
             Freqann = paste0(Freq, "%"))
    tir <- tb %>% 
      ggplot(aes(y=Freq, x="",
                 fill=Range, label=Freqann)) +
      geom_bar(stat="identity") +
      scale_fill_manual("", values=colrange)+
      ggrepel::geom_label_repel(aes(color=Range,fontface=2),
                                size = 4, face="bold", fill="grey65",
                                position = position_stack(vjust = 0.5),
                                show.legend = F)+
      scale_color_manual("", values=colrange)+
      theme_void() +
      coord_flip()+
      theme(legend.position = "bottom")+
      facet_wrap(~timeday, ncol=3)
  }
  
  return(tir)
}



###############################################################################
# Poincare plots
Poincare_plot <- function(fi, elipse_level=0.99,
                          subset = NULL){
  pdf <- fi %>% select(glucose, weekday, timeday) %>%
    filter(complete.cases(.))
  pdf <- data.frame(i = pdf$glucose[2:nrow(pdf)],
                    i.1 = pdf$glucose[1:(nrow(pdf)-1)],
                    timeday = pdf$timeday[-1],
                    weekday = pdf$weekday[-1])
  pp <- pdf %>% 
    ggplot(aes(i.1,i))+
    geom_point()+
    stat_ellipse(level=elipse_level, color=2)+
    labs(x="i - 1",
         y= "i")+
    theme_bw()
  
  if(!is.null(subset)){
    pp <- pp + facet_wrap(~pdf[[subset]])
  }
  
  
  return(pp)
}

###############################################################################
# CVGA plot

# dataframe for labels
coor <- data.frame(
  status = c("Upper C", "Upper D", "E-zone",
             "Upper B", "B-zone", "Lower D",
             "A-zone", "Lower B", "Lower C"),
  x = c(rep(c(100,80,60),3)),
  y = c(rep(350,3), rep(240,3), rep(145,3)),
  col = c("yellow3", "darkorange1", "red4",
          "darkgreen", "darkgreen", "darkorange1",
          "springgreen1", "darkgreen", "yellow3")
)

col <- coor %>% pull(col,name = status)

ebc.plot <- function(ebc, tit = NULL){
  ebc.plot <- 
    ebc %>% 
    mutate(Max = ifelse(Max > 400, 400,
                        ifelse(Max < 110, 110, Max)),
           Min = ifelse(Min < 50, 50,
                        ifelse(Min > 110, 110, Min))
    ) %>% 
    ggplot(aes(Min, Max)) + 
    geom_point(size=2.5, alpha=0.6, color="royalblue4") +
    geom_label(data=coor, aes(label=status,
                              x= x, y= y, color=status)) +
    scale_color_manual(values=col) +
    geom_vline(xintercept = c(90,70))+
    geom_hline(yintercept = c(180,300))+
    theme_bw()+
    scale_y_continuous(limits = c(110, 400) ,
                       breaks = c(110,180,300,400),
                       expand = c(110,110)) +
    scale_x_continuous(limits = c(110,50),
                       breaks = c(50, 70, 90, 110),
                       expand = c(110,110),
                       trans = "reverse") +
    coord_cartesian(expand = F) +
    ggtitle(tit) +
    theme(plot.title = element_text(hjust = 0.5, size=18))
  return(ebc.plot)
  
}

###############################################################################
# Boxplot
Boxplot_glucose <- function(fi,
                            xaxis="weekday",
                            yaxis="glucose"){
  if(yaxis == "glucose"){
    ylab <- "glucose (mg/dL)"
    yinterc <- c(low,high)
  } else if(yaxis == "risk"){
    ylab <- "Risk"
    yinterc <- c(-2.5,5)
  }
  
  bp <- 
    fi %>% 
    ggplot(aes(x = fi[[xaxis]], y = fi[[yaxis]])) +
    geom_jitter(aes(color=Range),
                alpha = 0.35, size = 0.5)+
    scale_color_manual(values= colrange)+
    guides(color = guide_legend(override.aes = list(size = 6)))+
    geom_boxplot(colour = "violetred4", fill = "snow3",
                 size = 0.6, notch=F) +
    ylab(ylab)+
    xlab(xaxis)+
    geom_hline(yintercept = yinterc, linetype = "dashed")+
    theme_bw()
  
  return(bp)
}


###############################################################################
# Event plot
# weekdays
Event_plot <- function(fi, events, subset="weekday"){
  ndays <- fi %>%
    mutate(day = format(time, "%D")) %>% 
    distinct(day, .data[[subset]]) %>% 
    group_by(.data[[subset]]) %>% 
    summarize(ndays = n())
 
  evdf <- rbind(
    events %>% group_by(.data[[subset]], Event_subtype) %>% 
      summarize(Count = n()) %>% rename(Event = "Event_subtype"),
    events %>% group_by(.data[[subset]], Event_type) %>% 
      summarize(Count = n()) %>% rename(Event = "Event_type")
  ) %>% filter(!Event %in% c("Normoglycemia", "No_Meal"))%>% 
    left_join(ndays, ., by= subset) %>% 
    mutate(Counts = Count/ndays)

  eventplot <- evdf  %>% 
    ggplot(aes(.data[[subset]], Counts, fill=Event)) +
    geom_col(position = "dodge2")+
    ylab("Counts / day of the week")+
    xlab(subset)+
    theme_bw()
  return(eventplot)

}


###############################################################################
