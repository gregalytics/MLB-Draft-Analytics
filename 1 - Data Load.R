##  Data load  ----
library(gt)
library(tidyverse)
library(tidylog)
library(lubridate)
library(caret)
library(tidymodels)
library(readr)
library(baseballr)
library(ConsRank)
library(readxl)
library(ggridges)
library(DMwR)

# Set working directory
setwd("~/Documents/MLB Draft Analytics")

## TBC ----
# Load batting data and correct Miami - Miami OH situation
tbc_batting <- read_csv("tbc_batting.csv") %>% 
  mutate(tm = ifelse(lg %in% c("IndyNCAA", "MAC") & tm == "Miami", "Miami-OH", tm)) 

tbc_pitching <- read_csv("tbc_pitching.csv") %>% 
  mutate(tm = ifelse(lg %in% c("IndyNCAA", "MAC") & tm == "Miami", "Miami-OH", tm)) 

# Load pitching
tbc_data <- bind_rows(tbc_batting, tbc_pitching)

# Get MLB Debut Year
pro_debuts <- tbc_data %>% 
  filter(lvl %in% c("Rk", "A-", "A", "A+", "AA", "AAA", "MLB")) %>% 
  group_by(mlb_id) %>%
  mutate(season = 1:n()) %>% 
  select(mlb_id, lvl, year) %>% 
  summarise(pro_debut = min(year))

# Function to use Bill Petti's baseballr function to 

## Draft Data ----
get_draft_mlb_2 <- function(yr) {
  get_draft_mlb(yr) %>% 
    mutate(person_draft_year = yr)
}

# Import tbc draft information - has more accurate info on players signing with their teams

draft_info <- read_csv("draft_info.csv") %>% 
  mutate(draft_overall = as.numeric(draft_overall),
         draft_year = as.numeric(draft_year)
  ) 

# Merge draft and signing information - merge IDs 
picks <- map_df(1990:2020, get_draft_mlb_2) %>% 
  mutate(school_class = case_when(
    str_detect(school_name, "HS") ~ "HS",
    str_detect(school_name, "JC") | str_detect(school_name, "CC") | str_detect(school_name, "Junior College") ~ "JC/CC",
    TRUE ~ as.character("NCAA")),
    person_mlb_debut_date = date(person_mlb_debut_date),
    debut_year = year(person_mlb_debut_date),
    years_to_debut = debut_year - person_draft_year,
    made_mlb = ifelse(!is.na(person_mlb_debut_date), "Yes", "No")) %>% 
  arrange(person_id, desc(person_draft_year)) %>% 
  group_by(person_id) %>% 
  mutate(time_picked_ago = row_number()) %>% 
  ungroup() %>% 
  arrange(desc(person_draft_year), pick_number) %>% 
  left_join(draft_info, by = c("person_draft_year" = "draft_year", "pick_number" = "draft_overall")) %>% 
  mutate(did_sign = ifelse(signed == "Yes", 1, 0),
         did_make_mlb = ifelse(made_mlb == "Yes" & did_sign == 1, 1, 0),
         is_pitcher = ifelse(draft_position == "P", "Pitcher", "Batter")
  )


## Boyd Park Factors ----

# Load Home/total Park Factors from Boyds Baseball
boyd_park_factors <- read_excel("boyd_park_factors.xlsx") %>% 
  separate(tmp, into = c("pf", "extra"), sep = " ", extra = "merge") %>% 
  mutate(extra = trimws(extra, "left")) %>% 
  separate(extra, into = c("tpf", "college"), extra = "merge") %>% 
  mutate(pf = as.numeric(pf),
         tpf = as.numeric(tpf)) %>% 
  arrange(college, desc(season))

# DF of school seasons
ncaa_teams_tbc <- tbc_data %>% 
  filter(lvl %in% c("NCAA-1", "NCAA-2", "NCAA-2", "NCAA-3", "NJCAA", "NAIA", "NWAAC", "CCCAA")) %>% 
  select(tm, year) %>% 
  distinct() 

# Modify School Names such that they match TBC

