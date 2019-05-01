---
author: "Satoshi Kato"
title: "rule extraction from xgboost model"
date: "2019/05/01"
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
```


```r
require(tidyverse)
require(magrittr)
require(data.table)
require(xgboost)
library(xgboostExplainer)
```

# Preparation (continued)


```r
kable_left <- function(df) {
  kable.df <- df %>% 
    knitr::kable(align=rep('l', 5)) %>%
    kableExtra::kable_styling(
      bootstrap_options = "striped",
      full_width = FALSE, 
      position   = "left")
  
  return(kable.df)
}
```


```r
loaded.obs  <- readRDS("./middle/data_and_model.Rds")

model.xgb   <- loaded.obs$model$xgb 

train.label <- loaded.obs$data$train$label
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix("./middle/train.xgbDMatrix")
```

```
[14:34:52] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[14:34:52] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
```

# Preditive result of All

In this case, eval_metrics were high enough, therefore, we use test data for following evaluation


```r
test.pred <- predict(model.xgb, test.xgb.DMatrix)

prediction.counts <- table(test.pred, test.label) %>% 
  data.frame %>%
  mutate(
    predict = substr(test.pred, start = 1, stop = 4),
    count   = ifelse(test.label == "0", Freq, -Freq)) 

prediction.counts %>% 
  ggplot(aes(x =  reorder(predict, -as.numeric(predict)),
             y = count, 
             fill = test.label)) +
  geom_bar(stat="identity") +
  coord_flip() +
  labs(x = "prediction") +
  ggtitle(sprintf("%i rules of %i instance was extracted", 
                  NROW(prediction.counts), NROW(test.pred)))
```

![](040_rule_extraction_xgbExplainer_files/figure-html/unnamed-chunk-2-1.png)<!-- -->

# Feature pruning

Target features are filterd using `xgb.importance()`


```r
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

```r
train.selected <- loaded.obs$data$train$dummy.data.frame %>% 
  select(target.feature)
  
train.selected.xgb.DMatrix <- xgb.DMatrix(data  = as.matrix(train.selected),
                                          label = train.label)

test.selected <- loaded.obs$data$test$dummy.data.frame %>% 
  select(target.feature) 
test.selected.xgb.DMatrix <- xgb.DMatrix(data  = as.matrix(test.selected),
                                         label = test.label)
param.set <- loaded.obs$model$param.set
param.set$alpha <- 0.8
set.seed(1)
cv <- xgb.cv(params  = param.set, 
             verbose = 1,
             data    = train.selected.xgb.DMatrix,
             nrounds = 200,
             nfold   = 5,
             early_stopping_rounds = 5)
```

```
[1]	train-auc:0.961775+0.008300	test-auc:0.959162+0.015649 
Multiple eval metrics are present. Will use test_auc for early stopping.
Will train until test_auc hasn't improved in 5 rounds.

[2]	train-auc:0.969237+0.005805	test-auc:0.967283+0.006990 
[3]	train-auc:0.976160+0.003362	test-auc:0.974887+0.003799 
[4]	train-auc:0.978366+0.003044	test-auc:0.975788+0.004162 
[5]	train-auc:0.978704+0.002931	test-auc:0.976428+0.003907 
[6]	train-auc:0.978900+0.002539	test-auc:0.975411+0.005021 
[7]	train-auc:0.979460+0.001522	test-auc:0.975930+0.005280 
[8]	train-auc:0.979425+0.001384	test-auc:0.976035+0.005180 
[9]	train-auc:0.979754+0.001136	test-auc:0.976348+0.004745 
[10]	train-auc:0.979680+0.001055	test-auc:0.976217+0.004932 
Stopping. Best iteration:
[5]	train-auc:0.978704+0.002931	test-auc:0.976428+0.003907
```

```r
cv$evaluation_log %>% 
  select(-ends_with("_std")) %>% 
  tidyr::gather(key = data, value = auc, train_auc_mean, test_auc_mean) %>%
  ggplot(aes(x = iter, y = auc, color = as.factor(data))) +
  geom_line() +
  geom_vline(xintercept = cv$niter)
```

![](040_rule_extraction_xgbExplainer_files/figure-html/explainer.DALEX-1.png)<!-- -->


```r
model.selected.xgb <- xgb.train(params  = loaded.obs$model$param.set, 
                       verbose = 1,
                       data    = train.selected.xgb.DMatrix,
                       nrounds = cv$niter)

model.selected.xgb
```

```
##### xgb.Booster
raw: 11.9 Kb 
call:
  xgb.train(params = loaded.obs$model$param.set, data = train.selected.xgb.DMatrix, 
    nrounds = cv$niter, verbose = 1)
params (as set within xgb.train):
  booster = "gbtree", objective = "binary:logistic", eval_metric = "auc", max_depth = "5", colsample_bytree = "0.8", subsample = "0.8", min_child_weight = "3", eta = "0.05", alpha = "0.25", gamma = "0", silent = "1"
xgb.attributes:
  niter
callbacks:
  cb.print.evaluation(period = print_every_n)
# of features: 5 
niter: 10
nfeatures : 5 
```


```r
pred <- predict(model.selected.xgb, test.selected.xgb.DMatrix)
# length(pred)
prediction.counts <- table(pred, test.label) %>% 
  data.frame %>% 
  mutate(
      predict = substr(pred, start = 1, stop = 4) %>% as.numeric(),
    count   = ifelse(test.label == "0", Freq, -Freq)) %>% 
  filter(Freq >0 )

prediction.counts %>% 
  ggplot(aes(x = reorder(predict, -as.numeric(predict)),
             y = count, 
             fill = test.label)) +
  geom_bar(stat="identity") +
  coord_flip() +
  labs(x = "prediction") +
  ggtitle(sprintf("%i rules of %i instance was extracted", 
                  NROW(prediction.counts), NROW(test.pred)))
```

