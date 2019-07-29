---
author: "Satoshi Kato"
title: Sensitivity analysis using xgboostExplainer
date: "2019/05/14"
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
install.packages("ggforce", dependencies = TRUE)

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

train.label  <- loaded.obs$data$train$label
train.df     <- loaded.obs$data$train$dummy.data.frame
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix(train.matrix, label = train.label, missing = NA)

test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix(test.matrix, missing = NA)
```


```r
shap.xgb <- xgboost:::predict.xgb.Booster(
  model.xgb, newdata = train.matrix, 
  predcontrib = TRUE, approxcontrib = FALSE) %>% 
  data.frame()

shap.xgb %>% head(4) %>% knitr::kable(digits = 4)
```



 satisfaction_level   last_evaluation   number_project   average_montly_hours   time_spend_company   Work_accident   promotion_last_5years     sales    salary      BIAS
-------------------  ----------------  ---------------  ---------------------  -------------------  --------------  ----------------------  --------  --------  --------
             0.7316            0.0507           0.3860                 0.3918               0.1786          0.1031                  0.0081   -0.0287    0.2492   -0.0058
             1.8492            0.1693          -0.0095                 1.2180               0.1870         -0.7878                  0.0082    0.0011   -0.0664   -0.0058
             0.3915            0.0751          -0.0911                 0.5579               0.6649          0.0886                  0.0092    0.1586   -0.1216   -0.0058
             1.3621            0.2717           0.2886                 0.2024              -0.0765          0.1185                  0.0081    0.0755    0.2096   -0.0058


```r
approxcontrib.xgb <- xgboost:::predict.xgb.Booster(
  model.xgb, newdata = train.matrix, 
  predcontrib = TRUE, approxcontrib = TRUE) %>% 
  data.frame()

approxcontrib.xgb %>% head(4) %>% knitr::kable(digits = 4)
```



 satisfaction_level   last_evaluation   number_project   average_montly_hours   time_spend_company   Work_accident   promotion_last_5years     sales    salary      BIAS
-------------------  ----------------  ---------------  ---------------------  -------------------  --------------  ----------------------  --------  --------  --------
             0.4126            0.2463           0.4089                 0.4002               0.1961          0.1443                  0.0081   -0.0181    0.2721   -0.0058
             1.8673            0.4315          -0.0605                 1.2590               0.1324         -1.0432                  0.0079    0.0244   -0.0495   -0.0058
             0.4670            0.2334          -0.1190                 0.5720               0.3843          0.1102                  0.0089    0.1790   -0.1026   -0.0058
             1.1641            0.5460           0.2507                 0.0915               0.0630          0.1301                  0.0081   -0.0226    0.2290   -0.0058

# feature responce

## example1: satisfaction_level


```r
feature.impact <- data.frame(value  = train.df$satisfaction_level, 
                             SHAP = shap.xgb$satisfaction_level,
                             structure = approxcontrib.xgb$satisfaction_level) %>% 
  gather(key = type, value = impact, -value)

ggp.sens.fi <- feature.impact %>% 
  ggplot(aes(x = value, y = impact)) + 
  geom_point(alpha = 0.7) +
  geom_smooth() +
  facet_grid(. ~ type) +
  labs(x = "satisfaction_level", y = "Feature impact on log-odds") +
  theme_bw()

ggsave(ggp.sens.fi, filename =  "./output/image.files/410_feature_impact_1.png",
    height = 4, width = 7)
`geom_smooth()` using method = 'gam' and formula 'y ~ s(x, bs = "cs")'
```

![](./output/image.files/410_feature_impact_1.png)

## example 2-1: last_evaluation


```r
feature.impact <- data.frame(value  = train.df$last_evaluation, 
                             SHAP = shap.xgb$last_evaluation,
                             structure = approxcontrib.xgb$last_evaluation,
                             satisfaction_level = train.df$satisfaction_level) %>% 
  gather(key = type, value = impact, -value, -satisfaction_level)
```


```r
ggp.sens.fi <- feature.impact %>% 
  ggplot(aes(x = value, y = impact)) + 
  geom_point(alpha = 0.7) +
  geom_smooth() +
  facet_grid(. ~ type) +
  labs(x = "last_evaluation", y = "Feature impact on log-odds") +
  theme_bw()

ggsave(ggp.sens.fi, filename =  "./output/image.files/410_feature_impact_2-1.png",
    height = 4, width = 7)
