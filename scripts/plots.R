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

the <- theme(legend.position = "bottom")
###############################################################################
# Gluplot for events
# declare an event as `e`
gluplot <- function(e){
  # extract info from minute-wise dataframe
  df <- fi2[fi2$time >= e$start & fi2$time <= e$end,] %>% 
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
    labs(title = "Insulin in plasma")+
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






###############################################################################





###############################################################################





###############################################################################






###############################################################################
