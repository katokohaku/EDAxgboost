---
author: "Satoshi Kato"
title: "building xgboost model"
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
install.packages("table1",      dependencies = TRUE)
install.packages("breakDown",   dependencies = TRUE)
install.packages("fastDummies", dependencies = TRUE)
install.packages("xgboost",     dependencies = TRUE)
install.packages("tidyverse",   dependencies = TRUE)
install.packages("AUC",         dependencies = TRUE)

install.packages("caret", dependencies = FALSE)
```


```r
require(fastDummies)
require(xgboost)
require(tidyverse)
require(AUC)
require(caret)

require(table1)
```

# Data 

according to `help(breakDown::HR_data)`

## Description

A dataset from Kaggle competition Human Resources Analytics: Why are our best and most experienced employees leaving prematurely?

* `satisfaction_level` Level of satisfaction (0-1)
* `last_evaluation` Time since last performance evaluation (in Years)
* `number_project` Number of projects completed while at work
* `average_montly_hours` Average monthly hours at workplace
* `time_spend_company` Number of years spent in the company
* `Work_accident` Whether the employee had a workplace accident
* `left` Whether the employee left the workplace or not (1 or 0) Factor
* `promotion_last_5years` Whether the employee was promoted in the last five years
* `sales` Department in which they work for
* `salary` Relative level of salary (high)

## Source

Dataset HR-analytics from https://www.kaggle.com




```r
data(HR_data, package = "breakDown")
HR_data %>% str
```

```
'data.frame':	14999 obs. of  10 variables:
 $ satisfaction_level   : num  0.38 0.8 0.11 0.72 0.37 0.41 0.1 0.92 0.89 0.42 ...
 $ last_evaluation      : num  0.53 0.86 0.88 0.87 0.52 0.5 0.77 0.85 1 0.53 ...
 $ number_project       : int  2 5 7 5 2 2 6 5 5 2 ...
 $ average_montly_hours : int  157 262 272 223 159 153 247 259 224 142 ...
 $ time_spend_company   : int  3 6 4 5 3 3 4 5 5 3 ...
 $ Work_accident        : int  0 0 0 0 0 0 0 0 0 0 ...
 $ left                 : int  1 1 1 1 1 1 1 1 1 1 ...
 $ promotion_last_5years: int  0 0 0 0 0 0 0 0 0 0 ...
 $ sales                : Factor w/ 10 levels "accounting","hr",..: 8 8 8 8 8 8 8 8 8 8 ...
 $ salary               : Factor w/ 3 levels "high","low","medium": 2 3 3 2 2 2 2 2 2 2 ...
```


```r
table1(~ left +
         satisfaction_level + last_evaluation + number_project + 
         average_montly_hours + time_spend_company + 
         Work_accident + promotion_last_5years 
       | left, data = HR_data)