boyd_park_fct <- boyd_park_factors %>% 
  mutate(college = case_when(
    college == "Albany" ~ "SUNY - Albany",
    college == "Arkansas-Little Rock" ~ "Ark-Little Rock",
    college == "Austin Peay State" ~ "Austin Peay",
    college == "Baker" ~ "Baker University",
    college == "Bryant" ~ "Bryant University",
    college == "Buffalo" ~ "University at Buffalo",
    college == "Colby" ~ "Colby College",
    college == "Canisius" ~ "Canisius College",
    college == "Centenary" ~ "Centenary College",
    college == "Central Connecticut State" ~ "Centenary College",
    college == "Colorado-Colorado Springs" ~ "Colorado Springs",
    college == "Concordia (AL)" ~ "Concordia College",
    college == "Coppin State" ~ "Coppin State College",
    college == "CSU Bakersfield" ~ "Cal State Bakersfield",
    college == "Davidson" ~ "Davidson College",
    college == "Florida International" ~ "Florida Intl",
    college == "Cal State Sacramento" ~ "Sacramento State",
    college %in% c("Huston Tillotson", "Huston-Tillotson") ~ "Huston-Tillotson College (Texas)",
    college == "Indiana-Kokomo" ~ "Indiana University-Kokomo",
    college == "Iona" ~ "Iona College",
    college == "IPFW" ~ "Indiana U.-Purdue U.-FW",
    college == "Lafayette" ~ "Lafayette College",
    college == "LaSalle" ~ "La Salle",
    college == "LeMoyne" ~ "Le Moyne",
    college %in% c("LIU Brooklyn", "LIU-Brooklyn", "Long Island") ~ "Long Island-Brooklyn",
    college == "Louisiana State" ~ "LSU",
    college == "Maryland-Baltimore County" ~ "UMD-Baltimore Cty",
    college == "Manhattan" ~ "Manhattan College",
    college == "Loyola (LA)" ~ "Loyola University",
    college == "Marian" ~ "Marian U",
    college == "Miami, Florida" ~ "Miami",
    college == "Miami, Ohio" ~ "Miami-OH",
    college == "Middle Tennessee State" ~ "Middle Tenn State",
    college == "Mississippi Valley State" ~ "Miss. Valley St",
    college == "Nebraska-Omaha" ~ "Nebraska at Omaha",
    college == "Nevada-Las Vegas" ~ "UNLV",
    college == "North Carolina A&T" ~ "NC A&T State",
    college == "North Carolina State" ~ "NC State",
    college == "North Carolina-Asheville" ~ "UNC Asheville",
    college == "North Carolina-Charlotte" ~ "UNC Charlotte",
    college == "North Carolina-Greensboro" ~ "UNC-Greensboro",
    college == "North Carolina-Wilmington" ~ "UNC Wilmington",
    college == "Parkside" ~ "UW Parkside",
    college == "Presbyterian" ~ "Presbyterian College",
    college == "Siena" ~ "Siena College",
    college == "South Carolina-Upstate" ~ "USC-Upstate",
    college == "Southeast Missouri State" ~ "SE Missouri State",
    college == "Southeastern Louisiana" ~ "SE Louisiana",
    college == "Southern California" ~ "USC",
    college == "Southern Illinois-Edwardsville" ~ "SIU-Edwardsville",
    college == "Southern Mississippi" ~ "Southern Miss",
    college == "Southwest Missouri State" ~ "Missouri State",
    college == "Southwest Texas State" ~ "Texas State",
    college == "St. Francis" ~ "St. Francis (NY)",
    college == "St. Joseph's" ~ "St. Joseph's College",
    college == "St. Louis" ~ "Saint Louis",
    college == "St. Peter's" ~ "Saint Peter's",
    college == "Stephen F. Austin State" ~ "Stephen F. Austin",
    college == "Texas-Rio Grande Valley" ~ "Rio Grande",
    college == "Troy State" ~ "Troy",
    college == "Union (TN)" ~ "Union U",
    college %in% c("Utah Valley", "Utah Valley State") ~ "Utah Valley U",    
    college == "Virginia Commonwealth" ~ "Va. Commonwealth",
    college %in% c("Virginia Military", "VMI") ~ "Va Military Inst.",
    college == "Wabash" ~ "Wabash College",
    college == "Waldorf" ~ "Waldorf College",
    college == "Wisconsin-Milwaukee" ~ "UW Milwaukee",
    TRUE ~ as.character(college)
  )) %>% 
  left_join(ncaa_teams_tbc, by = c("college" = "tm", "season" = "year")) %>% 
  group_by(college, season) %>% 
  mutate(instance = row_number()) %>% 
  filter(instance == 1) %>% 
  select(-instance) %>% 
  ungroup()

