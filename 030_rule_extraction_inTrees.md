---
author: "Satoshi Kato"
title: "rule extraction from xgboost model"
date: "2019/04/27"
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
install.packages("inTtrees", dependencies = TRUE)
install.packages("kableExtra", dependencies = TRUE)
```


```r
require(tidyverse)
require(data.table)
require(xgboost)
library(inTrees)
library(xtable)
require(knitr)
require(kableExtra)
```

# Preparation (continued)


```r
loaded.obs  <- readRDS("./middle/data_and_model.Rds")

model.xgb   <- loaded.obs$model$xgb 

train.label  <- loaded.obs$data$train$label
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix("./middle/train.xgbDMatrix")
```

```
[09:54:12] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[09:54:12] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
```

# Extract rules using inTrees

```r
require(inTrees)
```

## Extract rules from of trees


```r
treeList <- XGB2List(xgb = model.xgb, X = train.matrix)
ruleExec <- extractRules(treeList = treeList, 
                         X        = train.matrix,
                         random   = FALSE, 
                         digits   = 4)
```

```
187 rules (length<=6) were extracted from the first 12 trees.
```

```r
ruleExec <- unique(ruleExec)
```


```r
# Assign outcomes to a conditions, and measure the rules
ruleMetric <- getRuleMetric(ruleExec = ruleExec,X = train.matrix,target = train.label)

# Prune irrevant variable-value pair from a rule condition
ruleMetric <- pruneRule(rules = ruleMetric, X = train.matrix,target = train.label)
ruleMetric <- unique(ruleMetric)
# ruleMetric %>% str
```

## build a simplified tree ensemble learner (STEL)


```r
simple.rules    <- buildLearner(ruleMetric = ruleMetric, 
                                minFreq    = 0.01,
                                X      = train.matrix, 
                                target = train.label)

simple.readable <- presentRules(rules = simple.rules,
                                colN = colnames(train.matrix),
                                digits = 3)

simple.readable %>% 
  data.frame %>% 
  select(pred, condition, everything()) %>%
  kable(format = "html") %>% 
  kable_styling(bootstrap_options = "striped", full_width = FALSE, position = "left")
```

<table class="table table-striped" style="width: auto !important; ">
 <thead>
  <tr>
   <th style="text-align:left;"> pred </th>
   <th style="text-align:left;"> condition </th>
   <th style="text-align:left;"> len </th>
   <th style="text-align:left;"> freq </th>
   <th style="text-align:left;"> err </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.115 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.057 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> time_spend_company&gt;6.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.04 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=125 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.029 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.445 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.021 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> Else </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.853 </td>
   <td style="text-align:left;"> 0.214 </td>
  </tr>
</tbody>
</table>

### prediction using simplified rules


```r
pred.intrees <- applyLearner(learner = simple.rules, X = test.matrix)
table(prediction = pred.intrees, 
      truth      = test.label) %>% 
  caret::confusionMatrix()
```

```
Confusion Matrix and Statistics

          truth
prediction    0    1
         0 7627 1769
         1    0  604
                                          
               Accuracy : 0.8231          
                 95% CI : (0.8155, 0.8305)
    No Information Rate : 0.7627          
    P-Value [Acc > NIR] : < 2.2e-16       
                                          
                  Kappa : 0.3425          
                                          
 Mcnemar's Test P-Value : < 2.2e-16       
                                          
            Sensitivity : 1.0000          
            Specificity : 0.2545          
         Pos Pred Value : 0.8117          
         Neg Pred Value : 1.0000          
             Prevalence : 0.7627          
         Detection Rate : 0.7627          
   Detection Prevalence : 0.9396          
      Balanced Accuracy : 0.6273          
                                          
       'Positive' Class : 0               
                                          
```

## show all extracted


```r
ruleMetric  %>%
  presentRules(
    colN = colnames(train.matrix),
    digits = 3) %>% 
  data.frame %>% 
  select(pred, condition, everything()) %>%
  mutate(pred = pred %>%
           as.character() %>%
           as.numeric() %>%
           round(digits = 4)) %>%
  arrange(pred) %>% 
  kable(format = "html") %>% 
  kable_styling(bootstrap_options = "striped", full_width = FALSE, position = "left")