```

<!--html_preserve--><div class="Rtable1"><table class="Rtable1">
<thead>
<tr>
<th class='rowlabel firstrow lastrow'></th>
<th class='firstrow lastrow'><span class='stratlabel'>0<br><span class='stratn'>(n=11428)</span></span></th>
<th class='firstrow lastrow'><span class='stratlabel'>1<br><span class='stratn'>(n=3571)</span></span></th>
<th class='firstrow lastrow'><span class='stratlabel'>Overall<br><span class='stratn'>(n=14999)</span></span></th>
</tr>
</thead>
<tbody>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>left</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.00 (0.00)</td>
<td>1.00 (0.00)</td>
<td>0.238 (0.426)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.00 [0.00, 0.00]</td>
<td class='lastrow'>1.00 [1.00, 1.00]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>satisfaction_level</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.667 (0.217)</td>
<td>0.440 (0.264)</td>
<td>0.613 (0.249)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.690 [0.120, 1.00]</td>
<td class='lastrow'>0.410 [0.0900, 0.920]</td>
<td class='lastrow'>0.640 [0.0900, 1.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>last_evaluation</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.715 (0.162)</td>
<td>0.718 (0.198)</td>
<td>0.716 (0.171)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.710 [0.360, 1.00]</td>
<td class='lastrow'>0.790 [0.450, 1.00]</td>
<td class='lastrow'>0.720 [0.360, 1.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>number_project</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>3.79 (0.980)</td>
<td>3.86 (1.82)</td>
<td>3.80 (1.23)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>4.00 [2.00, 6.00]</td>
<td class='lastrow'>4.00 [2.00, 7.00]</td>
<td class='lastrow'>4.00 [2.00, 7.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>average_montly_hours</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>199 (45.7)</td>
<td>207 (61.2)</td>
<td>201 (49.9)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>198 [96.0, 287]</td>
<td class='lastrow'>224 [126, 310]</td>
<td class='lastrow'>200 [96.0, 310]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>time_spend_company</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>3.38 (1.56)</td>
<td>3.88 (0.978)</td>
<td>3.50 (1.46)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>3.00 [2.00, 10.0]</td>
<td class='lastrow'>4.00 [2.00, 6.00]</td>
<td class='lastrow'>3.00 [2.00, 10.0]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>Work_accident</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.175 (0.380)</td>
<td>0.0473 (0.212)</td>
<td>0.145 (0.352)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>promotion_last_5years</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.0263 (0.160)</td>
<td>0.00532 (0.0728)</td>
<td>0.0213 (0.144)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
<td class='lastrow'>0.00 [0.00, 1.00]</td>
</tr>
</tbody>
</table>
</div><!--/html_preserve-->


```r
table1(~ factor(sales) + factor(salary)
       | left, data = HR_data)
```

<!--html_preserve--><div class="Rtable1"><table class="Rtable1">
<thead>
<tr>
<th class='rowlabel firstrow lastrow'></th>
<th class='firstrow lastrow'><span class='stratlabel'>0<br><span class='stratn'>(n=11428)</span></span></th>
<th class='firstrow lastrow'><span class='stratlabel'>1<br><span class='stratn'>(n=3571)</span></span></th>
<th class='firstrow lastrow'><span class='stratlabel'>Overall<br><span class='stratn'>(n=14999)</span></span></th>
</tr>
</thead>
<tbody>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>factor(sales)</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>accounting</td>
<td>563 (4.9%)</td>
<td>204 (5.7%)</td>
<td>767 (5.1%)</td>
</tr>
<tr>
<td class='rowlabel'>hr</td>
<td>524 (4.6%)</td>
<td>215 (6.0%)</td>
<td>739 (4.9%)</td>
</tr>
<tr>
<td class='rowlabel'>IT</td>
<td>954 (8.3%)</td>
<td>273 (7.6%)</td>
<td>1227 (8.2%)</td>
</tr>
<tr>
<td class='rowlabel'>management</td>
<td>539 (4.7%)</td>
<td>91 (2.5%)</td>
<td>630 (4.2%)</td>
</tr>
<tr>
<td class='rowlabel'>marketing</td>
<td>655 (5.7%)</td>
<td>203 (5.7%)</td>
<td>858 (5.7%)</td>
</tr>
<tr>
<td class='rowlabel'>product_mng</td>
<td>704 (6.2%)</td>
<td>198 (5.5%)</td>
<td>902 (6.0%)</td>
</tr>
<tr>
<td class='rowlabel'>RandD</td>
<td>666 (5.8%)</td>
<td>121 (3.4%)</td>
<td>787 (5.2%)</td>
</tr>
<tr>
<td class='rowlabel'>sales</td>
<td>3126 (27.4%)</td>
<td>1014 (28.4%)</td>
<td>4140 (27.6%)</td>
</tr>
<tr>
<td class='rowlabel'>support</td>
<td>1674 (14.6%)</td>
<td>555 (15.5%)</td>
<td>2229 (14.9%)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>technical</td>
<td class='lastrow'>2023 (17.7%)</td>
<td class='lastrow'>697 (19.5%)</td>
<td class='lastrow'>2720 (18.1%)</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>factor(salary)</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>high</td>
<td>1155 (10.1%)</td>
<td>82 (2.3%)</td>
<td>1237 (8.2%)</td>
</tr>
<tr>
<td class='rowlabel'>low</td>
<td>5144 (45.0%)</td>
<td>2172 (60.8%)</td>
<td>7316 (48.8%)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>medium</td>
<td class='lastrow'>5129 (44.9%)</td>
<td class='lastrow'>1317 (36.9%)</td>
<td class='lastrow'>6446 (43.0%)</td>
</tr>
</tbody>
</table>
</div><!--/html_preserve-->
# Preparation

## create dummy cols


```r
HR.dummy <- HR_data %>% 
  dummy_cols(select_columns = c("sales", "salary"), remove_first_dummy = FALSE) %>% 
  select(-sales, -salary, -sales_management, -salary_high)

