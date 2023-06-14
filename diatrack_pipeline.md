date: 2023-06-14

# Define parameters to use for analysis

## Load utilities and environment


```r
# Load packages
library(tidyverse)
library(lubridate)
library(renv)
options(renv.verbose = F)

# Load the same packages versions using renv package
restore() 

# Load utilities
source("scripts/Utils.R")
```

## Diabetes manegement parameters

We define the parameters we will use for our analysis. The threshold for hypoglycemia and hyperglycemia, the raw data source type, the time period we want to study and the how we categorize the times of the day and define event time span.


```r
#Set low and high threesholds:
low <- 70
high <- 180

# set the source of glucose data
glucose_source <- "xdrip"
# set the source of insulin pump data
insulin_source <- "MiniMed"

#dates interval to show
from <- "2022-07-16"
to <- "2023-01-29"

## setting times of the day
morning <- c(7,12)
midday <- c(13,15)
afternoon <- c(16,19)
evening <- c(20,23)
nigth <- c(0,6)

# Setting time span around events
time.bf <- (90*60) #time analysis before event in minutes (1.5h)
time.af <- (180*60) # time analysis after event in minuts (3h)
```


# Load and process CGM data
In this step we use the function `CGM_process()` to convert datetime data from CGM source into `POSIXct`format. Also, we compute the slope in **mg/dL/min** between glucose reading entries (`slope`) and every 15 minutes (`slope15`).


```r
# Load function
source("scripts/CGM_process.R")
# Set glucose source path
glu_path <- "data/CGM_xDrip_export_20230126-165100.csv"

# Process glucose data
glucose <- CGM_process(glupath)
```


```r
kable(glucose[100:106,])
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> time </th>
   <th style="text-align:right;"> glucose </th>
   <th style="text-align:right;"> slope </th>
   <th style="text-align:right;"> slope15 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 100 </td>
   <td style="text-align:left;"> 2021-12-29 08:22:00 </td>
   <td style="text-align:right;"> 128 </td>
   <td style="text-align:right;"> -1.0000000 </td>
   <td style="text-align:right;"> -0.4666667 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 101 </td>
   <td style="text-align:left;"> 2021-12-29 08:27:00 </td>
   <td style="text-align:right;"> 132 </td>
   <td style="text-align:right;"> 0.8000000 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 102 </td>
   <td style="text-align:left;"> 2021-12-29 08:32:00 </td>
   <td style="text-align:right;"> 139 </td>
   <td style="text-align:right;"> 1.4000000 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 103 </td>
   <td style="text-align:left;"> 2021-12-29 08:37:00 </td>
   <td style="text-align:right;"> 143 </td>
   <td style="text-align:right;"> 0.8000000 </td>
   <td style="text-align:right;"> 1.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 104 </td>
   <td style="text-align:left;"> 2021-12-29 08:42:00 </td>
   <td style="text-align:right;"> 144 </td>
   <td style="text-align:right;"> 0.2000000 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 105 </td>
   <td style="text-align:left;"> 2021-12-29 08:49:00 </td>
   <td style="text-align:right;"> 139 </td>
   <td style="text-align:right;"> -0.7142857 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 106 </td>
   <td style="text-align:left;"> 2021-12-29 08:54:00 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 0.6000000 </td>
   <td style="text-align:right;"> -0.0588235 </td>
  </tr>
</tbody>
</table>

```r
writexl::write_xlsx(glucose, "out/Processed_CGM_data.xlsx")
```

# Load and process Insulin pump data

In this step we use the function `Insulin_process()` to tidy up raw data from Minimed Pump (Medtronic) and also estimate the insulin in plasma levels using the model from Schiavon et al., 2018.

<img src="figs/Shiavon_2018_model3.png" width="50%" style="display: block; margin: auto;" />
**Model exracted from (Schiavon, Dalla Man, and Cobelli 2018)**. U: Units of insulin injected, t: time, Г: time delay, Isc1:Insulin compartment1 (subcutaneous), Isc2: Insulin compartment 2 (Interstitial), Ip: Insulin compartment 3 (plasma), Kd: rate of diffusion from compartment 1 to 2, Ka1: rate of diffusion from compartment 1 to 3, ka2: rate of diffusion from compartment 2 to 3, ke: rate of clearance from compartment 3, V1: plasma volume.


```r
# source function
source("scripts/Insulin_pump_process.R")
# define raw data insulin path
ins_path <- "data/Insulin_pump_MiniMed_8-3-2023.csv"

