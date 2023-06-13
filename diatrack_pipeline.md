---
title: "Diabetes data analysis"
author: "Josep Garnica Caparrós"
date: "2023-06-13"
output:
  html_document:
    toc: yes
    toc_float: true
    keep_md: yes
subtitle: "Analysis of combined continuous glucose monitoring and insulin pump delivery data for type 1 diabetes treatment"
---



# Define parameters to use for analysis

## Load utilities and environment


```
## * The library is already synchronized with the lockfile.
```

## Diabetes manegement parameters

We define the parameters we will use for our analysis. The threshold for hypoglycemia and hyperglycemia, the raw data source type, the time period we want to study and the how we categorize the times of the day and define event time span.




# Load and process CGM data
In this step we use the function `CGM_process()` to convert datetime data from CGM source into `POSIXct`format. Also, we compute the slope in **mg/dL/min** between glucose reading entries (`slope`) and every 15 minutes (`slope15`).

<table class="table table-striped table-hover" style="font-size: 10px; width: auto !important; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;"> time </th>
   <th style="text-align:right;"> glucose </th>
   <th style="text-align:right;"> slope </th>
   <th style="text-align:right;"> slope15 </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:22:00 </td>
   <td style="text-align:right;"> 128 </td>
   <td style="text-align:right;"> -1.00 </td>
   <td style="text-align:right;"> -0.47 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:27:00 </td>
   <td style="text-align:right;"> 132 </td>
   <td style="text-align:right;"> 0.80 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:32:00 </td>
   <td style="text-align:right;"> 139 </td>
   <td style="text-align:right;"> 1.40 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:37:00 </td>
   <td style="text-align:right;"> 143 </td>
   <td style="text-align:right;"> 0.80 </td>
   <td style="text-align:right;"> 1.00 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:42:00 </td>
   <td style="text-align:right;"> 144 </td>
   <td style="text-align:right;"> 0.20 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:49:00 </td>
   <td style="text-align:right;"> 139 </td>
   <td style="text-align:right;"> -0.71 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2021-12-29 08:54:00 </td>
   <td style="text-align:right;"> 142 </td>
   <td style="text-align:right;"> 0.60 </td>
   <td style="text-align:right;"> -0.06 </td>
  </tr>
</tbody>
</table>

# Load and process Insulin pump data

In this step we use the function `Insulin_process()` to tidy up raw data from Minimed Pump (Medtronic) and also estimate the insulin in plasma levels using the model from Schiavon et al., 2018.

<img src="figs/Shiavon_2018_model3.png" width="50%" style="display: block; margin: auto;" />
*Model exracted from (Schiavon, Dalla Man, and Cobelli 2018). U: Units of insulin injected, t: time, Г: time delay, Isc1:Insulin compartment1 (subcutaneous), Isc2: Insulin compartment 2 (Interstitial), Ip: Insulin compartment 3 (plasma), Kd: rate of diffusion from compartment 1 to 2, Ka1: rate of diffusion from compartment 1 to 3, ka2: rate of diffusion from compartment 2 to 3, ke: rate of clearance from compartment 3, V1: plasma volume.*


```
## [1] "Processing of insulin data completed"
## [1] "Starting insulin in plasma estimation"
```

<table class="table table-striped table-hover" style="font-size: 10px; width: auto !important; margin-left: auto; margin-right: auto;">
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
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:09:00 </td>
   <td style="text-align:left;"> Normal </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.96 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.83 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:10:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.96 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.82 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:11:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.95 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.81 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:12:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.94 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.80 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:13:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.93 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.80 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:14:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.93 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.79 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2022-12-05 14:15:00 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.85 </td>
   <td style="text-align:right;"> 0.01 </td>
   <td style="text-align:right;"> 0.92 </td>
   <td style="text-align:right;"> 0.86 </td>
   <td style="text-align:right;"> 1.78 </td>
  </tr>
</tbody>
</table>


# Merge glucose and insulin datasets

Now we merge glucose levels and insulin events data, and get rid of time entries without meaningful information.




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