train.i <- sample(NROW(HR.dummy), NROW(HR.dummy) / 3)
test.i  <- setdiff(1:NROW(HR.dummy), train.i)

train.df     <- HR.dummy[train.i, ] 
train.matrix <- train.df %>% select(-left) %>% as.matrix()
# train.matrix %>% str
train.label  <- HR.dummy[train.i, ]$left
train.xgb.DMatrix <- xgb.DMatrix(train.matrix, label = train.label)
table(train.label)
```

```
train.label
   0    1 
3801 1198 
```

```r
test.df     <- HR.dummy[test.i, ] 
test.matrix <- test.df %>% select(-left) %>% as.matrix()
# test.matrix %>% str
test.label  <- HR.dummy[test.i, ]$left
test.xgb.DMatrix <- xgb.DMatrix(test.matrix, label = test.label)
table(test.label)
```

```
test.label
   0    1 
7627 2373 
```
# build XGBoost model

## parameter settings

see. https://xgboost.readthedocs.io/en/latest/parameter.html


```r
params <- list(
  booster      = "gbtree", # MUST be set booster = "gbtree" to build xgbExplainer
  objective    = "binary:logistic",
  eval_metric  = "auc",    # instead of "logloss", "error" and "aucpr"
  max_depth = 5,
  colsample_bytree= 0.8,
  subsample = 0.8,
  min_child_weight = 3,
  eta   = 0.05,
  alpha = 0.25,
  gamma = 0
) 
```

## search optimal number of booster with cross-validation


```r
cv <- xgb.cv(params  = params, 
             verbose = 1,
             data    = train.xgb.DMatrix,
             nrounds = 200,
             nfold   = 5,
             early_stopping_rounds = 10)
```

```
[1]	train-auc:0.965945+0.008385	test-auc:0.964709+0.013560 
Multiple eval metrics are present. Will use test_auc for early stopping.
Will train until test_auc hasn't improved in 10 rounds.

[2]	train-auc:0.972588+0.003931	test-auc:0.970187+0.014736 
[3]	train-auc:0.975726+0.004095	test-auc:0.972336+0.015878 
[4]	train-auc:0.979044+0.002817	test-auc:0.973521+0.016580 
[5]	train-auc:0.981272+0.002294	test-auc:0.976583+0.012226 
[6]	train-auc:0.981602+0.002181	test-auc:0.976680+0.012269 
[7]	train-auc:0.981953+0.001983	test-auc:0.976925+0.012332 
[8]	train-auc:0.982039+0.001924	test-auc:0.976083+0.013602 
[9]	train-auc:0.982787+0.002430	test-auc:0.977269+0.010914 
[10]	train-auc:0.983096+0.002413	test-auc:0.978000+0.011083 
[11]	train-auc:0.983303+0.002399	test-auc:0.977984+0.011147 
[12]	train-auc:0.983397+0.002406	test-auc:0.978240+0.011132 
[13]	train-auc:0.983538+0.002318	test-auc:0.978193+0.011515 
[14]	train-auc:0.983706+0.002200	test-auc:0.977462+0.011318 
[15]	train-auc:0.983958+0.001976	test-auc:0.977944+0.011662 
[16]	train-auc:0.984142+0.001963	test-auc:0.978028+0.011615 
[17]	train-auc:0.984057+0.001741	test-auc:0.977793+0.011638 
[18]	train-auc:0.984132+0.001765	test-auc:0.977649+0.011682 
[19]	train-auc:0.984168+0.001504	test-auc:0.977943+0.011651 
[20]	train-auc:0.984364+0.001482	test-auc:0.977902+0.011654 
[21]	train-auc:0.984512+0.001556	test-auc:0.977921+0.011561 
[22]	train-auc:0.984756+0.001555	test-auc:0.977454+0.011931 
Stopping. Best iteration:
[12]	train-auc:0.983397+0.002406	test-auc:0.978240+0.011132
```

```r
print(cv, verbose=TRUE)
```

```
##### xgb.cv 5-folds
call:
  xgb.cv(params = params, data = train.xgb.DMatrix, nrounds = 200, 
    nfold = 5, verbose = 1, early_stopping_rounds = 10)