# Arrange insulin events and data and compute insulin in plasma
tins <- Insulin_process(ins_path)
```

```
## [1] "Processing of insulin data completed"
## [1] "Starting insulin in plasma estimation"
```


```r
kable(tins[206145:206151,])
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> time </th>
   <th style="text-align:left;"> Bolus_type </th>
   <th style="text-align:right;"> Injec_bolus </th>
   <th style="text-align:left;"> Action </th>
   <th style="text-align:right;"> Basal_rate </th>
   <th style="text-align:right;"> Injec_basal </th>
   <th style="text-align:right;"> Bolus_ActI </th>
   <th style="text-align:right;"> Basal_ActI </th>
   <th style="text-align:right;"> Total_ActI </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 206145 </td>
   <td style="text-align:left;"> 2022-12-05 14:09:00 </td>
   <td style="text-align:left;"> Normal </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9647131 </td>
   <td style="text-align:right;"> 0.8625263 </td>
   <td style="text-align:right;"> 1.827239 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 206146 </td>
   <td style="text-align:left;"> 2022-12-05 14:10:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9570441 </td>
   <td style="text-align:right;"> 0.8627366 </td>
   <td style="text-align:right;"> 1.819781 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 206147 </td>
   <td style="text-align:left;"> 2022-12-05 14:11:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9492993 </td>
   <td style="text-align:right;"> 0.8629512 </td>
   <td style="text-align:right;"> 1.812250 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 206148 </td>
   <td style="text-align:left;"> 2022-12-05 14:12:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9414855 </td>
   <td style="text-align:right;"> 0.8631698 </td>
   <td style="text-align:right;"> 1.804655 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 206149 </td>
   <td style="text-align:left;"> 2022-12-05 14:13:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9336091 </td>
   <td style="text-align:right;"> 0.8633922 </td>
   <td style="text-align:right;"> 1.797001 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 206150 </td>
   <td style="text-align:left;"> 2022-12-05 14:14:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9256765 </td>
   <td style="text-align:right;"> 0.8636180 </td>
   <td style="text-align:right;"> 1.789295 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 206151 </td>
   <td style="text-align:left;"> 2022-12-05 14:15:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.0141667 </td>
   <td style="text-align:right;"> 0.9176936 </td>
   <td style="text-align:right;"> 0.8638471 </td>
   <td style="text-align:right;"> 1.781541 </td>
  </tr>
</tbody>
</table>

```r
writexl::write_xlsx(tins, "out/Processed_Insulin_data.xlsx")
```


# Merge glucose and insulin datasets

Now we merge glucose levels and insulin events data, and get rid of time entries without meaningful information.


```r
fi <- left_join(tins, glucose, by="time") %>%
  # remove not need rows
  filter(!is.na(glucose) |
         !is.na(Bolus_type) |
         !is.na(Action))
```


# Classify events

Next we create a new dataframe with the events in this period of time. This dataframe can be linked to the integrated dataset with minute-wise information based on date and time data. We use the function `Event_classification()`.

<img src="figs/Algorithm_events.png" width="50%" style="display: block; margin: auto;" />

*Events were firstly classified in meal and non-meal events based on presence of increasing slope of at least 2 mg/dL/min, and then into events with normo-, hyper- or hypoglycemia, based on the presence of at least 3 glucose values below or over the low and high thresholds. Start and end time for analysis event was set as 1.5h before and 3h after of event declaration parameter.*

At the same time we categorize datetime in weekdays, hours, and timeday for the subsequent analyses and plotting. Moreover, we compute the following parameters associated with each event:

