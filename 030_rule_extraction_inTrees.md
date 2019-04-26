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
[00:35:12] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[00:35:12] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
```

# Extract rules using inTrees

## rule extraction


```r
require(inTrees)
treeList <- XGB2List(model.xgb, X = train.matrix)

ruleExec <- extractRules(treeList, X = train.matrix)
```

```
187 rules (length<=6) were extracted from the first 12 trees.
```

```r
ruleExec <- unique(ruleExec)

# measure rules
ruleMetric <- getRuleMetric(ruleExec,X = train.matrix,target = train.label)

# prune each rule
ruleMetric <- pruneRule(ruleMetric, X = train.matrix,target = train.label)
ruleMetric <- unique(ruleMetric)
# ruleMetric %>% str
```

## simplify rules


```r
learner <- buildLearner(ruleMetric, X = train.matrix, target = train.label)
learner.readable <- presentRules(learner,colnames(train.matrix))

learner.readable %>% 
  data.frame %>% 
  select(pred, condition, everything()) %>%
  mutate(freq = freq %>% as.character() %>% as.numeric() %>% round(digits = 3),
         err  = err  %>% as.character() %>% as.numeric() %>% round(digits = 3)) %>% 
  kable(format = "html") %>% 
  kable_styling(bootstrap_options = "striped", full_width = FALSE, position = "left")
```

<table class="table table-striped" style="width: auto !important; ">
 <thead>
  <tr>
   <th style="text-align:left;"> pred </th>
   <th style="text-align:left;"> condition </th>
   <th style="text-align:left;"> len </th>
   <th style="text-align:right;"> freq </th>
   <th style="text-align:right;"> err </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.114999995 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.057 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> time_spend_company&gt;6.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.040 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=125 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.029 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.444999993 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.021 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> Else </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.853 </td>
   <td style="text-align:right;"> 0.214 </td>
  </tr>
</tbody>
</table>

## predict by simplified rules


```r
learner <- buildLearner(ruleMetric, X = train.matrix, target = train.label)
learner.readable <- presentRules(learner,colnames(train.matrix))
pred.intrees <- applyLearner(learner,    X = train.matrix)
table(prediction = pred.intrees, truth = train.label) %>% 
  caret::confusionMatrix()
```

```
Confusion Matrix and Statistics

          truth
prediction    0    1
         0 3801  914
         1    0  284
                                          
               Accuracy : 0.8172          
                 95% CI : (0.8062, 0.8278)
    No Information Rate : 0.7604          
    P-Value [Acc > NIR] : < 2.2e-16       
                                          
                  Kappa : 0.3209          
                                          
 Mcnemar's Test P-Value : < 2.2e-16       
                                          
            Sensitivity : 1.0000          
            Specificity : 0.2371          
         Pos Pred Value : 0.8062          
         Neg Pred Value : 1.0000          
             Prevalence : 0.7604          
         Detection Rate : 0.7604          
   Detection Prevalence : 0.9432          
      Balanced Accuracy : 0.6185          
                                          
       'Positive' Class : 0               
                                          
