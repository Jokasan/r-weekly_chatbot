library(tidyverse)
library(ragnar)

# Load all transcripts
episodes <- read.csv("/Users/joka/Documents/R_projects/r-weekly_chatbot/episodes_w_transcripts.csv")

# Prepare data - get ALL transcripts

episodes |> 
  arrange(desc(ep_date)) |> 
  select(ep_transcript) |> 
  na.omit() |>
  head(18)-> to_parse

cat(sprintf("Found %d transcripts to process\n", nrow(to_parse)))

# Chunk all transcripts at once by passing the vector
all_chunks <- markdown_chunk(to_parse$ep_transcript, target_size = 100)

# Create persistent store with file path
store <- ragnar_store_create(
  "rweeklypodcast.ragnar.duckdb", 
  embed = embed_openai(model = "text-embedding-3-small"),
  overwrite = TRUE
)

# Insert ALL chunks (this will call OpenAI API for embeddings - may take a while!)
ragnar_store_insert(store, all_chunks)

# Build the index
ragnar_store_build_index(store)

# Test retrieval directly
test_result <- ragnar_retrieve(
  store,
  text = "Who are the hosts?"
)
print(test_result)

# Disconnect the store to release the lock (don't shutdown, just disconnect)
rm(store)
gc()
