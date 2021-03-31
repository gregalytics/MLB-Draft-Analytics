library(tm)
library(tidyverse)
library(tidylog)
library(qdap)
library(RWeka)
library(wordcloud)
library(rJava)
library(tau)
library(tidytext)

# 

reports_ba <- scouting_reports_ba %>% mutate(person_draft_year = year(report_date))

# Get scouting reports for drafted players
picks_with_reports <- picks %>% 
  dplyr::inner_join(reports_ba, by = c("person_id" = "key_mlbam", "person_draft_year")) %>% 
  select(person_draft_year, person_id, person_full_name, person_last_name, pick_number, is_pitcher, did_sign, draft_school_type,
         did_make_mlb, is_pitcher, report) 


## 

picks_with_reports$report <- removeWords(picks_with_reports$report, stopwords("en")) %>% 
  stemDocument()

picks_with_reports$report <- mapply(gsub, pattern = picks_with_reports$person_last_name, x = picks_with_reports$report, replacement = "")

college_pitcher_ngrams <- picks_with_reports %>% 
  filter(draft_school_type == "College", is_pitcher == "Pitcher") %>% 
  unnest_tokens(output = "words", input = "report", token = "ngrams", n = 3)

# Initiate term-document matrix
college_pitcher_ngrams %>% 
  count(person_id, words) %>% 
  cast_tdm(term = words, document = person_id, value = n, weighting = tm::weightTf)


#Search all 3-word combinations that have the word fastball

tops_terms <- c("tops", "top", "reach", "reached", "reaches")
fastball_ngrams <- 
  college_pitcher_ngrams %>% 
  select(person_id, person_full_name, words) %>% 
  filter(str_detect(words, "fastball")) 