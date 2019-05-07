---
author: "Satoshi Kato"
title: variable responces of xgboost model
date: "2019/05/07"
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
install.packages("pdp", dependencies = TRUE)

```


```r
require(tidyverse)
require(xgboost)

require(pdp)
require(DALEX)
```

# Preparation (continued)


```r
loaded.obs  <- readRDS("./middle/data_and_model.Rds")
# loaded.obs %>% str
model.xgb   <- loaded.obs$model$xgb 

train.label  <- loaded.obs$data$train$label
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix("./middle/train.xgbDMatrix")
#> [23:02:50] 4000x9 matrix with 36000 entries loaded from ./middle/train.xgbDMatrix

test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
#> [23:02:50] 10999x9 matrix with 98991 entries loaded from ./middle/test.xgbDMatrix
```
# Target features

Target features to watch feature responces are filterd using `xgb.importance()`


```r

var.imp <- xgb.importance(model = model.xgb,
                          feature_names = dimnames(train.xgb.DMatrix)[[2]])

var.imp %>% mutate_if(is.numeric, round, digits = 4)
#>                 Feature   Gain  Cover Frequency
#> 1    satisfaction_level 0.3111 0.2191    0.2150
#> 2       last_evaluation 0.2117 0.1746    0.2066
#> 3  average_montly_hours 0.1890 0.1740    0.2112
#> 4    time_spend_company 0.1399 0.1621    0.1186
#> 5        number_project 0.0525 0.0754    0.1133
#> 6                salary 0.0487 0.0884    0.0446
#> 7         Work_accident 0.0293 0.0474    0.0212
#> 8                 sales 0.0160 0.0464    0.0638
#> 9 promotion_last_5years 0.0018 0.0126    0.0057
target.feature <- var.imp$Feature %>% head(6)
```
In this example, target features are satisfaction_level, last_evaluation, average_montly_hours, time_spend_company, number_project, salary

# Marginal Response for a Single Variable

##  ICE + PDP

individual conditional expectation (ICE) & Partial Dependence Plots (PDP) was drawn by subsample instances (due to large size)


```r
sub.sample <- sample(NROW(test.matrix), 500)
sub.matrix <- test.matrix[sub.sample, ]
sub.label  <- test.label[sub.sample]

pdp::partial(
  model.xgb, pred.var = "last_evaluation", train = sub.matrix, 
  plot = TRUE, rug = TRUE, ice = TRUE, alpha = 0.1,
  plot.engine = "ggplot2") #+ ggtitle(sprintf("ICE + PDP: %s", feature.name))
```

![](200_Sensitivity_analysis_files/figure-html/unnamed-chunk-1-1.png)<!-- -->

## Accumulated Local Effects Plots (ALE Plot)


```r
explainer.xgb <- DALEX::explain(
  model.xgb, data = test.matrix, y = test.label)

ale.xgb <- DALEX::variable_response(
  explainer.xgb, variable = "last_evaluation", type = "ale")

ale.xgb %>% plot()
```

![](200_Sensitivity_analysis_files/figure-html/unnamed-chunk-2-1.png)<!-- -->

## comparison by feature: ICE+PDP vs ALE plot


```r
sub.sample <- sample(NROW(test.matrix), 500)
sub.matrix <- test.matrix[sub.sample, ]
sub.label  <- test.label[sub.sample]

plot.pdps <- list()
for(feature.name in target.feature){
  plot.pdps[[feature.name]] <- pdp::partial(
     model.xgb, pred.var = feature.name, train = sub.matrix, 
     plot = TRUE, rug = TRUE, ice = TRUE, alpha = 0.1,
     plot.engine = "ggplot2") #+ ggtitle(sprintf("ICE + PDP: %s", feature.name))
}

plot.ales <- list()
for(feature.name in target.feature){
  ale <- variable_response(
    explainer.xgb, variable = feature.name, type = "ale", labels = NULL)
  
  plot.ales[[feature.name]] <- plot(ale) +
    theme(legend.position = 'none')# + ggtitle(feature.name)
}

ggp.varRes <- gridExtra::grid.arrange(
  grobs = c(plot.pdps, plot.ales), nrow = 2)
ggsave(ggp.varRes, width = 12, height = 4,
        filename = "./output/image.files/200_pdp-ale.png")
```
![](./output/image.files/200_pdp-ale.png)