* **Extreme value**: only applicable to events with hypo- or hyperglycemia, with lowest and highest glucose value, respectively (mg/dL).
* **AUC out of range**: Only applicable to non-normoglycemic events. Area under the curve outside of range. Most current analyses consider the amount of time out of range, but AUC also measures the extend of the hypoglycemia or hyperglycemia. 
* **Total slope**: Only applicable to no normoglycemic events. Slope of glucose (mg/dL/min) before arriving to out-of-range glucose values.
* **Diff_bolus**: Time difference between last bolus and out-of-range glucose levels in minutes.
* **Bolus_ActI, Basal_ActI and Total_ActI**: Units of insulin in plasma from bolus, basal or total (sum of bolus and basal), respectively, at the time of event declaration.
* **N_bolus**: Number of boluses delivered over the period of event analysises (-1.5-+3h)



```r
# Load function
source("scripts/Event_classification.R")
# Classifiy events, compute associated variables and categorize datetime
events <- Event_classification(fi)
```


```r
kable(head(events))
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> Event_type </th>
   <th style="text-align:left;"> start </th>
   <th style="text-align:left;"> end </th>
   <th style="text-align:left;"> Event_subtype </th>
   <th style="text-align:right;"> extreme.value </th>
   <th style="text-align:right;"> AUC_out_range </th>
   <th style="text-align:right;"> Total_slope </th>
   <th style="text-align:right;"> Diff_bolus </th>
   <th style="text-align:right;"> Bolus_ActI </th>
   <th style="text-align:right;"> Basal_ActI </th>
   <th style="text-align:right;"> Total_ActI </th>
   <th style="text-align:right;"> N_bolus </th>
   <th style="text-align:left;"> Overcorrection </th>
   <th style="text-align:left;"> weekday </th>
   <th style="text-align:right;"> timehour </th>
   <th style="text-align:left;"> timeday </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Meal </td>
   <td style="text-align:left;"> 2022-07-16 03:05:00 </td>
   <td style="text-align:left;"> 2022-07-16 07:35:00 </td>
   <td style="text-align:left;"> Hyperglycemia </td>
   <td style="text-align:right;"> 188 </td>
   <td style="text-align:right;"> 185.4522 </td>
   <td style="text-align:right;"> 2.000000 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.3495308 </td>
   <td style="text-align:right;"> 0.3915664 </td>
   <td style="text-align:right;"> 0.7410972 </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> No </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> night </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Meal </td>
   <td style="text-align:left;"> 2022-07-16 12:44:00 </td>
   <td style="text-align:left;"> 2022-07-16 17:14:00 </td>
   <td style="text-align:left;"> Normoglycemia </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:left;"> No </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:left;"> morning </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Meal </td>
   <td style="text-align:left;"> 2022-07-16 16:53:00 </td>
   <td style="text-align:left;"> 2022-07-16 21:23:00 </td>
   <td style="text-align:left;"> Hyperglycemia </td>
   <td style="text-align:right;"> 215 </td>
   <td style="text-align:right;"> 1027.0810 </td>
   <td style="text-align:right;"> 2.750000 </td>
   <td style="text-align:right;"> 86 </td>
   <td style="text-align:right;"> 2.0966934 </td>
   <td style="text-align:right;"> 0.7036195 </td>
   <td style="text-align:right;"> 2.8003128 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> No </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> afternoon </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Meal </td>
   <td style="text-align:left;"> 2022-07-16 23:55:00 </td>
   <td style="text-align:left;"> 2022-07-17 04:25:00 </td>
   <td style="text-align:left;"> Hyperglycemia </td>
   <td style="text-align:right;"> 202 </td>
   <td style="text-align:right;"> 454.8713 </td>
   <td style="text-align:right;"> 0.813253 </td>
   <td style="text-align:right;"> 90 </td>
   <td style="text-align:right;"> 0.3453051 </td>
   <td style="text-align:right;"> 0.7279544 </td>
   <td style="text-align:right;"> 1.0732594 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Yes </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:left;"> evening </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Meal </td>
   <td style="text-align:left;"> 2022-07-17 07:53:00 </td>
   <td style="text-align:left;"> 2022-07-17 12:23:00 </td>
   <td style="text-align:left;"> Hyperglycemia </td>
   <td style="text-align:right;"> 281 </td>
   <td style="text-align:right;"> 8735.3979 </td>
   <td style="text-align:right;"> 8.533333 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 0.0497262 </td>
   <td style="text-align:right;"> 0.4243056 </td>
   <td style="text-align:right;"> 0.4740318 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> No </td>
   <td style="text-align:left;"> Sunday </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:left;"> morning </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Meal </td>
   <td style="text-align:left;"> 2022-07-18 15:31:00 </td>
   <td style="text-align:left;"> 2022-07-18 20:01:00 </td>
   <td style="text-align:left;"> Normoglycemia </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> No </td>
   <td style="text-align:left;"> Monday </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:left;"> midday </td>
  </tr>
</tbody>
</table>

```r
writexl::write_xlsx(events, "out/Events_data.xlsx")
```

# Analysis

We also categorize datetime in weekdays, hours, and timeday of the glucose and insulin data integrated dataframe, using the funcion `Categories_time()`.


```r
# Load function
source("scripts/Categories_time.R")
# Function to obtain ranges of glucose data, risk, and
# time of the day and time of the week of time points
fi <- Categories_time(fi)
```


```r
kable(head(fi))
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> time </th>
   <th style="text-align:left;"> Bolus_type </th>
   <th style="text-align:right;"> Injec_bolus </th>
   <th style="text-align:left;"> Action </th>
   <th style="text-align:right;"> Basal_rate </th>
   <th style="text-align:right;"> Injec_basal </th>
   <th style="text-align:right;"> Bolus_ActI </th>
   <th style="text-align:right;"> Basal_ActI </th>
   <th style="text-align:right;"> Total_ActI </th>
   <th style="text-align:right;"> glucose </th>
   <th style="text-align:right;"> slope </th>
   <th style="text-align:right;"> slope15 </th>
   <th style="text-align:left;"> Range </th>
   <th style="text-align:left;"> meal_factor </th>
   <th style="text-align:right;"> mealtime </th>
   <th style="text-align:left;"> weekday </th>
   <th style="text-align:right;"> timehour </th>
   <th style="text-align:left;"> timeday </th>
   <th style="text-align:right;"> risk </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2022-07-16 00:01:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.7 </td>
   <td style="text-align:right;"> 0.0116667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 123 </td>
   <td style="text-align:right;"> 2.0 </td>
   <td style="text-align:right;"> 2.125000 </td>
   <td style="text-align:left;"> In range </td>
   <td style="text-align:left;"> outmeal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> 1.6613429 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-07-16 00:06:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.7 </td>
   <td style="text-align:right;"> 0.0116667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 0.0000000 </td>
   <td style="text-align:right;"> 119 </td>
   <td style="text-align:right;"> -0.8 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> In range </td>
   <td style="text-align:left;"> outmeal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> 1.0444300 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-07-16 00:11:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.7 </td>
   <td style="text-align:right;"> 0.0116667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0044732 </td>
   <td style="text-align:right;"> 0.0044732 </td>
   <td style="text-align:right;"> 114 </td>
   <td style="text-align:right;"> -1.0 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> In range </td>
   <td style="text-align:left;"> outmeal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> 0.2439874 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-07-16 00:16:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.7 </td>
   <td style="text-align:right;"> 0.0116667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0153147 </td>
   <td style="text-align:right;"> 0.0153147 </td>
   <td style="text-align:right;"> 107 </td>
   <td style="text-align:right;"> -1.4 </td>
   <td style="text-align:right;"> -1.066667 </td>
   <td style="text-align:left;"> In range </td>
   <td style="text-align:left;"> outmeal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> -0.9365794 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-07-16 00:21:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.7 </td>
   <td style="text-align:right;"> 0.0116667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0311854 </td>
   <td style="text-align:right;"> 0.0311854 </td>
   <td style="text-align:right;"> 106 </td>
   <td style="text-align:right;"> -0.2 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> In range </td>
   <td style="text-align:left;"> outmeal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> -1.1113950 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-07-16 00:26:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.7 </td>
   <td style="text-align:right;"> 0.0116667 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.0509331 </td>
   <td style="text-align:right;"> 0.0509331 </td>
   <td style="text-align:right;"> 108 </td>
   <td style="text-align:right;"> 0.4 </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> In range </td>
   <td style="text-align:left;"> outmeal </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> Saturday </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> night </td>
   <td style="text-align:right;"> -0.7633610 </td>
  </tr>
