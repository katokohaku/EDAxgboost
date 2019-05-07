#' Step 3-1: Get prediction breakdown for a single row of data
#'
#' This function return a list of the feature impact breakdown for a single data row.
#' @param xgb.breakdown A xgb.breakdown object returnd by explainPredictions.
#' @param DMatrix The DMatrix in which the row to be predicted is stored
#' @param data.matrix The matrix of data from which the DMatrix was built
#' @param idx The row number of the data to be explained
#' @param type The objective function of the model - either "binary" (for binary:logistic) or "regression" (for reg:linear)
#' @param threshold Default = 0.0001. The waterfall chart will group all variables with absolute impact less than the threshold into a variable called 'Other'

#' @return a list
#' @export
#' @import data.table
#' @import xgboost
#
summaryBreakdown <- function(xgb.breakdown, DMatrix, data.matrix,
                             idx, type = "binary", threshold = 1e-04, .show.result = TRUE){
  breakdown <- xgb.breakdown[idx, ]
  weight = rowSums(breakdown)

  if (type == "regression") {
    pred = weight
  }  else {
    pred = 1/(1 + exp(-weight))
  }
  breakdown_summary = as.matrix(breakdown)[1, ]
  data_for_label = data.matrix[idx, ]
  i = order(abs(breakdown_summary), decreasing = TRUE)
  breakdown_summary = breakdown_summary[i]
  data_for_label = data_for_label[i]

  intercept = breakdown_summary[names(breakdown_summary) == "intercept"]
  data_for_label = data_for_label[names(breakdown_summary) != "intercept"]
  breakdown_summary = breakdown_summary[names(breakdown_summary) != "intercept"]

  i_other = which(abs(breakdown_summary) < threshold)
  other_impact = 0
  if (length(i_other > 0)) {
    other_impact = sum(breakdown_summary[i_other])
    names(other_impact) = "other"
    breakdown_summary = breakdown_summary[-i_other]
    data_for_label = data_for_label[-i_other]
  }

  if (abs(other_impact) > 0) {
    breakdown_summary = c(intercept, breakdown_summary, other_impact)
    data_for_label = c("", data_for_label, "")
    labels = paste0(names(breakdown_summary), " = ", data_for_label)
    labels[1] = "intercept"
    labels[length(labels)] = "other"
  } else {
    breakdown_summary = c(intercept, breakdown_summary)
    data_for_label = c("", data_for_label)
    labels = paste0(names(breakdown_summary), " = ", data_for_label)
    labels[1] = "intercept"
  }

  names(breakdown_summary) <- labels

  Actual = NA
  if (!is.null(getinfo(DMatrix, "label"))) {
    Actual = getinfo(slice(DMatrix, as.integer(idx)), "label")
  }

  if(.show.result){
    cat("\nActual: ", Actual)
    cat("\nPrediction: ", pred)
    cat("\nWeight: ", weight)
    cat("\nBreakdown")
    cat("\n")
    print(breakdown_summary)
  }

  res <- list(
    type = type, actual = Actual, prediction = pred, weight = weight,
    labels = labels, breakdown = breakdown_summary
  )

  return(res)
}

