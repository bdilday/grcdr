#' Geom Excursion
#'
#' Excursion plots. Shortcut to a \code{stat_run} with \code{x} and \code{y} aesthetics and a \code{path}
#' geom
#'
#' @inheritParams StatRun
#' @export
#' @examples
#' set.seed(101)
#' wip
#'
geom_excursion = function(mapping = NULL, data = NULL,
                          position = "identity", na.rm = FALSE, show.legend = NA,
                          inherit.aes = TRUE,
                          stadium_ids = NULL,
                          run_length = 1,
                          run_fill_value = NULL,
                          run_fill_step = 1,
                          run_fun = base::cumsum,
                          x_run_fill_value=NULL,
                          x_run_fun=NULL,
                          y_run_fill_value=NULL,
                          y_run_fun=NULL,
                          ...) {
  # TODO: force an x aesthetic
  layer(
    stat = StatRun, data = data, mapping = mapping, geom = 'path',
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