</tbody>
</table>

```r
writexl::write_xlsx(fi, "out/Integrated_data.xlsx")
```

## Diabetes measuraments

We use the previous integrated and events datasets to obtain meaningful and interpretable values of overall diabetes management success in a summary table, using the function `Summary_diabetes_measures()`: 


```r
# Load function
source("scripts/Summary_diabetes_measurements.R")

# Compute summary measures
Diabetes_summary <- Summary_diabetes_measures(glucose, fi, events)
```


```r
for(i in names(Diabetes_summary)){
  cat(i, "\n")
  kable(Diabetes_summary[[i]])
}
```

```
## Glucose_measures 
## Insulin_measures
```




## Stats

### Chi-squared test for weekday and time day distribution of undesired events

In this part we aim to explore significant correlation of undesired diabetes management events (hypoglycemia and hyperglycemia) and days of the week and/or times of day. The aim of this is to mainly try to find moments of the week or day statistically more prone to undesired events in order to focus the diabetes management adjustments. This endeavor was addressed by performing chi-square test on the number of hyper- and hypoglycemia events, respectively, in each time day of the week and each time of the day (*morning, midday, afternoon, evening, and night*). 


```r
# filter out not needed events (Normoglycemia) and not need variables
e2 <- events %>% 
  select(grep("type|AUC|ActI|extreme|N_bolus|timeday|weekday|start|end", names(.),value = T)) %>% 
  filter(Event_subtype != "Normoglycemia")

# Perform Chi-sequred test for hyper- and hypoglycemia
# for either time of day or weekday

cq.hyper <- e2 %>% filter(Event_subtype == "Hyperglycemia") %>%  
              with(table(weekday))
cq.hyper
```

