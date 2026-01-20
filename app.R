library(shiny)
library(shinychat)
library(ellmer)
library(ragnar)
library(bslib)

# For Posit Cloud: API key should be set in Project Options > Environment Variables
# For local development: uncomment the line below and create a .Renviron file
# readRenviron(".Renviron")

messages <- '
🎙️ **Hello, R enthusiast!** I\'m your friendly R Weekly Highlights podcast assistant! 

I\'ve listened to episodes 200-217 so you don\'t have to search through hours of content. Ask me anything about what Eric and Mike discussed!
⚠️ Whilst RAG with llm is powerful, it might not always ahve the correct answer. Please check out the episodes directly for more details!

💡 **Try these to get started:**

* <span class="suggestion">🎯 Who are the hosts and where can I find them?</span>
* <span class="suggestion">🐍 What did Mike and Eric say about Python and R working together in episode 217?</span>
* <span class="suggestion submit">📦 Tell me about cool packages they mentioned in episode 204</span>
'

# Custom theme matching the podcast logo colors
app_theme <- bs_theme(
  bg = "#F8F9FA",           # Light gray background instead of pure white
  fg = "#2C3E50",
  primary = "#9B59B6",      # Purple (from the stars)
  secondary = "#F39C12",    # Orange (from the stars)
  success = "#27AE60",      # Green (from the stars)
  info = "#3498DB",
  base_font = font_google("Open Sans"),
  heading_font = font_google("Roboto"),
  font_scale = 1.0
)

# UI
ui <- page_fillable(
  theme = app_theme,
  # Add custom CSS for fun background
  tags$head(
    tags$style(HTML("
      body {
        background: linear-gradient(135deg, #E8F5F7 0%, #F5E8F7 25%, #FFF4E6 50%, #E8F7E8 75%, #E8F5F7 100%);
        background-attachment: fixed;
      }
      .card {
        box-shadow: 0 4px 6px rgba(155, 89, 182, 0.1), 0 1px 3px rgba(243, 156, 18, 0.08);
        border: none;
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(10px);
      }
      .suggestion {
        background: linear-gradient(90deg, #9B59B6 0%, #F39C12 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.3s ease;
      }
      .suggestion:hover {
        transform: scale(1.05);
        filter: brightness(1.2);
      }
    "))
  ),
  card(
    card_header(
      tags$div(
        style = "background: linear-gradient(135deg, #9B59B6 0%, #F39C12 50%, #27AE60 100%); 
                 color: white; 
                 padding: 10px; 
                 border-radius: 5px;
                 font-weight: bold;",
        icon("podcast", style = "margin-right: 8px;"),
        "R Weekly Podcast Chat",
        tooltip(
          icon("wand-magic-sparkles", style = "color: white; margin-left: 10px;"), 
          "Powered by RAG (Retrieval Augmented Generation) to search through R Weekly Highlights podcast episodes 200-217 transcripts!"
        )
      ),
      class = "d-flex justify-content-between align-items-center"
    ),
    chat_ui(
      id = "chat",
      messages = messages
    )
  ),
  fillable_mobile = TRUE
)

# Server
server <- function(input, output, session) {
  # Connect to the store inside the server function
  store <- ragnar_store_connect("rweeklypodcast.ragnar.duckdb", read_only = TRUE)
  
  # Initialize chat with OpenAI
  chat <- chat_openai(
    system_prompt = "You are an enthusiastic and friendly assistant who loves the R Weekly Highlights podcast! 
    You have access to all podcast transcripts through a RAG tool. 
    Use the tool to find relevant information before answering questions.
    
    When answering:
    - Be conversational and fun, like you're chatting with a fellow R enthusiast
    - Cite specific episode numbers when possible (e.g., 'In episode 217, Eric mentioned...')
    - If Eric or Mike said something funny or interesting, share that!
    - Use emojis occasionally to keep things light 😊
    - Keep answers concise but informative"
  )
  
  # Register the RAG store as a tool
  ragnar_register_tool_retrieve(chat, store)
  
  # Handle user input
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)
