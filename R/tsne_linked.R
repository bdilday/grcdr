#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#' @import Rtsne
#' @import dplyr
#' @importFrom magrittr %<>%
#'
#' @export
tsne_linked <- function(dfX,
                 label_var = NULL,
                 group_var = NULL,
                 tsne_point_data=NULL,
                 tsne_histogram_data=NULL,
                 tsne_coords=NULL,
                 tsne_perplexity=30,
                 tsne_rseed = 101,
                 width = NULL,
                 height = NULL,
                 elementId = NULL) {

  dfX = as.data.frame(dfX)
  set.seed(tsne_rseed)

  if (is.null(tsne_point_data)) {
    xx <- dfX[,tsne_coords]
    tmp <- Rtsne::Rtsne(xx, perplexity = tsne_perplexity)
    tsne_point_data <- as.data.frame(tmp$Y)
  }

  if (is.null(label_var)) {
    tsne_point_data$label_var = row.names(tsne_point_data)
  } else {
    tsne_point_data$label_var = dfX[,label_var]
  }

  if (is.null(group_var)) {
    tsne_point_data$group_var = 1
  } else {
    tsne_point_data$group_var = dfX[,group_var]
  }

  widget_options <- list(dum='yup',
                         margin=NULL)
  # forward options using x


  tsne_histogram_data =
    cbind.data.frame(dfX[,tsne_coords],
                     group_var = tsne_point_data$group_var,
                     label_var = tsne_point_data$label_var) %>%
    tidyr::gather(coord_name, coord_value, -group_var, -label_var)

  hdata_length = tsne_histogram_data %>% distinct(coord_name) %>% nrow()

  x = list(
    histogram_data = tsne_histogram_data,
    hdata_length = hdata_length,
    point_data = tsne_point_data,
    options=widget_options
  )

  # create widget
  htmlwidgets::createWidget(
    name = 'tsne_linked',
    x,
    width = width,
    height = height,
    package = 'grcdr',
    elementId = elementId
  )
}

#' Shiny bindings for tsne
#'
#' Output and render functions for using tsne within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a tsne
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name tsne-shiny
#'
#' @export
tsneOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'tsne_linked', width, height, package = 'grcdr')
}

#' @rdname tsne-shiny
#' @export
renderTsne <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, tsneOutput, env, quoted = TRUE)
}
