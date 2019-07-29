---
author: "Satoshi Kato"
title: "add noise on data"
date: "2019/05/13"
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
install.packages("tidyverse",   dependencies = TRUE)
install.packages("table1",      dependencies = TRUE)
install.packages("GGally",      dependencies = TRUE)
```


```r
require(tidyverse)
require(magrittr)
require(data.table)
require(table1)
require(MASS)
require(GGally)
```

# Purpose

Make dataset noisy according to: https://medium.com/applied-data-science/new-r-package-the-xgboost-explainer-51dd7d1aa211

## Description

according to `help(breakDown::HR_data)`, 

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

Original dataset HR-analytics is from https://www.kaggle.com

Source data in this sample is from : https://github.com/ryankarlos/Human-Resource-Analytics-Kaggle-Dataset/tree/master/Original_Kaggle_Dataset


```r
full = fread('./input/HR_comma_sep.csv', stringsAsFactors = T)
full <- full %>%
  mutate(left = factor(left)) %>% 
  dplyr::select(left, everything()) %>% 
  as.data.table()
full %>% str
```

```
Classes 'data.table' and 'data.frame':	14999 obs. of  10 variables:
 $ left                 : Factor w/ 2 levels "0","1": 2 2 2 2 2 2 2 2 2 2 ...
 $ satisfaction_level   : num  0.38 0.8 0.11 0.72 0.37 0.41 0.1 0.92 0.89 0.42 ...
 $ last_evaluation      : num  0.53 0.86 0.88 0.87 0.52 0.5 0.77 0.85 1 0.53 ...
 $ number_project       : int  2 5 7 5 2 2 6 5 5 2 ...
 $ average_montly_hours : int  157 262 272 223 159 153 247 259 224 142 ...
 $ time_spend_company   : int  3 6 4 5 3 3 4 5 5 3 ...
 $ Work_accident        : int  0 0 0 0 0 0 0 0 0 0 ...
 $ promotion_last_5years: int  0 0 0 0 0 0 0 0 0 0 ...
 $ sales                : Factor w/ 10 levels "IT","RandD","accounting",..: 8 8 8 8 8 8 8 8 8 8 ...
 $ salary               : Factor w/ 3 levels "high","low","medium": 2 3 3 2 2 2 2 2 2 2 ...
 - attr(*, ".internal.selfref")=<externalptr> 
```


```r
ggpair.before <- GGally::ggpairs(full, 
                                 aes(color = left, point_alpha = 0.3, alpha = 0.5),
                                 upper = list(continuous = "density"),
                                 progress = FALSE)

ggsave(ggpair.before, filename = "./output/image.files/000_ggpair_before.png", width = 6, height = 5)
```

![](./output/image.files/000_ggpair_before.png)


```r
table1(~ left +
         satisfaction_level + last_evaluation + number_project + 
         average_montly_hours + time_spend_company + 
         Work_accident + promotion_last_5years 
       | left, data = full)
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
<td class='rowlabel'>0</td>
<td>11428 (100%)</td>
<td>0 (0%)</td>
<td>11428 (76.2%)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>1</td>
<td class='lastrow'>0 (0%)</td>
<td class='lastrow'>3571 (100%)</td>
<td class='lastrow'>3571 (23.8%)</td>
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
       | left, data = full)
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
<td class='rowlabel'>IT</td>
<td>954 (8.3%)</td>
<td>273 (7.6%)</td>
<td>1227 (8.2%)</td>
</tr>
<tr>
<td class='rowlabel'>RandD</td>
<td>666 (5.8%)</td>
<td>121 (3.4%)</td>
<td>787 (5.2%)</td>
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


 # add Random Noise (to continuous feature)
 

```r
tmp_std = sd(full[,satisfaction_level])
full[,satisfaction_level:=satisfaction_level + runif(.N,-tmp_std,tmp_std)]
full[,satisfaction_level:=satisfaction_level - min(satisfaction_level)]
full[,satisfaction_level:=satisfaction_level / max(satisfaction_level)]
full[,satisfaction_level:=round(satisfaction_level, digits = 4)]

tmp_std = sd(full[,last_evaluation])
full[,last_evaluation:=last_evaluation + runif(.N,-tmp_std,tmp_std) ]
full[,last_evaluation:=last_evaluation - min(last_evaluation)]
full[,last_evaluation:=last_evaluation / max(last_evaluation)]
full[,last_evaluation:=round(last_evaluation, digits = 4)]

tmp_min = min(full[,number_project])
tmp_std = sd(full[,number_project])
full[,number_project:=number_project + sample(-ceiling(tmp_std):ceiling(tmp_std),.N, replace=T)]
full[,number_project:=number_project - min(number_project) + tmp_min]

tmp_min = min(full[,average_montly_hours])
tmp_std = sd(full[,average_montly_hours])
full[,average_montly_hours:=average_montly_hours + sample(-ceiling(tmp_std):ceiling(tmp_std),.N, replace=T)]
full[,average_montly_hours:=average_montly_hours - min(average_montly_hours) + tmp_min]

tmp_min = min(full[,time_spend_company])
tmp_std = sd(full[,time_spend_company])
full[,time_spend_company:=time_spend_company + sample(-ceiling(tmp_std):ceiling(tmp_std),.N, replace=T)]
full[,time_spend_company:=time_spend_company - min(time_spend_company) + tmp_min]

tmp_min = min(full[,number_project])
tmp_std = sd(full[,number_project])
full[,number_project:=number_project + sample(-ceiling(tmp_std):ceiling(tmp_std),.N, replace=T)]
full[,number_project:=number_project - min(number_project) + tmp_min]
```


