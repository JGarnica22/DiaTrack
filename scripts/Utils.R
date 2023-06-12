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