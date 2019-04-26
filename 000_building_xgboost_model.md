---
author: "Satoshi Kato"
title: "building xgboost model"
date: "2019/04/26"
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
```

# Data preparation


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
HR.dummy <- HR_data %>% 
  dummy_cols(select_columns = c("sales", "salary"), remove_first_dummy = FALSE) %>% 
  select(-sales, -salary, -sales_management, -salary_high)

train.i <- sample(NROW(HR.dummy), NROW(HR.dummy) / 3)
test.i  <- setdiff(1:NROW(HR.dummy), train.i)

train.matrix <- HR.dummy[train.i, ] %>% select(-left) %>% as.matrix()
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
test.matrix <- HR.dummy[test.i, ] %>% select(-left) %>% as.matrix()
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

# parameter settings for XGBoost

see. https://xgboost.readthedocs.io/en/latest/parameter.html


```r
params <- list(
  booster      = "gbtree", # MUST be set booster = "gbtree" to build explainer
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
                       nrounds = cv$best_iteration,
                       nfold   = 5)
```

# Save data and model


```r
res <- list(
  data = list(
    original = HR.dummy,
    train = list(
      matrix = train.matrix,
      label  = train.label
    ),
    test = list(
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


