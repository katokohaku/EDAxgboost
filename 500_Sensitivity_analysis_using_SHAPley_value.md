---
author: "Satoshi Kato"
title: individual explanation using Shapley value
date: "2019/05/09"
output:
  html_document:
    fig_caption: yes
    pandoc_args:
      - --from
      - markdown+autolink_bare_uris+tex_math_single_backslash-implicit_figures
    keep_md: yes
    toc: yes
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
install.packages("devtools", dependencies = TRUE)
devtools::install_github("AppliedDataSciencePartners/xgboostExplainer")

install.packages("ggridges", dependencies = TRUE)

```


```r
require(tidyverse)
require(magrittr)
require(data.table)
require(xgboost)
require(xgboostExplainer)
require(ggridges)

```

# Preparation 


```r
loaded.obs  <- readRDS("./middle/data_and_model.Rds")

model.xgb   <- loaded.obs$model$xgb 

train.label <- loaded.obs$data$train$label
train.df    <- loaded.obs$data$train$dummy.data.frame
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix(train.matrix, label = train.label, missing = NA)

test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix(test.matrix, missing = NA)
```

# breakdown obsavation

## Using Shapley value

According to help(xgboost:::predict.xgb.Booster)@Details

Setting `predcontrib = TRUE` allows to calculate contributions of each feature to individual predictions. 

*  For "gblinear" booster, feature contributions are simply linear terms (feature_beta * feature_value). 
*  For "gbtree" booster, feature contributions are SHAP values (Lundberg 2017) that sum to the difference between the expected output of the model and the current prediction (where the hessian weights are used to compute the expectations). 


```r
prediction.xgb <- xgboost:::predict.xgb.Booster(
  model.xgb, newdata = train.matrix)

predShap.xgb <- xgboost:::predict.xgb.Booster(
  model.xgb, newdata = train.matrix, 
  predcontrib = TRUE, approxcontrib = FALSE) %>% 
  data.frame()

predShap.xgb %>% head(4) %>% t
                                 1            2            3            4
satisfaction_level    -0.515436172 -0.586677372  0.525480807  2.053030491
last_evaluation        0.121358186  0.369296879  0.057982970 -0.399072826
number_project        -0.022691106  0.437221318 -0.095180556  0.096285738
average_montly_hours   0.872058332 -0.126130879 -0.131584838  0.393718511
time_spend_company     0.924191236  0.174715430  0.149822012 -0.294579685
Work_accident          0.100723140  0.089056358  0.109960638  0.114590660
promotion_last_5years  0.006513606  0.006683344  0.004951648  0.005639516
sales                 -0.089338966  0.129772797 -0.278872371  0.240690008
salary                -0.218401656 -0.166973829  0.407709092  0.247819394
BIAS                  -0.005168790 -0.005168790 -0.005168790 -0.005168790
```


```r
prediction.xgb %>% head
[1] 0.7638327 0.5797617 0.6781101 0.9207772 0.4998003 0.9250071
weight.shap <- predShap.xgb %>% head %>% rowSums()
weight.shap
          1           2           3           4           5           6 
 1.17380781  0.32179525  0.74510061  2.45295302 -0.00079815  2.51240769 
1/(1 + exp(-weight.shap))
        1         2         3         4         5         6 
0.7638326 0.5797617 0.6781102 0.9207771 0.4998005 0.9250071 
```


```r
source("./R/waterfallBreakdown.R")

ggp.shap <- waterfallBreakdown(
  breakdown = unlist(predShap.xgb[1, ]), type = "binary",
  labels = paste(colnames(predShap.xgb), 
                 c(train.matrix[1, ],""), sep =" = ")) +
  ggtitle("SHAP estimates")

ggsave(ggp.shap, filename = "./output/image.files/500_breakdownSHAP.png",
       width = 5, height = 3.5)