![](040_rule_extraction_xgbExplainer_files/figure-html/unnamed-chunk-4-1.png)<!-- -->


```r
explainer.xgb <-  buildExplainer(xgb.model    = model.selected.xgb, 
                                 trainingData = test.selected.xgb.DMatrix, 
                                 type         = "binary",
                                 base_score   = 0.5,
                                 trees_idx    = NULL)
```


```r
# install.packages("ggforce", dependencies = TRUE)
require(ggforce) # for `geom_sina`

xgb.breakdown <- explainPredictions(xgb.model = model.selected.xgb,
                                    explainer = explainer.xgb,
                                    data      = test.selected.xgb.DMatrix)
xgb.breakdown.loger <- xgb.breakdown %>%
  select(-intercept) %>% 
  mutate(id = 1:n()) %>% 
  gather(key = feature, value = impact, -id) %>% 
  arrange(id)

scaled.value.loger <- test.selected %>%
  scale() %>% 
  data.frame() %>% 
  mutate(id = 1:n()) %>% 
  gather(key = feature, value = value, -id) %>% 
  arrange(id)

feature.impact <- left_join(xgb.breakdown.loger,
                            scaled.value.loger,
                            by = c("id", "feature"))

ggplot(data = feature.impact) +
    coord_flip() + 
    # sina plot: 
    geom_sina(aes(x = feature, y = impact, color = value),
              method = "density", maxwidth = 1, alpha = 0.2) +
   scale_color_gradient(low="#FF0000", high="#0000FF", 
                        breaks=c(0,1), labels=c("Low        ","           High"),
                        guide = guide_colorbar(barwidth = 10, barheight = 0.3)) +
    theme_bw() + 
    theme(axis.line.y = element_blank(), 
          axis.ticks.y = element_blank(), # remove axis line
          legend.position="bottom",
          legend.title=element_text(size=10), 
          legend.text=element_text(size=8),
          axis.title.x= element_text(size = 10)) + 
    geom_hline(yintercept = 0) + # the vertical line
      labs(y = "feature attribution on model output", x = "", color = "Feature value  ") 
```

![](040_rule_extraction_xgbExplainer_files/figure-html/unnamed-chunk-6-1.png)<!-- -->

# clustering for extracted rules


```r
# install.packages("Rtsne", dependencies = TRUE)
require(Rtsne)
```

```
Loading required package: Rtsne
```

```r
# install.packages("plotly", dependencies = TRUE)
require(plotly)
```

```
Loading required package: plotly
```

```

Attaching package: 'plotly'
```

```
The following object is masked from 'package:xgboost':

    slice
```

```
The following object is masked from 'package:ggplot2':

    last_plot
```

```
The following object is masked from 'package:stats':

    filter
```

```
The following object is masked from 'package:graphics':

    layout
```

```r
set.seed(1)

feature.breakdown <- cbind(predict = test.pred, 
                           true    = test.label,
                           xgb.breakdown) %>%
  select(-intercept) %>% 
  # sample_n(1000) %>% 
  as.matrix()

rules.tsne <- Rtsne(feature.breakdown[, -(1:2)], perplexity = 100, check_duplicates = FALSE)
rules.tsne %>% str
```

```
List of 14
 $ N                  : int 10000
 $ Y                  : num [1:10000, 1:2] 1.827 -16.863 -10.424 0.785 0.785 ...
 $ costs              : num [1:10000] 5.35e-05 1.07e-04 8.32e-06 8.03e-05 8.02e-05 ...
 $ itercosts          : num [1:20] 70.9 58.6 56.6 56.1 55.8 ...
 $ origD              : int 5
 $ perplexity         : num 100
 $ theta              : num 0.5
 $ max_iter           : num 1000
 $ stop_lying_iter    : int 250
 $ mom_switch_iter    : int 250
 $ momentum           : num 0.5
 $ final_momentum     : num 0.8
 $ eta                : num 200
 $ exaggeration_factor: num 12
```

```r
mapping.tsne <-  data.frame(id      = 1:length(feature.breakdown[, 1]),
                            tsne1   = rules.tsne$Y[, 1],
                            tsne2   = rules.tsne$Y[, 2], 
                            predict = feature.breakdown[, 1],
                            true    = feature.breakdown[, 2])

ggp.map.tsne <- mapping.tsne %>% 
  ggplot(aes(x = tsne1, y = tsne2, color = predict, text = paste(id,true,sep=":"))) +
  geom_point(alpha = 0.5) + 
  scale_color_gradient(high="#FF0000", low="#0000FF") +  theme_bw()

plotly::ggplotly(ggp.map.tsne)
```

<!--html_preserve--><div id="htmlwidget-ae203b738564e034912b" style="width:576px;height:576px;" class="plotly html-widget"></div>



```r
obs <- c(9135, 9993, 10000, 9999, 9890)

for(i in 1:length(obs)){
  
  ggp.sw <- showWaterfall(
    idx = obs[i],
    xgb.model   = model.selected.xgb, 
    explainer   = explainer.xgb, 
    DMatrix     = test.selected.xgb.DMatrix, 
    data.matrix = as.matrix(test.selected)) +
    ggtitle(paste("ID =", obs[i]))

  ggsave(ggp.sw, filename = sprintf("./output/image.files/040_explain_%05i.png", obs[i]))
}
```
![explain prediction](./output/image.files/040_explain_09135.png)
![explain prediction](./output/image.files/040_explain_09890.png)
![explain prediction](./output/image.files/040_explain_09993.png)
![explain prediction](./output/image.files/040_explain_09999.png)
![explain prediction](./output/image.files/040_explain_10000.png)