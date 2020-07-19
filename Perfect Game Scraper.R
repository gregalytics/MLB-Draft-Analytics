library(rvest)
library(purrr)
library(tidyverse)
library(furrr)
library(tictoc)
library(naniar)
library(RMySQL)
library(RODBC)

conn <- dbConnect(MySQL(), user='root', password='root', host='127.0.0.1', db= 'mlb_draft', port=8889)
on.exit(dbDisconnect(conn))

scrape_pg_player_summary <- function(playerID) {
  url <- paste0("https://www.perfectgame.org/Players/PlayerProfile.aspx?ID=", playerID)
  text_xml <- read_html(url)
  
  noder <- function(page, node) {
    node_content <- html_text(html_nodes(page, node))
    ifelse(length(node_content) == 0, NA, node_content)
  }
  
  tibble(playerID = playerID,
         player_name = noder(text_xml, "#ContentPlaceHolder1_lblPlayerName"),
         pg_events = noder(text_xml, "#spnEventNum"),
         pg_awards = noder(text_xml, "#ContentPlaceHolder1_lbTrophies"),
         college_reports = noder(text_xml, "#ContentPlaceHolder1_lbCollegeReports"),
         position = noder(text_xml, "#ContentPlaceHolder1_lblPos"),
         hometown = noder(text_xml, "#ContentPlaceHolder1_lblHomeTown"),
         hs_grad = noder(text_xml, "#ContentPlaceHolder1_lblHSGrad"),
         high_school = noder(text_xml, "#ContentPlaceHolder1_lblHS"),
         commitment = noder(text_xml, "#ContentPlaceHolder1_hl4yearCommit"),
         draft_date = noder(text_xml, "#ContentPlaceHolder1_lblRecentDraftedDate"),
         draft_age = noder(text_xml, "#ContentPlaceHolder1_lblAgeOnDraft"),
         fb_velo = noder(text_xml, "#ContentPlaceHolder1_lblPGEventResultsFB"),
         fb_velo_bump = noder(text_xml, "#ContentPlaceHolder1_lblProgressFB"),
         exit_velo = noder(text_xml, "#ContentPlaceHolder1_lblPGEventResultsExitVelo"),
         barrel_speed = noder(text_xml, "#ContentPlaceHolder1_lblMaxBarrelSpeed"),
         impact_momentum = noder(text_xml, "#ContentPlaceHolder1_lblImpactMomentum"),
         dash_60_yard = noder(text_xml, "#ContentPlaceHolder1_lblPGEventResults60"),
         split_10_yard = noder(text_xml, "#ContentPlaceHolder1_lblPGEventResults10"),
         max_acceleration = noder(text_xml, "#ContentPlaceHolder1_lblMaxAcceleration"),
         ranking_note = noder(text_xml, "#ContentPlaceHolder1_lblRankingNote"),
         scouting_report = noder(text_xml, "#ContentPlaceHolder1_lblLatestReport"),
         best_pg_grade = noder(text_xml, "#ContentPlaceHolder1_lblBestPGGrade"),
         national_rank = noder(text_xml, "#ContentPlaceHolder1_lblNationalRank"),
         national_pos_rank = noder(text_xml, "#ContentPlaceHolder1_lblNationalPosRank"),
         state_of_rank = noder(text_xml, "#ContentPlaceHolder1_hlStateRankings"),
         state_rank = noder(text_xml, "#ContentPlaceHolder1_lblStateRank"),
         state_pos_rank = noder(text_xml, " #ContentPlaceHolder1_lblStatePos"),
         height = noder(text_xml, "#ContentPlaceHolder1_lblHt"),
         weight = noder(text_xml, "#ContentPlaceHolder1_lblWt"),
         bat_throw = noder(text_xml, "#ContentPlaceHolder1_lbl"),
         
  )
}

plan(multisession(workers = 7))

children_9 <- future_map(800001:850000, scrape_pg_player_summary, .progress = TRUE)
children_8 <- future_map(800000:750000, scrape_pg_player_summary, .progress = TRUE)
children_7 <- future_map(749999:700000, possibly(scrape_pg_player_summary, NULL), .progress = TRUE)
children_6 <- future_map(699999:600000, possibly(scrape_pg_player_summary, NULL), .progress = TRUE)
children_5 <- future_map(599999:400000, possibly(scrape_pg_player_summary, NULL), .progress = TRUE)
children_4 <- future_map(399999:200000, possibly(scrape_pg_player_summary, NULL), .progress = TRUE)
children_3 <- future_map(199999:1, possibly(scrape_pg_player_summary, NULL), .progress = TRUE)

cmen <- bind_rows(children_9)
all_the_children <- bind_rows(children_3, children_4, children_5, children_6, children_7, children_8, children_9) %>% 
  filter(!is.na(player_name))

children <- 
  all_the_children %>% 
  separate(draft_date, into = c("draft_round", "draft_year"), sep = "-") %>% 
  separate(height, into = c("height_feet", "height_inches"), sep = "-") %>% 
  separate(hometown, into = c("home_city", "home_state"), sep = ",") %>% 
  separate(state_of_rank, into = c("state", "trash1", "trash2"), sep = " ") %>% 
  mutate(height = as.numeric(height_feet) * 12 + as.numeric(height_inches),
         pg_events = as.numeric(pg_events),
         hs_grad = parse_number(hs_grad),
         pg_awards = parse_number(pg_awards),
         home_state = str_trim(home_state, side = "both"),
         draft_round = parse_number(draft_round),
         draft_year = parse_number(draft_year),
         fb_velo = as.numeric(fb_velo),
         exit_velo = as.numeric(exit_velo),
         barrel_speed = as.numeric(barrel_speed),
         impact_momentum = as.numeric(impact_momentum),
         fb_velo_bump = parse_number(fb_velo_bump),
         college_reports = parse_number(college_reports),
         dash_60_yard = as.numeric(dash_60_yard),
         split_10_yard = as.numeric(split_10_yard),
         max_acceleration = as.numeric(max_acceleration),
         weight = parse_number(weight),
         best_pg_grade = as.numeric(best_pg_grade),
         national_rank_status = case_when(
           as.numeric(national_rank) > 1 & national_rank != "Top 1000" ~ "Ranked",
           TRUE ~ as.character(national_rank)
         ),
         state_rank = as.numeric(state_rank),
         national_pos_rank = as.numeric(national_pos_rank),
         national_rank = as.numeric(national_rank)
  ) %>% 
  replace_with_na(replace = list(high_school = "NA",
                                 national_rank_status = "NR",
                                 national_pos_rank = c("NR", "NA"),
                                 state_rank = c("NR", ""),
                                 state_pos_rank = "NR",
                                 ranking_note = "",
                                 home_city = "")) %>% 
  select(playerID, player_name, best_pg_grade, pg_events, pg_awards, college_reports, 
         draft_round, draft_year, draft_age, home_city, 
         home_state, hs_grad, high_school, commitment,
         position, height, weight, 
         national_rank, national_rank_status, state, state_rank, 
         fb_velo, fb_velo_bump, exit_velo, barrel_speed, impact_momentum, dash_60_yard, split_10_yard,
         max_acceleration, ranking_note, scouting_report) %>% 
  rename(player_id = playerID) %>% 
  arrange(player_id) 

dbWriteTable(conn, 'perfect_game_player_summary', children, overwrite=T, row.names = FALSE)



