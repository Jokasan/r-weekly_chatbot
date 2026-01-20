# R Weekly Highlights Podcast Chatbot

An AI-powered chatbot that answers questions about the R Weekly Highlights podcast using Retrieval Augmented Generation (RAG).

[**Try the live app →**](https://jokasan-r-weekly-chatbot.share.connect.posit.cloud)


This project [scrapes podcast transcripts using the code shares by Yann Tourman](https://bsky.app/profile/yannco.bsky.social/post/3mbarm75kik2j), builds a vector database for semantic search, and provides an interactive chat interface to query podcast content.

## Files Overview

### Data Collection
- **`scraping_episodes_with_transcripts.R`** - Scrapes podcast metadata and transcripts from Podhome.fm. Uses a two-step process: extracts episode IDs from page HTML, then fetches transcripts via API endpoint.
- **`episodes_w_transcripts.csv`** - Raw data containing episode metadata and transcripts for 218 episodes (76 episodes missing transcripts).

### RAG Pipeline
- **`build_store.r`** - Production script that chunks all transcripts into ~100 token segments, creates embeddings using OpenAI's `text-embedding-3-small` model, and builds a DuckDB vector store with BM25 and vector search indices.
- **`rweeklypodcast.ragnar.duckdb`** - The vector database containing embedded transcript chunks (episodes 200-217 due to deployment size constraints).

### Application
- **`app.R`** - Shiny app with chat interface using `shinychat` and `ellmer`. Connects to the vector store in read-only mode and registers it as a tool for the OpenAI chat model.
- **`deploy.R`** - Deployment script for Posit Connect Cloud.

### Documentation
- **`index.qmd`** / **`index.html`** - Quarto-generated project documentation explaining the implementation, challenges, and design decisions.

## Packages Used

- **RAG**: `ragnar` package for vector store management
- **LLM**: OpenAI GPT-4 via `ellmer` package
- **UI**: `shinychat` for conversational interface
- **Web Scraping**: `rvest` and `httr` for data collection
- **Deployment**: Posit Connect Cloud

## Quick Start

```r
# 1. Set up environment variables with your OpenAI API key
readRenviron(".Renviron")

# 2. Build the vector store (optional - already included)
source("build_store.r")

# 3. Run the app locally
shiny::runApp("app.R")
```

## Limitations

- Only 18 most recent episodes included in vector store (deployment size constraints)
- Some episodes lack transcripts (142/218 episodes)
- Requires OpenAI API key for embeddings and chat
