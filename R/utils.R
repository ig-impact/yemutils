#' Returns the path to the SharePoint folder path
#'
#'
#' @return character vector
#' @export
get_sharepoint_basepath <- function() {
  base_path <- Sys.getenv("SHAREPOINT_ROOT", unset = NA)
  if (is.na(base_path)) {
    cli::cli_abort(c(
      "x" = "{.envvar SHAREPOINT_ROOT} is not set",
      "i" = "Please use {.code usethis::edit_r_environ(scope = 'user')}",
      "i" = "{.code SHAREPOINT_ROOT='/path/to/sharepoint'}"
    ))
  }

  if (!fs::dir_exists(base_path)) {
    cli::cli_abort(c(
      "x" = "{.file {base_path}} does not exist"
    ))
  }

  return(base_path)
}
