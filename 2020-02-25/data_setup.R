library(readr)
library(rvest)
library(dplyr)
library(stringr)
library(purrr)
library(here)
library(curl)
library(httr)
library(skimr)
############################# Set Proxy #############################
config_proxy <- use_proxy(
  url = curl::ie_get_proxy_for_url("https://mran.microsoft.com/"), 
  auth = "ntlm", 
  username = ""
)
set_config(config_proxy)


# Get the Data

measles <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-02-25/measles.csv')


url_wsj <- "https://raw.githubusercontent.com/WSJ/measles-data/master/all-measles-rates.csv"

wsj <- read_csv(url_wsj)

list_of_urls <- "https://github.com/WSJ/measles-data/tree/master/individual-states"

raw_states <- list_of_urls %>% 
  read_html() %>% 
  html_table() %>% 
  .[[1]] %>% 
  select(Name) %>% 
  mutate(Name = str_remove(Name, "\\.csv")) %>% 
  filter(str_length(Name) > 3, str_length(Name) < 20) %>% 
  pull(Name)

all_states <- glue::glue("https://raw.githubusercontent.com/WSJ/measles-data/master/individual-states/{raw_states}.csv") %>% 
  map(read_csv)

clean_states <- all_states %>% 
  map(~select(., state, name, lat, lng)) %>% 
  map(~mutate_at(., vars(lat, lng), as.numeric)) %>% 
  bind_rows() %>% 
  filter(!is.na(lat))

wsj %>% 
  left_join(clean_states, by = c("name", "state")) %>% 
  write_csv(here::here("2020-02-25","measles_raw.csv"))
write_csv(measles,here::here("2020-02-25","measles.csv"))
glimpse(wsj)
skimr::skim(measles)
