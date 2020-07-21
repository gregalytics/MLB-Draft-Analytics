# MLB-Draft-Analytics
Attempting to make a dent in public MLB Draft Analytics through statistics and text analytics

# Perfect Game Scrapers
Perfect Game is an invaluable resource to the baseball scouting community, with reports and data on over 10,000 drafted baseball players and hundreds of thousands of others. The majority of top draft prospects and high-end college baseball players participate in PG Events. 

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





