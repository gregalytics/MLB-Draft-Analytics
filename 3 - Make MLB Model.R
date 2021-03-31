# Clean divisions such that all are modern. For Divisions other than D1, the division "lvl" is fine.
# Also compute pitch count estimate, total batters faced, k and bb pct, etc.

college_pitching <- tbc_pitching %>% 
  filter(lvl %in% c("NCAA-1", "NCAA-2", "NCAA-3", "NJCAA", "NAIA", "NWAAC", "CCCAA")) %>% 
  mutate(lg = case_when(
    lg == "Big8" ~ "Big12",
    lg == "Pac10" ~ "Pac12",
    lg == "Socon" ~ "SoCon",
    lg == "NYSBC" ~ "AmEast",
    lg %in% c("WCAC", "Ill-Conf", "EAA", "MWCity", "Yankee", "Plains", "EIBL", "AMCU", "BigSky",
              "AmSou", "CIBA", "SCBA", "GMWC", "ECC1", "NCBA", "NAC", "ECAC", "PCAA", "MWCC", "Pac8", "Metro", "Trans",
              "SWC", "GWC", "MCC", "AAC") ~ "NCAA-1-Other",
    lvl == "NCAA-1" & !lg %in% c("Big8", "Pac10", "Socon", "NYSBC") ~ lg,
    TRUE ~ as.character(lvl)
  )) %>% 
  mutate(pitch_count_est = 3.3 * (3*ip + h + bb) + 1.5 * so + 2.2 * bb,
         tbf = 3 * floor(ip) + 10 * (ip %% 1) + h + bb + hb,
         k_pct = so / tbf,
         bb_pct = bb / tbf,
         baa = h/(tbf - bb - hb),
         babip = (h - hr) / (tbf - bb - hb - so - hr),
         major_leaguer = as.factor(ifelse(`High Level` == "Major Leagues", "MLB", "No_MLB"))) %>% 
  select(major_leaguer, player_name, tm, exp, tbc_id, mlb_id, lg, lvl, year, age, org,
         g, gs, ip, tbf, pitch_count_est, tbf, k_pct, bb_pct, babip, ra9, baa) %>% 
  left_join(select(boyd_park_fct, college, season, tpf, pf), by = c("tm" = "college", "year" = "season"))  %>% 
  filter(tbf < 2000) %>% 
  mutate(tpf = ifelse(is.na(tpf), 100, tpf),
         pf = ifelse(is.na(pf), 100, pf),
         start_pct = gs/g)

# Filter for 30 innings and more recent seasons
pitching_college <- college_pitching %>% 
  filter(ip >= 30, year <= 2015, year >= 2000) %>% 
  mutate(lg = as.factor(lg))

pitching_college_2 <- college_pitching %>% 
  filter(ip >= 30, year >= 2000) %>% 
  mutate(lg = as.factor(lg))

# Correlation plot of college pitcher stats
pitching_college %>% 
  select(k_pct, bb_pct, babip, ra9, baa, tpf, pitch_count_est) %>% 
  rename(`K%` = k_pct, `BB%` = `bb_pct`, BABIP = babip, RA9 = ra9, BAA = baa, `Park Factor` = tpf, `Pitch Count` = pitch_count_est) %>% 
  cor() %>% 
  ggcorrplot(hc.order = TRUE,
             outline.color = "white",
             lab = TRUE,
             title = "Correlations Between College Pitching Stats") 

# Train on 2000-2010, test on 2011-2015
pitching_train <- pitching_college %>% filter(year <= 2010)
pitching_test <- pitching_college %>% filter(year > 2010)

# Train Control - Classification problem - Make MLB or not 
pitching_control <- trainControl(method = "cv",
                                 number = 5,
                                 summaryFunction = twoClassSummary,
                                 classProbs = TRUE)


# Pitching Random Forest
pitching_ranger <- train(major_leaguer ~ k_pct + bb_pct + baa + age + lg + tpf + ra9 + ip + tbf + babip,
                         data = pitching_train,
                         method = "ranger",
                         preProcess = c("scale", "center"),
                         importance = "permutation",
                         trControl = pitching_control
)


# Pitching Random Forest with Upsampling
pitching_ranger_up <- train(major_leaguer ~ k_pct + bb_pct + baa + age + lg + tpf + ra9 + ip + tbf + babip,
                            data = pitching_train,
                            method = "ranger",
                            preProcess = c("scale", "center"),
                            importance = "permutation",
                            trControl = trainControl(method = "cv",
                                                     number = 5,
                                                     summaryFunction = twoClassSummary, 
                                                     sampling = "up",
                                                     classProbs = TRUE)
)