```
## weekday
##    Monday   Tuesday Wednesday  Thursday    Friday  Saturday    Sunday 
##        70        48        54        54        39        87        81
```

```r
chisq.test(cq.hyper)
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq.hyper
## X-squared = 30.762, df = 6, p-value = 2.814e-05
```

```r
cq.hypo <- e2 %>% filter(Event_subtype == "Hypoglycemia") %>%  
              with(table(weekday))
cq.hypo
```

```
## weekday
##    Monday   Tuesday Wednesday  Thursday    Friday  Saturday    Sunday 
##        17        24        34        31        34        22        31
```

```r
chisq.test(cq.hypo)
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq.hypo
## X-squared = 9.4922, df = 6, p-value = 0.1477
```

```r
cq2.hyper <- e2 %>% filter(Event_subtype == "Hyperglycemia") %>%  
              with(table(timeday))
cq2.hyper
```

```
## timeday
##   morning    midday afternoon   evening     night 
##        85        70        62        76       140
```

```r
chisq.test(cq2.hyper)
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq2.hyper
## X-squared = 44.425, df = 4, p-value = 5.236e-09
```

```r
cq2.hypo <- e2 %>% filter(Event_subtype == "Hypoglycemia") %>%  
              with(table(timeday))
cq2.hypo
```

```
## timeday
##   morning    midday afternoon   evening     night 
##        41        15        25        38        74
```

```r
chisq.test(cq2.hypo)
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq2.hypo
## X-squared = 51.845, df = 4, p-value = 1.487e-10
```

### Events variables correlation

It was previously defined the list of events occurring within the period examined, at the same time we annotated in each of the event a list of variables associated with these events. The aim of this part of the project is to try to define which of such parameters are more correlated with each of the undesired events subtypes (hyperglycemia and hypoglycemia). 

We firstly prepare the data for the model application. 


