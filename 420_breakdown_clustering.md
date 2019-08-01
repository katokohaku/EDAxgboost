---
author: "Satoshi Kato"
title: individual/group explanation using xgboost
date: "2019/08/01"
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
install.packages("Rtsne", dependencies = TRUE)
install.packages("uwot", dependencies = TRUE)
install.packages("ggdendro", dependencies = TRUE)
install.packages("ggrepel", dependencies = TRUE)

```


```r
require(tidyverse)
require(magrittr)
require(xgboost)

require(Rtsne)
require(uwot)
library(ggdendro)
require(ggrepel)
```

# Preparation 

If file = "./middle/data_and_model.Rds" doesn't exist, RUN `100_building_xgboost_model.Rmd`.


```r
loaded.obs  <- readRDS("./middle/data_and_model.Rds")

model.xgb   <- loaded.obs$model$xgb 

train.label <- loaded.obs$data$train$label
train.matrix <- loaded.obs$data$train$matrix
train.xgb.DMatrix <- xgb.DMatrix(train.matrix, label = train.label, missing = NA)

test.label  <- loaded.obs$data$test$label
test.matrix <- loaded.obs$data$test$matrix
test.xgb.DMatrix  <- xgb.DMatrix(test.matrix, missing = NA)

prediction.xgb <- xgboost:::predict.xgb.Booster(model.xgb, newdata = train.matrix)
```

## get breakdown explanations

Feature contributions (SHAP values using built-in function.) for "gbtree" booster.


```r
shap.xgb <- xgboost:::predict.xgb.Booster(
  model.xgb, newdata = train.matrix, 
  predcontrib = TRUE, approxcontrib = FALSE)

shap.xgb %>% head(4) %>% t
                              [,1]         [,2]         [,3]         [,4]
satisfaction_level    -0.515436172 -0.586677372  0.525480807  2.053030491
last_evaluation        0.121358186  0.369296879  0.057982970 -0.399072826
number_project        -0.022691106  0.437221318 -0.095180556  0.096285738
average_montly_hours   0.872058332 -0.126130879 -0.131584838  0.393718511
time_spend_company     0.924191236  0.174715430  0.149822012 -0.294579685
Work_accident          0.100723140  0.089056358  0.109960638  0.114590660
promotion_last_5years  0.006513606  0.006683344  0.004951648  0.005639516
sales                 -0.089338966  0.129772797 -0.278872371  0.240690008
salary                -0.218401656 -0.166973829  0.407709092  0.247819394
BIAS                  -0.005168790 -0.005168790 -0.005168790 -0.005168790
```


```r
prediction.xgb %>% head()
[1] 0.7638327 0.5797617 0.6781101 0.9207772 0.4998003 0.9250071
weight.shap <- shap.xgb %>% rowSums()
weight.shap %>% head
[1]  1.17380781  0.32179525  0.74510061  2.45295302 -0.00079815  2.51240769
1/(1 + exp(-weight.shap)) %>% head
[1] 0.7638326 0.5797617 0.6781102 0.9207771 0.4998005 0.9250071
```



```r
source("./R/waterfallBreakdown.R")

ggp.shap <- waterfallBreakdown(
  breakdown = unlist(shap.xgb[1, ]), type = "binary",
  labels = paste(colnames(shap.xgb), 
                 c(train.matrix[1, ],""), sep =" = ")) +
  ggtitle("SHAP value")

ggsave(ggp.shap, filename = "./output/image.files/420_explain_single_obs_SHAP.png",
       width = 3.5, height = 4)
```


![](output/image.files/420_explain_single_obs_SHAP.png)

# clustering of observation based on breakdown

## dimension reduction using t-SNE

according to :
http://jmonlong.github.io/Hippocamplus/2017/12/02/tsne-and-clustering/


```r
# shap.xgb %>% str
# prediction.xgb %>% str

shap.xgb.tsne <- shap.xgb %>% 
  # data.frame() %>% 
  data.frame(pred = prediction.xgb) %>% 
  select(-BIAS) %>%
  Rtsne::Rtsne(perplexity = 50, check_duplicates = FALSE)

# shap.xgb.tsne %>% str

mapping.tsne <- data.frame(
  id     = 1:length(prediction.xgb),
  dim1  = shap.xgb.tsne$Y[, 1],
  dim2  = shap.xgb.tsne$Y[, 2],
  pred   = prediction.xgb,
  weight = weight.shap)

