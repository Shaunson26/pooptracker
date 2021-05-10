library(shiny)
library(shinyWidgets)
library(magrittr)
library(ggplot2)

type_map <- 
  structure(.Data = paste('Type', 1:7),
            names = c('Hard lumps', 'Lumpy sausage', 'Cracked sausage',
                      'Smooth sausage', 'Soft blobs', 'Mushy', 'Liquid'),
            labels = c('Hard\nlumps', 'Lumpy\nsausage', 'Cracked\nsausage',
                       'Smooth\nsausage', 'Soft\nblobs', 'Mushy', 'Liquid'))

poops <- 
  readr::read_csv("../raw-data/export_20210414.csv") %>% 
  dplyr::mutate(week = lubridate::floor_date(date, unit = 'week') %>% as.Date(),
                hour = lubridate::hour(date)) %>% 
  dplyr::mutate(quantity = sub('Very Large', 'Very-Large', quantity),
                quantity = factor(quantity, 
                                  levels = c('Small', 'Small-Medium',
                                             'Medium', 'Medium-Large', 
                                             'Large', 'Very-Large'),
                                  labels = c('Small', 'Small\nMedium',
                                             'Medium', 'Medium\nLarge', 
                                             'Large', 'Very\nLarge'))) %>% 
  dplyr::mutate(type = factor(type, 
                              levels = type_map,
                              labels = names(type_map))) %>% 
  dplyr::filter(as.Date(date) > '2020-05-01' &
                  !is.na(notes)) %>% 
  dplyr::mutate(place = dplyr::case_when(
    grepl('^[Hh]ome', notes) ~ 'Home',
    grepl('^[Ww]ork', notes) ~ 'Work',
    grepl('[Mm]other|[Nn]icole', notes) ~ 'Family',
    TRUE ~ 'Other'),
    place = factor(place, levels = c('Home', 'Work', 'Family', 'Other'))) %>% 
  dplyr::select(type, quantity, hour, place, week)

n_poops = nrow(poops)

ui <- 
  fluidPage(style='max-width:1400px; margin:auto;',
            titlePanel('Poopy poops'),
            p('An interactive data explorer from my poop tracking journey.', 
              'Use the widgets in the sidebar to focus in on the data.'),
            sidebarLayout(
              sidebarPanel(style='border: 2px solid #87431d; background-color: white;',
                           tags$style('.irs-bar, .irs-to, .irs-from {background-color: #87431d!important;border-top:#87431d!important;border-bottom:#87431d!important;}'),
                           sliderInput("hour-slider", label = "Pooping hour", 
                                       min = 0, max = 23, value = c(0, 23)),
                           hr(),
                           prettyCheckboxGroup('type-select',label = 'Poop type',
                                               choices = levels(poops$type), selected = NULL,
                                               shape = 'round', status = 'danger',
                                               animation = 'pulse'),
                           hr(),
                           prettyCheckboxGroup('quantity-select',label = 'Poop size', 
                                               choices = levels(poops$quantity), selected = NULL,
                                               shape = 'round', status = 'danger', 
                                               animation = 'pulse'),
                           hr(),
                           prettyCheckboxGroup('place-select',label = 'Place de poop', 
                                               choices = levels(poops$place), selected = NULL,
                                               shape = 'round', status = 'danger',
                                               animation = 'pulse')
              ),
              mainPanel(
                fluidRow(plotOutput('hour'),
                         #shiny::verbatimTextOutput('test')
                ),
                fluidRow(
                  column(4, plotOutput('type')),
                  column(4, plotOutput('quantity')),
                  column(4, plotOutput('place'))
                )
              )
            )
  )


