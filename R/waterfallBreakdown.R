#' Step 3-2: Waterfall chart for prediction breakdow of a single row of data
#'
#' This function plots as waterfall chart of the feature impact breakdown for a single data row.
#' @param summary.breakdown A summary.breakdown object returnd by summaryBreakdown().
#' @param limits The limits of the y axis - for binary this is on logit scale (e.g. c(-3,3) would give a scale approximately from 0.04 to 0.96)

#' Step 3-1: Get prediction breakdown for a single row of data
#'
#' This function return a list of the feature impact breakdown for a single data row.

#' @return a ggplots object from waterfalls
#' @export
#' @import waterfalls
#' @import scales
#' @import ggplot2
#
waterfallBreakdown <- function(summary.breakdown, limits = c(NA, NA)) {

  type              <- summary.breakdown$type
  weight            <- summary.breakdown$weight
  breakdown_summary <- summary.breakdown$breakdown
  labels            <- summary.breakdown$labels

  if (type == "regression") {
    waterfalls::waterfall(values = breakdown_summary,
                          rect_text_labels = round(breakdown_summary, 2),
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
    waterfalls::waterfall(values = breakdown_summary,
                          rect_text_labels = round(breakdown_summary, 2),
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