<table class="table table-striped table-hover" style="font-size: 10px; width: auto !important; margin-left: auto; margin-right: auto;">
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
   <td style="text-align:right;"> 185.45 </td>
   <td style="text-align:right;"> 2.00 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 0.35 </td>
   <td style="text-align:right;"> 0.39 </td>
   <td style="text-align:right;"> 0.74 </td>
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
   <td style="text-align:right;"> 1027.08 </td>
   <td style="text-align:right;"> 2.75 </td>
   <td style="text-align:right;"> 86 </td>
   <td style="text-align:right;"> 2.10 </td>
   <td style="text-align:right;"> 0.70 </td>
   <td style="text-align:right;"> 2.80 </td>
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
   <td style="text-align:right;"> 454.87 </td>
   <td style="text-align:right;"> 0.81 </td>
   <td style="text-align:right;"> 90 </td>
   <td style="text-align:right;"> 0.35 </td>
   <td style="text-align:right;"> 0.73 </td>
   <td style="text-align:right;"> 1.07 </td>
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
   <td style="text-align:right;"> 8735.40 </td>
   <td style="text-align:right;"> 8.53 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 0.05 </td>
   <td style="text-align:right;"> 0.42 </td>
   <td style="text-align:right;"> 0.47 </td>
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

# Analysis

We also categorize datetime in weekdays, hours, and timeday of the glucose and insulin data integrated dataframe, using the funcion `Categories_time()`.

<table class="table table-striped table-hover" style="font-size: 10px; width: auto !important; margin-left: auto; margin-right: auto;">
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
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> NA </td>
  </tr>
</tbody>
</table>

## Diabetes measuraments

We use the previous integrated and events datasets to obtain meaningful and interpretable values of overall diabetes management success in a summary table, using the function `Summary_diabetes_measures()`: 


```
## Glucose_measures 
## <table class="table table-striped table-hover" style="font-size: 10px; width: auto !important; margin-left: auto; margin-right: auto;">
##  <thead>
##   <tr>
##    <th style="text-align:left;"> Stat </th>
##    <th style="text-align:left;"> Value </th>
##   </tr>
##  </thead>
## <tbody>
##   <tr>
##    <td style="text-align:left;"> Days of analysis </td>
##    <td style="text-align:left;"> 197 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Sensor coverage </td>
##    <td style="text-align:left;"> 91.7 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> SG mean &amp; SD </td>
##    <td style="text-align:left;"> 134.9 ± 49.5 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> SG mean &amp; SD (premeal) </td>
##    <td style="text-align:left;"> 115.8 ± 47.3 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> SG mean &amp; SD (postmeal) </td>
##    <td style="text-align:left;"> 156.4 ± 55.9 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> SG mean &amp; SD (outmeal) </td>
##    <td style="text-align:left;"> 127.6 ± 40.6 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV </td>
##    <td style="text-align:left;"> 36.7 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV (premeal) </td>
##    <td style="text-align:left;"> 40.89 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV (postmeal) </td>
##    <td style="text-align:left;"> 35.77 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV (outmeal) </td>
##    <td style="text-align:left;"> 31.84 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> GMI </td>
##    <td style="text-align:left;"> 6.54 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> BGRI </td>
##    <td style="text-align:left;"> 1.2 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> LBGI </td>
##    <td style="text-align:left;"> 4.9 ± 3.9 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV LBGI </td>
##    <td style="text-align:left;"> 81 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> HBGI </td>
##    <td style="text-align:left;"> 6.1 ± 4.3 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV HBGI </td>
##    <td style="text-align:left;"> 70.35 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> BGRI (premeal) </td>
##    <td style="text-align:left;"> -0.8 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> LBGI (premeal) </td>
##    <td style="text-align:left;"> 6.1 ± 4.7 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> HBGI (premeal) </td>
##    <td style="text-align:left;"> 5.3 ± 4.2 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> BGRI (postmeal) </td>
##    <td style="text-align:left;"> 3.5 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> LBGI (postmeal) </td>
##    <td style="text-align:left;"> 4.1 ± 3.4 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> HBGI (postmeal) </td>
##    <td style="text-align:left;"> 7.6 ± 4.7 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> BGRI (outmeal) </td>
##    <td style="text-align:left;"> 0.6 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> LBGI (outmeal) </td>
##    <td style="text-align:left;"> 4.6 ± 3.6 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> HBGI (outmeal) </td>
##    <td style="text-align:left;"> 5.2 ± 3.6 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> SD Rate of Change (RoC) </td>
##    <td style="text-align:left;"> 1.97 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> % offvalues [-2,2] RoC </td>
##    <td style="text-align:left;"> 8.6 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time in range </td>
##    <td style="text-align:left;"> 79 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time in hyperglycemia </td>
##    <td style="text-align:left;"> 12.4 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time in extreme hyperglycemia </td>
##    <td style="text-align:left;"> 3.2 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time in hypoglycemia </td>
##    <td style="text-align:left;"> 4 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time in extreme hypoglycemia </td>
##    <td style="text-align:left;"> 1.3 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Week day with worst TIR </td>
##    <td style="text-align:left;"> Sunday </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Week day with highest HBGI </td>
##    <td style="text-align:left;"> Sunday </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Week day with highest LBGI </td>
##    <td style="text-align:left;"> Thursday </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time of day with worst TIR </td>
##    <td style="text-align:left;"> night </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time of day with highest HBGI </td>
##    <td style="text-align:left;"> night </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Time of day with highest LBGI </td>
##    <td style="text-align:left;"> night </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N hyperglycemia/day </td>
##    <td style="text-align:left;"> 2.2 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N hypoglycemia/day </td>
##    <td style="text-align:left;"> 0.98 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> % hypoglycemia overcorrection </td>
##    <td style="text-align:left;"> 0.09 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> % hyperglycemia overcorrection </td>
##    <td style="text-align:left;"> 0 </td>
##   </tr>
## </tbody>
## </table>Insulin_measures 
## <table class="table table-striped table-hover" style="font-size: 10px; width: auto !important; margin-left: auto; margin-right: auto;">
##  <thead>
##   <tr>
##    <th style="text-align:left;"> Stat </th>
##    <th style="text-align:left;"> Value </th>
##   </tr>
##  </thead>
## <tbody>
##   <tr>
##    <td style="text-align:left;"> Total Insulin/day </td>
##    <td style="text-align:left;"> 31.6 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Total bolus insulin/day </td>
##    <td style="text-align:left;"> 14.4 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Total basal insulin/day </td>
##    <td style="text-align:left;"> 17.3 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N bolus/day </td>
##    <td style="text-align:left;"> 15.2 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Mean basal rate </td>
##    <td style="text-align:left;"> 0.7 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> CV basal rate </td>
##    <td style="text-align:left;"> 47.3 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> Normal bolus size </td>
##    <td style="text-align:left;"> 0.9 ± 0.8 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N temporal basal/day </td>
##    <td style="text-align:left;"> 4.7 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N 0 basal/day </td>
##    <td style="text-align:left;"> 4.3 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N bolus/meal </td>
##    <td style="text-align:left;"> 3.7 ± 2.9 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N bolus outmeal/day </td>
##    <td style="text-align:left;"> 2.9 ± 3.2 </td>
##   </tr>
##   <tr>
##    <td style="text-align:left;"> N detected meals/day </td>
##    <td style="text-align:left;"> 2.7 </td>
##   </tr>
## </tbody>
## </table>
```




