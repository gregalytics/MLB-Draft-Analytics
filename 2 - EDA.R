# EDA 

format_plot <- theme_bw() +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1)) 

## Signed ----

# View Draft Picks Signed by Draft Year 

draft_year_summary <- picks %>%
  group_by(person_draft_year) %>% 
  summarise(signed = sum(did_sign, na.rm = TRUE),
            n = n(),
            sign_pct = signed/n,
            made_mlb = sum(did_make_mlb),
            made_mlb_of_signed = made_mlb / signed) 

mutate(picks, signed = ifelse(is.na(signed), "No", signed)) %>% 
  ggplot(aes(x = as.factor(person_draft_year), fill = signed)) +
  geom_bar() +
  labs(title = "Draft Picks and Signings by Draft Year", x = "Draft Year", y = "Draftees") +
  format_plot

# Expand analysis to account for school type and position ----

draft_year_type_summary <- picks %>%
  mutate(is_pitcher = ifelse(draft_position == "P", "Pitcher", "Batter")) %>% 
  group_by(person_draft_year, draft_school_type, is_pitcher) %>% 
  summarise(signed = sum(did_sign, na.rm = TRUE),
            n = n(),
            sign_pct = signed/n,
            made_mlb = sum(did_make_mlb),
            made_mlb_of_signed = made_mlb / signed) %>% 
  arrange(desc(person_draft_year))

## Made MLB? ----

# Made MLB by School Type and Batter/Pitcher - not too useful

filter(picks, signed == "Yes", draft_school_type %in% c("High School", "College")) %>% 
  ggplot(aes(x = person_draft_year, fill = made_mlb)) +
  geom_bar() +
  facet_grid(is_pitcher ~ draft_school_type) +
  labs(title = "Chart of Draftees Making MLB by School Type and Position", x = "Draft Year") +
  format_plot
  

# Same chart - filter to first five rounds (160 in 2020, so let's go with that) 

filter(picks, signed == "Yes", draft_school_type %in% c("High School", "College"),
       pick_number <= 160) %>% 
  ggplot(aes(x = person_draft_year, fill = made_mlb)) +
  geom_bar() +
  facet_grid(is_pitcher ~ draft_school_type) +
  labs(title = "First 5 Rounds Draftees Making MLB, By School Type and Position", x = "Draft Year", y = "Draftees") +
  format_plot


# Top 50 picks

filter(picks, signed == "Yes", draft_school_type %in% c("High School", "College"),
       pick_number <= 50) %>% 
  ggplot(aes(x = person_draft_year, fill = made_mlb)) +
  geom_bar() +
  facet_grid(is_pitcher ~ draft_school_type) +
  labs(title = "Top 50 Picks", x = "Draft Year", y = "Draftees") +
  format_plot

# Table for Top 50 picks that signed

picks %>% 
  filter(signed == "Yes", pick_number <= 50, person_draft_year <= 2015,
         draft_school_type %in% c("College", "High School")) %>% 
  group_by(is_pitcher, draft_school_type) %>% 
  summarise(mlb = sum(did_make_mlb),
            n = n(),
            pct = mlb/n) %>% 
  ungroup() %>% 
  gt() %>% 
  tab_header(
    title = "Percentage of Top 50 Picks to Make MLB",
    subtitle = "1990-2015, pre-2021"
  ) %>% 
  fmt_percent(columns = "pct") %>% 
  cols_label(is_pitcher = "Position",
             draft_school_type = "School Type",
             mlb = "Made MLB",
             n = "Signed",
             pct = "Percent")

## Rankings ----

# Compare Ranks for Guys ranked 50 or less 

ranks %>% 
  spread(key = source, value = rank) %>% 
  arrange(year, `Baseball America`) %>% 
  filter(!is.na(`MLB Pipeline`)) %>% 
  filter(`Baseball America` <= 100 | `MLB Pipeline` <= 100) %>% 
  ggplot(aes(x = `Baseball America`, y = `MLB Pipeline`)) +
  geom_point() + 
  facet_wrap(~year, scales = "free") +
  scale_x_reverse() + 
  scale_y_reverse() +
  labs(title = "Disparity Between BA and MLB.com Draft Rankings") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))


# Both are similar in amount of pitchers in top 50 by year
ranks %>% 
  inner_join(picks, by = c("year" = "person_draft_year", "key_mlbam" = "person_id")) %>% 
  select(key_mlbam, year, rank = rank.x, person_full_name, person_primary_position_name, source) %>% 
  mutate(is_pitcher = ifelse(person_primary_position_name == "Pitcher", "Pitcher", "Batter")) %>% 
  filter(rank <= 50, year >= 2011) %>% 
  group_by(year, source, is_pitcher) %>% 
  summarise(n = n()) %>% 
  filter(is_pitcher == "Pitcher") %>% 
  spread(key = source, value = n) %>% 
  ungroup() %>% 
  select(-is_pitcher) %>% 
  gt() %>% 
  tab_header(title = "Pitchers in Top 50") %>% 
  cols_label(year = "Year")

# Both are similar in how many college players they rank in top 50
ranks %>% 
  inner_join(picks, by = c("year" = "person_draft_year", "key_mlbam" = "person_id")) %>% 
  select(key_mlbam, year, rank = rank.x, person_full_name, person_primary_position_name, source, draft_school_type) %>% 
  filter(rank <= 50,
         year >= 2011) %>% 
  group_by(year, source, draft_school_type) %>% 
  summarise(n = n()) %>% 
  filter(draft_school_type == "College") %>% 
  spread(key = source, value = n) %>% 
  ungroup() %>% 
  select(-draft_school_type) %>% 
  gt() %>% 
  tab_header(title = "College Players in Top 50") %>% 
  cols_label(year = "Year")



# Years to debut plot - inspired by Namita Nandakumar
## https://github.com/namitanandakumar/Draft-Analysis/blob/master/Prospect%20TImelines/RITHAC%20Slides.pdf

picks %>% 
  filter(signed == "Yes", pick_round %in% c("1", "CBA", "2", "CBB", "2C", "3", "4", "5"), person_draft_year <= 2010,
         person_draft_year >= 2000,
         draft_school_type %in% c("High School", "College")) %>% 
  mutate(years_to_debut = ifelse(years_to_debut >= 6, 6, years_to_debut)) %>% 
  group_by(pick_round, years_to_debut, draft_school_type, is_pitcher) %>% 
  summarise(mlb = n()) %>%
  group_by(pick_round, is_pitcher, draft_school_type) %>% 
  mutate(draftees = sum(mlb),
         years_to_debut = ifelse(is.na(years_to_debut), "No MLB", as.character(years_to_debut)),
         pct = mlb/draftees * 100,
         pick_round = case_when(
           pick_round == "1" ~ "1st",
           pick_round == "2" ~ "2nd",
           pick_round == "3" ~ "3rd",
           pick_round == "4" ~ "4th",
           pick_round == "5" ~ "5th"
         )) %>% 
  ggplot(aes(x = pct, y = pick_round, fill = fct_rev(years_to_debut))) +
  geom_bar(position = "stack", stat = "identity") +
  scale_x_continuous(breaks = seq(0, 100, 10)) +
  facet_grid(draft_school_type ~ is_pitcher) +
  labs(x = "% of Top 5 Round Picks, 2000-2010", y = "Round", title = "Time Until MLB Debut by Position and School Type",
       fill = "Seasons Needed") +
  theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5))