```r
# Firstly, we filter out entries containing NA and
# normoglycemic events
e3 <- events %>% 
  filter(Event_subtype != "Normoglycemia") %>% 
  filter(complete.cases(.))
# Also, some time between event and bolus are infinite due to NA
# We convert them to the defined time of event
e3[is.infinite(e3$Diff_bolus),"Diff_bolus"] <- (time.bf+time.af)/60

# scaling and normalization
# select numerical variables for the model
num <- c("Total_slope", "Diff_bolus", "Bolus_ActI",
         "Basal_ActI", "N_bolus")
X <- e3[,num] %>% scale(.)
# We calculate norma L2 using apply
L2 <- apply(X, 2, function(x) {sqrt(sum(x^2))})
# we divied each value for its respective norma L2
X <- X/L2
```

The parameters `Extreme value` and `AUC out of range` were not added to the formula, since these would highly correlate with the subtype of event. Also, Total plasma insulin (`Total_ActI`) was removed as it is the sum of bolus and basal insulin.


```r
# Define categorical variables
cat <- c("Event_type", "Event_subtype", "weekday", "timeday")
# Build dataset for the model
lm.data <- cbind(e3[, cat], as.data.frame(X))
# Convert event subytpe to a binomial factor
lm.data <- lm.data %>% 
  mutate(Event_subtype = factor(Event_subtype,
                             levels=c("Hypoglycemia", "Hyperglycemia"),
                             labels=c(0,1), ordered = T)
         )
```

#### Logistic regression
Since this model presented two event outcome types, we choose a binomial logistic regression model using the following formula:


```r
lgm <- glm(Event_subtype ~ Total_slope + Diff_bolus + Bolus_ActI + 
            Basal_ActI + N_bolus + weekday + timeday,
            data= lm.data,
            family = binomial)
summary(lgm)
```

```
## 
## Call:
## glm(formula = Event_subtype ~ Total_slope + Diff_bolus + Bolus_ActI + 
##     Basal_ActI + N_bolus + weekday + timeday, family = binomial, 
##     data = lm.data)
## 
## Deviance Residuals: 
##        Min          1Q      Median          3Q         Max  
## -3.067e-04   2.000e-08   2.000e-08   2.000e-08   3.846e-04  
## 
## Coefficients:
##                    Estimate Std. Error z value Pr(>|z|)
## (Intercept)       2.867e+02  3.165e+04   0.009    0.993
## Total_slope       1.286e+04  1.131e+06   0.011    0.991
## Diff_bolus       -9.697e+00  1.641e+05   0.000    1.000
## Bolus_ActI        3.489e+01  2.370e+05   0.000    1.000
## Basal_ActI       -6.478e+00  1.035e+05   0.000    1.000
## N_bolus           2.097e+01  5.940e+05   0.000    1.000
## weekdayTuesday   -1.031e+00  1.966e+04   0.000    1.000
## weekdayWednesday  1.558e-01  1.532e+04   0.000    1.000
## weekdayThursday  -3.916e+00  2.150e+04   0.000    1.000
## weekdayFriday    -1.456e+01  1.958e+04  -0.001    0.999
## weekdaySaturday  -3.777e+00  2.569e+04   0.000    1.000
## weekdaySunday     1.703e+00  1.243e+04   0.000    1.000
## timedaymidday     1.856e+01  1.809e+04   0.001    0.999
## timedayafternoon -9.302e+00  5.148e+04   0.000    1.000
## timedayevening    4.593e-01  3.845e+04   0.000    1.000
## timedaynight      2.682e+01  1.732e+04   0.002    0.999
## 
## (Dispersion parameter for binomial family taken to be 1)
## 
##     Null deviance: 2.4968e+02  on 371  degrees of freedom
## Residual deviance: 3.6815e-07  on 356  degrees of freedom
## AIC: 32
## 
## Number of Fisher Scoring iterations: 25
```



# Plots

```r
# Load plots functions 

source("scripts/Plots.R")
```

## Combined glucose, risk and insulin plots on hours

