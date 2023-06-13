library(tidyverse)
library(lubridate)

# useful functions
# Arrange functions:
# substract function
substract = function(a, b) {
  a - (b)
}

# functions to compute percentils
quan25 = function(x) {
  quantile(x,probs = 0.25, na.rm = T)
}
quan75 = function(x) {
  quantile(x,probs = 0.75, na.rm = T)
}
quan5 = function(x) {
  quantile(x,probs = 0.05, na.rm = T)
}
quan95 = function(x) {
  quantile(x,probs = 0.95, na.rm = T)
}

#########################################################################
library(kableExtra)

# For "kableExtra," we need to specify "html" format:
show_table <- function(df) {
  kable(head(airquality), digits = 2,
        format = "html", row.names = TRUE) %>%
  kable_styling(bootstrap_options = c("striped", "hover"),
                full_width = F,
                font_size = 12,
                position = "center")
}