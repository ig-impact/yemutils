test_that("yem_init_dependencies sets up packages correctly", {
  proj_dir <- withr::local_tempdir()
  mock_use_package <- mockery::mock()
  mock_renv_init <- mockery::mock()

  mockery::stub(yem_init_dependencies, "usethis::use_package", mock_use_package)
  mockery::stub(yem_init_dependencies, "renv::init", mock_renv_init)

  silent_create_package(proj_dir)


  yem_init_dependencies(proj_dir)

  calls <- mockery::mock_args(mock_use_package)

  # Check core deps
  for (i in seq_along(yem_core_deps)) {
    expect_equal(calls[[i]][[1]], yem_core_deps[i])
    expect_null(calls[[i]]$type)
  }

  # Check dev deps
  dev_start <- length(yem_core_deps) + 1
  for (i in seq_along(yem_dev_deps)) {
    expect_equal(calls[[dev_start + i - 1]][[1]], yem_dev_deps[i])
    expect_equal(calls[[dev_start + i - 1]]$type, "Suggests")
  }
})

test_that("yem_init_dependencies handles custom dependencies", {
  proj_dir <- withr::local_tempdir()
  mock_use_package <- mockery::mock()
  mock_renv_init <- mockery::mock()

  silent_create_package(proj_dir)


  mockery::stub(yem_init_dependencies, "usethis::use_package", mock_use_package)
  mockery::stub(yem_init_dependencies, "renv::init", mock_renv_init)

  custom_deps <- c("custom1", "custom2")
  yem_init_dependencies(proj_dir, dependencies = custom_deps)

  calls <- mockery::mock_args(mock_use_package)
  expect_equal(
    length(calls),
    length(unique(c(yem_core_deps, custom_deps))) + length(yem_dev_deps)
  )
})

test_that("yem_init_dependencies sets up packages correctly", {
  proj_dir <- withr::local_tempdir()
  mock_use_package <- mockery::mock()
  mock_renv_init <- mockery::mock()

  mockery::stub(yem_init_dependencies, "usethis::use_package", mock_use_package)
  mockery::stub(yem_init_dependencies, "renv::init", mock_renv_init)

  silent_create_package(proj_dir)

  yem_init_dependencies(proj_dir)

  calls <- mockery::mock_args(mock_use_package)

  # Check core deps
  for (i in seq_along(yem_core_deps)) {
    expect_equal(calls[[i]][[1]], yem_core_deps[i])
    expect_null(calls[[i]]$type)
  }

  # Check dev deps
  dev_start <- length(yem_core_deps) + 1
  for (i in seq_along(yem_dev_deps)) {
    expect_equal(calls[[dev_start + i - 1]][[1]], yem_dev_deps[i])
    expect_equal(calls[[dev_start + i - 1]]$type, "Suggests")
  }
})

test_that("renv initialization and snapshot work correctly", {
  proj_dir <- withr::local_tempdir()
  mock_snapshot <- mockery::mock()

  mockery::stub(yem_init_dependencies, "renv::snapshot", mock_snapshot)

  silent_create_package(proj_dir)

  yem_init_dependencies(proj_dir)

  # Verify snapshot called with correct params
  snapshot_args <- mockery::mock_args(mock_snapshot)[[1]]
  expect_equal(snapshot_args$project, proj_dir)
  expect_equal(snapshot_args$prompt, FALSE)
  expect_equal(snapshot_args$type, "implicit")
  expect_equal(snapshot_args$dev, TRUE)
})

test_that("recommended options are set in .Rprofile", {
  proj_dir <- withr::local_tempdir()

  silent_create_package(proj_dir)
  yem_init_dependencies(proj_dir)

  rprofile <- readLines(file.path(proj_dir, ".Rprofile"))
  expect_true(any(grepl("renv.consent = TRUE", rprofile)))
  expect_true(any(grepl("renv.config.auto.snapshot = TRUE", rprofile)))
})

test_that("renv snapshot creates consistent project state", {
  proj_dir <- withr::local_tempdir()

  silent_create_package(proj_dir)

  yem_init_dependencies(proj_dir)

  # Check renv.lock exists and contains expected packages
  expect_true(file.exists(file.path(proj_dir, "renv.lock")))
  lock_content <- jsonlite::read_json(file.path(proj_dir, "renv.lock"))

  # Verify core packages are in lock file
  expect_true(all(yem_core_deps %in% names(lock_content$Packages)))

  # Verify dev packages are in lock file
  expect_true(all(yem_dev_deps %in% names(lock_content$Packages)))

  # Verify renv directory structure
  expect_true(dir.exists(file.path(proj_dir, "renv")))
  expect_true(file.exists(file.path(proj_dir, "renv/activate.R")))

  status <- renv::status(project = proj_dir, dev = TRUE)
  expect_equal(status$synchronized, TRUE)
  expect_equal(length(status$out_of_sync), 0)
})