```

## show all extracted


```r
ruleMetric  %>%
  presentRules(colnames(train.matrix)) %>% 
  data.frame %>% 
  select(pred, condition, everything()) %>%
  mutate(pred = pred %>% as.character() %>% as.numeric() %>% round(digits = 6),
         freq = freq %>% as.character() %>% as.numeric() %>% round(digits = 3),
         err  = err  %>% as.character() %>% as.numeric() %>% round(digits = 3)) %>%
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
   <th style="text-align:right;"> freq </th>
   <th style="text-align:right;"> err </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 0.000000 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=125 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.031 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.000000 </td>
   <td style="text-align:left;"> time_spend_company&gt;6.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.040 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.000000 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.444999993 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.028 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.000000 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 &amp; time_spend_company&gt;5.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.007 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.007685 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.344999999 &amp; time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.208 </td>
   <td style="text-align:right;"> 0.008 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.014145 </td>
   <td style="text-align:left;"> number_project&gt;2.5 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.509 </td>
   <td style="text-align:right;"> 0.014 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.014905 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.591 </td>
   <td style="text-align:right;"> 0.015 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.015654 </td>
   <td style="text-align:left;"> time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.217 </td>
   <td style="text-align:right;"> 0.015 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.017544 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.764999986 &amp; number_project&lt;=4.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.205 </td>
   <td style="text-align:right;"> 0.017 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.018600 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; average_montly_hours&lt;=216.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.409 </td>
   <td style="text-align:right;"> 0.018 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.020806 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; last_evaluation&lt;=0.814999998 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.452 </td>
   <td style="text-align:right;"> 0.020 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.020833 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=216.5 &amp; time_spend_company&gt;5.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.048 </td>
   <td style="text-align:right;"> 0.020 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.021224 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.764999986 &amp; last_evaluation&gt;0.605000019 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.245 </td>
   <td style="text-align:right;"> 0.021 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.022798 </td>
   <td style="text-align:left;"> number_project&gt;2.5 &amp; average_montly_hours&lt;=216.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.447 </td>
   <td style="text-align:right;"> 0.022 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.024531 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 &amp; last_evaluation&lt;=0.754999995 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.277 </td>
   <td style="text-align:right;"> 0.024 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.027920 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.764999986 &amp; number_project&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.430 </td>
   <td style="text-align:right;"> 0.027 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.035581 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.805000007 &amp; number_project&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.107 </td>
   <td style="text-align:right;"> 0.034 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.036220 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.764999986 &amp; number_project&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.127 </td>
   <td style="text-align:right;"> 0.035 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.042553 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 &amp; number_project&lt;=2.5 &amp; salary_low&lt;=0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.019 </td>
   <td style="text-align:right;"> 0.041 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.043478 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465000004 &amp; satisfaction_level&gt;0.114999995 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.046 </td>
   <td style="text-align:right;"> 0.042 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.045455 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.574999988 &amp; average_montly_hours&gt;161.5 &amp; sales_sales&lt;=0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.092 </td>
   <td style="text-align:right;"> 0.043 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.050847 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 &amp; number_project&lt;=2.5 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.024 </td>
   <td style="text-align:right;"> 0.048 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.061940 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.834999979 &amp; number_project&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.536 </td>
   <td style="text-align:right;"> 0.058 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.063054 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 &amp; last_evaluation&lt;=0.824999988 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.384 </td>
   <td style="text-align:right;"> 0.059 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.077419 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 &amp; number_project&lt;=2.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.031 </td>
   <td style="text-align:right;"> 0.071 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.081928 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.114999995 &amp; satisfaction_level&lt;=0.355000019 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.083 </td>
   <td style="text-align:right;"> 0.075 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.095201 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.114999995 &amp; number_project&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.780 </td>
   <td style="text-align:right;"> 0.086 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.095224 </td>
   <td style="text-align:left;"> number_project&gt;2.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.666 </td>
   <td style="text-align:right;"> 0.086 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.097642 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.721 </td>
   <td style="text-align:right;"> 0.088 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.102041 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.039 </td>
   <td style="text-align:right;"> 0.092 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.103448 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.300000012 &amp; time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.006 </td>
   <td style="text-align:right;"> 0.093 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.127749 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.834999979 &amp; number_project&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.191 </td>
   <td style="text-align:right;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.148148 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.355000019 &amp; last_evaluation&lt;=0.625 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.032 </td>
   <td style="text-align:right;"> 0.126 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.156459 </td>
   <td style="text-align:left;"> number_project&gt;2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.836 </td>
   <td style="text-align:right;"> 0.132 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.158465 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.355000019 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.720 </td>
   <td style="text-align:right;"> 0.133 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.161798 </td>
   <td style="text-align:left;"> time_spend_company&gt;5.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.089 </td>
   <td style="text-align:right;"> 0.136 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.172456 </td>
   <td style="text-align:left;"> time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.651 </td>
   <td style="text-align:right;"> 0.143 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.180140 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.574999988 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.715 </td>
   <td style="text-align:right;"> 0.148 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.204426 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.834999979 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.687 </td>
   <td style="text-align:right;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.204651 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.355000019 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.860 </td>
   <td style="text-align:right;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.204719 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.764999986 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.577 </td>
   <td style="text-align:right;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.287199 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.764999986 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.423 </td>
   <td style="text-align:right;"> 0.205 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.301814 </td>
   <td style="text-align:left;"> time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.783 </td>
   <td style="text-align:right;"> 0.211 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.316933 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.834999979 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.313 </td>
   <td style="text-align:right;"> 0.216 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.389045 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.574999988 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.285 </td>
   <td style="text-align:right;"> 0.238 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.395484 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=161.5 &amp; average_montly_hours&gt;125 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.275 </td>
   <td style="text-align:right;"> 0.239 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.606887 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465000004 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.279 </td>
   <td style="text-align:right;"> 0.239 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.664225 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.164 </td>
   <td style="text-align:right;"> 0.223 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.721925 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.150 </td>
   <td style="text-align:right;"> 0.201 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.758815 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465000004 &amp; last_evaluation&lt;=0.574999988 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.142 </td>
   <td style="text-align:right;"> 0.183 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.760695 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.764999986 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.150 </td>
   <td style="text-align:right;"> 0.182 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.763636 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.985000014 &amp; number_project&gt;4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.011 </td>
   <td style="text-align:right;"> 0.180 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.787307 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.764999986 &amp; number_project&gt;4.5 &amp; time_spend_company&gt;3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.117 </td>
   <td style="text-align:right;"> 0.167 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.808333 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;4.5 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.072 </td>
   <td style="text-align:right;"> 0.155 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.817896 </td>
   <td style="text-align:left;"> number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.127 </td>
   <td style="text-align:right;"> 0.149 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.841091 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.574999988 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.125 </td>
   <td style="text-align:right;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.857576 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; last_evaluation&gt;0.824999988 &amp; time_spend_company&gt;4.5 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.066 </td>
   <td style="text-align:right;"> 0.122 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.863222 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; last_evaluation&gt;0.805000007 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.066 </td>
   <td style="text-align:right;"> 0.118 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.872340 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465000004 &amp; last_evaluation&gt;0.444999993 &amp; last_evaluation&lt;=0.574999988 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.122 </td>
   <td style="text-align:right;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.872671 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; last_evaluation&gt;0.814999998 &amp; average_montly_hours&gt;214.5 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.064 </td>
   <td style="text-align:right;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.872671 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; last_evaluation&gt;0.814999998 &amp; average_montly_hours&gt;213 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.064 </td>
   <td style="text-align:right;"> 0.111 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.875208 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465000004 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.120 </td>
   <td style="text-align:right;"> 0.109 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.878125 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.465000004 &amp; last_evaluation&gt;0.814999998 &amp; average_montly_hours&gt;216.5 &amp; time_spend_company&gt;4.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.064 </td>
   <td style="text-align:right;"> 0.107 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.885196 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.824999988 &amp; average_montly_hours&gt;214.5 &amp; time_spend_company&gt;4.5 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.066 </td>
   <td style="text-align:right;"> 0.102 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.911232 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.574999988 &amp; last_evaluation&gt;0.454999983 &amp; number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.110 </td>
   <td style="text-align:right;"> 0.081 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.914336 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.574999988 &amp; last_evaluation&gt;0.444999993 &amp; number_project&lt;=2.5 &amp; time_spend_company&gt;2.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 0.114 </td>
   <td style="text-align:right;"> 0.078 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.916667 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.574999988 &amp; number_project&lt;=2.5 &amp; average_montly_hours&lt;=161.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.113 </td>
   <td style="text-align:right;"> 0.076 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.932143 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.465000004 &amp; satisfaction_level&gt;0.355000019 &amp; number_project&lt;=2.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.112 </td>
   <td style="text-align:right;"> 0.063 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1.000000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.114999995 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.057 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1.000000 </td>
   <td style="text-align:left;"> number_project&gt;6.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.016 </td>
   <td style="text-align:right;"> 0.000 </td>
  </tr>
</tbody>
</table>



