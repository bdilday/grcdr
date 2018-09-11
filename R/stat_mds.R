#' Multi-Dimensional Scaling
#'
#' Data reduction using multi-dimensional scaling
#'
#'
#' @param mapping Set of aesthetic mappings created by \code{\link{aes}} or
#'   \code{\link{aes_}}. If specified and \code{inherit.aes = TRUE} (the
#'   default), it is combined with the default mapping at the top level of the
#'   plot. You must supply \code{mapping} if there is no plot mapping.
#' @param data The data to be displayed in this layer. There are three
#'    options:
#'
#'    If \code{NULL}, the default, the data is inherited from the plot
#'    data as specified in the call to \code{\link{ggplot}}.
#'
#'    A \code{data.frame}, or other object, will override the plot
#'    data. All objects will be fortified to produce a data frame. See
#'    \code{\link{fortify}} for which variables will be created.
#'
#'    A \code{function} will be called with a single argument,
#'    the plot data. The return value must be a \code{data.frame.}, and
#'    will be used as the layer data.
#' @param geom The geom to display the data
#' @param position Position adjustment, either as a string, or the result of
#'  a call to a position adjustment function.
#' @param na.rm If \code{FALSE}, the default, missing values are removed with
#'   a warning. If \code{TRUE}, missing values are silently removed.
#' @param show.legend logical. Should this layer be included in the legends?
#'   \code{NA}, the default, includes if any aesthetics are mapped.
#'   \code{FALSE} never includes, and \code{TRUE} always includes.
#' @param inherit.aes If \code{FALSE}, overrides the default aesthetics,
#'   rather than combining with them. This is most useful for helper functions
#'   that define both data and aesthetics and shouldn't inherit behavior from
#'   the default plot specification, e.g. \code{\link{borders}}.
#' @param mds_method The MDS algorithm. Valid choices are "pca" and "tsne"
#' @param tsne_perplexity Perplexity for the tSNE algorithm
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
#'
StatMDS = ggproto(
  "StatMDS", Stat,
  required_aes = c("x1", "x2"),
  extra_params = c("na.rm", "mds_method", "tsne_perplexity"),

  setup_data = function(data, params) {
    data
  },

  compute_group = function(data, scales,
                           mds_method = NULL,
                           tsne_perplexity = NULL) {
    fit_columns = grep("x[0-9]+", names(data), value=TRUE)
    data_matrix = as.matrix(data[,fit_columns])

    if (!is.null(mds_method)) {
      mds_method = tolower(mds_method)
    }

    if (mds_method == "pca") {
      mds_mod = prcomp(data_matrix, retx = TRUE)
      data$x = mds_mod$x[,1]
      data$y = mds_mod$x[,2]
    } else if (mds_method == "tsne") {
      has_tsne = require(Rtsne)
      if (!has_tsne) {
        stop("Rtsne must be installed to use the tsne mds_method")
      }
      mds_mod = Rtsne::Rtsne(data_matrix, perplexity=tsne_perplexity)
      data$x = mds_mod$Y[,1]
      data$y = mds_mod$Y[,2]
    } else {
      stop("mds_method supports: pca, tsne")
    }
    data
  }
)

#' Stat MDS
#'
#' Stat MDS
#'
#' @inheritParams StatMDS
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
stat_mds = function(mapping = NULL, data = NULL, geom = "point",
                    position = "identity", na.rm = FALSE, show.legend = NA,
                    inherit.aes = TRUE,
                    mds_method = "pca",
                    tsne_perplexity = 30,
                    ...) {

  layer(data = data, mapping = mapping, stat = StatMDS, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(
      mds_method = mds_method,
      tsne_perplexity = tsne_perplexity,
      na.rm = na.rm,
      ...
    )
  )
}