Here we combine the glucose readings, computed risk based on glucose levels, insulin in plasma and insulin delivery events over the same period of time spanning several hours. It is useful to examine certain undesired events. 
We just need to use the function `gluplot()` indicating the events dataframe entry we want to show and the integrated dataset from where to extract the data.


```r
set.seed(22)
for(i in floor(runif(3, 1, nrow(events)))){
  cat("\n\n")
  print(gluplot(events[i,], fi))
}
```



![](figs/gluplot-1.png)<!-- -->

![](figs/gluplot-2.png)<!-- -->

![](figs/gluplot-3.png)<!-- -->

## Percentile plots

Similar to previous plot, these plots summarize glucose reading, computed risk based on glucose levels, insulin in plasma and insulin delivery events. However, in this instance not only one event spanning few or some hours it is shown, but the distribution curves of some days or weeks. Both glucose and risk plots show: 1) The median of values (50th percentil), 2) the interquartile range (IQR); the 25th–75th percentile band, showing 50% of the values for each timepoint, 3) The 5th–95th percentile band, showing the 90% of the values for each timepoint. A similar plot is used for insulin in plasma levels, where is shown 1) Median levels for each time point and 2) the interquartile range (IQR); the 25th–75th percentile band, showing 50% of the values. Finally, the last part of the joined plot shows the number of events (bolus and start of basal temporal) for each time point.

The function `perplot()` uses the integrated dataset, a subtitle can be added is data was subsetted (`subtit`), and the time periods for grouping varibles is defined by `tx` (by default 20 mins).


```r
# All values analyzed
perplot(fi)
```

![](figs/perplots-1.png)<!-- -->

```r
# Only certain weekdays, for instance Tuesday
x <- fi %>% filter(weekday == "Tuesday")
perplot(x, subtit="Tuesday")
```

![](figs/perplots-2.png)<!-- -->

```r
# Only certain time of day, for instance morning
x <- fi %>% filter(timeday == "morning")
perplot(x, subtit="morning", tx="5 mins")
```

![](figs/perplots-3.png)<!-- -->

```r
# We can also define moment around meal events
x <- fi %>% filter(meal_factor == "outmeal")
perplot(x, subtit="Outmeal")
```

![](figs/perplots-4.png)<!-- -->

```r
# or only show events of hyper- or hypoglycemia
for(o in c("Hyperglycemia","Hypoglycemia")){
  x <- data.frame(matrix(nrow=0, ncol=length(fi)))
  names(x) <- names(fi)
  idx <- which(events$Event_subtype == o)
  # Compute all variables for each subEvent based on the events dataframe
  for(i in idx){
    x0 <- fi %>% filter(time >= events[i,"start"] & time <= events[i,"end"])
    x <- rbind(x, x0)
  }
  print(perplot(x, subtit=o))
}
```

![](figs/perplots-5.png)<!-- -->![](figs/perplots-6.png)<!-- -->

### Meal percentile plots
For reproducing the same time of plots but indicating time around meal events we created the funcion `mealplot()`, which works likes `perplot()` but setting as 0 the meal event.


```r
mealplot(fi)
```

![](figs/mealplot-1.png)<!-- -->

## TIR plots
TIR (Time in Range) plots indicate the relative proportion of time during which glucose readings are within a target glucose range of 70–180 mg/dL. Additionally, time out of range can be subdivided into mild or severe hypoglycemia and hyperglycemia, respectively. Moreover, the function `TIR_plot()` allows to subset by weekday of time of day.


```r
TIR_plot(fi)
```

![](figs/TIR_plots-1.png)<!-- -->

```r
TIR_plot(fi, subset="weekday")
```

![](figs/TIR_plots-2.png)<!-- -->

```r
TIR_plot(fi, subset="timeday")
```

![](figs/TIR_plots-3.png)<!-- -->

## Poincaré plot

