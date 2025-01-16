#' Core Dependencies
#' @export
yem_core_deps <- c(
  "targets", "tarchetypes", "fs",
  "pointblank", "readxl", "dplyr",
  "visNetwork"
)

#' Development Dependencies
#' @export
yem_dev_deps <- c(
  "renv", "pkgdown",
  "cli", "devtools",
  "usethis", "lintr",
  "styler"
)

recommended_options <- list(
  renv.config.auto.snapshot = TRUE,
  renv.config.pak.enabled = TRUE,
  renv.config.ppm.enabled = TRUE,
  renv.config.ppm.default = TRUE
)

#' Initialize analysis project
#'
#' @param project_name chracter vector project name
#' @param project_dir path
#' @param use_git boolean Whether to use git or not
#'
#' @return boolean invisible
#' @export
yem_init_project <- function(project_name,
                             project_dir = ".",
                             use_git = TRUE) {
  project_path <- fs::path(project_dir, project_name)
  cli::cli_alert_info("Initializing project in {.path {project_path}}")

  withr::with_options(
    recommended_options,
    {
      usethis::create_package(
        path = project_path,
        open = FALSE,
        rstudio = FALSE,
        roxygen = TRUE
      )

      usethis::with_project(
        path = project_path,
        {
          desc_file <- rprojroot::find_package_root_file("DESCRIPTION") # nolint
          cli::cli_alert_info("{.path {desc_file}}")
          lapply(yem_core_deps, usethis::use_package)
          lapply(yem_dev_deps, usethis::use_package, type = "Suggests")
        }
      )

      renv::init(
        project = project_path,
        load = FALSE,
        restart = FALSE
      )

      usethis::with_project(path = project_path, {
        if (use_git) {
          tryCatch(
            usethis::use_git(),
            error = function(e) {
              cli::cli_alert_danger(c(
                "x" = "{e}"
              ))
            }
          )
        }

        withr::with_package("targets", {
          cli::cli_alert_info("Initializing targets in {.path {getwd()}}")
          targets::use_targets(open = FALSE)
        })
      })
    }
  )
}
