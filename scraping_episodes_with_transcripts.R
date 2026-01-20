# library(tidyverse)
# readRDS('/Users/joka/Documents/R_projects/r-podcast/data/all_data.rds')
library(collapse)
library(rvest)
library(stringi)
library(glue)
library(tidyverse)
library(httr)

url <- "https://serve.podhome.fm/r-weekly-highlights"
r_weekly <- read_html(url)

# Get number of pages to then iterate over each page
page_count <- '.pagination-link'
n_pages <- r_weekly |> html_elements(page_count) |> length()

# Inner functions to extract data from html based on css selectors, either text or href
get_href <- function(css_selector){
  map(1:n_pages,\(n_pg) {
    page_html <- read_html(glue("{url}?currentPage={n_pg}&searchTerm="))
    page_html |> html_elements(css_selector) |> html_attr("href") 
  }) |> unlist()
}
get_text2 <- function(css_selector){
  map(1:n_pages,\(n_pg) {
    page_html <- read_html(glue("{url}?currentPage={n_pg}&searchTerm="))
    page_html |> html_elements(css_selector) |> html_text2()
  }) |> unlist()
}
#

# Function to scrape transcript from individual episode page
get_transcript <- function(episode_url){
  tryCatch({
    Sys.sleep(10) # Increased sleep to avoid overwhelming server/connection pool
    episode_page <- read_html(episode_url)
    
    # Extract episode ID from the page scripts
    scripts <- episode_page |> html_elements('script') |> as.character()
    episode_id <- NULL
    
    for(script in scripts) {
      match <- stri_extract_first_regex(script, '/api/transcript/([a-f0-9-]+)')
      if(!is.na(match)) {
        episode_id <- stri_replace_first_regex(match, '/api/transcript/', '')
        break
      }
    }
    
    if(is.null(episode_id)) {
      message(glue("Could not find episode ID for {episode_url}"))
      return(NA_character_)
    }
    
    # Fetch transcript from API
    api_url <- paste0('https://serve.podhome.fm/api/transcript/', episode_id)
    response <- httr::GET(api_url)
    
    # Close the connection explicitly to avoid connection pool exhaustion
    on.exit(try(close(response$request$output), silent = TRUE))
    
    if(httr::status_code(response) != 200) {
      message(glue("Failed to fetch transcript from API (Status {httr::status_code(response)}): {episode_url}"))
      return(NA_character_)
    }
    
    # Get HTML content and extract text
    transcript_html <- httr::content(response, as = 'text', encoding = 'UTF-8')
    
    # Check if the response is actually empty or just whitespace
    if(nchar(stri_trim_both(transcript_html)) < 50) {
      message(glue("Transcript appears to be empty for {episode_url}"))
      return(NA_character_)
    }
    
    # Parse HTML and extract clean text
    transcript_doc <- read_html(transcript_html)
    transcript_text <- transcript_doc |> html_text2()
    
    # Final check - if transcript is too short, it's probably not a real transcript
    if(nchar(stri_trim_both(transcript_text)) < 100) {
      message(glue("Transcript too short (possibly no transcript available) for {episode_url}"))
      return(NA_character_)
    }
    
    return(transcript_text)
    
  }, error = function(e) {
    message(glue("Error scraping transcript from {episode_url}: {e$message}"))
    return(NA_character_)
  })
}

get_ep_metadata <- function(n_episodes = NULL){
  # Vector of links to all episodes
  eps <- get_href(".episodeLink")
  
  # Limit to first n_episodes if specified (for testing)
  if(!is.null(n_episodes)) {
    eps <- head(eps, n_episodes)
  }
  
  ep_link <- paste0("https://serve.podhome.fm", eps) 
  ep_name <-  ep_link |> stri_replace_last_regex("^.*/","") |> snakecase::to_snake_case()
  
  episode <<- matrix(data = c(ep_link, ep_name),ncol=2,dimnames = list(NULL, c("link", "name"))) # exported to global environemnt, as it will be then used by the other function.
  
  date_duration <- get_text2(".is-tablet+ .has-text-grey")
  
  # split date and duration
  date_duration <- map(date_duration, \(s) s |>
                         stri_split_fixed(" &vert; ") |>
                         unlist() |>
                         stri_trim_both())
  ep_date <- map_chr(date_duration, \(x) x[[1]]) |> dmy()
  ep_duration <- map_chr(date_duration, \(x) x[[2]]) |> hms()
  
  # get short description
  ep_desc_short <- get_text2(".is-hidden-touch")
  ep_desc_short <- ep_desc_short[seq(2, length(ep_desc_short), 2)] |> stri_trim_both() # some duplication, plus the first one is not an episode description
  # A fix due to multiple pages: need to filter header from each page
  indx_remove <- stri_detect_fixed(ep_desc_short,'Contact') |> which()
  ep_description_short <- ep_desc_short[-indx_remove]
  
  # Limit other vectors to match number of episodes if testing
  if(!is.null(n_episodes)) {
    ep_date <- head(ep_date, n_episodes)
    ep_duration <- head(ep_duration, n_episodes)
    ep_description_short <- head(ep_description_short, n_episodes)
  }
  
  # Scrape transcripts from each episode page
  message("Scraping transcripts from individual episode pages...")
  ep_transcript <- map_chr(ep_link, get_transcript, .progress = TRUE)
  
  tibble::tibble(ep_name, ep_date, ep_duration, ep_description_short, ep_transcript)
}

# put it all in a nice table
# Test with first 3 episodes
all_episodes <- get_ep_metadata()

# To get ALL episodes, use:
# all_episodes <- get_ep_metadata()

all_episodes

# Option 1: Scrape in batches
batch_size <- 20
all_results <- list()

for(i in seq(1, 218, by = batch_size)) {
  end_idx <- min(i + batch_size - 1, 218)
  cat(sprintf("Processing episodes %d to %d\n", i, end_idx))
  
  batch <- get_ep_metadata(n_episodes = end_idx)[i:min(end_idx, nrow(all_episodes)),]
  all_results[[length(all_results) + 1]] <- batch
  
  # Pause between batches
  if(end_idx < 218) {
    cat("Pausing for 5 seconds...\n")
    Sys.sleep(10)
  }
}

all_episodes <- bind_rows(all_results)
tt <- bind_rows(all_results)

# Check open connections
showConnections()

# Close all connections (nuclear option - use with caution)
closeAllConnections()