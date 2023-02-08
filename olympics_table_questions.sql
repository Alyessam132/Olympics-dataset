SELECT * FROM olympics_history LIMIT 10 ;

CREATE VIEW olympics_history_dist as (
SELECT DISTINCT games,sport,event,medal,noc
FROM olympics_history ) ;

CREATE VIEW team_medal as (
SELECT nr.region as country, 
SUM(CASE WHEN ohd.medal = 'gold' then 1 else 0 end) as gold,
SUM(CASE WHEN ohd.medal = 'silver' then 1 else 0 end) as silver,
SUM(CASE WHEN ohd.medal = 'bronze' then 1 else 0 end) as bronze
FROM olympics_history_dist ohd
JOIN olympics_history_noc_regions nr
ON nr.noc = ohd.noc
GROUP BY nr.region
ORDER BY 2 DESC, 3 DESC , 4 DESC ) ; 

CREATE VIEW game_team_medal as (
SELECT ohd.games as games, nr.region as country, 
SUM(CASE WHEN ohd.medal = 'gold' then 1 else 0 end) as gold,
SUM(CASE WHEN ohd.medal = 'silver' then 1 else 0 end) as silver,
SUM(CASE WHEN ohd.medal = 'bronze' then 1 else 0 end) as bronze
FROM olympics_history_dist ohd
JOIN olympics_history_noc_regions nr
ON nr.noc = ohd.noc
GROUP BY nr.region, ohd.games
ORDER BY 1, 2 ) ;

## 1. How many olympics games have been held?
SELECT count(distinct games) as no_olympic_games
FROM olympics_history ;

## 2.List down all Olympics games held so far.
SELECT distinct year, season, city
FROM olympics_history 
ORDER BY year;


## 3.Mention the total no of nations who participated in each olympics game?
SELECT count(distinct nr.region) as no_of_nations, oh.games
FROM olympics_history oh
JOIN olympics_history_noc_regions nr
ON nr.noc = oh.noc
GROUP BY oh.games
ORDER BY oh.games;

## 4.Which year saw the highest and lowest no of countries participating in olympics?
with nations as 
(SELECT count(distinct nr.region) as no_of_nations, oh.games
FROM olympics_history oh
JOIN olympics_history_noc_regions nr
ON nr.noc = oh.noc
GROUP BY oh.games 
)

SELECT distinct
 concat( first_value(games) over ( order by no_of_nations ASC), " - " , 
first_value(no_of_nations) over ( order by no_of_nations ASC) )as lowest_countries,

concat( first_value(games) over ( order by no_of_nations DESC), " - " , 
first_value(no_of_nations) over ( order by no_of_nations DESC) )as highest_countries
FROM nations ;

# 5.Which nation has participated in all of the olympic games?
SELECT nations, no_participations
FROM
(
SELECT *,
rank() over(PARTITION BY nations ORDER by games) as no_participations
FROM
(
SELECT distinct nr.region as nations, oh.games
FROM olympics_history oh
JOIN olympics_history_noc_regions nr
ON nr.noc = oh.noc
ORDER BY oh.games
) na_table
) nation_rank
WHERE no_participations = (SELECT count(distinct games) as no_olympic_games FROM olympics_history) ;

# Identify the sport which was played in all summer olympics.

SELECT sport, no_participations
FROM
(
SELECT *, rank() over(PARTITION BY sport ORDER by games) as no_participations
FROM
(
SELECT distinct sport, games
FROM olympics_history
where season = 'summer'
) sp_table
) sport_rank
WHERE no_participations = (SELECT count(distinct games) as no_olympic_games FROM olympics_history where season = 'summer') ;


#7. Which Sports were just played only once in the olympics

with sp_table as (SELECT sport, count(distinct games) as no_of_games
FROM olympics_history
GROUP BY sport),

gm_table as  (SELECT distinct games,  sport
FROM olympics_history
GROUP BY sport)

SELECT sp.sport, sp.no_of_games, gm.games
FROM sp_table sp
JOIN gm_table gm on sp.sport=gm.sport and sp.no_of_games = 1
ORDER by 1 ;

# 8. Fetch the total no of sports played in each olympic games.
SELECT count(distinct sport) as no_of_sports, games
FROM olympics_history
GROUP BY games
ORDER by 1 DESC ;

# 9. Fetch oldest athletes to win a gold medal
SELECT *
FROM olympics_history
where medal = 'gold' and age = (SELECT max(age) FROM olympics_history where medal = 'gold' and age != 'NA') ;

