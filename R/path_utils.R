#' Validate path existence and access
#'
#' @param path Character vector of path to validate
#' @param should_exist Logical indicating if path should exist
#' @return Silently returns path if valid, errors if invalid
#' @export
yem_validate_path <- function(path, should_exist = TRUE) {
  if (should_exist && !fs::dir_exists(path) && !fs::file_exists(path)) {
    cli::cli_abort(c(
      "x" = "{.file {path}} does not exist"
    ))
  }

  if (should_exist && !fs::file_access(path, mode = "read")) {
    cli::cli_abort(c(
      "x" = "No read permissions for {.file {path}}"
    ))
  }

  path
}

#' Returns the path to the SharePoint folder path
#'
#' @return character vector representing the normalized SharePoint base path
#' @export
yem_get_sharepoint_basepath <- function() {
  base_path <- Sys.getenv("SHAREPOINT_ROOT", unset = NA)

  if (is.na(base_path)) {
    cli::cli_abort(c(
      "x" = "{.envvar SHAREPOINT_ROOT} is not set",
      "i" = "Please use {.code usethis::edit_r_environ(scope = 'user')}",
      "i" = "{.code SHAREPOINT_ROOT='/path/to/sharepoint'}"
    ))
  }

  base_path <- fs::path_norm(base_path)

  if (!fs::dir_exists(base_path)) {
    cli::cli_abort(c(
      "x" = "{.file {base_path}} does not exist"
    ))
  }

  return(base_path)
}

#' Build paths relative to SharePoint root
#'
#' @param ... Character vectors, arguments to construct a path
#' @param must_exist Logical indicating if final path should exist
#' @return A normalized path string starting from SharePoint root
#' @export
yem_build_path <- function(..., must_exist = TRUE) {
  root <- yem_get_sharepoint_basepath()
  path <- fs::path(root, ...)
  yem_validate_path(path, should_exist = must_exist)
}

#' Find files in SharePoint by exact name match
#'
#' @param filename Character string of exact filename to find
#' @return Character vector of matching relative paths
#' @export
yem_find_file <- function(filename) {
  root <- yem_get_sharepoint_basepath()
  paths <- fs::dir_ls(root,
    recurse = TRUE,
    type = "file",
    file = FALSE,
    fail = FALSE
  )
  matches <- fs::path_rel(
    paths[basename(paths) == filename],
    start = root
  )
  return(matches)
}