server <- function(input, output) {
  
  # Selectors ----
  hours_selected <- reactive(input$`hour-slider`)
  types_selected <- reactive(input$`type-select`)
  quantities_selected <- reactive(input$`quantity-select`)
  places_selected <- reactive(input$`place-select`)
  
  # Data ----
  poops_reactive <- reactive({
    
    subset_out <-
      poops %>% 
      dplyr::filter(hour >= hours_selected()[1] & 
                      hour <= hours_selected()[2],
                    if (is.null(types_selected())) { TRUE } 
                    else { type %in% types_selected() },
                    if (is.null(quantities_selected())) { TRUE } 
                    else { quantity %in% quantities_selected() },
                    if (is.null(places_selected())) { TRUE } 
                    else { place %in% places_selected() }
      )
    
    list(original = poops,
         subset = subset_out)
    
  })
  
  #output$test <- renderPrint({poops_reactive()})
  
  # Hour ----
  output$hour <- renderPlot({
    
    counts <-
      poops_reactive() %>% 
      lapply(function(data){
        data %>% 
          dplyr::count(hour) %>% 
          tidyr::complete(hour = 0:23, fill = list(n = NA)) %>% 
          dplyr::mutate(hour = factor(hour, levels = 0:23)) %>% 
          dplyr::arrange(hour) %>% 
          dplyr::mutate(prop = n / n_poops * 100)
      })
    
    
    axis_colour <- ifelse(!is.na(counts$subset$n), 'black', 'grey75')
    
    ggplot(counts$subset, aes(counts, x = hour, y = prop)) +
      geom_hline(yintercept = 0, size = 0.25) +
      geom_col(data = counts$original, alpha = 0.25, fill = '#87431d') +
      geom_col(fill = '#87431d') +
      scale_y_continuous(expand = expansion(mult = c(0,0.05))) +
      theme(text = element_text(size = 16),
            panel.grid.major.x = element_blank(),
            panel.grid.major.y = element_line(colour = 'grey75', size = 0.25),
            panel.grid.minor.y = element_blank(),
            panel.background = element_blank(),
            axis.ticks.y = element_line(colour = 'white'),
            plot.title.position = 'plot') +
      theme(axis.text.x = element_text(colour = axis_colour),
            axis.ticks.x = element_line(colour = axis_colour)) +
      labs(title = 'Pooping hour', x = 'Hour of day', y = 'Probability (%)')
  })
  
  output$type <- renderPlot({
    
    counts <-
      poops_reactive() %>% 
      lapply(function(data){
        data %>% 
          dplyr::count(type) %>% 
          tidyr::complete(type = names(type_map), fill = list(n = NA)) %>% 
          dplyr::mutate(type = factor(type, levels = names(type_map),
                                      labels = attributes(type_map)$labels)) %>% 
          dplyr::arrange(type) %>% 
          dplyr::mutate(prop = n / n_poops * 100)
      })
    
    axis_colour <- ifelse(!is.na(counts$subset$n), 'black', 'grey75')
    
    ggplot(counts$subset, aes(x = type, y = prop)) +
      geom_col(data = counts$original, alpha = 0.25, fill = '#87431d') +
      geom_col(fill = '#87431d') +
      scale_y_continuous(expand = expansion(mult = c(0,0.05)),
                         breaks = c(0, 30, 60)) +
      theme(text = element_text(size = 16),
            panel.grid.major.y = element_blank(),
            panel.grid.major.x = element_line(colour = 'grey75', size = 0.25),
            panel.grid.minor.x = element_blank(),
            panel.background = element_blank(),
            axis.ticks.x = element_line(colour = 'white'),
            plot.title.position = 'plot') +
      theme(axis.text.y = element_text(colour = axis_colour),
            axis.ticks.y = element_line(colour = axis_colour)) +
      coord_flip()  +
      labs(title = 'Poop type', y = '%', x = NULL)
  })
  
  output$quantity <- renderPlot({
    
    counts <-
      poops_reactive() %>% 
      lapply(function(data){
        data %>% 
          dplyr::count(quantity) %>% 
          tidyr::complete(quantity = levels(quantity), fill = list(n = NA)) %>% 
          dplyr::mutate(quantity = factor(quantity, levels = levels(poops$quantity))) %>% 
          dplyr::arrange(quantity)%>% 
          dplyr::mutate(prop = n / n_poops * 100)
      })
    
    axis_colour <- ifelse(!is.na(counts$subset$n), 'black', 'grey75')
    
    ggplot(counts$subset, aes(x = quantity, y = prop)) +
      geom_col(data = counts$original, alpha = 0.25, fill = '#87431d') +
      geom_col(fill = '#87431d') + 
      scale_y_continuous(expand = expansion(mult = c(0,0.05)),
                         breaks = c(0, 20, 40)) +
      theme(text = element_text(size = 16),
            panel.grid.major.y = element_blank(),
            panel.grid.major.x = element_line(colour = 'grey75', size = 0.25),
            panel.grid.minor.x = element_blank(),
            panel.background = element_blank(),
            axis.ticks.x = element_line(colour = 'white'),
            plot.title.position = 'plot') +
      theme(axis.text.y = element_text(colour = axis_colour),
            axis.ticks.y = element_line(colour = axis_colour)) +
      coord_flip()  +
      labs(title = 'Poop size', y = '%', x = NULL)
  })
  
  output$place <- renderPlot({
    counts <-
      poops_reactive() %>% 
      lapply(function(data){
        data %>% 
          dplyr::count(place) %>% 
          tidyr::complete(place = levels(place), fill = list(n = NA)) %>% 
          dplyr::mutate(place = factor(place, levels = levels(poops$place))) %>% 
          dplyr::arrange(place) %>% 
          dplyr::mutate(prop = n / n_poops * 100)
      })
    
    axis_colour <- ifelse(!is.na(counts$subset$n), 'black', 'grey75')
    
    ggplot(counts$subset, aes(x = place, y = prop)) +
      geom_col(data = counts$original, alpha = 0.25, fill = '#87431d') +
      geom_col(fill = '#87431d') +
      scale_y_continuous(expand = expansion(mult = c(0,0.05)),
                         breaks = c(0, 30, 60)) +
      theme(text = element_text(size = 16),
            panel.grid.major.y = element_blank(),
            panel.grid.major.x = element_line(colour = 'grey75', size = 0.25),
            panel.grid.minor.x = element_blank(),
            panel.background = element_blank(),
            axis.ticks.x = element_line(colour = 'white'),
            plot.title.position = 'plot') +
      theme(axis.text.y = element_text(colour = axis_colour),
            axis.ticks.y = element_line(colour = axis_colour)) +
      coord_flip() +
      labs(title = 'Place de poop', y = '%', x = NULL)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
