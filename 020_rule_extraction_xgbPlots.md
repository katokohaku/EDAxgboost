---
author: "Satoshi Kato"
title: rule extraction from xgboost model"
date: "2019/04/30"
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
```


```r
require(tidyverse)
require(data.table)
require(xgboost)
library(inTrees)
library(xtable)

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
[17:06:16] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[17:06:16] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
```

# View tree model structure

## Parse a boosted tree model text dump into a data.table structure.


```r
xgb.model.dt.tree(model = model.xgb) %>% 
  mutate(Feature = str_trunc(Feature, width = 12, side = "right"),
         Quality = round(Quality, 2),
         Cover   = as.integer(Cover)) %>% 
  data.table()
```

```
     Tree Node    ID      Feature   Split  Yes   No Missing Quality Cover
  1:    0    0   0-0 number_pr...   2.500  0-1  0-2     0-1  534.90   999
  2:    0    1   0-1 last_eval...   0.575  0-3  0-4     0-3  255.54   163
  3:    0    2   0-2 time_spen...   3.500  0-5  0-6     0-5  431.24   836
  4:    0    3   0-3 average_m... 161.500  0-7  0-8     0-7   97.65   122
  5:    0    4   0-4 sales_tec...   0.500  0-9 0-10     0-9    2.29    41
 ---                                                                     
358:   11   24 11-24         Leaf      NA <NA> <NA>    <NA>    0.00     3
359:   11   25 11-25         Leaf      NA <NA> <NA>    <NA>   -0.07    35
360:   11   26 11-26         Leaf      NA <NA> <NA>    <NA>   -0.03     4
361:   11   27 11-27         Leaf      NA <NA> <NA>    <NA>   -0.02     6
362:   11   28 11-28         Leaf      NA <NA> <NA>    <NA>    0.07    56
```

## Project all trees on one tree and plot it


```r
# install.packages("rsvg", dependencies = TRUE)
# devtools::install_github('rich-iannone/DiagrammeRsvg')
                          
ggp.multi.tree <- xgb.plot.multi.trees(model = model.xgb, render=FALSE)
```

```
Column 2 ['No'] of item 2 is missing in item 1. Use fill=TRUE to fill with NA (NULL for list columns), or use.names=FALSE to ignore column names. use.names='check' (default from v1.12.2) emits this message and proceeds as if use.names=FALSE for  backwards compatibility. See news item 5 in v1.12.2 for options to control this message.
```

```r
DiagrammeR::export_graph(ggp.multi.tree, "./output/image.files/020_summarise_xgbTrees.pdf",
                         width=960, height=720)
```

[See pdf file](./output/image.files/020_summarise_xgbTrees.pdf)

# Plot a boosted tree model

## First tree


```r
ggp.1st.tree <- xgb.plot.tree(model = model.xgb, trees = 0)
DiagrammeR::export_graph(ggp.multi.tree, "./output/image.files/020_xgb_1st_tree.pdf",
                         width=960, height=720)
```

[See pdf file](./output/image.files/020_xgb_1st_tree.pdf)

## Following booster


```r
ggp.2nd.tree <- xgb.plot.tree(model = model.xgb, trees = 0)
DiagrammeR::export_graph(ggp.multi.tree, "./output/image.files/020_xgb_2nd_tree.pdf",
                         width=960, height=720)
```

[See pdf file](./output/image.files/020_xgb_2nd_tree.pdf)