```r
table1(~ left +
         satisfaction_level + last_evaluation + number_project + 
         average_montly_hours + time_spend_company + 
         Work_accident + promotion_last_5years 
       | left, data = full)
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
<td class='rowlabel'>0</td>
<td>11428 (100%)</td>
<td>0 (0%)</td>
<td>11428 (76.2%)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>1</td>
<td class='lastrow'>0 (0%)</td>
<td class='lastrow'>3571 (100%)</td>
<td class='lastrow'>3571 (23.8%)</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>satisfaction_level</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.586 (0.186)</td>
<td>0.422 (0.216)</td>
<td>0.547 (0.205)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.599 [0.0242, 1.00]</td>
<td class='lastrow'>0.404 [0.00, 0.933]</td>
<td class='lastrow'>0.564 [0.00, 1.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>last_evaluation</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>0.527 (0.198)</td>
<td>0.529 (0.227)</td>
<td>0.527 (0.205)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>0.525 [0.00, 0.999]</td>
<td class='lastrow'>0.533 [0.0771, 1.00]</td>
<td class='lastrow'>0.527 [0.00, 1.00]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>number_project</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>7.78 (2.23)</td>
<td>7.88 (2.73)</td>
<td>7.80 (2.36)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>8.00 [2.00, 14.0]</td>
<td class='lastrow'>8.00 [2.00, 15.0]</td>
<td class='lastrow'>8.00 [2.00, 15.0]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>average_montly_hours</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>246 (54.0)</td>
<td>254 (67.9)</td>
<td>248 (57.7)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>246 [96.0, 382]</td>
<td class='lastrow'>253 [124, 406]</td>
<td class='lastrow'>247 [96.0, 406]</td>
</tr>
<tr>
<td class='rowlabel firstrow'><span class='varlabel'>time_spend_company</span></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
<td class='firstrow'></td>
</tr>
<tr>
<td class='rowlabel'>Mean (SD)</td>
<td>5.39 (2.11)</td>
<td>5.90 (1.74)</td>
<td>5.51 (2.04)</td>
</tr>
<tr>
<td class='rowlabel lastrow'>Median [Min, Max]</td>
<td class='lastrow'>5.00 [2.00, 14.0]</td>
<td class='lastrow'>6.00 [2.00, 10.0]</td>
<td class='lastrow'>5.00 [2.00, 14.0]</td>
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
ggpair.after <- GGally::ggpairs(full, aes(color = left, point_alpha = 0.3, alpha = 0.5),
                                 upper = list(continuous = "density"),
                                 progress = FALSE)

ggsave(ggpair.after, filename = "./output/image.files/000_ggpair_after.png", width = 6, height = 5)
```

![](./output/image.files/000_ggpair_after.png)

# Shuffle rows


```r
full = full[sample(.N)]
full
```

```
       left satisfaction_level last_evaluation number_project
    1:    1             0.7053          0.8034              9
    2:    0             0.4535          0.4843              9
    3:    1             0.3056          0.6243              9
    4:    0             0.5913          0.7118             11
    5:    0             0.8116          0.8650              8
   ---                                                       
14995:    1             0.2751          0.3789              2
14996:    0             0.6043          0.4197             11
14997:    0             0.6752          0.7504             11
14998:    0             0.4654          0.9551              7
14999:    0             0.4178          0.4630              7
       average_montly_hours time_spend_company Work_accident
    1:                  275                  6             0
    2:                  275                  4             0
    3:                  293                  6             0
    4:                  323                  4             0
    5:                  301                  5             0
   ---                                                      
14995:                  188                  5             0
14996:                  190                  3             0
14997:                  231                  4             0
14998:                  178                  6             1
14999:                  176                  4             0
       promotion_last_5years       sales salary
    1:                     0       sales    low
    2:                     0          IT    low
    3:                     0          IT    low
    4:                     0   technical    low
    5:                     0   technical   high
   ---                                         
14995:                     0       RandD    low
14996:                     0  accounting    low
14997:                     0     support    low
14998:                     0       RandD medium
14999:                     0 product_mng    low
```


# Save data and model


```r
write.csv(full, "./input/HR_shuffle_and_noise.csv", row.names = FALSE)
```