ggp.tsne <- mapping.tsne %>% 
  ggplot(aes(x = dim1, y = dim2, colour = prediction.xgb)) + 
    geom_point(alpha = 0.3) + theme_bw() +
  scale_color_gradient2(midpoint=0.5, low="blue", mid="gray", high="red") + 
  guides(colour = FALSE) + 
  labs(title = "t-SNE")

ggsave(ggp.tsne, filename =  "./output/image.files/420_map_tSNE.png",
    height = 5, width = 5)
```

![](output/image.files/420_map_tSNE.png)


## Hierarchical clustering


```r
shap.xgb.tsne.hc <- mapping.tsne %>% 
  select(-id) %>% 
  as.matrix() %>% 
  dist() %>% 
  hclust()
shap.xgb.tsne.hc

Call:
hclust(d = .)

Cluster method   : complete 
Distance         : euclidean 
Number of objects: 4000 
```

### explore cut.off for cutree


```r
library(ggdendro)

cut.off = 12

ggd.breakdown <- ggdendrogram(shap.xgb.tsne.hc, rotate = TRUE, size = 2) +
  geom_hline(yintercept = cut.off, color = "red")

ggsave(ggd.breakdown, filename =  "./output/image.files/420_hclust_rules.png",
    height = 12, width = 7)
```

![](./output/image.files/420_hclust_rules.png)


```r
require(ggrepel)

mapping.tsne$hclust <- shap.xgb.tsne.hc %>%
  cutree(h = cut.off) %>%
  factor()

hc.cent <- mapping.tsne %>% 
  group_by(hclust) %>%
  select(dim1, dim2) %>% 
  summarize_all(mean)
Adding missing grouping variables: `hclust`

map.tsne.labeled <- mapping.tsne %>% 
  ggplot(aes(x = dim1, y = dim2, colour = hclust)) + 
  geom_point(alpha = 0.3) + 
  theme_bw() +
  ggrepel::geom_label_repel(data = hc.cent, aes(label = hclust)) + 
  guides(colour = FALSE)

ggsave(map.tsne.labeled, filename =  "./output/image.files/420_map_tSNE_labeled.png",
    height = 7, width = 7)
```

![](output/image.files/420_map_tSNE_labeled.png)


## dimension reduction using UMAP

according to :
https://rdrr.io/cran/uwot/man/umap.html


### non-optional


```r
shap.xgb.umap <- shap.xgb %>% 
  data.frame() %>% 
  select(-BIAS) %>%
  uwot::umap()

shap.xgb.umap %>% str
 num [1:4000, 1:2] -0.519 2.003 -2.625 -8.544 3.021 ...
 - attr(*, "scaled:center")= num [1:2] -0.081 -0.193

mapping.umap <- data.frame(
  id     = 1:length(prediction.xgb),
  dim1  = shap.xgb.umap[, 1],
  dim2  = shap.xgb.umap[, 2],
  pred   = prediction.xgb,
  weight = weight.shap)
# mapping.umap %>% str

ggp.umap <- mapping.umap %>% 
  ggplot(aes(x = dim1, y = dim2, colour = prediction.xgb)) + 
    geom_point(alpha = 0.3) + theme_bw() +
  scale_color_gradient2(midpoint=0.5, low="blue", mid="gray", high="red") + 
  guides(colour = FALSE) + 
  labs(title = "UMAP (without label)") 

ggsave(ggp.umap, filename =  "./output/image.files/420_map_umap.png",
       height = 5, width = 7)
```

![](output/image.files/420_map_umap.png)

### supervised dimension reduction


```r
shap.xgb.sumap <- shap.xgb %>% 
  data.frame() %>% 
  select(-BIAS) %>%
  uwot::umap(n_neighbors = 12,
             learning_rate = 0.7,
             y = prediction.xgb)

# shap.xgb.sumap

mapping.sumap <- data.frame(
  id     = 1:length(prediction.xgb),
  dim1  = shap.xgb.sumap[, 1],
  dim2  = shap.xgb.sumap[, 2],
  pred   = prediction.xgb,
  weight = weight.shap)
# mapping.sumap %>% str