```

<table class="table table-striped" style="width: auto !important; ">
 <thead>
  <tr>
   <th style="text-align:right;"> pred </th>
   <th style="text-align:left;"> condition </th>
   <th style="text-align:left;"> len </th>
   <th style="text-align:left;"> freq </th>
   <th style="text-align:left;"> err </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=125 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.031 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> time_spend_company&gt;6.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.04 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.445 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.028 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 &amp; time_spend_company&gt;5.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.007 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0077 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.345 &amp; time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.208 </td>
   <td style="text-align:left;"> 0.008 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0141 </td>
   <td style="text-align:left;"> number_project&gt;2.5 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.509 </td>
   <td style="text-align:left;"> 0.014 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0149 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.591 </td>
   <td style="text-align:left;"> 0.015 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0157 </td>
   <td style="text-align:left;"> time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.217 </td>
   <td style="text-align:left;"> 0.015 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0175 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.765 &amp; number_project&lt;=4.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.205 </td>
   <td style="text-align:left;"> 0.017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0186 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; average_montly_hours&lt;=216.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.409 </td>
   <td style="text-align:left;"> 0.018 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0208 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=216.5 &amp; time_spend_company&gt;5.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.048 </td>
   <td style="text-align:left;"> 0.02 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0208 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; last_evaluation&lt;=0.815 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.452 </td>
   <td style="text-align:left;"> 0.02 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0212 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.765 &amp; last_evaluation&gt;0.605 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.245 </td>
   <td style="text-align:left;"> 0.021 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0228 </td>
   <td style="text-align:left;"> number_project&gt;2.5 &amp; average_montly_hours&lt;=216.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.447 </td>
   <td style="text-align:left;"> 0.022 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0245 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 &amp; last_evaluation&lt;=0.755 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.277 </td>
   <td style="text-align:left;"> 0.024 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0279 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.765 &amp; number_project&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.43 </td>
   <td style="text-align:left;"> 0.027 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0356 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.805 &amp; number_project&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.107 </td>
   <td style="text-align:left;"> 0.034 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0362 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.765 &amp; number_project&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.127 </td>
   <td style="text-align:left;"> 0.035 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0426 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 &amp; number_project&lt;=2.5 &amp; salary_low&lt;=0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.019 </td>
   <td style="text-align:left;"> 0.041 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0435 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465 &amp; satisfaction_level&gt;0.115 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.046 </td>
   <td style="text-align:left;"> 0.042 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0455 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.575 &amp; average_montly_hours&gt;161.5 &amp; sales_sales&lt;=0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.092 </td>
   <td style="text-align:left;"> 0.043 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0508 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 &amp; number_project&lt;=2.5 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.024 </td>
   <td style="text-align:left;"> 0.048 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0619 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.835 &amp; number_project&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.536 </td>
   <td style="text-align:left;"> 0.058 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0631 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 &amp; last_evaluation&lt;=0.825 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.384 </td>
   <td style="text-align:left;"> 0.059 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0774 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 &amp; number_project&lt;=2.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.031 </td>
   <td style="text-align:left;"> 0.071 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0819 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.115 &amp; satisfaction_level&lt;=0.355 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.083 </td>
   <td style="text-align:left;"> 0.075 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0952 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.115 &amp; number_project&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.78 </td>
   <td style="text-align:left;"> 0.086 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0952 </td>
   <td style="text-align:left;"> number_project&gt;2.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.666 </td>
   <td style="text-align:left;"> 0.086 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0976 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.721 </td>
   <td style="text-align:left;"> 0.088 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1020 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.039 </td>
   <td style="text-align:left;"> 0.092 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1034 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3 &amp; time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.006 </td>
   <td style="text-align:left;"> 0.093 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1277 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.835 &amp; number_project&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.191 </td>
   <td style="text-align:left;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1481 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.355 &amp; last_evaluation&lt;=0.625 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.032 </td>
   <td style="text-align:left;"> 0.126 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1565 </td>
   <td style="text-align:left;"> number_project&gt;2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.836 </td>
   <td style="text-align:left;"> 0.132 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1585 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.355 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.72 </td>
   <td style="text-align:left;"> 0.133 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1618 </td>
   <td style="text-align:left;"> time_spend_company&gt;5.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.089 </td>
   <td style="text-align:left;"> 0.136 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1725 </td>
   <td style="text-align:left;"> time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.651 </td>
   <td style="text-align:left;"> 0.143 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1801 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.575 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.715 </td>
   <td style="text-align:left;"> 0.148 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2044 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.835 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.687 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2047 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.765 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.577 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2047 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.355 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.86 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2872 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.765 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.423 </td>
   <td style="text-align:left;"> 0.205 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3018 </td>
   <td style="text-align:left;"> time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.783 </td>
   <td style="text-align:left;"> 0.211 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3169 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.835 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.313 </td>
   <td style="text-align:left;"> 0.216 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3890 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.575 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.285 </td>
   <td style="text-align:left;"> 0.238 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3955 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=161.5 &amp; average_montly_hours&gt;125 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.275 </td>
   <td style="text-align:left;"> 0.239 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6069 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.279 </td>
   <td style="text-align:left;"> 0.239 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6642 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.164 </td>
   <td style="text-align:left;"> 0.223 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7219 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.15 </td>
   <td style="text-align:left;"> 0.201 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7588 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465 &amp; last_evaluation&lt;=0.575 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.142 </td>
   <td style="text-align:left;"> 0.183 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7607 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.765 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.15 </td>
   <td style="text-align:left;"> 0.182 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7636 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.985 &amp; number_project&gt;4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.011 </td>
   <td style="text-align:left;"> 0.18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7873 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.765 &amp; number_project&gt;4.5 &amp; time_spend_company&gt;3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.117 </td>
   <td style="text-align:left;"> 0.167 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8083 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;4.5 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.072 </td>
   <td style="text-align:left;"> 0.155 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8179 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.127 </td>
   <td style="text-align:left;"> 0.149 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8411 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.575 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.125 </td>
   <td style="text-align:left;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8576 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; last_evaluation&gt;0.825 &amp; time_spend_company&gt;4.5 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.066 </td>
   <td style="text-align:left;"> 0.122 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8632 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; last_evaluation&gt;0.805 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.066 </td>
   <td style="text-align:left;"> 0.118 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8723 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465 &amp; last_evaluation&gt;0.445 &amp; last_evaluation&lt;=0.575 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.122 </td>
   <td style="text-align:left;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8727 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; last_evaluation&gt;0.815 &amp; average_montly_hours&gt;214.5 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.064 </td>
   <td style="text-align:left;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8727 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; last_evaluation&gt;0.815 &amp; average_montly_hours&gt;213 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.064 </td>
   <td style="text-align:left;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8752 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.12 </td>
   <td style="text-align:left;"> 0.109 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8781 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465 &amp; last_evaluation&gt;0.815 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.064 </td>
   <td style="text-align:left;"> 0.107 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8852 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.825 &amp; average_montly_hours&gt;214.5 &amp; time_spend_company&gt;4.5 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.066 </td>
   <td style="text-align:left;"> 0.102 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9112 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.575 &amp; last_evaluation&gt;0.455 &amp; number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.11 </td>
   <td style="text-align:left;"> 0.081 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9143 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.575 &amp; last_evaluation&gt;0.445 &amp; number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.114 </td>
   <td style="text-align:left;"> 0.078 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9167 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.575 &amp; number_project&lt;=2.5 &amp; average_montly_hours&lt;=161.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.113 </td>
   <td style="text-align:left;"> 0.076 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9321 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465 &amp; satisfaction_level&gt;0.355 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.112 </td>
   <td style="text-align:left;"> 0.063 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1.0000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.115 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.057 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1.0000 </td>
   <td style="text-align:left;"> number_project&gt;6.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.016 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
</tbody>
</table>