Poincaré plots provide a look to the stability of the system (in this case glucose stability). This plot is often used in physics to visualize the dynamic behavior of the investigated system (Brennan, Palaniswami, and Kamen 2001): a smaller, more concentrated plot indicates system (patient) stability, whereas a more scattered Poincaré plot indicates system (patient) irregularity, reflecting in our case poorer glucose control and rapid glucose excursions. Each point of the plot has coordinates BG(ti-1) on the y-axis and BG(ti) on the x-axis. Thus, the difference (y-x) coordinates of each data point represent the BG Rate of Change occurring between times. In the `Poincare_plot` function the red ellipse depicts 99% of the values by default. Data can also be shown subsetting it by factors such as weekday or time of the day.


```r
Poincare_plot(fi)
```

![](figs/Poincare_plot-1.png)<!-- -->

```r
Poincare_plot(fi, subset = "weekday")
```

![](figs/Poincare_plot-2.png)<!-- -->

```r
Poincare_plot(fi, subset = "timeday")
```

![](figs/Poincare_plot-3.png)<!-- -->


## Event-based clinical characteristics CVGA (24h periods)

Control Variability Grid Analysis (CVGA) is a valuable tool used to assess the glycemic regulation. This graphical representation presents the minimum and maximum glucose values within a period of time, offering both a visual and numerical evaluation of the overall quality of glycemic control (Magni et al. 2008). 

We need to extract max and minim values for given time (all 24h, a certain day or moment...) and pass this data to the funcion `ebc.plot()`.


```r
# EBC plot for 24 h period of all days
fi %>% 
  mutate(day = format(time, "%D")) %>% 
  group_by(day) %>% 
  summarize(Max = max(glucose, na.rm = T),
            Min = min(glucose, na.rm=T)) %>% 
  ebc.plot(tit="24h")
```

![](figs/CVGA_plots-1.png)<!-- -->

```r
# On Afternoon
fi %>% 
  mutate(day = format(time, "%D")) %>% 
  group_by(day, timeday) %>% 
  summarize(Max = max(glucose, na.rm = T),
            Min = min(glucose, na.rm=T)) %>% 
  filter(timeday == "afternoon") %>% 
  ebc.plot(tit=i) %>% print()
```

![](figs/CVGA_plots-2.png)<!-- -->

```r
# On Mondays
fi %>% 
  mutate(day = format(time, "%D")) %>% 
  group_by(day, weekday) %>% 
  summarize(Max = max(glucose, na.rm = T),
            Min = min(glucose, na.rm=T)) %>% 
  filter(weekday == "Monday") %>% 
  ebc.plot(tit=i) %>% print()
```

![](figs/CVGA_plots-3.png)<!-- -->

```r
# After meal
fi %>% 
  mutate(day = format(time, "%D")) %>% 
  group_by(day, meal_factor) %>% 
  summarize(Max = max(glucose, na.rm = T),
            Min = min(glucose, na.rm=T)) %>% 
  filter(meal_factor == "postmeal") %>% 
  ebc.plot(tit=i) %>% print()
```

![](figs/CVGA_plots-4.png)<!-- -->

## boxplot

Boxplot offer the possibility to visualize and assess the distribution, hence the variability, in glucose readings or risk within specific times. They offer similar information than percentile plots but showing the variability based on days of the week or time of the days. On top of that, we also added each of glucose or risk measures to better examine the number of glycemic excursions in each time period and to get a sense of the time in range.
The funcion `Boxplot_glucose()` takes the integrated data, and allow to define x-axis (Glucose or risk) and y-axis (weekday of time of the day):


```r
Boxplot_glucose(fi)
```

![](figs/boxplot-1.png)<!-- -->

```r
Boxplot_glucose(fi, xaxis = "timeday", yaxis="risk")
```

![](figs/boxplot-2.png)<!-- -->

## Events plots

Event plots show the mean number of events: hyperglycemia, hypoglycemia and meals, happening for each specific time period. This plot is helpful in conjunction with previous Chi-squared analysis to find moment of the day or days of the week where patient can be more prone to undesired events.
The function `Event_plot()` requires the integrated and events dataset, and events can be divided by weekday or time of the day by the variable `subset`.


```r
Event_plot(fi, events)
```

![](figs/Event_plots-1.png)<!-- -->

```r
Event_plot(fi, events, subset="timeday")
```

![](figs/Event_plots-2.png)<!-- -->






