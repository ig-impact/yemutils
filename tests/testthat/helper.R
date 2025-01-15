silent_create_package <- function(proj_dir) {
  withr::with_output_sink(
    new = withr::local_tempfile(),
    code = {
      withr::with_message_sink(
        new = withr::local_tempfile(),
        code = {
          usethis::create_package(path = proj_dir, open = FALSE)
        }
      )
    }
  )
}