`geom_smooth()` using method = 'gam' and formula 'y ~ s(x, bs = "cs")'
```

![](./output/image.files/410_feature_impact_2-1.png)


## example 2-2: last_evaluation x satisfaction_level


```r
ggp.sens.fi <- feature.impact %>% 
  ggplot(aes(x = value, y = impact, color = satisfaction_level)) + 
  geom_point(alpha = 0.7) +
  geom_smooth() +
  facet_grid(. ~ type) +
  labs(x = "last_evaluation", y = "Feature impact on log-odds") +
  theme_bw() + 
  scale_color_gradient2(midpoint = 0.5, low="blue", mid="grey", high="red")

ggsave(ggp.sens.fi, filename =  "./output/image.files/410_feature_impact_2-2.png",
    height = 4, width = 7)
`geom_smooth()` using method = 'gam' and formula 'y ~ s(x, bs = "cs")'
```

![](./output/image.files/410_feature_impact_2-2.png)


## Average feature responce

**According to man(xgb.plot.shap)::Detail**

Visualizing the SHAP feature contribution to prediction dependencies on feature value.

These scatterplots represent how SHAP feature contributions depend of feature values. The similarity to partial dependency plots is that they also give an idea for how feature values affect predictions. However, in partial dependency plots, we usually see marginal dependencies of model prediction on feature value, while SHAP contribution dependency plots display the estimated contributions of a feature to model prediction for each individual case.

When plot_loess = TRUE is set, feature values are rounded to 3 significant digits and weighted LOESS is computed and plotted, where weights are the numbers of data points at each rounded value.

Note: SHAP contributions are shown on the scale of model margin. E.g., for a logistic binomial objective, the margin is prediction before a sigmoidal transform into probability-like values. Also, since SHAP stands for "SHapley Additive exPlanation" (model prediction = sum of SHAP contributions for all features + bias), depending on the objective used, transforming SHAP contributions for a feature from the marginal to the prediction space is not necessarily a meaningful thing to do.



```r
png(filename = "./output/image.files/410_varresp_SHAP.png", width = 1200, height = 320, pointsize = 24)
shap <- xgb.plot.shap(data  = train.matrix,
              model = model.xgb, 
              # sabsumple = 300,
              top_n = 6,
              n_col = 6, col = col, pch = 7, pch_NA = 17)
dev.off()
png 
  2 
```

![SHAP  contribution dependency plots](./output/image.files/410_varresp_SHAP.png)


## summary

according to: 
https://liuyanguu.github.io/post/2018/10/14/shap-visualization-for-xgboost/


```r
feature.value.long <- train.df %>% 
  scale() %>%
  data.frame() %>% 
  mutate(id = as.character(1:n())) %>% 
  gather(key = feature, value = value, -id)

feature.impact.long <- shap.xgb %>% 
  mutate(id = as.character(1:n())) %>% 
  select(-BIAS) %>% 
  gather(key = feature, value = impact, -id) %>% 
  left_join(feature.value.long, by = c("id", "feature")) %>% 
  mutate(feature = factor(feature))
  
feature.impact.long %>% head
  id            feature    impact       value
1  1 satisfaction_level 0.7315803  0.08398073
2  2 satisfaction_level 1.8491962 -1.37971574
3  3 satisfaction_level 0.3915311 -0.72096038
4  4 satisfaction_level 1.3621190 -0.81014290
5  5 satisfaction_level 1.6664042 -1.76678622
6  6 satisfaction_level 0.3596488  0.21775450
```

```r
# require(ggridge)
feature.impact.long %>% 
  ggplot(aes(x = impact, y = feature, point_color = value, fill = feature))+
  geom_density_ridges(
    scale = 2.0,
    rel_min_height = 0.01,
    alpha = 0.3, 
    jittered_points = TRUE, point_alpha = 0.05, point_size = 2, point_shape = "|",
    position = position_points_jitter(width = 0.05, height = 0)) + 
  scale_color_gradient(low="#FFCC33", high="#6600CC", labels=c("Low","High"))
Picking joint bandwidth of 0.0585
```

![](410_breakdown_feature_response-interaction_files/figure-html/unnamed-chunk-9-1.png)<!-- -->


```r
feature.impact.long %>% 
  ggplot()+
    coord_flip() + 
    # sina plot: 
    ggforce::geom_sina(aes(x = feature, y = impact, color = value),
              method = "counts", maxwidth = 0.7, alpha = 0.2) +
  scale_color_gradient(low="#FFCC33", high="#6600CC") +
  theme_bw()
