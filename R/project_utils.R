#' @export
yem_core_deps <- c(
  "targets", "tarchetypes", "fs",
  "pointblank", "readxl", "dplyr",
  "visNetwork"
)

#' @export
yem_dev_deps <- c(
  "renv", "pkgdown",
  "cli", "devtools",
  "usethis", "lintr",
  "styler"
)


#' Initialize package dependencies
#' @param path Path to package root
#' @param dependencies Character vector of additional dependencies
#' @param core_deps Character vector of core dependencies to include
#' @keywords internal
yem_init_dependencies <- function(path,
                                  dependencies = character(),
                                  core_deps = yem_core_deps) {
  recommended_options <- list(
    renv.consent = TRUE,
    renv.config.auto.snapshot = TRUE,
    renv.config.pak.enabled = TRUE,
    renv.config.ppm.enabled = TRUE,
    renv.config.ppm.default = TRUE,
    usethis.quiet = TRUE
  )

  withr::with_options(recommended_options, {
    all_deps <- unique(c(core_deps, dependencies))
    rlang::check_installed("renv")

    usethis::with_project(path, {
      renv::init(bare = TRUE)
      renv::activate(project = path)
      usethis::write_union(".Rprofile", glue::glue(
        "options({names(recommended_options)} = {recommended_options})"
      ))
      purrr::walk(all_deps, ~ usethis::use_package(.x))
      purrr::walk(yem_dev_deps, ~ usethis::use_package(.x, type = "Suggests"))
      renv::snapshot(
        project = path,
        prompt = FALSE, type = "implicit", dev = TRUE
      )
    })
  })
}

#' Setup documentation structure
#' @param path Path to package root
#' @keywords internal
yem_init_documentation <- function(path) {
  usethis::with_project(path, {
    usethis::use_pkgdown()

    if (!fs::dir_exists("man")) fs::dir_create("man")
    if (!fs::dir_exists("R")) fs::dir_create("R")
  })
}

#' Create standard folder structure
#' @param path Path to package root
#' @keywords internal
yem_init_folders <- function(path) {
  usethis::with_project(path, {
    usethis::use_directory("inst/extdata/raw", ignore = TRUE)
    usethis::use_directory("inst/extdata/processed", ignore = TRUE)
    usethis::use_directory("R")
  })
}

#' Setup targets pipeline template
#' @param path Path to package root
#' @keywords internal
yem_init_targets <- function(path) {
  usethis::with_project(path = path, {
    targets::use_targets(open = FALSE)
  })
}

#' Initialize a new data analysis project
#' @param name Name of the project/package
#' @param path Path where to create the project
#' @param git Should git be initialized
#' @export
yem_init_project <- function(name,
                             path = ".",
                             git = TRUE) {
  proj_path <- fs::path(path, name)
  cli::cli_alert_info("Initializing project in {.path {proj_path}}")

  # Create package structure first
  usethis::create_package(
    proj_path,
    open = FALSE,
    roxygen = TRUE,
    rstudio = FALSE,
    check_name = FALSE
  )

  # Initialize in specific order
  yem_init_dependencies(proj_path)

  # Group remaining setup under one with_project call
  usethis::with_project(proj_path, {
    yem_init_folders(proj_path)
    yem_init_targets(proj_path)
    yem_init_documentation(proj_path)

    if (git) usethis::use_git()
  })

  renv::snapshot(project = proj_path, prompt = FALSE)

  cli::cli_alert_success(
    "Project {.val {name}} initialized at {.file {proj_path}}"
  )
}
