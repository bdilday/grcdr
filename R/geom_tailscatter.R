#' Create a tail scatter plot
#'
#' Create a tail scatter plot
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
#' @param stat The statistical transformation to use on the data for this
#'    layer, as a string.
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
#' @param tail_scale The maximum length of the tails, in units of the coordinate frame,
#' i.e. 1 corresponds to the whole frame
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
#'

GeomTailScatter <- ggproto("StatTailScatter", Geom,
                   required_aes = c("x", "y"),
                   extra_params = c("na.rm", "tail_scale"),

                   default_aes = list(
                     shape = 19,
                     colour = "black",
                     size = 1.5,
                     fill = NA,
                     alpha = NA,
                     stroke = 0.5),

                   draw_group = function(data, panel_params, coord,
                                         tail_scale, ...) {

                     if (tail_scale>1) {
                       warning("tail_scale values gt 1 will extend past the limits of the panel")
                     }

                     if (tail_scale <= 0) {
                      stop("tail_scale must be greater than 0")
                     }

                     coords = coord$transform(data, panel_params)
                     fit_columns = grep("x[0-9]+", names(data), value = TRUE)

                     gl = grid::gList(
                       grid::pointsGrob(
                         coords$x, coords$y,
                         pch = coords$shape,
                         gp = grid::gpar(
                           col = alpha(coords$colour, coords$alpha),
                           fill = alpha(coords$fill, coords$alpha),
                           # Stroke is added around the outside of the point
                           fontsize = coords$size * .pt + coords$stroke * .stroke / 2,
                           lwd = coords$stroke * .stroke / 2
                         )
                       ))

                     ll = lapply(1:length(fit_columns), function(i) {
                       s = fit_columns[i]
                       MAXR = tail_scale
                       B = 1 / (max(coords[,s]) - min(coords[,s]))
                       A = - B * min(coords[,s])

                       xx = A + B * coords[,s]
                       dx = MAXR * xx * cos(-(15 + 30 * i) * pi /180)
                       dy = MAXR * xx * sin(-(15 + 30 * i) * pi /180)
                       g = grid::segmentsGrob(x0 = coords$x, y0 = coords$y,
                                            x1 = coords$x + dx, y1 = coords$y + dy,
                                            gp = grid::gpar(col = coords$colour))
                     })

                     Reduce(function(a1, a2) {grid:::addToGList.grob(a2, a1)},
                            ll, gl)
})

#' Geom TailScatter
#'
#' Geom TailScatter ab absurdum
#'
#' @inheritParams GeomTailScatter
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
geom_tailscatter <- function(mapping = NULL, data = NULL, stat = "identity",
                     position = "identity", na.rm = FALSE, show.legend = NA,
                     inherit.aes = TRUE, tail_scale = 0.1,
                     ...) {
  layer(
    geom = GeomTailScatter, data = data, mapping = mapping, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, tail_scale = tail_scale, ...)
  )
}
