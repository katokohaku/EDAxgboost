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
install.packages("DiagrammeR", dependencies = TRUE)
install.packages("inTtrees", dependencies = TRUE)

install.packages("devtools", dependencies = TRUE)
devtools::install_github("AppliedDataSciencePartners/xgboostExplainer")
```


```r
require(tidyverse)
require(data.table)
require(xgboost)
library(xgboostExplainer)
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
[00:36:08] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[00:36:08] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
```