ggp.sumap <- mapping.sumap %>% 
  ggplot(aes(x = dim1, y = dim2, colour = prediction.xgb)) + 
    geom_point(alpha = 0.3) + theme_bw() +
  scale_color_gradient2(midpoint=0.5, low="blue", mid="gray", high="red") + 
  guides(colour = FALSE) + 
  labs(title = "supervised UMAP") 

ggsave(ggp.sumap, filename = "./output/image.files/420_map_sumap.png",
       height = 5, width = 7)
```

![](output/image.files/420_map_sumap.png)

## Hierarchical Density-based spatial clustering of applications with noise (HDBSCAN)

Reference:

https://hdbscan.readthedocs.io/en/latest/how_hdbscan_works.html

according to:

https://cran.r-project.org/web/packages/dbscan/vignettes/hdbscan.html


```r
# install.packages("dbscan", dependencies = TRUE)
require(dbscan)
Loading required package: dbscan
```

`minPts` not only acts as a minimum cluster size to detect, but also as a "smoothing" factor of the density estimates implicitly computed from HDBSCAN.


```r
# mapping.sumap %>% str
cl.hdbscan <- mapping.sumap %>% 
  select(dim1, dim2) %>% 
  hdbscan(minPts = 30)
cl.hdbscan
HDBSCAN clustering for 4000 objects.
Parameters: minPts = 30
The clustering contains 29 cluster(s) and 92 noise points.

  0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17 
 92 102 105 585 217 159  78  52  49 132  77  49  35  94  30  83  73 232 
 18  19  20  21  22  23  24  25  26  27  28  29 
479 101 143 150  90 147 144  73 215  46 128  40 

Available fields: cluster, minPts, cluster_scores,
                  membership_prob, outlier_scores, hc

plot(cl.hdbscan, show_flat = TRUE)
```

![](420_breakdown_clustering_files/figure-html/unnamed-chunk-11-1.png)<!-- -->


```r
# install.packages("ggrepel", dependencies = TRUE)
require(ggrepel)

mapping.sumap$hdbscan <- factor(cl.hdbscan$cluster)

hdbscan.cent <- mapping.sumap %>% 
  filter(hdbscan != 0) %>% 
  dplyr::group_by(hdbscan) %>%
  select(dim1, dim2) %>% 
  summarize_all(mean)
Adding missing grouping variables: `hdbscan`

ggp.sumap.labeled <- mapping.sumap %>% 
  ggplot(aes(x = dim1, y = dim2, colour = hdbscan)) + 
  geom_point(alpha = 0.3) + 
  theme_bw() +
  ggrepel::geom_label_repel(data = hdbscan.cent, 
                            aes(label = hdbscan),
                            label.size = 0.1) + 
  guides(colour = FALSE) + 
  labs(title = "supervised UMAP + HDBSCAN") 


ggsave(ggp.sumap.labeled, filename =  "./output/image.files/420_map_sumap_labeled.png",
    height = 7, width = 7)
```

![](output/image.files/420_map_sumap_labeled.png)


```r
ggp.tsne.sumap <- gridExtra::arrangeGrob(
  ggp.tsne, 
  ggp.umap,
  ggp.sumap, 
  ggp.sumap.labeled,
  ncol = 2)

ggsave(ggp.tsne.sumap, filename =  "./output/image.files/420_tSNE_sumap.png",
    height = 10, width = 10)
```

![](output/image.files/420_tSNE_sumap.png)


# View rules in several group

NOTE: observations with `hdbscan == 0` are as noise by hDBSCAN.


```r
clust.id = 1
sample.n = 12

target <- mapping.sumap %>% 
  filter(hdbscan == clust.id) %>% 
  arrange(desc(pred))

sw <- list(NULL)
for(i in 1:sample.n){
  idx = target$id[i]
  
  sw[[i]]  <- waterfallBreakdown(
    breakdown = unlist(shap.xgb[idx, ]),
    type = "binary",
    labels = paste(colnames(shap.xgb), 
                   c(train.matrix[idx, ],""), sep =" = ")) +
    ggtitle(sprintf("predict = %.04f\nweight = %.04f",
                    target$predict[i], target$weight[i]))
}

ggp.sw <- gridExtra::arrangeGrob(grobs = sw, ncol = 4)
ggsave(ggp.sw, height = 9,
       filename = "./output/image.files/420_rules_cl1.png")
```

![](./output/image.files/420_rules_cl1.png)


