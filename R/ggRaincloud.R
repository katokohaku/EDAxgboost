#' rain could plot wrapper for ggRidges package 
#'
#' Template wrapper for ggridges::geom_density_ridges(., jittered_points = TRUE, position = "raincloud")
#'
#' @param .data a data frame or a matrix 
#' @param title title text passed to labs(title = title, ...)
#' @param scaled logical. If .data are scaled for each colmn (default = TRUE).
#' @param .alpha
#' @param .scale
#' @param ... other options passed to theme(., ...)
#' 
#' @example
#' ggRaincloud(iris)
#' 
#' iris %>%
#' select(-Species) %>% 
#' ggRaincloud("feature distribution", scaled =FALSE, .vervose = FALSE)
#'
#' @return a ggplots object
#' 
#' @export
#' 
#' @import ggplot2
#' @importFrom tidylog mutate_all
#' @importFrom ggRidges geom_density_ridges
#

ggRaincloud <- function(.data, title = "", xlab = "", ylab = "", scaled = TRUE,
                        .alpha = 0.3, .scale = 0.9, .vervose = TRUE, ...) {
  stopifnot(!missing(.data))
  
  mutate_all2 <- dplyr::mutate_all
  if(.vervose) {
    mutate_all2 <- tidylog::mutate_all
  }
  
  .data <- .data %>%
    mutate_if(is.character, factor) %>%
    mutate_all2(as.numeric)
  
  if(scaled) {
    .data <- scale(.data)
  }
  
  feature.value.long <- .data %>%
    data.frame() %>% 
    gather(key = feature, value = value)
  
  ggp.raincloud <- feature.value.long %>% 
    ggplot(aes(x = value, y = feature, color = feature, fill = feature))+
    ggridges::geom_density_ridges(
      jittered_points = TRUE, position = "raincloud", alpha = .alpha, scale = .scale) +
    theme(legend.position = 'none', ...) +
    labs(title = title, x=xlab, y=ylab)
  
  return(ggp.raincloud)
}




