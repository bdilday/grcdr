#' Compute running quantities
#'
#' Compute running quantities, e.g. sums, averages.
#'
#' @seealso
#'   \code{\link{geom_excursion}}
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
#' @param run_length The number of epochs to average over
#' @param run_fill_value Fill missing epochs with this value
#' @param run_fill_step Fill in the \code{t} aesthetic with this cadance
#' @param run_fun The running function. Defaults to \code{base::cumsum}
#' @param x_run_fill_value x-specific fill value. Defaults to \code{run_fill_value}
#' @param x_run_fun x-specific running function. Defaults to \code{run_fun}
#' @param y_run_fill_value y-specific fill value. Defaults to \code{run_fill_value}
#' @param y_run_fun y-specific running function. Defaults to \code{run_fun}
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
#'
StatRun <- ggproto("StatRun", Stat,
                   required_aes = c("t", "y"),
                   default_aes = list(
                     "x_weight" = 1,
                     "y_weight" = 1,
                     "color" = "black"
                   ),

                   setup_params = function(data, params) {
                     params
                   },

                   setup_data = function(data, params) {
                     data
                   },


                   compute_group = function(data, scales,
                                            run_length=NULL,
                                            run_fill_value=NULL,
                                            run_fill_step=NULL,
                                            run_fun=NULL,
                                            x_run_fill_value=NULL,
                                            x_run_fun=NULL,
                                            y_run_fill_value=NULL,
                                            y_run_fun=NULL
                                            ) {

                     run_value_ok = !xor(is.null(x_run_fill_value), is.null(y_run_fill_value))
                     if (!run_value_ok) {
                       stop(paste0("x_run_fill_value and y_run_fill_value must both be defined or both be NULL. ",
                                   "If you want the same fill vlaue for x and y aesthetics simply use run_fill_value")
                       )
                     }

                     if ("x" %in% names(data)) {
                       hasX = TRUE
                     } else {
                       hasX = FALSE
                       data$x = data$t
                     }

                     if (is.null(x_run_fun)) {
                       x_run_fun = run_fun
                     }
                     if (is.null(y_run_fun)) {
                       y_run_fun = run_fun
                     }

                     if (is.null(x_run_fill_value)) {
                       x_run_fill_value = run_fill_value
                     }

                     if (is.null(y_run_fill_value)) {
                       y_run_fill_value = run_fill_value
                     }


                     idx = order(data$t)
                     data = data[idx,]

                     x_fill = !is.null(x_run_fill_value) || !is.null(run_fill_value)
                     y_fill = !is.null(y_run_fill_value) || !is.null(run_fill_value)

                     if (x_fill || y_fill) {
                       tmin = min(data$t)
                       tmax = max(data$t)
                       t_seq = seq(tmin, tmax, by=run_fill_step)
                       fill_df = data.frame(t = t_seq)
                       tmp = merge(data, fill_df, by="t", all.y=TRUE)
                       r = tmp[1,]
                       for (nm in names(r)) {
                         # just copy the first record for groups, colors, etc
                         if (nm %in% c("x", "y", "t")) {
                           # next
                         } else {
                           tmp[,nm] = r[,nm]
                         }
                       }

                       ccx = is.na(tmp$x)
                       ccy = is.na(tmp$y)

                       if (sum(ccx) > 0) {
                         tmp[ccx,]$x = x_run_fill_value
                       }

                       if (sum(ccy) > 0) {
                         tmp[ccy,]$y = y_run_fill_value
                       }


                       data = tmp
                     }

                     npts = nrow(data)
                     if (run_length < 1) {
                       warning("run_length less than 1 is not defined. Resetting to 1")
                       run_length = 1
                     } else if (run_length > npts-1) {
                       warning(sprintf("run_length %d is larger than size of data - 1(%d). Resetting to %d",
                                       run_length, npts-1, npts-1))
                       run_length = npts - 1
                     }

                     if (hasX) {
                       if ("x_weight" %in% names(data)) {
                         sx_num = x_run_fun(data$x * data$x_weight)
                         sx_denom = x_run_fun(data$x_weight)
                       } else {
                         sx_num = x_run_fun(data$x)
                         sx_denom = NULL
                       }
                     } else {
                       sx_num = data$t
                       sx_denom = NULL
                     }

                     if ("y_weight" %in% names(data)) {
                       sy_num = y_run_fun(data$y * data$y_weight)
                       sy_denom = y_run_fun(data$y_weight)
                     } else {
                       sy_num = y_run_fun(data$y)
                       sy_denom = NULL
                     }

                     if (run_length > 1) {
                       if (is.null(sx_denom)) {
                         x_ = diff(sx_num, lag = run_length - 1)
                       } else {
                         x_ = diff(sx_num, lag = run_length - 1) / diff(sx_denom, lag = run_length - 1)
                       }

                       if (is.null(sy_denom)) {
                         y_ = diff(sy_num, lag = run_length - 1)
                       } else {
                         y_ = diff(sy_num, lag = run_length - 1) / diff(sy_denom, lag = run_length - 1)
                       }

                       t_ = (data$t)[1:length(y_)]
                     } else {
                       x_ = data$x
                       y_ = data$y
                       t_ = data$t
                     }

                     if (!hasX) {
                       data.frame(x=t_,
                                  y=y_,
                                  t=t_)

                     } else {
                       data.frame(x=x_,
                                  y=y_,
                                  t=t_)
                     }
                   }


)

#' Stat run
#'
#' Stat run ab absurdum
#'
#' @inheritParams StatRun
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
stat_run <- function(mapping = NULL, data = NULL, geom = "path",
                    position = "identity", na.rm = FALSE, show.legend = NA,
                    inherit.aes = TRUE,
                    run_length = 1,
                    run_fill_value = NULL,
                    run_fill_step = 1,
                    run_fun = base::cumsum,
                    x_run_fill_value=NULL,
                    x_run_fun=NULL,
                    y_run_fill_value=NULL,
                    y_run_fun=NULL,
                    ...) {
  layer(
    stat = StatRun, data = data, mapping = mapping, geom = geom,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm,
                  run_length = run_length,
                  run_fill_value = run_fill_value,
                  run_fill_step = run_fill_step,
                  run_fun = run_fun,
                  x_run_fill_value = x_run_fill_value,
                  x_run_fun = x_run_fun,
                  y_run_fill_value = y_run_fill_value,
                  y_run_fun = y_run_fun,
                  ...)
  )
}
