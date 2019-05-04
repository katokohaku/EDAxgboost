---
author: "Satoshi Kato"
title: "rule extraction from xgboost model"
date: "2019/05/04"
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
[22:19:08] 4000x9 matrix with 36000 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[22:19:08] 10999x9 matrix with 98991 entries loaded from ./middle/test.xgbDMatrix
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
                         ntree    = 20,
                         random   = FALSE, 
                         digits   = 4)
```

```
431 rules (length<=6) were extracted from the first 20 trees.
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
                                # minFreq    = 0.01,
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
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:left;"> time_spend_company&gt;10.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.012 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> Else </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.988 </td>
   <td style="text-align:left;"> 0.494 </td>
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
         0  225    0
         1 9203 1571
                                          
               Accuracy : 0.1633          
                 95% CI : (0.1564, 0.1703)
    No Information Rate : 0.8572          
    P-Value [Acc > NIR] : 1               
                                          
                  Kappa : 0.0069          
                                          
 Mcnemar's Test P-Value : <2e-16          
                                          
            Sensitivity : 0.02387         
            Specificity : 1.00000         
         Pos Pred Value : 1.00000         
         Neg Pred Value : 0.14581         
             Prevalence : 0.85717         
         Detection Rate : 0.02046         
   Detection Prevalence : 0.02046         
      Balanced Accuracy : 0.51193         
                                          
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
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; number_project&lt;=8.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.004 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; number_project&lt;=9.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.006 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> time_spend_company&gt;10.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.012 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; number_project&lt;=9.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.007 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; number_project&lt;=8.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.005 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3673 &amp; number_project&lt;=9.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.006 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0000 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4199 &amp; time_spend_company&gt;9.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.006 </td>
   <td style="text-align:left;"> 0 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0324 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.6104 &amp; last_evaluation&lt;=0.4795 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.1 </td>
   <td style="text-align:left;"> 0.031 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0357 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3873 &amp; number_project&lt;=9.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.007 </td>
   <td style="text-align:left;"> 0.034 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0358 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5925 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.112 </td>
   <td style="text-align:left;"> 0.035 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0374 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5868 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.114 </td>
   <td style="text-align:left;"> 0.036 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0390 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.115 </td>
   <td style="text-align:left;"> 0.038 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0390 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5812 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.115 </td>
   <td style="text-align:left;"> 0.038 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0459 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5727 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.12 </td>
   <td style="text-align:left;"> 0.044 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0485 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5655 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.124 </td>
   <td style="text-align:left;"> 0.046 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0485 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5654 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.124 </td>
   <td style="text-align:left;"> 0.046 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0500 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5932 &amp; average_montly_hours&lt;=172.5 &amp; salary&gt;1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.015 </td>
   <td style="text-align:left;"> 0.048 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0538 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; average_montly_hours&gt;247.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.093 </td>
   <td style="text-align:left;"> 0.051 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0543 </td>
   <td style="text-align:left;"> time_spend_company&lt;=2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.032 </td>
   <td style="text-align:left;"> 0.051 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0605 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5574 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.128 </td>
   <td style="text-align:left;"> 0.057 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0667 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; average_montly_hours&lt;=292.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.008 </td>
   <td style="text-align:left;"> 0.062 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0676 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5339 &amp; last_evaluation&gt;0.4883 &amp; average_montly_hours&lt;=226 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.07 </td>
   <td style="text-align:left;"> 0.063 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0694 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; average_montly_hours&gt;234.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.112 </td>
   <td style="text-align:left;"> 0.065 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0695 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5823 &amp; last_evaluation&lt;=0.577 &amp; average_montly_hours&gt;193.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.148 </td>
   <td style="text-align:left;"> 0.065 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0703 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5359 &amp; last_evaluation&gt;0.5037 &amp; average_montly_hours&lt;=225.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.064 </td>
   <td style="text-align:left;"> 0.065 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0713 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3873 &amp; average_montly_hours&gt;229.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.116 </td>
   <td style="text-align:left;"> 0.066 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0719 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; average_montly_hours&gt;232.5 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.115 </td>
   <td style="text-align:left;"> 0.067 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0719 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5925 &amp; last_evaluation&lt;=0.5781 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.174 </td>
   <td style="text-align:left;"> 0.067 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0742 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5868 &amp; last_evaluation&lt;=0.5769 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.175 </td>
   <td style="text-align:left;"> 0.069 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0801 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5823 &amp; last_evaluation&lt;=0.577 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.178 </td>
   <td style="text-align:left;"> 0.074 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0806 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; average_montly_hours&lt;=237.5 &amp; salary&gt;1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.068 </td>
   <td style="text-align:left;"> 0.074 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0811 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4247 &amp; average_montly_hours&lt;=293.5 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.009 </td>
   <td style="text-align:left;"> 0.075 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0812 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; last_evaluation&lt;=0.577 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.178 </td>
   <td style="text-align:left;"> 0.075 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0841 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; salary&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.054 </td>
   <td style="text-align:left;"> 0.077 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0849 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; salary&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.053 </td>
   <td style="text-align:left;"> 0.078 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0852 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.6076 &amp; average_montly_hours&lt;=241.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.12 </td>
   <td style="text-align:left;"> 0.078 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0933 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5925 &amp; average_montly_hours&lt;=241.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.131 </td>
   <td style="text-align:left;"> 0.085 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0941 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5812 &amp; last_evaluation&lt;=0.592 &amp; average_montly_hours&gt;232 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.114 </td>
   <td style="text-align:left;"> 0.085 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0943 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5868 &amp; average_montly_hours&lt;=237.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.127 </td>
   <td style="text-align:left;"> 0.085 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0949 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5823 &amp; average_montly_hours&lt;=231.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.113 </td>
   <td style="text-align:left;"> 0.086 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0959 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5812 &amp; last_evaluation&lt;=0.592 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.188 </td>
   <td style="text-align:left;"> 0.087 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.0965 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; average_montly_hours&lt;=231.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.114 </td>
   <td style="text-align:left;"> 0.087 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1010 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5812 &amp; average_montly_hours&lt;=236.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.129 </td>
   <td style="text-align:left;"> 0.091 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1033 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; average_montly_hours&lt;=237.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.131 </td>
   <td style="text-align:left;"> 0.093 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1034 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; last_evaluation&lt;=0.6057 &amp; time_spend_company&gt;8.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.007 </td>
   <td style="text-align:left;"> 0.093 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1034 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; time_spend_company&gt;8.5 &amp; salary&gt;1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.007 </td>
   <td style="text-align:left;"> 0.093 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1053 </td>
   <td style="text-align:left;"> number_project&lt;=6.5 &amp; average_montly_hours&lt;=237.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.01 </td>
   <td style="text-align:left;"> 0.094 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1095 </td>
   <td style="text-align:left;"> number_project&lt;=9.5 &amp; salary&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.05 </td>
   <td style="text-align:left;"> 0.097 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1096 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5655 &amp; last_evaluation&lt;=0.5819 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.196 </td>
   <td style="text-align:left;"> 0.098 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1105 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5868 &amp; average_montly_hours&lt;=245.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.142 </td>
   <td style="text-align:left;"> 0.098 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1124 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.6922 &amp; average_montly_hours&lt;=225.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.042 </td>
   <td style="text-align:left;"> 0.1 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1200 </td>
   <td style="text-align:left;"> number_project&gt;10.5 &amp; average_montly_hours&lt;=229.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.025 </td>
   <td style="text-align:left;"> 0.106 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1308 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.397 &amp; average_montly_hours&gt;250.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.065 </td>
   <td style="text-align:left;"> 0.114 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1316 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.7406 &amp; number_project&lt;=8.5 &amp; Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.01 </td>
   <td style="text-align:left;"> 0.114 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1341 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.8063 &amp; average_montly_hours&lt;=232 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.02 </td>
   <td style="text-align:left;"> 0.116 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1362 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.2661 &amp; salary&gt;2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.059 </td>
   <td style="text-align:left;"> 0.118 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1419 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.5548 &amp; average_montly_hours&lt;=242 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.118 </td>
   <td style="text-align:left;"> 0.122 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1447 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.4598 &amp; time_spend_company&lt;=3.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.076 </td>
   <td style="text-align:left;"> 0.124 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1465 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; average_montly_hours&lt;=260 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.184 </td>
   <td style="text-align:left;"> 0.125 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1512 </td>
   <td style="text-align:left;"> salary&gt;2.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.064 </td>
   <td style="text-align:left;"> 0.128 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1532 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.086 </td>
   <td style="text-align:left;"> 0.13 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1548 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5727 &amp; average_montly_hours&lt;=260.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.189 </td>
   <td style="text-align:left;"> 0.131 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1549 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5727 &amp; average_montly_hours&lt;=160.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.018 </td>
   <td style="text-align:left;"> 0.131 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1573 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4247 &amp; satisfaction_level&gt;0.3495 &amp; last_evaluation&gt;0.5292 &amp; average_montly_hours&lt;=301.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.022 </td>
   <td style="text-align:left;"> 0.133 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1622 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4883 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.028 </td>
   <td style="text-align:left;"> 0.136 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1633 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.631 &amp; average_montly_hours&lt;=244 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.087 </td>
   <td style="text-align:left;"> 0.137 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1667 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=229.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.026 </td>
   <td style="text-align:left;"> 0.139 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1673 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.7661 &amp; number_project&gt;6.5 &amp; Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.066 </td>
   <td style="text-align:left;"> 0.139 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1675 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4628 &amp; average_montly_hours&gt;286.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.051 </td>
   <td style="text-align:left;"> 0.139 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1695 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4598 &amp; average_montly_hours&gt;278.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.059 </td>
   <td style="text-align:left;"> 0.141 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1706 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.289 &amp; average_montly_hours&lt;=319.5 &amp; Work_accident&gt;0.5 &amp; sales&lt;=8.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.053 </td>
   <td style="text-align:left;"> 0.142 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1774 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; last_evaluation&gt;0.4883 &amp; time_spend_company&lt;=5.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.179 </td>
   <td style="text-align:left;"> 0.146 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1779 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; last_evaluation&gt;0.4883 &amp; time_spend_company&lt;=5.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.181 </td>
   <td style="text-align:left;"> 0.146 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1857 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; satisfaction_level&lt;=0.5823 &amp; last_evaluation&gt;0.5037 &amp; sales&lt;=7.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.052 </td>
   <td style="text-align:left;"> 0.151 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1862 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4883 &amp; average_montly_hours&gt;248.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.12 </td>
   <td style="text-align:left;"> 0.152 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1871 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4883 &amp; number_project&gt;7.5 &amp; average_montly_hours&gt;243.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.074 </td>
   <td style="text-align:left;"> 0.152 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1892 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=232.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.028 </td>
   <td style="text-align:left;"> 0.153 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1903 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.504 &amp; average_montly_hours&gt;250.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.124 </td>
   <td style="text-align:left;"> 0.154 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1929 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; last_evaluation&lt;=0.577 &amp; average_montly_hours&gt;217.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.219 </td>
   <td style="text-align:left;"> 0.156 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1929 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.2361 &amp; last_evaluation&lt;=0.7406 &amp; Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.084 </td>
   <td style="text-align:left;"> 0.156 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.1980 </td>
   <td style="text-align:left;"> number_project&gt;6.5 &amp; Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.074 </td>
   <td style="text-align:left;"> 0.159 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2018 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=234.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.028 </td>
   <td style="text-align:left;"> 0.161 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2043 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; satisfaction_level&lt;=0.5339 &amp; last_evaluation&gt;0.4883 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.093 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2045 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4883 &amp; average_montly_hours&gt;243.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.132 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2053 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; satisfaction_level&lt;=0.5371 &amp; average_montly_hours&gt;234.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.094 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2060 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; satisfaction_level&lt;=0.5333 &amp; average_montly_hours&gt;232.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.092 </td>
   <td style="text-align:left;"> 0.164 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2113 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.5037 &amp; average_montly_hours&gt;243.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.142 </td>
   <td style="text-align:left;"> 0.167 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2135 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.7406 &amp; Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.092 </td>
   <td style="text-align:left;"> 0.168 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2181 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.4199 &amp; satisfaction_level&lt;=0.5347 &amp; average_montly_hours&gt;229.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.074 </td>
   <td style="text-align:left;"> 0.171 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2222 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; satisfaction_level&lt;=0.5655 &amp; last_evaluation&gt;0.5316 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.101 </td>
   <td style="text-align:left;"> 0.173 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2278 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5925 &amp; last_evaluation&lt;=0.8247 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.326 </td>
   <td style="text-align:left;"> 0.176 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2317 </td>
   <td style="text-align:left;"> Work_accident&gt;0.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.109 </td>
   <td style="text-align:left;"> 0.178 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2337 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5825 &amp; last_evaluation&lt;=0.8254 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.338 </td>
   <td style="text-align:left;"> 0.179 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2353 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.4247 &amp; last_evaluation&gt;0.462 &amp; time_spend_company&lt;=6.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.268 </td>
   <td style="text-align:left;"> 0.18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2433 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3873 &amp; time_spend_company&lt;=4.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.225 </td>
   <td style="text-align:left;"> 0.184 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2492 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3673 &amp; average_montly_hours&gt;229.5 &amp; salary&gt;1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.221 </td>
   <td style="text-align:left;"> 0.187 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2803 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.4247 &amp; salary&gt;1.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.324 </td>
   <td style="text-align:left;"> 0.202 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2818 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5925 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.375 </td>
   <td style="text-align:left;"> 0.202 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2835 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5868 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.383 </td>
   <td style="text-align:left;"> 0.203 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2850 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.39 </td>
   <td style="text-align:left;"> 0.204 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2912 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.504 &amp; average_montly_hours&lt;=278.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.269 </td>
   <td style="text-align:left;"> 0.206 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2918 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3873 &amp; satisfaction_level&lt;=0.5817 &amp; average_montly_hours&gt;229.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.134 </td>
   <td style="text-align:left;"> 0.207 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.2967 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5654 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.418 </td>
   <td style="text-align:left;"> 0.209 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3280 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3673 &amp; number_project&gt;8.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.249 </td>
   <td style="text-align:left;"> 0.22 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3364 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; average_montly_hours&gt;232.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.41 </td>
   <td style="text-align:left;"> 0.223 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3406 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; last_evaluation&gt;0.4455 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.456 </td>
   <td style="text-align:left;"> 0.225 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3422 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; last_evaluation&gt;0.4622 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.432 </td>
   <td style="text-align:left;"> 0.225 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3462 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; last_evaluation&gt;0.4883 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.4 </td>
   <td style="text-align:left;"> 0.226 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3518 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; last_evaluation&gt;0.5037 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.384 </td>
   <td style="text-align:left;"> 0.228 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3518 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 &amp; number_project&gt;10.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.077 </td>
   <td style="text-align:left;"> 0.228 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3595 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.4247 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.638 </td>
   <td style="text-align:left;"> 0.23 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3606 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.4199 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.644 </td>
   <td style="text-align:left;"> 0.231 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3704 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3873 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.684 </td>
   <td style="text-align:left;"> 0.233 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3747 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.374 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.7 </td>
   <td style="text-align:left;"> 0.234 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3771 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.71 </td>
   <td style="text-align:left;"> 0.235 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3772 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.3673 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.71 </td>
   <td style="text-align:left;"> 0.235 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4086 </td>
   <td style="text-align:left;"> salary&gt;1.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.484 </td>
   <td style="text-align:left;"> 0.242 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4258 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.367 &amp; average_montly_hours&lt;=234.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.308 </td>
   <td style="text-align:left;"> 0.244 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4658 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=314.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.818 </td>
   <td style="text-align:left;"> 0.249 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4762 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.6109 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.605 </td>
   <td style="text-align:left;"> 0.249 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4780 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.7406 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.801 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4793 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.5874 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.573 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4796 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=345.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.936 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4809 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=350.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.947 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4826 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.289 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.86 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4837 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.8063 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.883 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4842 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.5004 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.554 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4843 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.504 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.55 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4856 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.2661 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.884 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4872 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.8299 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.91 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4873 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.2361 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.915 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4877 </td>
   <td style="text-align:left;"> number_project&lt;=11.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.923 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4903 </td>
   <td style="text-align:left;"> number_project&gt;3.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.958 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4935 </td>
   <td style="text-align:left;"> number_project&lt;=8.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.612 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4945 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.9132 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.975 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5196 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.5004 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.446 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5200 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.499 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.445 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5222 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4963 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.44 </td>
   <td style="text-align:left;"> 0.25 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5365 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4598 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.377 </td>
   <td style="text-align:left;"> 0.249 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5382 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.4506 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.363 </td>
   <td style="text-align:left;"> 0.249 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5887 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.7406 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.199 </td>
   <td style="text-align:left;"> 0.242 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.5957 </td>
   <td style="text-align:left;"> average_montly_hours&lt;=177.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.138 </td>
   <td style="text-align:left;"> 0.241 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6071 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.289 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.14 </td>
   <td style="text-align:left;"> 0.239 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6098 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.2543 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.102 </td>
   <td style="text-align:left;"> 0.238 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6104 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.2661 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.116 </td>
   <td style="text-align:left;"> 0.238 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6277 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.07 </td>
   <td style="text-align:left;"> 0.234 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6288 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.8299 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.09 </td>
   <td style="text-align:left;"> 0.233 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6364 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.2361 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.085 </td>
   <td style="text-align:left;"> 0.231 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6435 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.504 &amp; average_montly_hours&lt;=250.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.327 </td>
   <td style="text-align:left;"> 0.229 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6472 </td>
   <td style="text-align:left;"> number_project&gt;11.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.077 </td>
   <td style="text-align:left;"> 0.228 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6538 </td>
   <td style="text-align:left;"> average_montly_hours&gt;314.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.182 </td>
   <td style="text-align:left;"> 0.226 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6723 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.4628 &amp; average_montly_hours&gt;286.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.268 </td>
   <td style="text-align:left;"> 0.22 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6922 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5817 &amp; average_montly_hours&lt;=232.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.291 </td>
   <td style="text-align:left;"> 0.213 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6923 </td>
   <td style="text-align:left;"> average_montly_hours&gt;241.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.11 </td>
   <td style="text-align:left;"> 0.213 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6928 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5868 &amp; average_montly_hours&lt;=229.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.286 </td>
   <td style="text-align:left;"> 0.213 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6980 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.4598 &amp; average_montly_hours&gt;278.5 &amp; time_spend_company&gt;3.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.279 </td>
   <td style="text-align:left;"> 0.211 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7008 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.397 &amp; average_montly_hours&gt;295.5 &amp; Work_accident&lt;=0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.227 </td>
   <td style="text-align:left;"> 0.21 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7073 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5823 &amp; last_evaluation&gt;0.8647 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.031 </td>
   <td style="text-align:left;"> 0.207 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7129 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.9132 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.025 </td>
   <td style="text-align:left;"> 0.205 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7208 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5472 &amp; last_evaluation&gt;0.6922 &amp; time_spend_company&gt;6.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.066 </td>
   <td style="text-align:left;"> 0.201 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7224 </td>
   <td style="text-align:left;"> last_evaluation&lt;=0.397 &amp; average_montly_hours&lt;=250.5 &amp; Work_accident&lt;=0.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.194 </td>
   <td style="text-align:left;"> 0.201 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7261 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.8063 &amp; average_montly_hours&gt;232 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.097 </td>
   <td style="text-align:left;"> 0.199 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7281 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5817 &amp; average_montly_hours&gt;237.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.057 </td>
   <td style="text-align:left;"> 0.198 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7305 </td>
   <td style="text-align:left;"> number_project&lt;=3.5 &amp; salary&lt;=2.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.042 </td>
   <td style="text-align:left;"> 0.197 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7333 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.5868 &amp; average_montly_hours&gt;237.5 &amp; time_spend_company&gt;7.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.056 </td>
   <td style="text-align:left;"> 0.196 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7358 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5088 &amp; average_montly_hours&gt;285.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.159 </td>
   <td style="text-align:left;"> 0.194 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7385 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3873 &amp; average_montly_hours&lt;=313.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.224 </td>
   <td style="text-align:left;"> 0.193 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7474 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4247 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.362 </td>
   <td style="text-align:left;"> 0.189 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7521 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4199 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.356 </td>
   <td style="text-align:left;"> 0.186 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7535 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3873 &amp; average_montly_hours&lt;=250.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.143 </td>
   <td style="text-align:left;"> 0.186 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7568 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5932 &amp; average_montly_hours&lt;=172.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.092 </td>
   <td style="text-align:left;"> 0.184 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7636 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4247 &amp; last_evaluation&lt;=0.5292 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.194 </td>
   <td style="text-align:left;"> 0.181 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7636 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3673 &amp; average_montly_hours&lt;=250.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.124 </td>
   <td style="text-align:left;"> 0.18 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7703 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.5874 &amp; average_montly_hours&gt;314.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.123 </td>
   <td style="text-align:left;"> 0.177 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7739 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; average_montly_hours&lt;=231.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.107 </td>
   <td style="text-align:left;"> 0.175 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7802 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3873 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.316 </td>
   <td style="text-align:left;"> 0.171 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7802 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4972 &amp; last_evaluation&lt;=0.631 &amp; salary&lt;=1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.172 </td>
   <td style="text-align:left;"> 0.171 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7854 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5727 &amp; number_project&lt;=7.5 &amp; average_montly_hours&lt;=229.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.185 </td>
   <td style="text-align:left;"> 0.169 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7906 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; last_evaluation&lt;=0.5569 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.159 </td>
   <td style="text-align:left;"> 0.166 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7930 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.3 </td>
   <td style="text-align:left;"> 0.164 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7958 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5655 &amp; last_evaluation&lt;=0.5316 &amp; salary&lt;=1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.178 </td>
   <td style="text-align:left;"> 0.163 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7973 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5868 &amp; last_evaluation&lt;=0.4622 &amp; number_project&lt;=7.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.184 </td>
   <td style="text-align:left;"> 0.162 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.7978 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5925 &amp; last_evaluation&lt;=0.4883 &amp; average_montly_hours&lt;=248.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.25 </td>
   <td style="text-align:left;"> 0.161 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8002 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3673 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.29 </td>
   <td style="text-align:left;"> 0.16 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8009 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.29 </td>
   <td style="text-align:left;"> 0.159 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8020 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5823 &amp; last_evaluation&lt;=0.5037 &amp; average_montly_hours&lt;=243.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.246 </td>
   <td style="text-align:left;"> 0.159 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8069 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5817 &amp; last_evaluation&lt;=0.4883 &amp; average_montly_hours&lt;=243.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.238 </td>
   <td style="text-align:left;"> 0.156 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8069 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5812 &amp; last_evaluation&lt;=0.4883 &amp; average_montly_hours&lt;=243.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.238 </td>
   <td style="text-align:left;"> 0.156 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8126 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3495 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.262 </td>
   <td style="text-align:left;"> 0.152 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8139 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5817 &amp; number_project&lt;=6.5 &amp; average_montly_hours&lt;=229.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.144 </td>
   <td style="text-align:left;"> 0.151 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8167 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; average_montly_hours&gt;231.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.183 </td>
   <td style="text-align:left;"> 0.15 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8190 </td>
   <td style="text-align:left;"> average_montly_hours&gt;348.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.058 </td>
   <td style="text-align:left;"> 0.148 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8258 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3142 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.215 </td>
   <td style="text-align:left;"> 0.144 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8272 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.5655 &amp; last_evaluation&lt;=0.462 &amp; average_montly_hours&lt;=236 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.202 </td>
   <td style="text-align:left;"> 0.143 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8273 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3673 &amp; average_montly_hours&gt;250.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.166 </td>
   <td style="text-align:left;"> 0.143 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8281 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; last_evaluation&lt;=0.5173 &amp; average_montly_hours&lt;=281.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.11 </td>
   <td style="text-align:left;"> 0.142 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8298 </td>
   <td style="text-align:left;"> average_montly_hours&gt;345.5 &amp; Work_accident&lt;=0.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.059 </td>
   <td style="text-align:left;"> 0.141 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8333 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; last_evaluation&lt;=0.5042 &amp; average_montly_hours&lt;=281.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.112 </td>
   <td style="text-align:left;"> 0.139 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8381 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; last_evaluation&lt;=0.5037 &amp; average_montly_hours&lt;=271.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.105 </td>
   <td style="text-align:left;"> 0.136 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8406 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; last_evaluation&lt;=0.471 &amp; average_montly_hours&lt;=279.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.097 </td>
   <td style="text-align:left;"> 0.134 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8426 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; salary&lt;=1.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.167 </td>
   <td style="text-align:left;"> 0.133 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8431 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.4247 &amp; last_evaluation&lt;=0.5292 &amp; average_montly_hours&lt;=247 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.145 </td>
   <td style="text-align:left;"> 0.132 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8436 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; number_project&lt;=6.5 &amp; average_montly_hours&lt;=291.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.069 </td>
   <td style="text-align:left;"> 0.132 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8522 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.8063 &amp; number_project&gt;8.5 &amp; average_montly_hours&gt;232 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.051 </td>
   <td style="text-align:left;"> 0.126 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8604 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; number_project&lt;=6.5 &amp; average_montly_hours&lt;=272.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.066 </td>
   <td style="text-align:left;"> 0.12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8605 </td>
   <td style="text-align:left;"> satisfaction_level&gt;0.7133 &amp; last_evaluation&gt;0.8247 &amp; salary&gt;1.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.011 </td>
   <td style="text-align:left;"> 0.12 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8653 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; average_montly_hours&gt;281.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.136 </td>
   <td style="text-align:left;"> 0.117 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8696 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.9132 &amp; number_project&gt;8.5 &amp; salary&gt;1.5 &amp; salary&lt;=2.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.006 </td>
   <td style="text-align:left;"> 0.113 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8748 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3673 &amp; average_montly_hours&gt;281.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.134 </td>
   <td style="text-align:left;"> 0.11 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8841 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.349 &amp; average_montly_hours&gt;279.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.127 </td>
   <td style="text-align:left;"> 0.102 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8881 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.631 &amp; average_montly_hours&gt;244 &amp; time_spend_company&gt;6.5 &amp; salary&lt;=1.5 </td>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> 0.072 </td>
   <td style="text-align:left;"> 0.099 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.8976 </td>
   <td style="text-align:left;"> average_montly_hours&gt;361.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.032 </td>
   <td style="text-align:left;"> 0.092 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9007 </td>
   <td style="text-align:left;"> last_evaluation&gt;0.6109 &amp; average_montly_hours&gt;350.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.035 </td>
   <td style="text-align:left;"> 0.089 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9011 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; number_project&gt;6.5 &amp; average_montly_hours&gt;271.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.132 </td>
   <td style="text-align:left;"> 0.089 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9023 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; number_project&gt;6.5 &amp; average_montly_hours&gt;272.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.13 </td>
   <td style="text-align:left;"> 0.088 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9049 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3177 &amp; average_montly_hours&gt;278.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.113 </td>
   <td style="text-align:left;"> 0.086 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9095 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.3177 &amp; last_evaluation&gt;0.7186 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.055 </td>
   <td style="text-align:left;"> 0.082 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9100 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; last_evaluation&gt;0.4617 &amp; average_montly_hours&gt;281.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.122 </td>
   <td style="text-align:left;"> 0.082 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9111 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.1218 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.045 </td>
   <td style="text-align:left;"> 0.081 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9137 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; last_evaluation&gt;0.4223 &amp; average_montly_hours&gt;281.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.124 </td>
   <td style="text-align:left;"> 0.079 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9160 </td>
   <td style="text-align:left;"> average_montly_hours&gt;362.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.03 </td>
   <td style="text-align:left;"> 0.077 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9167 </td>
   <td style="text-align:left;"> number_project&gt;8.5 &amp; average_montly_hours&gt;350.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.036 </td>
   <td style="text-align:left;"> 0.076 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9167 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.367 &amp; last_evaluation&gt;0.4665 &amp; average_montly_hours&gt;279.5 </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> 0.123 </td>
   <td style="text-align:left;"> 0.076 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9297 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.131 &amp; average_montly_hours&gt;242 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.046 </td>
   <td style="text-align:left;"> 0.065 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9377 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.2456 &amp; average_montly_hours&gt;291.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.072 </td>
   <td style="text-align:left;"> 0.058 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9458 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.374 &amp; average_montly_hours&gt;348.5 </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> 0.042 </td>
   <td style="text-align:left;"> 0.051 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9593 </td>
   <td style="text-align:left;"> satisfaction_level&lt;=0.09 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.031 </td>
   <td style="text-align:left;"> 0.039 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.9833 </td>
   <td style="text-align:left;"> average_montly_hours&gt;373.5 </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> 0.015 </td>
   <td style="text-align:left;"> 0.016 </td>
  </tr>
</tbody>
</table>



