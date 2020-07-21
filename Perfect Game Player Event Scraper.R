library(RSelenium)
library(rvest)
library(tidyverse)
library(furrr)

setwd("~/Dropbox/Statcast Code")

# Connect to Docker https://www.docker.com/products/docker-desktop

rD <- rsDriver(browser="firefox", port=5295L, verbose=F)
remDr$open() 
remDr <- rD[["client"]]

# Credentials for Perfect Game, helps performance 
user <- list("<ENTER YOUR USERNAME>")
pwd <- list("<ENTER YOUR PASSWORD>")

remDr$navigate("https://www.perfectgame.org/") 

# Enter credentials using selenium, clicks privacy policy button

remDr$findElement(using = 'css selector', "button.dropdown-toggle")$clickElement()
remDr$findElement(using = 'css selector', "button.dropdown-toggle")$clickElement()
remDr$findElement(using = 'css selector', "#HeaderTop_tbGreen")$sendKeysToElement(user)
remDr$findElement(using = 'css selector', "#HeaderTop_tbDarkBlue")$sendKeysToElement(pwd)
remDr$findElement(using = 'css selector', "#HeaderTop_btnGoldSilver")$clickElement()
remDr$findElement(using = 'css selector', ".cc-btn")$clickElement()

# Scrapes a players individual events
    #1) Looks at how many events player has in element #spnEventNum
    #2) Scrapes through that number of events for all possible metrics
       #** There will be nulls
scrape_pg_events <- function(playerID) {
  
  player_id <- playerID
    url <- paste0("https://www.perfectgame.org/Players/Playerprofile.aspx?ID=", player_id)
    
    remDr$navigate(url)
    remDr$findElement(using = 'css selector', "#ContentPlaceHolder1_lbEvents")$clickElement()
    remDr$findElement(using = 'css selector', "#ContentPlaceHolder1_lbEvents")$clickElement()
    remDr$findElement(using = 'css selector', "#ContentPlaceHolder1_lbEvents")$clickElement()
    
    Sys.sleep(8)
    pg_page_source <- remDr$getPageSource()[[1]]
    pg_html <- read_html(pg_page_source)
    
    
    noder <- function(page, node) {
      node_content <- html_text(html_nodes(page, node))
      ifelse(length(node_content) == 0, NA, node_content)
    }
    
    events <- noder(pg_html, "#spnEventNum") %>% as.numeric()
    seq <- seq(0, events-1)
    
    
    get_data <- function(seq) { 
      tibble(
    # Player Info -------------
        player_id = player_id,
        player_name = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblPlayerName_", seq)),
        position = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventPos_", seq)),
        height = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventHt_", seq)),
        weight = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventWt_", seq)),
        bat_throw = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblBatThrows_", seq)),
        grad_year = noder(pg_html, "#ContentPlaceHolder1_lblHSGrad"), 
        hometown = noder(pg_html, "#ContentPlaceHolder1_lblHomeTown"),
        hs = noder(pg_html, "#ContentPlaceHolder1_lblHS"),
        draft_date = noder(pg_html, "#ContentPlaceHolder1_lblRecentDraftedDate"),
        mlb_debut = noder(pg_html, "#ContentPlaceHolder1_lblDebutDate"),
        commit = noder(pg_html, "#ContentPlaceHolder1_hl4yearCommit"),
    # Event Data ---------------  
        event_name = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_hlEventName_", seq)),
        event_dates = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventDate_", seq)),
        event_location = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventLocation_", seq)),
        event_type = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventType_", seq)),
    # Player Grades -------
        overall_grade = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblEventPGGrade_", seq)),
        hit_grade = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblHitGrade_", seq)),
        power_grade = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblPowerGrade_", seq)),
        fielding_grade = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblFieldingGrade_", seq)),
        scouting_report = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblReports_", seq)),
    # Diamond Kinetics Hitting Metrics -------
        max_barrel_speed = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblMaxBarrelSpeed_", seq)),
        impact_momentum = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblImpactMomentum_", seq)),
        max_acceleration = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblMaxAcceleration_", seq)),
        hand_speed = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblHandSpeed_", seq)),
        trigger_time = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblTrigger_", seq)),
        approach_angle_fly = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblApproachAngleB1_", seq)),
        approach_angle_liner = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblApproachAngleB2_", seq)),
        approach_angle_ground = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblApproachAngleB3_", seq)),
        exit_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblPocketRadarExit_", seq)),
        zepp_bat_speed = noder(pg_html, paste0("ContentPlaceHolder1_rptEvents_lblZeppBat_", seq)),
        zepp_hand_speed = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblZeppHand_", seq)),
        zepp_impact_time = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblZeppTime_", seq)),
     # Velos, Pops, Speeds -------
        dash_60 = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lbl60_", seq)),
        dash_10 = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lbl10_", seq)),
        if_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblIF_", seq)),
        first_base_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lbl1B_", seq)),
        catcher_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblC_", seq)),
        catcher_pop = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblPop_", seq)),
        fastball_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblFB_", seq)),
        slider_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblSL_", seq)),
        changeup_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblCH_", seq)),
        fastball_range = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblRange_", seq)),
        curveball_velo = noder(pg_html, paste0("#ContentPlaceHolder1_rptEvents_lblCB_", seq))
      )
    }

map_df(seq, get_data)
}

remDr$close


