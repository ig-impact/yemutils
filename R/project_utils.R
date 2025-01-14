#' Initialize package dependencies
#' @param path Path to package root
#' @param dependencies Character vector of additional dependencies
#' @param core_deps Character vector of core dependencies to include
#' @keywords internal
yem_init_dependencies <- function(path,
                                  dependencies = character(),
                                  core_deps = c(
                                    "targets", "tarchetypes", "fs",
                                    "pointblank", "readxl", "dplyr",
                                    "visNetwork"
                                  )) {
  # Set global options to minimize prompts
  withr::with_options(
    list(
      renv.consent = TRUE,
      renv.config.auto.snapshot = TRUE,
      renv.config.pak.enabled = TRUE,
      usethis.quiet = TRUE
    ),
    {
      # Combine all dependencies upfront
      all_deps <- unique(c(core_deps, dependencies))
      dev_deps <- c(
        "renv", "pkgdown",
        "cli", "devtools",
        "usethis", "lintr",
        "styler"
      )

      # Initialize renv with minimal setup
      rlang::check_installed("renv")
      renv::init(project = path, bare = TRUE)

      # Install all packages in one batch
      tryCatch(
        renv::install(
          unique(c(all_deps, dev_deps)),
          project = path,
          prompt = FALSE
        ),
        error = function(e) {
          cli::cli_abort(c(
            "x" = "Failed to install packages: {e$message}",
            "i" = "Check package availability and network connection"
          ))
        }
      )

      usethis::with_project(path, {
        purrr::walk(all_deps, ~ usethis::use_package(.x))
        purrr::walk(dev_deps, ~ usethis::use_package(.x, type = "Suggests"))
      })
    }
  )
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