# 10. Find the Ratio of male and female athletes participated in all olympic games.
with sex_count as(SELECT sex, count(distinct name) as no_of_athletes
FROM olympics_history
GROUP BY sex)

SELECT concat('1 : ', max(no_of_athletes)/min(no_of_athletes)) as female_male_ratio
FROM sex_count ;

# 11. Fetch the top 5 athletes who have won the most gold medals.
## Dense Rank here is used to list all the players who have the same number of medals 
SELECT name, team, no_of_golds
FROM
(
SELECT *, dense_rank() over (ORDER BY no_of_golds DESC) as gold_rank
FROM
(
SELECT name, team, count(medal) as no_of_golds
FROM olympics_history
where medal = 'gold'
GROUP BY name, team
) gold_names
) gold_rank_table
WHERE gold_rank <= 5 ;
# 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT name, team, no_of_medals
FROM
(
SELECT *, dense_rank() over (ORDER BY no_of_medals DESC) as medal_rank
FROM
(
SELECT name, team, count(medal) as no_of_medals
FROM olympics_history
where medal != 'NA'
GROUP BY name, team
) medal_names
) medal_rank_table
WHERE medal_rank <= 5 ;


# 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.


with team_medal_count as 
(SELECT nr.region as country, count(ohd.medal) as no_of_medals
FROM olympics_history_dist ohd
JOIN olympics_history_noc_regions nr
ON nr.noc = ohd.noc
where ohd.medal <> 'NA'
GROUP BY nr.region),

team_medal_rank as 
(
SELECT *,
rank() over (ORDER BY no_of_medals DESC) as medal_rank
FROM team_medal_count
)

SELECT *
FROM team_medal_rank
WHERE medal_rank <= 5 ;

# 14. List down total gold, silver and bronze medals won by each country.

SELECT *
FROM team_medal ;



# 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

SELECT *
FROM game_team_medal ;

# 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

SELECT DISTINCT games, 
concat(FIRST_VALUE(country) over (partition by games order by gold DESC), " - ", FIRST_VALUE(gold) over (partition by games order by gold DESC)) as max_gold,
concat(FIRST_VALUE(country) over (partition by games order by silver DESC), " - ", FIRST_VALUE(silver) over (partition by games order by silver DESC)) as max_silver,
concat(FIRST_VALUE(country) over (partition by games order by bronze DESC), " - ", FIRST_VALUE(bronze) over (partition by games order by bronze DESC)) as max_bronze
FROM game_team_medal 
ORDER BY games ;

# 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.


with game_team_total as ( 
SELECT * , gold+silver+bronze as total_medal
FROM game_team_medal)

SELECT DISTINCT games, 
concat(FIRST_VALUE(country) over (partition by games order by gold DESC), " - ", FIRST_VALUE(gold) over (partition by games order by gold DESC)) as max_gold,
concat(FIRST_VALUE(country) over (partition by games order by silver DESC), " - ", FIRST_VALUE(silver) over (partition by games order by silver DESC)) as max_silver,
concat(FIRST_VALUE(country) over (partition by games order by bronze DESC), " - ", FIRST_VALUE(bronze) over (partition by games order by bronze DESC)) as max_bronze,
concat(FIRST_VALUE(country) over (partition by games order by total_medal DESC), " - ", FIRST_VALUE(total_medal) over (partition by games order by total_medal DESC)) as max_total
FROM game_team_total ;


# 18. Which countries have never won gold medal but have won silver/bronze medals?

SELECT *
FROM team_medal 
WHERE gold = 0 and (bronze > 0 or silver > 0)
ORDER BY silver DESC, bronze DESC ;


# 19. In which Sport/event, India has won highest medals.
with india_medals as (SELECT nr.region as country, ohd.sport, count(ohd.medal) as no_of_medals
FROM olympics_history_dist ohd
JOIN olympics_history_noc_regions nr
ON nr.noc = ohd.noc
where ohd.medal <> 'NA' and nr.region = 'india'
GROUP BY nr.region, ohd.sport)

SELECT DISTINCT first_value(sport) OVER (ORDER BY no_of_medals DESC) as sport ,
first_value(no_of_medals) OVER (ORDER BY no_of_medals DESC) as no_of_medals
FROM india_medals ;

# 20 Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
SELECT nr.region as country, ohd.sport, ohd.games, count(ohd.medal) as no_of_medals
FROM olympics_history_dist ohd
JOIN olympics_history_noc_regions nr
ON nr.noc = ohd.noc
where ohd.medal <> 'NA' and nr.region = 'india' and ohd.sport = 'hockey'
GROUP BY nr.region, ohd.sport, ohd.games
ORDER BY ohd.games ;
