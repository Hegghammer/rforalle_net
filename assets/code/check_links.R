# R script to check the qmd files for broken external links.
#
# I keep it in `assets/code/` and have the following in `_quarto.yml`:
#
#   post-render:
#     - assets/code/check_links.R"
#
# The script uses markdown-link-check (MLC)
# https://github.com/tcort/markdown-link-check.
# I made it because MLC cannot show just the external links.
# Using a config file with `"ignorePatterns": [{"pattern":"^(?!http)"}]`
# does not print the links to stdout, even with the --verbose option.

# change as necessary
logpath <- "assets/code/linkcheck.log"

# Run MLC
message("Checking for broken external links. This may take a few minutes ..")
tmp <- tempfile() # only way to fully silence MLC
cmd <- paste0("find . -name '*.qmd' -print0 | xargs -0 -n1 markdown-link-check > ", tmp, " 2>&1")
res <- try(system(cmd, intern = TRUE))


if (class(res) == "try-error") {
  # Tell me if it fails
  message("Error. `markdown-link-check` is probably not installed
          on your system. See the documentation at
          https://github.com/tcort/markdown-link-check
          or try installing with:
          \n\n npm install -g markdown-link-check")
} else {
  # Summarize results
  output <- readLines(tmp)
  fine <- grep("\\[✓\\] http", output, value = TRUE)
  broken <- grep("\\[✖\\] http", output, value = TRUE)
  nfine <- length(fine)
  nbroken <- length(broken)
  nall <- nfine + nbroken
  summary <- paste0(
    nall, " external links checked, ",
    nbroken, " broken links found:\n"
  )
  message(summary)
  print(broken)
  # Log the full results
  line <- paste0("\n", paste0(rep("-", 55), collapse = ""), "\n")
  ts <- format(Sys.time(), "%e %b %Y at %X")
  rootdir <- paste0(basename(getwd()), "/*")
  logheader <- paste0(
    line,
    "Results of markdown-link-check for ", rootdir,
    "\nrun on ", ts, ".",
    line
  )
  log <- paste0(
    logheader, "\n",
    summary,
    paste(broken, collapse = "\n"),
    "\n\nDetails:\n",
    paste(res, collapse = "\n")
  )
  write(log, logpath)
  message("\nSee `", logpath, "` for details.")
  invisible(file.remove(tmp))
}
