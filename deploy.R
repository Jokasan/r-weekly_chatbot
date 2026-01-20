# Deployment script for shinyapps.io
library(rsconnect)

# Check if database exists
if (!file.exists("rweeklypodcast.ragnar.duckdb")) {
  stop("Database file not found! Run build_store.r first.")
}

# Check if .Renviron exists
if (!file.exists(".Renviron")) {
  stop(".Renviron file not found! Create it with your OPENAI_API_KEY")
}

cat("Deploying R Weekly Podcast Chat to shinyapps.io...\n")
cat("This may take several minutes due to the database file size.\n\n")

# Deploy the app
rsconnect::deployApp(
  appDir = getwd(),
  appFiles = c(
    "app.R",
    "rweeklypodcast.ragnar.duckdb",
    ".Renviron"
  ),
  appName = "r-weekly-podcast-chat",
  forceUpdate = TRUE,
  launch.browser = TRUE
)

cat("\n✓ Deployment complete!\n")