```

![](410_breakdown_feature_response-interaction_files/figure-html/unnamed-chunk-10-1.png)<!-- -->


# SHAP values of contributions of interaction of each pair of features 

For "gblinear" booster, feature contributions are simply linear terms (feature_beta * feature_value). 

### `predinteraction = TRUE, approxcontrib = FALSE`	

For "gbtree" booster, with `predinteraction = TRUE, approxcontrib = FALSE`, SHAP values of contributions of interaction of each pair of features are computed. Note that this operation might be rather expensive in terms of compute and memory. Since it quadratically depends on the number of features, it is recommended to perfom selection of the most important features first. 


```r
system.time(
  predinteraction.shap <- xgboost:::predict.xgb.Booster(
    model.xgb, newdata = train.matrix, 
    predinteraction = TRUE, approxcontrib = FALSE)
)
   user  system elapsed 
  82.73    0.02    1.90 
```

### `predinteraction = TRUE, approxcontrib = FALSE`	

For "gbtree" booster, with `predinteraction = TRUE, approxcontrib = FALSE`, SHAP values are approximated by structureal based. The contribution of each feature is not a single predetermined value, but depends on the rest of the feature vector which determines the decision path that traverses the tree and thus the guards/contributions that are passed along the way.

This operation is less expensive in terms of compute and memory.


```r
system.time(
  predinteraction.app <- xgboost:::predict.xgb.Booster(
    model.xgb, newdata = train.matrix, 
    predinteraction = TRUE, approxcontrib = TRUE)
)
   user  system elapsed 
   2.98    0.03    0.14 
```

## 2-way feature interaction of single observation


```r
idx = 1
single.2way <- predinteraction.shap[idx, ,] %>% 
  data.frame %>%
  select(-BIAS) 

single.2way %>% knitr::kable()
```

                         satisfaction_level   last_evaluation   number_project   average_montly_hours   time_spend_company   Work_accident   promotion_last_5years        sales       salary
----------------------  -------------------  ----------------  ---------------  ---------------------  -------------------  --------------  ----------------------  -----------  -----------
satisfaction_level                0.3565456         0.1065983        0.0765232              0.1726695            0.0125977       0.0045283               0.0004165   -0.0003602    0.0020614
last_evaluation                   0.1065981        -0.5661533        0.1482790              0.4193752           -0.0421255      -0.0083401              -0.0001521   -0.0043293   -0.0024293
number_project                    0.0765234         0.1482787        0.0992946              0.0701535            0.0004989      -0.0197244              -0.0000091    0.0027893    0.0082059
average_montly_hours              0.1726698         0.4193753        0.0701537             -0.2235044           -0.0270705       0.0010212              -0.0000727   -0.0071462   -0.0135768
time_spend_company                0.0125977        -0.0421254        0.0004989             -0.0270703            0.2429929      -0.0052467               0.0000440    0.0032244   -0.0063475
Work_accident                     0.0045285        -0.0083401       -0.0197244              0.0010213           -0.0052466       0.1245393               0.0000933   -0.0012861    0.0075240
promotion_last_5years             0.0004164        -0.0001521       -0.0000091             -0.0000728            0.0000441       0.0000933               0.0080393   -0.0000273   -0.0001880
sales                            -0.0003605        -0.0043293        0.0027894             -0.0071462            0.0032244      -0.0012861              -0.0000273   -0.0415437    0.0200262
salary                            0.0020613        -0.0024292        0.0082058             -0.0135769           -0.0063476       0.0075240              -0.0001880    0.0200263    0.2338871
BIAS                              0.0000000         0.0000000        0.0000000              0.0000000            0.0000000       0.0000000               0.0000000    0.0000000    0.0000000


```r
single.2way %>% 
  rownames_to_column("feature") %>% 
  gather(key = interact, value = value, -feature) %>%
  filter(feature != "BIAS") %>% 
  mutate_at(vars(feature, interact), as.factor) %>% 
  ggplot(aes(x = feature, y = interact, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, 
                       low="blue", mid = "white", high="red") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
```

![](410_breakdown_feature_response-interaction_files/figure-html/unnamed-chunk-14-1.png)<!-- -->

## Mean absolute feature interaction of all observation


```r
mafi.shap <- apply(abs(predinteraction.shap), 2:3, sum) /
  NROW(predinteraction.shap)
mafi.app  <- apply(abs(predinteraction.app), 2:3, sum) /
  NROW(predinteraction.app)

mafi.shap %>% 
  data.frame %>%
  select(-BIAS) %>% 
  rownames_to_column("feature") %>% 
  gather(key = interact, value = value, -feature) %>%
  filter(feature != "BIAS") %>% 
  mutate_at(vars(feature, interact), as.factor) %>% 
  ggplot(aes(x = feature, y = interact, fill = value)) +
  geom_tile() +
  scale_fill_gradient(low="white",high="red") +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
```

![](410_breakdown_feature_response-interaction_files/figure-html/unnamed-chunk-15-1.png)<!-- -->

