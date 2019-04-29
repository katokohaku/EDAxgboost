---
author: "Satoshi Kato"
title: rule extraction from xgboost model"
date: "2019/04/29"
output:
  html_document:
    fig_caption: yes
    pandoc_args:
      - --from
      - markdown+autolink_bare_uris+tex_math_single_backslash-implicit_figures
    toc: yes
    keep_md: yes
  word_document:
    toc: yes
    toc_depth: 3
  pdf_document:
    toc: yes
    toc_depth: 3
editor_options: 
  chunk_output_type: inline
---




```r
install.packages("DiagrammeR", dependencies = TRUE)
install.packages("inTtrees", dependencies = TRUE)

install.packages("devtools", dependencies = TRUE)
devtools::install_github("AppliedDataSciencePartners/xgboostExplainer")
```


```r
require(tidyverse)
require(xgboost)
require(AUC)
require(caret)
require(DALEX)
```

# Preparation (continued)


```r
loaded.obs  <- readRDS("./middle/data_and_model.Rds")

model.xgb   <- loaded.obs$model$xgb 

train.label <- loaded.obs$data$train$label
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix("./middle/train.xgbDMatrix")
```

```
[22:02:24] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[22:02:24] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
```
# Marginal Response for a Single Variable


```r
explainer.xgb <- DALEX::explain(model.xgb, 
                                data  = test.matrix, 
                                y     = test.label, 
                                label = "xgboost")

var.imp <- xgb.importance(model = model.xgb,
                          feature_names = dimnames(train.xgb.DMatrix)[[2]])

var.imp %>% mutate_if(is.numeric, round, digits = 4)
```

```
                Feature   Gain  Cover Frequency
1    satisfaction_level 0.3343 0.2370    0.1600
2    time_spend_company 0.2611 0.2832    0.2629
3        number_project 0.1826 0.2016    0.1086
4       last_evaluation 0.1610 0.1222    0.1943
5  average_montly_hours 0.0593 0.1297    0.1771
6         Work_accident 0.0008 0.0069    0.0171
7       sales_technical 0.0003 0.0092    0.0286
8            salary_low 0.0002 0.0030    0.0171
9         sales_support 0.0002 0.0021    0.0114
10          sales_sales 0.0001 0.0006    0.0114
11     sales_accounting 0.0001 0.0022    0.0057
12          sales_RandD 0.0000 0.0024    0.0057
```

```r
target.feature <- var.imp$Feature %>% head(5)
target.feature
```

```
[1] "satisfaction_level"   "time_spend_company"   "number_project"      
[4] "last_evaluation"      "average_montly_hours"
```

## Partial Dependence Plots (PDP)


```r
plot.pdps <- list()
for(feature.name in target.feature){
  pdp <- variable_response(explainer.xgb,
                           variable =  feature.name,
                           type = "pdp")
  plot.pdps[[feature.name]] <- plot(pdp) + ggtitle(feature.name)
}
plot.pdps[[1]] 
```

![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

## Accumulated Local Effects Plots (ALE Plot)


```r
plot.ales <- list()
for(feature.name in target.feature){
  ale <- variable_response(explainer.xgb,
                           variable =  feature.name,
                           type = "ale")
  plot.ales[[feature.name]] <- plot(ale) + ggtitle(feature.name)
}
plot.ales[[1]] 
```

![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-2-1.png)<!-- -->




```r
for(feature.name in target.feature){
gridExtra::grid.arrange(plot.pdps[[feature.name]], 
                        plot.ales[[feature.name]], ncol=2)
}
```

![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-3-1.png)<!-- -->![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-3-2.png)<!-- -->![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-3-3.png)<!-- -->![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-3-4.png)<!-- -->![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-3-5.png)<!-- -->


# SHAP contribution dependency plots

Visualizing the SHAP feature contribution to prediction dependencies on feature value.

These scatterplots represent how SHAP feature contributions depend of feature values. The similarity to partial dependency plots is that they also give an idea for how feature values affect predictions. However, in partial dependency plots, we usually see marginal dependencies of model prediction on feature value, while SHAP contribution dependency plots display the estimated contributions of a feature to model prediction for each individual case.

When plot_loess = TRUE is set, feature values are rounded to 3 significant digits and weighted LOESS is computed and plotted, where weights are the numbers of data points at each rounded value.

Note: SHAP contributions are shown on the scale of model margin. E.g., for a logistic binomial objective, the margin is prediction before a sigmoidal transform into probability-like values. Also, since SHAP stands for "SHapley Additive exPlanation" (model prediction = sum of SHAP contributions for all features + bias), depending on the objective used, transforming SHAP contributions for a feature from the marginal to the prediction space is not necessarily a meaningful thing to do.


```r
xgb.plot.shap(data  = train.matrix,
              model = model.xgb, 
              # trees = trees0, 
              # target_class = 1, 
              # plot_loess = FALSE,
              top_n = 6,
              n_col = 2, col = col, pch = 16, pch_NA = 17)
```

![](050_Sensitivity_analysis_files/figure-html/unnamed-chunk-4-1.png)<!-- -->