## Stats

### Chi-squared test for weekday and time day distribution of undesired events

In this part we aim to explore significant correlation of undesired diabetes management events (hypoglycemia and hyperglycemia) and days of the week and/or times of day. The aim of this is to mainly try to find moments of the week or day statistically more prone to undesired events in order to focus the diabetes management adjustments. This endeavor was addressed by performing chi-square test on the number of hyper- and hypoglycemia events, respectively, in each time day of the week and each time of the day (*morning, midday, afternoon, evening, and night*). 


```
## weekday
##    Monday   Tuesday Wednesday  Thursday    Friday  Saturday    Sunday 
##        70        48        54        54        39        87        81
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq.hyper
## X-squared = 30.762, df = 6, p-value = 2.814e-05
```

```
## weekday
##    Monday   Tuesday Wednesday  Thursday    Friday  Saturday    Sunday 
##        17        24        34        31        34        22        31
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq.hypo
## X-squared = 9.4922, df = 6, p-value = 0.1477
```

```
## timeday
##   morning    midday afternoon   evening     night 
##        85        70        62        76       140
```

```
## 
## 	Chi-squared test for given probabilities
## 
## data:  cq2.hyper
## X-squared = 44.425, df = 4, p-value = 5.236e-09
```

```
## timeday
##   morning    midday afternoon   evening     night 
##        41        15        25        38        74
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



The parameters `Extreme value` and `AUC out of range` were not added to the formula, since these would highly correlate with the subtype of event. Also, Total plasma insulin (`Total_ActI`) was removed as it is the sum of bolus and basal insulin.



#### Logistic regression
Since this model presented two event outcome types, we choose a binomial logistic regression model using the following formula:


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


## Combined glucose, risk and insulin plots on hours

Here we combine the glucose readings, computed risk based on glucose levels, insulin in plasma and insulin delivery events over the same period of time spanning several hours. It is useful to examine certain undesired events. 
We just need to use the function `gluplot()` indicating the events dataframe entry we want to show and the integrated dataset from where to extract the data.

![](/figs/gluplot-1.png)<!-- -->![](/figs/gluplot-2.png)<!-- -->![](/figs/gluplot-3.png)<!-- -->

## Percentile plots

Similar to previous plot, these plots summarize glucose reading, computed risk based on glucose levels, insulin in plasma and insulin delivery events. However, in this instance not only one event spanning few or some hours it is shown, but the distribution curves of some days or weeks. Both glucose and risk plots show: 1) The median of values (50th percentil), 2) the interquartile range (IQR); the 25th–75th percentile band, showing 50% of the values for each timepoint, 3) The 5th–95th percentile band, showing the 90% of the values for each timepoint. A similar plot is used for insulin in plasma levels, where is shown 1) Median levels for each time point and 2) the interquartile range (IQR); the 25th–75th percentile band, showing 50% of the values. Finally, the last part of the joined plot shows the number of events (bolus and start of basal temporal) for each time point.

The function `perplot()` uses the integrated dataset, a subtitle can be added is data was subsetted (`subtit`), and the time periods for grouping varibles is defined by `tx` (by default 20 mins).

![](/figs/perplots-1.png)<!-- -->![](/figs/perplots-2.png)<!-- -->![](/figs/perplots-3.png)<!-- -->![](/figs/perplots-4.png)<!-- -->![](/figs/perplots-5.png)<!-- -->![](/figs/perplots-6.png)<!-- -->

### Meal percentile plots
For reproducing the same time of plots but indicating time around meal events we created the funcion `mealplot()`, which works likes `perplot()` but setting as 0 the meal event.

![](/figs/mealplot-1.png)<!-- -->

## TIR plots
TIR (Time in Range) plots indicate the relative proportion of time during which glucose readings are within a target glucose range of 70–180 mg/dL. Additionally, time out of range can be subdivided into mild or severe hypoglycemia and hyperglycemia, respectively. Moreover, the function `TIR_plot()` allows to subset by weekday of time of day.

![](/figs/TIR_plots-1.png)<!-- -->![](/figs/TIR_plots-2.png)<!-- -->![](/figs/TIR_plots-3.png)<!-- -->

## Poincaré plot

Poincaré plots provide a look to the stability of the system (in this case glucose stability). This plot is often used in physics to visualize the dynamic behavior of the investigated system (Brennan, Palaniswami, and Kamen 2001): a smaller, more concentrated plot indicates system (patient) stability, whereas a more scattered Poincaré plot indicates system (patient) irregularity, reflecting in our case poorer glucose control and rapid glucose excursions. Each point of the plot has coordinates BG(ti-1) on the y-axis and BG(ti) on the x-axis. Thus, the difference (y-x) coordinates of each data point represent the BG Rate of Change occurring between times. In the `Poincare_plot` function the red ellipse depicts 99% of the values by default. Data can also be shown subsetting it by factors such as weekday or time of the day.

![](/figs/Poincare_plot-1.png)<!-- -->![](/figs/Poincare_plot-2.png)<!-- -->![](/figs/Poincare_plot-3.png)<!-- -->


## Event-based clinical characteristics CVGA (24h periods)

Control Variability Grid Analysis (CVGA) is a valuable tool used to assess the glycemic regulation. This graphical representation presents the minimum and maximum glucose values within a period of time, offering both a visual and numerical evaluation of the overall quality of glycemic control (Magni et al. 2008). 

We need to extract max and minim values for given time (all 24h, a certain day or moment...) and pass this data to the funcion `ebc.plot()`.

![](/figs/CVGA plots-1.png)<!-- -->![](/figs/CVGA plots-2.png)<!-- -->![](/figs/CVGA plots-3.png)<!-- -->![](/figs/CVGA plots-4.png)<!-- -->

## boxplot

Boxplot offer the possibility to visualize and assess the distribution, hence the variability, in glucose readings or risk within specific times. They offer similar information than percentile plots but showing the variability based on days of the week or time of the days. On top of that, we also added each of glucose or risk measures to better examine the number of glycemic excursions in each time period and to get a sense of the time in range.
The funcion `Boxplot_glucose()` takes the integrated data, and allow to define x-axis (Glucose or risk) and y-axis (weekday of time of the day):

![](/figs/boxplot-1.png)<!-- -->![](/figs/boxplot-2.png)<!-- -->

## Events plots

Event plots show the mean number of events: hyperglycemia, hypoglycemia and meals, happening for each specific time period. This plot is helpful in conjunction with previous Chi-squared analysis to find moment of the day or days of the week where patient can be more prone to undesired events.
The function `Event_plot()` requires the integrated and events dataset, and events can be divided by weekday or time of the day by the variable `subset`.

![](/figs/Event_plots-1.png)<!-- -->![](/figs/Event_plots-2.png)<!-- -->






