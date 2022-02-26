#' Raw poop tracker csv data wrangling and output to JSON for webpage
#'
#' Load a few functions
#' Import data
#' Create json

library(tidyverse)

# functions ---
english_date <- function(date){
  
  day <-
    lubridate::day(date) %>% 
    scales::ordinal()
  
  month_year <- 
    format(date, '%B %Y')
  
  paste(day, month_year)
  
}

get_often_values <- function(x, var, threshold_prob, format_hour = F){
  
  collapse <- function(x){
    if (length(x) > 1) {
      paste(x, collapse = ' to ')
    } else {
      x
    }
  }
  
  var = rlang::enquo(var)
  
  x_selected <-
    x %>% 
    filter(prob > threshold_prob) %>% 
    arrange(!!var)
  
  if (nrow(x_selected) > 1 ){
    x_selected = slice(x_selected, c(1, n()))
  }
  
  x_vars <- 
    x_selected %>% 
    pull(!!var)
  
  if (format_hour) {
    x_vars <- sprintf('%02d%s', x_vars, '00')
  }
  
  x_vars %>% 
    collapse()
}


# data ---
file_in <- rev(list.files('raw-data/', full.names = T))[1]

poops <- readr::read_csv(file_in)

# * n ----
min_date_english <- english_date(min(poops$date))
max_date_english <- english_date(max(poops$date))

n_days <-
  poops$date %>% 
  as.Date() %>% 
  range() %>% 
  diff() %>% 
  as.numeric()

n_months <- 
  round(n_days / 30.5, digits = 0)

n_years <-
  round(n_days / 365.25, digits = 2)

n_poops <- nrow(poops)

# * plot data ----
# ** Poops per day
daily <-
  poops %>% 
  mutate(day = as.Date(date)) %>% 
  count(day, name = 'poops') %>% 
  complete(day = seq.Date(from = min(day),
                          to = max(day),
                          by = 'day'),
           fill = list(poops = 0)) %>% 
  count(poops) %>% 
  mutate(prob = n / sum(n) * 100,
         prob = round(prob, 1))

likely_n_poop <-
  daily %>% 
  slice(which.max(n)) %>% 
  pull(poops) %>% 
  as.character() %>% 
  switch('0' = 'less than once',
         '1' = 'once',
         '2' = 'twice',
         '3' = 'three or more times')

poop_rate <- round(n_poops / n_days, 1)

# ** Poops per hour
hourly <-
  poops %>% 
  mutate(hour = lubridate::hour(date)) %>% 
  count(hour) %>% 
  complete(hour = seq(1:23),
           fill = list(n = 0)) %>% 
  arrange(hour) %>% 
  mutate(prob = n / sum(n) * 100,
         prob = round(prob, 1))

likely_poop_time <-
  hourly %>% 
  slice(which.max(n)) %>% 
  pull(hour) %>% 
  sprintf('%02d%s', ., '00')

often_poop_time <-
  hourly %>% 
  get_often_values(var = hour, threshold_prob = 10, format_hour = T)

# ** Poop size
size <-
  poops %>% 
  mutate(quantity = sub('Very Large', 'Very-Large', quantity),
         quantity = factor(quantity, 
                           levels = c('Small', 'Small-Medium',
                                      'Medium', 'Medium-Large', 
                                      'Large', 'Very-Large'))) %>% 
  count(quantity) %>% 
  mutate(prob = n / sum(n) * 100,
         prob = round(prob, 1))

often_poop_size <-
  size %>% 
  get_often_values(var = quantity, threshold_prob = 30)

# ** Poop type
type_map <- 
  tibble(type = paste('Type', 1:7),
         label = c('Hard lumps', 'Lumpy sausage', 'Cracked sausage',
                   'Smooth sausage', 'Soft blobs', 'Mushy', 'Liquid'))

type <-
  poops %>% 
  mutate(type = factor(type, 
                       levels = type_map$type,
                       labels = type_map$label)) %>% 
  count(type) %>% 
  complete(type,
           fill = list(n = 0)) %>% 
  mutate(prob = n / sum(n) * 100,
         prob = round(prob, 1))

often_poop_type <-
  type %>% 
  get_often_values(var = type, threshold_prob = 50)


# ** Poop places
place <-
  poops %>% 
  filter(as.Date(date) > '2020-05-01' &
           !is.na(notes)) %>% 
  mutate(place = case_when(
    grepl('^[Hh]ome', notes) ~ 'Home',
    grepl('^[Ww]ork', notes) ~ 'Work',
    grepl('[Mm]other|[Nn]icole', notes) ~ 'Family',
    TRUE ~ 'Other'),
    place = factor(place, levels = c('Home', 'Work', 'Family', 'Other'))) %>% 
  count(place) %>% 
  mutate(prob = n / sum(n) * 100,
         prob = round(prob, 1))

often_poop_place <-
  place %>% 
  get_often_values(var = place, threshold_prob = 50)

# toJson ----

# * break labels for chartJS
size <-
  size %>% 
  mutate(quantity = 
           as.character(quantity) %>%
           strsplit(split = '-'))
type <-
  type %>% 
  mutate(type = 
           as.character(type) %>%
           strsplit(split = ' '))

# * values for text
list(start_date = min_date_english,
     end_date = max_date_english,
     n_days = paste(n_days, 'days'),
     n_months = paste(n_months, 'months'),
     n_years = paste(n_years, 'years'),
     n_poops = n_poops,
     likely_n_poop = likely_n_poop,
     poop_rate = paste(poop_rate, 'poops per day'),
     likely_poop_time = likely_poop_time,
     often_poop_time = often_poop_time,
     often_poop_size = often_poop_size,
     often_poop_type = often_poop_type,
     often_poop_place = often_poop_place,
     daily = daily,
     hourly = hourly,
     size = size,
     type = type,
     place = place) %>% 
  jsonlite::toJSON(dataframe = 'columns') %>% 
  writeLines('web/data/poop_data.json')

