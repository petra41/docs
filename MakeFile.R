library(knitr)
library(dplyr)
library(magrittr)
library(glue)

options(
  width = 250,
  scipen = 100,
  max.print = 5000,
  stringsAsFactors = FALSE
)

knitr::opts_chunk$set(
  echo = TRUE,
  comment = NA,
  cache = FALSE,
  message = FALSE,
  warning = FALSE,
  dpi = 144
)

## generate (updated) html and md files
# docs_path <- rstudioapi::getActiveProject()
# setwd(docs_path)
docs_path <- setwd(".")
if (basename(getwd()) != "docs") stop("Wrong working directory set")
# docs_path <- setwd("~/gh/docs")
system('make')

knit_docs <- function(x) {
  setwd(file.path(docs_path, x, "app"))
  list.files(pattern = "*.Rmd") %>% sapply(knit)
  setwd(file.path("../..", x)); system("make")
}
sapply(
  c("data", "design", "basics", "model", "multivariate"),
  knit_docs
)
## setup articles for pkgdown
setwd(docs_path)
make_content <- function(files, app) {
  for (file in files) {
    article <- readLines(file.path(glue("{app}/app"), file), warn = FALSE)
    figs <- ifelse(app == "data", "figures", glue("figures_{app}"))
    article <- gsub(figs, glue("https://radiant-rstats.github.io/docs/{app}/{figs}/"), article)
    file <- paste0("_", sub("\\.md$", ".Rmd", file))
    cat(article, file = file.path(glue("../radiant.{app}/vignettes/pkgdown/{file}")), sep = "\n")
  }
}

files <- c(
  "combine.Rmd", "explore.md", "manage.md", "pivotr.md",
  "report_r.md", "report_rmd.md", "state.md", "transform.Rmd",
  "view.Rmd", "visualize.md"
)

make_content(files, "data")

files <- c(
  "doe.md", "sample_size.Rmd", "sample_size_comp.Rmd", "sampling.md", "randomizer.md"
)

make_content(files, "design")

files <- c(
  "clt.md", "compare_means.md", "compare_props.md", "correlation.md",
  "cross_tabs.md", "goodness.md", "prob_calc.Rmd", "single_mean.md",
  "single_prop.md"
)

make_content(files, "basics")

files <- c(
  "crs.md", "crtree.md", "dtree.Rmd", "evalbin.md",
  "evalreg.md", "logistic.Rmd", "mnl.Rmd", "nb.md", "nn.md",
  "gbt.md", "rforest.md", "regress.Rmd", "simulater.Rmd"
)

make_content(files, "model")

files <- c(
  "conjoint.md", "full_factor.md", "hclus.md", "kclus.md",
  "mds.md", "pre_factor.md", "prmap.md"
)

make_content(files, "multivariate")

## making the README.md file after clean-up
setwd(docs_path)
knit("README.Rmd")
setwd(file.path(docs_path, "sub"))
knit("README_dev.Rmd")
knit("tutorials_dev.Rmd")

file.copy(
  "README_dev.md",
  file.path("../../radiant.data/inst/app/tools/app/about.md"),
  overwrite = TRUE
)

file.copy(
  "tutorials_dev.md",
  file.path("../../radiant.data/inst/app/tools/app/tutorials.md"),
  overwrite = TRUE
)

copy_docs <- function(app) {
  readLines("README_dev.md", warn = FALSE) %>% paste0(., collapse = "\n") %>%
    sub("radiant.png", paste0(app, ".png"), . ) %>%
    sub("radiant-rstats/radiant)", paste0("radiant-rstats/", app,")"), ., fixed = TRUE) %>%
    sub("badges/version/radiant)", paste0("badges/version/", app,")"), ., fixed = TRUE) %>%
    sub("package=radiant)", paste0("package=",app,")"), ., fixed = TRUE) %>%
    sub("radiant/issues", paste0(app,"/issues"), ., fixed = TRUE) %>%
    cat(file = file.path("../..", app, "README.md"))
}

sapply(
  c("radiant","radiant.data","radiant.design",
    "radiant.basics","radiant.model","radiant.multivariate"),
  copy_docs
)

## sync (R)md files to gh/radiant
setwd(docs_path)
system('sh rsync_docs2app.sh')
