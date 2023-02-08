DROP TABLE IF EXISTS OLYMPICS_HISTORY;

CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
    id          INT,
    name        VARCHAR(255),
    sex         VARCHAR(255),
    age         VARCHAR(255),
    height      VARCHAR(255),
    weight      VARCHAR(255),
    team        VARCHAR(255),
    noc         VARCHAR(255),
    games       VARCHAR(255),
    year        INT,
    season      VARCHAR(255),
    city        VARCHAR(255),
    sport       VARCHAR(255),
    event       VARCHAR(255),
    medal       VARCHAR(255)
);





DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_REGIONS;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS
(
    noc         VARCHAR(255),
    region      VARCHAR(255),
    notes       VARCHAR(255)
);



