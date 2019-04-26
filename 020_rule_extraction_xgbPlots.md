---
author: "Satoshi Kato"
title: rule extraction from xgboost model"
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
[00:34:34] 4999x18 matrix with 89982 entries loaded from ./middle/train.xgbDMatrix
```

```r
test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix("./middle/test.xgbDMatrix")
```

```
[00:34:34] 10000x18 matrix with 180000 entries loaded from ./middle/test.xgbDMatrix
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
xgb.plot.multi.trees(model = model.xgb)
```

```
Column 2 ['No'] of item 2 is missing in item 1. Use fill=TRUE to fill with NA (NULL for list columns), or use.names=FALSE to ignore column names. use.names='check' (default from v1.12.2) emits this message and proceeds as if use.names=FALSE for  backwards compatibility. See news item 5 in v1.12.2 for options to control this message.
```

<!--html_preserve--><div id="htmlwidget-a10f342daf62c57fb7fd" style="width:768px;height:768px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-a10f342daf62c57fb7fd">{"x":{"diagram":"digraph {\n\ngraph [layout = \"dot\",\n       rankdir = \"LR\"]\n\nnode [color = \"DimGray\",\n      fillcolor = \"beige\",\n      style = \"filled\",\n      shape = \"rectangle\",\n      fontname = \"Helvetica\"]\n\nedge [color = \"DimGray\",\n     arrowsize = \"1.5\",\n     arrowhead = \"vee\",\n     fontname = \"Helvetica\"]\n\n  \"1\" [label = \"number_project (1807.4)\nsatisfaction_level (3709.7)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"2\" [label = \"last_evaluation (747.59)\ntime_spend_company (488.46)\nnumber_project (606.26)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"3\" [label = \"time_spend_company (2948.70)\nnumber_project ( 176.59)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"4\" [label = \"average_montly_hours ( 97.647034)\ntime_spend_company (285.862137)\nlast_evaluation (260.338257)\nsatisfaction_level ( 52.287872)\nLeaf ( -0.059191)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"5\" [label = \"sales_technical (   3.700020)\nsatisfaction_level (1451.359348)\nLeaf (  -0.069374)\nlast_evaluation (   2.339676)\ntime_spend_company (  52.411171)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"6\" [label = \"average_montly_hours (25.53943)\nLeaf (-0.25958)\nsatisfaction_level ( 0.40234)\nlast_evaluation (55.34875)\nnumber_project ( 0.11536)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"7\" [label = \"average_montly_hours ( 501.43)\nlast_evaluation (1356.18)\nnumber_project ( 110.37)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"8\" [label = \"average_montly_hours (60.98260)\nLeaf (-0.35323)\nsatisfaction_level (72.96243)\nlast_evaluation ( 0.88525)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"9\" [label = \"sales_sales ( 1.55903)\nsatisfaction_level (80.47212)\nLeaf (-0.12255)\ntime_spend_company (84.12794)\naverage_montly_hours (24.15977)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"10\" [label = \"last_evaluation (0.88152)\nLeaf (0.46618)\ntime_spend_company (0.44287)\nWork_accident (3.18340)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"11\" [label = \"average_montly_hours ( 9.62574)\nLeaf (-0.19212)\nlast_evaluation ( 1.94758)\ntime_spend_company ( 1.25650)\nsales_accounting ( 1.19870)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"12\" [label = \"Leaf (-0.51917)\nsatisfaction_level ( 0.16333)\nlast_evaluation ( 1.71790)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"13\" [label = \"Leaf (-0.20098)\nnumber_project (53.90333)\nsales_sales ( 0.65605)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"14\" [label = \"Leaf (-0.23158)\nlast_evaluation ( 7.39745)\nsales_technical ( 1.39301)\naverage_montly_hours ( 8.23991)\ntime_spend_company (17.57888)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"15\" [label = \"last_evaluation (272.6132)\naverage_montly_hours (206.5151)\ntime_spend_company (398.4468)\nnumber_project (286.2052)\nWork_accident (  6.5168)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"16\" [label = \"Leaf (-0.27307)\nsatisfaction_level ( 1.03954)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"17\" [label = \"last_evaluation ( 1.977509)\naverage_montly_hours ( 9.008698)\nLeaf (-0.083611)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"18\" [label = \"Leaf (-0.11159)\nlast_evaluation ( 6.37347)\naverage_montly_hours ( 3.52763)\nsales_RandD ( 0.84335)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"19\" [label = \"Leaf ( -0.11827)\nsatisfaction_level (380.99132)\ntime_spend_company ( 29.47128)\nlast_evaluation ( 26.97871)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"20\" [label = \"Leaf (-0.16933)\nsalary_low ( 2.35268)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"21\" [label = \"salary_low (0.897757)\ntime_spend_company (3.532241)\nLeaf (0.010054)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"22\" [label = \"Leaf (-0.33269)\naverage_montly_hours ( 2.82586)\nsalary_low ( 0.44186)\ntime_spend_company ( 2.04573)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"23\" [label = \"Leaf (-0.30776)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"24\" [label = \"average_montly_hours (75.585)\ntime_spend_company (80.911)\nsatisfaction_level (53.468)\nnumber_project (19.754)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"25\" [label = \"number_project (109.69104)\ntime_spend_company (104.35210)\nLeaf ( -0.45602)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"26\" [label = \"Leaf (0.27561)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"27\" [label = \"Leaf (0.14941)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"28\" [label = \"Leaf (-0.080879)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"29\" [label = \"Leaf (-0.10171)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"30\" [label = \"Leaf (-0.37227)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"31\" [label = \"Leaf (0.25687)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"32\" [label = \"Leaf (0.1745)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"33\" [label = \"Leaf (-0.072505)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"34\" [label = \"Leaf (0.0024192)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"35\" [label = \"Leaf (0.10452)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"36\" [label = \"sales_support ( 2.92036)\nLeaf (-0.28970)\naverage_montly_hours ( 4.70669)\nsales_technical ( 0.37863)\ntime_spend_company ( 0.57770)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"37\" [label = \"Leaf (-0.20235)\nlast_evaluation ( 0.49461)\ntime_spend_company (34.21330)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"38\" [label = \"Leaf (-0.3296)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"39\" [label = \"Leaf (-0.16956)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"40\" [label = \"Leaf (0.10455)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"41\" [label = \"Leaf (0.16915)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"42\" [label = \"Leaf (-0.029995)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"43\" [label = \"Leaf (-0.12243)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"44\" [label = \"Leaf (-0.12032)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"45\" [label = \"Leaf (-0.079781)\nnumber_project ( 0.372292)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"46\" [label = \"Leaf (-0.043325)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"47\" [label = \"Leaf (-0.0028926)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"48\" [label = \"Leaf (-0.12586)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"49\" [label = \"Leaf (-0.00064039)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"50\" [label = \"last_evaluation (14.159393)\nLeaf (-0.055512)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"51\" [label = \"last_evaluation ( 5.651399)\nLeaf (-0.016977)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"52\" [label = \"Leaf (-0.065629)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"53\" [label = \"Leaf (-0.042852)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"54\" [label = \"Leaf (-0.055918)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"55\" [label = \"Leaf (0.0091865)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"56\" [label = \"Leaf (-0.0044334)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"57\" [label = \"Leaf (0.035684)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"58\" [label = \"Leaf (0.035226)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"59\" [label = \"Leaf (0.054043)\", fillcolor = \"#F5F5DC\", fontcolor = \"#000000\"] \n  \"1\"->\"2\" \n  \"2\"->\"4\" \n  \"3\"->\"6\" \n  \"4\"->\"8\" \n  \"5\"->\"10\" \n  \"6\"->\"12\" \n  \"7\"->\"14\" \n  \"8\"->\"16\" \n  \"9\"->\"18\" \n  \"10\"->\"20\" \n  \"11\"->\"22\" \n  \"15\"->\"24\" \n  \"17\"->\"26\" \n  \"21\"->\"28\" \n  \"24\"->\"30\" \n  \"25\"->\"32\" \n  \"19\"->\"34\" \n  \"14\"->\"36\" \n  \"36\"->\"38\" \n  \"18\"->\"40\" \n  \"37\"->\"42\" \n  \"12\"->\"44\" \n  \"16\"->\"46\" \n  \"22\"->\"48\" \n  \"13\"->\"50\" \n  \"45\"->\"52\" \n  \"50\"->\"54\" \n  \"51\"->\"56\" \n  \"20\"->\"58\" \n  \"1\"->\"3\" \n  \"2\"->\"5\" \n  \"3\"->\"7\" \n  \"4\"->\"9\" \n  \"5\"->\"11\" \n  \"6\"->\"13\" \n  \"7\"->\"15\" \n  \"8\"->\"17\" \n  \"9\"->\"19\" \n  \"10\"->\"21\" \n  \"11\"->\"23\" \n  \"15\"->\"25\" \n  \"17\"->\"27\" \n  \"21\"->\"29\" \n  \"24\"->\"31\" \n  \"25\"->\"33\" \n  \"19\"->\"35\" \n  \"14\"->\"37\" \n  \"36\"->\"39\" \n  \"18\"->\"41\" \n  \"37\"->\"43\" \n  \"12\"->\"45\" \n  \"16\"->\"47\" \n  \"22\"->\"49\" \n  \"13\"->\"51\" \n  \"45\"->\"53\" \n  \"50\"->\"55\" \n  \"51\"->\"57\" \n  \"20\"->\"59\" \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

# Plot a boosted tree model

## First tree


```r
xgb.plot.tree(model = model.xgb, trees = 0)
```

<!--html_preserve--><div id="htmlwidget-61c7ef36a62044620361" style="width:768px;height:768px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-61c7ef36a62044620361">{"x":{"diagram":"digraph {\n\ngraph [layout = \"dot\",\n       rankdir = \"LR\"]\n\nnode [color = \"DimGray\",\n      style = \"filled\",\n      fontname = \"Helvetica\"]\n\nedge [color = \"DimGray\",\n     arrowsize = \"1.5\",\n     arrowhead = \"vee\",\n     fontname = \"Helvetica\"]\n\n  \"1\" [label = \"Tree 0\nnumber_project\nCover: 999\nGain: 534.899292\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"2\" [label = \"last_evaluation\nCover: 163\nGain: 255.540955\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"3\" [label = \"time_spend_company\nCover: 836\nGain: 431.239624\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"4\" [label = \"average_montly_hours\nCover: 122\nGain: 97.6470337\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"5\" [label = \"sales_technical\nCover: 41\nGain: 2.28980255\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"6\" [label = \"average_montly_hours\nCover: 509\nGain: 19.8862305\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"7\" [label = \"average_montly_hours\nCover: 327\nGain: 383.447571\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"8\" [label = \"average_montly_hours\nCover: 111\nGain: 60.982605\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"9\" [label = \"sales_sales\nCover: 11\nGain: 1.55902672\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"10\" [label = \"last_evaluation\nCover: 33.75\nGain: 0.881515503\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"11\" [label = \"average_montly_hours\nCover: 7.25\nGain: 0.145298481\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"12\" [label = \"Leaf\nCover: 506\nValue: -0.0976084843\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"13\" [label = \"Leaf\nCover: 3\nValue: 0.0218749996\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"14\" [label = \"Leaf\nCover: 132.75\nValue: -0.0883177593\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"15\" [label = \"last_evaluation\nCover: 194.25\nGain: 272.61322\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"16\" [label = \"Leaf\nCover: 4.75\nValue: -0.0804347843\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"17\" [label = \"last_evaluation\nCover: 106.25\nGain: 1.97750854\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"18\" [label = \"Leaf\nCover: 8\nValue: -0.0819444433\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"19\" [label = \"Leaf\nCover: 3\nValue: -0.0218749996\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"20\" [label = \"Leaf\nCover: 21.75\nValue: -0.0928571448\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"21\" [label = \"salary_low\nCover: 12\nGain: 0.897756577\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"22\" [label = \"Leaf\nCover: 4\nValue: -0.0474999994\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"23\" [label = \"Leaf\nCover: 3.25\nValue: -0.0147058833\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"24\" [label = \"average_montly_hours\nCover: 47\nGain: 2.09757996\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"25\" [label = \"number_project\nCover: 147.25\nGain: 109.69104\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"26\" [label = \"Leaf\nCover: 5\nValue: 0.0395833366\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"27\" [label = \"Leaf\nCover: 101.25\nValue: 0.0910758004\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"28\" [label = \"Leaf\nCover: 5.5\nValue: -0.075000003\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"29\" [label = \"Leaf\nCover: 6.5\nValue: -0.0316666663\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"30\" [label = \"Leaf\nCover: 37\nValue: -0.0891447365\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"31\" [label = \"Leaf\nCover: 10\nValue: -0.0488636382\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"32\" [label = \"Leaf\nCover: 11\nValue: -0.090625003\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"33\" [label = \"Leaf\nCover: 136.25\nValue: 0.0674863383\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n\"1\"->\"2\" [label = \"< 2.5\", style = \"bold\"] \n\"2\"->\"4\" [label = \"< 0.574999988\", style = \"bold\"] \n\"3\"->\"6\" [label = \"< 3.5\", style = \"bold\"] \n\"4\"->\"8\" [label = \"< 161.5\", style = \"bold\"] \n\"5\"->\"10\" [label = \"< 0.5\", style = \"bold\"] \n\"6\"->\"12\" [label = \"< 281.5\", style = \"bold\"] \n\"7\"->\"14\" [label = \"< 216.5\", style = \"bold\"] \n\"8\"->\"16\" [label = \"< 125\", style = \"bold\"] \n\"9\"->\"18\" [label = \"< 0.5\", style = \"bold\"] \n\"10\"->\"20\" [label = \"< 0.824999988\", style = \"bold\"] \n\"11\"->\"22\" [label = \"< 197.5\", style = \"bold\"] \n\"15\"->\"24\" [label = \"< 0.764999986\", style = \"bold\"] \n\"17\"->\"26\" [label = \"< 0.454999983\", style = \"bold\"] \n\"21\"->\"28\" [label = \"< 0.5\", style = \"bold\"] \n\"24\"->\"30\" [label = \"< 269.5\", style = \"bold\"] \n\"25\"->\"32\" [label = \"< 3.5\", style = \"bold\"] \n\"1\"->\"3\" [style = \"bold\", style = \"solid\"] \n\"2\"->\"5\" [style = \"solid\", style = \"solid\"] \n\"3\"->\"7\" [style = \"solid\", style = \"solid\"] \n\"4\"->\"9\" [style = \"solid\", style = \"solid\"] \n\"5\"->\"11\" [style = \"solid\", style = \"solid\"] \n\"6\"->\"13\" [style = \"solid\", style = \"solid\"] \n\"7\"->\"15\" [style = \"solid\", style = \"solid\"] \n\"8\"->\"17\" [style = \"solid\", style = \"solid\"] \n\"9\"->\"19\" [style = \"solid\", style = \"solid\"] \n\"10\"->\"21\" [style = \"solid\", style = \"solid\"] \n\"11\"->\"23\" [style = \"solid\", style = \"solid\"] \n\"15\"->\"25\" [style = \"solid\", style = \"solid\"] \n\"17\"->\"27\" [style = \"solid\", style = \"solid\"] \n\"21\"->\"29\" [style = \"solid\", style = \"solid\"] \n\"24\"->\"31\" [style = \"solid\", style = \"solid\"] \n\"25\"->\"33\" [style = \"solid\", style = \"solid\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Following booster


```r
xgb.plot.tree(model = model.xgb, trees = 1)
```

<!--html_preserve--><div id="htmlwidget-de577b997e2fd3abcb1b" style="width:768px;height:768px;" class="grViz html-widget"></div>
<script type="application/json" data-for="htmlwidget-de577b997e2fd3abcb1b">{"x":{"diagram":"digraph {\n\ngraph [layout = \"dot\",\n       rankdir = \"LR\"]\n\nnode [color = \"DimGray\",\n      style = \"filled\",\n      fontname = \"Helvetica\"]\n\nedge [color = \"DimGray\",\n     arrowsize = \"1.5\",\n     arrowhead = \"vee\",\n     fontname = \"Helvetica\"]\n\n  \"1\" [label = \"Tree 1\nsatisfaction_level\nCover: 1003.96625\nGain: 805.609924\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"2\" [label = \"time_spend_company\nCover: 279.249603\nGain: 198.162491\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"3\" [label = \"time_spend_company\nCover: 724.716675\nGain: 307.728271\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"4\" [label = \"time_spend_company\nCover: 229.335556\nGain: 121.855225\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"5\" [label = \"satisfaction_level\nCover: 49.9140396\nGain: 62.0129166\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"6\" [label = \"Leaf\nCover: 597.908691\nValue: -0.0922183394\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"7\" [label = \"last_evaluation\nCover: 126.807991\nGain: 182.837738\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"8\" [label = \"Leaf\nCover: 19.2060184\nValue: -0.0752717331\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"9\" [label = \"satisfaction_level\nCover: 210.129532\nGain: 48.8415527\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"10\" [label = \"Leaf\nCover: 5.49387789\nValue: 0.0801373646\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"11\" [label = \"Leaf\nCover: 44.4201622\nValue: -0.086495176\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"12\" [label = \"Leaf\nCover: 47.1626282\nValue: -0.0834410787\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"13\" [label = \"average_montly_hours\nCover: 79.6453629\nGain: 111.214516\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"14\" [label = \"Leaf\nCover: 53.1899261\nValue: 0.0947514176\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"15\" [label = \"satisfaction_level\nCover: 156.939606\nGain: 229.920624\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"16\" [label = \"time_spend_company\nCover: 16.4705276\nGain: 3.05454636\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"17\" [label = \"time_spend_company\nCover: 63.174839\nGain: 41.3607178\", shape = \"rectangle\", fontcolor = \"black\", fillcolor = \"Beige\"] \n  \"18\" [label = \"Leaf\nCover: 34.9327278\nValue: -0.0726748481\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"19\" [label = \"Leaf\nCover: 122.006882\nValue: 0.071160607\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"20\" [label = \"Leaf\nCover: 3.74389124\nValue: -0.0206319448\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"21\" [label = \"Leaf\nCover: 12.726635\nValue: -0.0843973011\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"22\" [label = \"Leaf\nCover: 59.4311562\nValue: 0.0802548751\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n  \"23\" [label = \"Leaf\nCover: 3.74368\nValue: -0.0753362849\", shape = \"oval\", fontcolor = \"black\", fillcolor = \"Khaki\"] \n\"1\"->\"2\" [label = \"< 0.465000004\", style = \"bold\"] \n\"2\"->\"4\" [label = \"< 4.5\", style = \"bold\"] \n\"3\"->\"6\" [label = \"< 4.5\", style = \"bold\"] \n\"4\"->\"8\" [label = \"< 2.5\", style = \"bold\"] \n\"5\"->\"10\" [label = \"< 0.114999995\", style = \"bold\"] \n\"7\"->\"12\" [label = \"< 0.805000007\", style = \"bold\"] \n\"9\"->\"14\" [label = \"< 0.114999995\", style = \"bold\"] \n\"13\"->\"16\" [label = \"< 216.5\", style = \"bold\"] \n\"15\"->\"18\" [label = \"< 0.355000019\", style = \"bold\"] \n\"16\"->\"20\" [label = \"< 5.5\", style = \"bold\"] \n\"17\"->\"22\" [label = \"< 6.5\", style = \"bold\"] \n\"1\"->\"3\" [style = \"bold\", style = \"solid\"] \n\"2\"->\"5\" [style = \"solid\", style = \"solid\"] \n\"3\"->\"7\" [style = \"solid\", style = \"solid\"] \n\"4\"->\"9\" [style = \"solid\", style = \"solid\"] \n\"5\"->\"11\" [style = \"solid\", style = \"solid\"] \n\"7\"->\"13\" [style = \"solid\", style = \"solid\"] \n\"9\"->\"15\" [style = \"solid\", style = \"solid\"] \n\"13\"->\"17\" [style = \"solid\", style = \"solid\"] \n\"15\"->\"19\" [style = \"solid\", style = \"solid\"] \n\"16\"->\"21\" [style = \"solid\", style = \"solid\"] \n\"17\"->\"23\" [style = \"solid\", style = \"solid\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