## Rankings ----

# Baseball America
ranks_ba <- read_csv("ranks_ba.csv") %>% 
  mutate(key_mlbam = case_when(
    player_name == "C.J. Abrams" ~ 682928,
    player_name == "J.J. Bleday" ~ 668709,
    player_name == "J.J. Goss" ~ 683101,
    player_name == "Carson Montgomery" ~ 691000,
    player_name == "D.J. Stewart" ~ 621466,
    player_name == "D.J. LeMahieu" ~ 518934,
    player_name == "J.R. Murphy" ~ 571974,
    player_name == "Jeremy Hazel- baker" ~ 571757,
    player_name == "D.L. Hall" ~ 669084,
    player_name == "Jackie Bradley" ~ 598265,
    player_name == "Ti'quan Forbes" ~ 656431,
    player_name == "Dwight Smith Jr." ~ 596105,
    player_name == "Lineras Torres Jr." ~ 678013,
    player_name == "A.J. Reed" ~ 607223,
    player_name == "M.J. Melendez" ~ 669004,
    player_name == "Delino DeShields Jr." ~ 592261,
    player_name == "K.J. Harrison" ~ 656508,
    player_name == "Riley Cornelio" ~ 683000,
    player_name == "J.J. Schwarz" ~ 656943,
    player_name == "Derick Velasquez" ~ 621164,
    player_name == "Simeon Woods-Richardson" ~ 680573,
    player_name == "J.T. Chargois" ~ 608638,
    # player_name == ""
    TRUE ~ as.numeric(key_mlbam) 
  )) #%>% 
#filter(is.na(key_mlbam), year != 2020) %>% 
# arrange(rank)

# MLB Pipeline 

ranks_pipeline <- read_csv("ranks_pipeline.csv", 
                           col_types = cols(X1 = col_skip()))

# Keith Law Rankings and Reports

law <- read_csv("~/Downloads/keith_law_big_boards.csv")

# Combine rankings 

ranks <- bind_rows(ranks_ba, ranks_pipeline) %>% 
  group_by(year, key_mlbam, source) %>%
  mutate(player_ranked = 1:n()) %>% 
  filter(player_ranked == 1) %>% 
  ungroup() %>% 
  select(-player_ranked, -player_name) 

## Reports ----

scouting_reports_ba <- read_csv("scouting_reports_ba.csv") %>% 
  mutate(key_mlbam = case_when(
    name == "C.J. Abrams" ~ 682928,
    name == "J.J. Bleday" ~ 668709,
    name == "J.J. Goss" ~ 683101,
    name == "Carson Montgomery" ~ 691000,
    name == "D.J. Stewart" ~ 621466,
    name == "D.J. LeMahieu" ~ 518934,
    name == "J.R. Murphy" ~ 571974,
    name == "Jeremy Hazel- baker" ~ 571757,
    name == "D.L. Hall" ~ 669084,
    name == "Jackie Bradley" ~ 598265,
    name == "Ti'quan Forbes" ~ 656431,
    name == "Dwight Smith Jr." ~ 596105,
    name == "Lineras Torres Jr." ~ 678013,
    name == "A.J. Reed" ~ 607223,
    name == "M.J. Melendez" ~ 669004,
    name == "Delino DeShields Jr." ~ 592261,
    name == "K.J. Harrison" ~ 656508,
    name == "Riley Cornelio" ~ 683000,
    name == "J.J. Schwarz" ~ 656943,
    name == "Derick Velasquez" ~ 621164,
    name == "Simeon Woods-Richardson" ~ 680573,
    name == "J.T. Chargois" ~ 608638,
    TRUE ~ as.numeric(key_mlbam) 
  ))

