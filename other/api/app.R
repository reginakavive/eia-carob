
library(plumber)
# 'plumber.R' is the location of the file shown above
pr(file.path(home_dir,"other/api/plumber.R")) %>%
  pr_run(port=8008,host = "0.0.0.0")

# ngrok http http://127.0.0.1:8008
