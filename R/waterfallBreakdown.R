#' Waterfall chart for prediction breakdown of a prediction (single row of data)
#'
#' This function plots as waterfall chart of the feature impact breakdown for a single data row.
#'
#' @param breakdown Numeric vector of prediction breakdown.
#' @param type Type of task `type = "regression"` or `type = "binary"` (classification).
#' @param labels Character vector for feature names.
#' @param label.values Numeric vector for feature value.
#' @param limits The limits of the y axis - for binary this is on logit scale (e.g. c(-3,3) would give a scale approximately from 0.04 to 0.96)
#'
#' @example
#'
#' waterfallBreakdown(breakdown = c(0.1, -0.2, 0.3, 0.4),
#' type      = "bin",
#' labels    = letters[1:4],
#' label.values = runif(4))
#'
#' @return a ggplots object from waterfalls
#' @export
#' @import waterfalls
#' @import scales
#' @import ggplot2
#

waterfallBreakdown <- function(breakdown, type = c("binary", "regression"),
                               labels, limits = c(NA, NA)) {
  type   <- match.arg(type)
  weight <- sum(breakdown)

  if (type == "regression") {
    waterfalls::waterfall(values = breakdown,
                          rect_text_labels = round(breakdown, 2),
                          labels = labels,
                          calc_total = TRUE,
                          total_rect_text = round(weight, 2),
                          total_axis_text = "Prediction") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

  } else {
    inverse_logit_trans <- scales::trans_new("inverse logit",
                                             transform = plogis,
                                             inverse = qlogis)
    inverse_logit_labels = function(x) {
      return(1/(1 + exp(-x)))
    }
    logit = function(x) {
      return(log(x/(1 - x)))
    }

    ybreaks <- logit(seq(2, 98, 2)/100)

    waterfalls::waterfall(values = breakdown,
                          rect_text_labels = round(breakdown, 2),
                          labels = labels,
                          calc_total = TRUE,
                          total_rect_text = round(weight, 2),
                          total_axis_text = "Prediction") +
      scale_y_continuous(labels = inverse_logit_labels,
                         breaks = ybreaks,
                         limits = limits) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
}