params (as set within xgb.cv):
  booster = "gbtree", objective = "binary:logistic", eval_metric = "auc", max_depth = "5", colsample_bytree = "0.8", subsample = "0.8", min_child_weight = "3", eta = "0.05", alpha = "0.25", gamma = "0", silent = "1"
callbacks:
  cb.print.evaluation(period = print_every_n, showsd = showsd)
  cb.evaluation.log()
  cb.early.stop(stopping_rounds = early_stopping_rounds, maximize = maximize, 
    verbose = verbose)
niter: 22
best_iteration: 12
best_ntreelimit: 12
evaluation_log:
 iter train_auc_mean train_auc_std test_auc_mean test_auc_std
    1      0.9659452   0.008384731     0.9647092   0.01355988
    2      0.9725884   0.003931400     0.9701866   0.01473620
    3      0.9757258   0.004095221     0.9723362   0.01587807
    4      0.9790436   0.002817093     0.9735214   0.01657956
    5      0.9812724   0.002294002     0.9765832   0.01222591
    6      0.9816016   0.002180952     0.9766802   0.01226892
    7      0.9819532   0.001982889     0.9769252   0.01233205
    8      0.9820394   0.001924411     0.9760834   0.01360175
    9      0.9827866   0.002430161     0.9772690   0.01091404
   10      0.9830956   0.002413275     0.9780004   0.01108266
   11      0.9833034   0.002399231     0.9779836   0.01114671
   12      0.9833966   0.002406025     0.9782398   0.01113163
   13      0.9835382   0.002317625     0.9781932   0.01151472
   14      0.9837064   0.002200470     0.9774622   0.01131811
   15      0.9839578   0.001976229     0.9779442   0.01166195
   16      0.9841416   0.001963440     0.9780276   0.01161498
   17      0.9840566   0.001741255     0.9777928   0.01163782
   18      0.9841318   0.001765152     0.9776490   0.01168170
   19      0.9841678   0.001503546     0.9779426   0.01165148
   20      0.9843640   0.001482087     0.9779018   0.01165372
   21      0.9845124   0.001555583     0.9779208   0.01156060
   22      0.9847562   0.001554672     0.9774542   0.01193050
 iter train_auc_mean train_auc_std test_auc_mean test_auc_std
Best iteration:
 iter train_auc_mean train_auc_std test_auc_mean test_auc_std
   12      0.9833966   0.002406025     0.9782398   0.01113163
```


```r
model.xgb <- xgb.train(params  = params, 
                       verbose = 1,
                       data    = train.xgb.DMatrix,
                       nrounds = cv$best_iteration)
```

# Save data and model


```r
res <- list(
  data = list(
    original = HR.dummy,
    train = list(
      dummy.data.frame = train.df,
      matrix = train.matrix,
      label  = train.label
    ),
    test = list(
      dummy.data.frame = test.df,
      matrix = test.matrix,
      label  = test.label
    )
  ),
  model = list(
    param.set = params,
    cv = cv,
    xgb = model.xgb
  )
)
 
saveRDS(res, file = "./middle/data_and_model.Rds")
xgb.DMatrix.save(train.xgb.DMatrix, fname = "./middle/train.xgbDMatrix")
```

```
[1] TRUE
```

```r
xgb.DMatrix.save(test.xgb.DMatrix,  fname = "./middle/test.xgbDMatrix")
```

```
[1] TRUE
```


