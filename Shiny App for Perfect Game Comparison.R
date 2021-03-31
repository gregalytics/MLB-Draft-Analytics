
library(shiny)
library(rsconnect)

load("~/Dropbox/Statcast Code/PG_Shiny_App/Workspace.RData")

server <- function(input, output) {

  filtered_df <- reactive(hitter_percentiles %>% 
                      filter(player_name == input$Player))
  
  filtered_similarity <- reactive(similarity_table %>% 
                                    filter(player_name == input$Player))
  
  
  output$plot_similarity <- renderPlot({
    plot_pg_results(input$Player)
  })
  
  output$comp_table <- render_gt(
    pg_player_similarity(input$Player)
  )
}

ui <- fluidPage(
  titlePanel("Perfect Game Workout Results and Similarity"),
  sidebarPanel(
    selectInput('Player', 'Pick a Player', unique(hitter_percentiles$player_name))
  ),
  mainPanel(
    plotOutput("plot_similarity"),
    gt_output("comp_table")
  )
)

shinyApp(ui, server)

rsconnect::setAccountInfo(name='gregalytics', 
                          token='4C247DEA83136AB1BD529E2A6C784057', 
                          secret='jkr2deU2LVdWrbTMywltygljHGHDGTVQEDj1EbKT')

rsconnect::deployApp()