# Pitching Random Forest with Downsampling

pitching_ranger_down <- train(major_leaguer ~ k_pct + bb_pct + baa + age + lg + tpf + ra9 + ip + tbf + babip,
                            data = pitching_train,
                            method = "ranger",
                            preProcess = c("scale", "center"),
                            importance = "permutation",
                            trControl = trainControl(method = "cv",
                                                     number = 5,
                                                     summaryFunction = twoClassSummary, 
                                                     sampling = "down",
                                                     classProbs = TRUE)
)

# With SMOTE 

pitching_ranger_smote <- train(major_leaguer ~ k_pct + bb_pct + baa + age + lg + tpf + ra9 + ip + tbf + babip,
                             data = pitching_train,
                             method = "ranger",
                             preProcess = c("scale", "center"),
                             importance = "permutation",
                             trControl = trainControl(method = "cv",
                                                      number = 5,
                                                      summaryFunction = twoClassSummary, 
                                                      sampling = "smote",
                                                      classProbs = TRUE)
)


# Compare models 

rangers <- list(orig = pitching_ranger,
                down = pitching_ranger_down,
                up = pitching_ranger_up,
                smote = pitching_ranger_smote)

ranger_resamples <- resamples(rangers)
summary(ranger_resamples)

# Get test set AUC
get_auc <- function(model, data) {
  library(Metrics)
  
  # Predict class probabilities on the test data
  preds <- predict(model, data, type = "prob")[, "MLB"]
  
  # Calculate and return AUC value
  auc(data$major_leaguer == "MLB", preds)
}

#Test set AUC's
auc_values <- sapply(rangers, get_auc, data = pitching_test)
print(auc_values)


# Variable Importance 
varImp(pitching_ranger_up)$importance %>% 
  as.data.frame() %>% 
  rownames_to_column(var = "var") %>% 
  arrange(desc(Overall)) %>% 
  head(15) %>% 
  mutate(var = case_when(
    var == "k_pct" ~ "K%",
    var == "ip" ~ "IP",
    var == "baa" ~ "BAA",
    var == "tbf" ~ "Batters Faced",
    var == "ra9" ~ "RA9",
    var == "age" ~ "Age",
    var == "babip" ~ "BABIP",
    var == "bb_pct" ~ "BB%",
    var == "tpf" ~ "Park Factor",
    str_detect(var, "lg") ~ substr(var, 3, nchar(var)),
    TRUE ~ as.character(var)
  )) %>% 
  ggplot(aes(x = reorder(var, Overall), y = Overall)) +
  coord_flip() +
  geom_linerange(aes(ymin = 0, ymax = Overall), size = 1.5, color = 'grey') +
  geom_point(size = 3, color = 'black') +
  scale_x_discrete(expand = c(0.05, 0.05)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) + 
  labs(x = 'Variable',
       y = 'Variable Importance',
       title = "Variable Importance of Pitching Make MLB Model - Random Forest with Upsampling") +
  theme_bw()

# View predictions on test set
pitching_test %>% 
  mutate(pred = predict(pitching_ranger_up, pitching_test, type = "prob")$MLB)

# 
pitching_predictions_2000 <- pitching_college_2 %>% 
  filter(year >= 2000) %>% 
  mutate(pred = predict(pitching_ranger_up, pitching_college_2, type = "prob")$MLB) %>% 
  arrange(desc(pred))

# Top 10 college seasons
pitching_predictions_2000 %>% 
  select(player_name, year, tm, lg, g, gs, ip, ra9, k_pct, bb_pct, baa, pred) %>% 
  head(10) %>% 
  gt() %>% 
  fmt_percent(columns = vars(k_pct, bb_pct, pred)) %>% 
  fmt_number(columns = vars(baa), decimals = 3) %>% 
  cols_label(player_name = "Player",
             year = "Season",
             tm = "Team",
             lg = "League",
             g = "Games",
             gs = "Starts",
             ip = "Innings",
             ra9 = "RA9",
             k_pct = "K%",
             bb_pct = "BB%",
             baa = "BAA",
             pred = "Prob MLB"
             ) %>% 
  tab_header("Top 10 College Pitching Season by MLB Likelihood") %>% 
  gt::cols_align(align = "center")
  

