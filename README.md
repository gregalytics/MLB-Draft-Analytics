# MLB-Draft-Analytics
Attempting to make a dent in public MLB Draft Analytics through statistics and text analytics. My overarching goal is to be able to compare the abundant text reports, scouting reports, and stats from a variety of (open) sources and decipher between these data sources to create an informed pre-draft prediction of players. The inspiration for this project is [Text Mining of Scouting Reports as a Novel Data Source
for Improving NHL Draft Analytics](https://pdfs.semanticscholar.org/2f0a/a4de57e251846b55de8792e5b5ef97264cfc.pdf) by Seppa, Schuckers, Rovito.

# EDA
Filtering for the top 50 picks in the draft from 1990-2015, over 70% of college pitchers and batters made the MLB, while high school batters and pitchers made it close to 60% of the time. Batters have a slight bump over pitchers. 

![image](https://user-images.githubusercontent.com/23176357/113215767-37f7bc00-9230-11eb-925d-80122c3f349f.png)


![image](https://user-images.githubusercontent.com/23176357/113215405-a5efb380-922f-11eb-90f8-1ad8a09332c9.png)

MLB.com and Baseball America generally agree early on at the top of the draft, but disagree as each approach the bottom of their top 100.

Neither Baseball America nor MLB.com have a major bias in pitching or college players.

![image](https://user-images.githubusercontent.com/23176357/113216106-b6ecf480-9230-11eb-8016-dfc58afd7cf4.png)

![image](https://user-images.githubusercontent.com/23176357/113216233-da17a400-9230-11eb-95ba-762727af18c0.png)

College players unsurpringly reach the MLB quicker than high schoolers, where a good portion of college players reach the bigs in 2-4 years, while high schoolers take 3-5 more frequently. There is also a good contingent of college pitchers that reach the MLB the year after being drafted. Further research with survival modeling could provide better insights into time to MLB.

![image](https://user-images.githubusercontent.com/23176357/113216275-ef8cce00-9230-11eb-8b29-d14a4da3ae1a.png)

# College Pitcher Make MLB Model

I have developed a stats-only based model to predict if a college pitcher will make the MLB based off of only one season of pitching. I trained on NCAA stats at all levels from 2000-2010, and tested on future data with 2011-2015 data. 

The data is heavily imbalanced, as most pitchers do not reach the MLB, so I used a random forest with upsampling to predict if a pitcher will reach at least one game. Stats used were strikeout and walk percentages, RA9, Batting Average Against, Total Park Factor from BoydsWorld.com, innings pitched, conference, and age. 

Evaluating some of these stats, there is a negative correlation between strikeout rate and RA9 and BAA. BB% has a positive correlation with RA9. 

![image](https://user-images.githubusercontent.com/23176357/113217225-77bfa300-9232-11eb-8c30-0244bd8096b7.png)

The most important variables in predicting if a pitcher will reach the majors or not are the statistical categories, highlighted by K% and BAA, with the SEC, Pac12, and Big12 coming up as some of the most important divisions in NCAA baseball.

![image](https://user-images.githubusercontent.com/23176357/113218009-a722df80-9233-11eb-85a1-749d46562d5d.png)

Based off of single seasons, here are the top 10 single seasons in MLB likelihood. Jered Weaver has two of the top 10 seasons, as he was an excellent starter at Long Beach State. Further needs to be done to blend multiple seasons together in the likelihood of making the majors, but this is a decent starting point. 

![image](https://user-images.githubusercontent.com/23176357/113217656-13511380-9233-11eb-9fba-a38780ca3b2c.png)

After I figure a way to weight each season in predicting reaching the MLB, I will then add text analytics (sentiment) and structured "unstructured" data (throws fastball, slider, curveball, arm slot, etc.) in predicting if pitchers will make the MLB or not. This doesn't necessarily players will be great major leaguers, so I will extend the analysis to account for a player's first 6-year WAR, and also may change the cutoff from just making the MLB to pitching 100 innings in the MLB. 


# Perfect Game Scrapers
[Perfect Game](https://www.perfectgame.org/default.aspx)  is an invaluable resource to the baseball scouting community, with reports and data on over 10,000 drafted baseball players and hundreds of thousands of others. The majority of top draft prospects and high-end college baseball players participate in PG Events. 

I have written two scrapers. The first is built on rvest to look through a wide number of potential ID's to find if players exist there, and scrape static information that you first see when looking at the page. 

For example, here is what Austin Riley's page looks like when you first enter:

![image](https://user-images.githubusercontent.com/23176357/88014467-dcd3ce00-cad3-11ea-8f41-90121a4e01e3.png)

scrape_pg_player_summary goes to his page, and extracts all of his latest information. My script changes data types upon completion of scraping many player ID's, and I have included code to upload to a MySQL Database.

```r
scrape_pg_player_summary(346538)
```

![image](https://user-images.githubusercontent.com/23176357/88014942-ef023c00-cad4-11ea-8c6c-50c0ff60e89c.png)

While this is useful information, Austin Riley has attended 11 Perfect Game Events, and as someone who wishes to evaluate talent, I want to see how Riley has progressed through these events, and get access to all his written reports to compare to other sources. However, this requires dynamic web scraping, powered by RSelenium.

![image](https://user-images.githubusercontent.com/23176357/88015433-ff66e680-cad5-11ea-9a4b-cb7491b744a6.png)

The Perfect Game scraper clicks on the "Events" tab, and collects all of the information there. On the bucket list is to scrape the tabular stat information, which does require a Diamondkast subscription.

![image](https://user-images.githubusercontent.com/23176357/88015995-53be9600-cad7-11ea-9821-09edd4e47033.png)