```

![](output/image.files/500_breakdownSHAP.png)


# SHAP contribution dependency plots

## Average feature responce

**According to man(xgb.plot.shap)::Detail**

Visualizing the SHAP feature contribution to prediction dependencies on feature value.

These scatterplots represent how SHAP feature contributions depend of feature values. The similarity to partial dependency plots is that they also give an idea for how feature values affect predictions. However, in partial dependency plots, we usually see marginal dependencies of model prediction on feature value, while SHAP contribution dependency plots display the estimated contributions of a feature to model prediction for each individual case.

When plot_loess = TRUE is set, feature values are rounded to 3 significant digits and weighted LOESS is computed and plotted, where weights are the numbers of data points at each rounded value.

Note: SHAP contributions are shown on the scale of model margin. E.g., for a logistic binomial objective, the margin is prediction before a sigmoidal transform into probability-like values. Also, since SHAP stands for "SHapley Additive exPlanation" (model prediction = sum of SHAP contributions for all features + bias), depending on the objective used, transforming SHAP contributions for a feature from the marginal to the prediction space is not necessarily a meaningful thing to do.


```r
png(filename = "./output/image.files/210_varresp_SHAP.png", width = 1200, height = 400, pointsize = 24)
shap <- xgb.plot.shap(data  = train.matrix,
              model = model.xgb, 
              # sabsumple = 300,
              top_n = 6,
              n_col = 6, col = col, pch = 7, pch_NA = 17)
dev.off()
png 
  2 
```

![SHAP  contribution dependency plots](./output/image.files/210_varresp_SHAP.png)


## Individual feature responce

example: last_evaluation x satisfaction_level


```r
feature.impact <- data.frame(value  = train.df$last_evaluation, 
                             impact = predShap.xgb$last_evaluation,
                             satisfaction_level = train.df$satisfaction_level)
feature.impact %>% 
  ggplot(aes(x = value, y = impact, color = satisfaction_level)) + 
  geom_point(alpha = 0.7) +
  labs(title = "last_evaluation", x = "last_evaluation", y = "Shaply value") +
  theme_bw() + 
  scale_color_gradient2(midpoint = 0.5, low="blue", mid="grey", high="red")
```

![](500_Sensitivity_analysis_using_SHAPley_value_files/figure-html/unnamed-chunk-5-1.png)<!-- -->

# SHAP values of contributions of interaction of each pair of features 

With `predinteraction = TRUE`, SHAP values of contributions of interaction of each pair of features are computed. Note that this operation might be rather expensive in terms of compute and memory. Since it quadratically depends on the number of features, it is recommended to perfom selection of the most important features first. See below about the format of the returned results.


```r
predinteraction.xgb <- xgboost:::predict.xgb.Booster(
  model.xgb, newdata = train.matrix, 
  predinteraction = TRUE)

predinteraction.xgb %>% str
 num [1:4000, 1:10, 1:10] -1.055 -1.159 0.114 1.339 -1.195 ...
 - attr(*, "dimnames")=List of 3
  ..$ : NULL
  ..$ : chr [1:10] "satisfaction_level" "last_evaluation" "number_project" "average_montly_hours" ...
  ..$ : chr [1:10] "satisfaction_level" "last_evaluation" "number_project" "average_montly_hours" ...
```


## Interaction of single observation


```r
idx = 1
predinteraction.xgb[idx, ,] %>% 
  data.frame %>% 
  rownames_to_column("feature") %>% 
  gather(key = interact, value = value, -feature) %>% 
  mutate_at(vars(feature, interact), as.factor) %>% 
  ggplot(aes(x = feature, y = interact, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, 
                       low="blue", mid = "white", high="red") +
  theme(axis.text.x = element_text(angle = 90))
```

![](500_Sensitivity_analysis_using_SHAPley_value_files/figure-html/unnamed-chunk-7-1.png)<!-- -->

## Average interaction of all observation


```r
mean.interaction <- apply(abs(predinteraction.xgb), 2:3, sum) / NROW(predinteraction.xgb)

mean.interaction %>% 
  data.frame %>% 
  rownames_to_column("feature") %>% 
  gather(key = interact, value = value, -feature) %>% 
  mutate_at(vars(feature, interact), as.factor) %>% 
  ggplot(aes(x = feature, y = interact, fill = value)) +
  geom_tile() +
  scale_fill_gradient(low="white",high="red") +
  theme(axis.text.x = element_text(angle = 90))
```

![](500_Sensitivity_analysis_using_SHAPley_value_files/figure-html/unnamed-chunk-8-1.png)<!-- -->

