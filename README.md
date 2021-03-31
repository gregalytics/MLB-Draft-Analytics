# MLB-Draft-Analytics
Attempting to make a dent in public MLB Draft Analytics through statistics and text analytics. My overarching goal is to be able to compare the abundant text reports, scouting reports, and stats from a variety of (open) sources and decipher between these data sources to create an informed pre-draft prediction of players. The inspiration for this project is [Text Mining of Scouting Reports as a Novel Data Source
for Improving NHL Draft Analytics](https://pdfs.semanticscholar.org/2f0a/a4de57e251846b55de8792e5b5ef97264cfc.pdf) by Seppa, Schuckers, Rovito.

# Research Goal 
How can I predict major leaguers and their performance at the MLB level using publicly available (at least by paid subscription) statistics and scouting reports?

# EDA
Filtering for the top 50 picks in the draft from 1990-2015, over 70% of college pitchers and batters made the MLB, while high school batters and pitchers made it close to 60% of the time. Batters have a slight bump over pitchers. 

![image](https://user-images.githubusercontent.com/23176357/113215767-37f7bc00-9230-11eb-925d-80122c3f349f.png)


Filtering for the top 50 picks in the draft from 1990-2015, over 70% of college pitchers and batters made the MLB, while high school batters and pitchers made it close to 60% of the time. 
![image](https://user-images.githubusercontent.com/23176357/113215405-a5efb380-922f-11eb-90f8-1ad8a09332c9.png)

MLB.com and Baseball America generally agree early on at the top of the draft, but disagree as each approach the bottom of their top 100.

Neither Baseball America nor MLB.com have a major bias in pitching or college players

![image](https://user-images.githubusercontent.com/23176357/113216106-b6ecf480-9230-11eb-8016-dfc58afd7cf4.png)

![image](https://user-images.githubusercontent.com/23176357/113216233-da17a400-9230-11eb-95ba-762727af18c0.png)

College players unsurpringly reach the MLB quicker than high schoolers, where a good portion of college players reach the bigs in 2-4 years, while high schoolers take 3-5 more frequently. There is also a good contingent of college pitchers that reach the MLB the year after being drafted. 

![image](https://user-images.githubusercontent.com/23176357/113216275-ef8cce00-9230-11eb-8b29-d14a4da3ae1a.png)

# College Pitcher Make MLB Model




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





