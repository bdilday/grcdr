
library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)

hr_data = function(conn = NULL, df=NULL) {

  if (is.null(conn)) {
    conn <- dbConnect(
      RPostgres::Postgres(),
      password=Sys.getenv("PSQL_PASS"),
      user=Sys.getenv("PSQL_USER"),
      port=Sys.getenv("PSQL_PORT"),
      dbname='retrosheet')
  }

  if (is.null(df)) {
    df = dbGetQuery(conn, 'select * from daybyday_playing_primary ')
  }


  dfX = df %>%
    filter(season_phase == 'R') %>%
    select(game_key:B_CS) %>%
    mutate(season=lubridate::year(game_date),
           k=paste(person_key, season, sep='_'))

  top9_df = data.frame(
    k = c(
      "ruthb101_1927",
      "ruthb101_1921",
      "marir101_1961",
      "mantm101_1961",
      "mcgwm001_1987",
      "mcgwm001_1998",
      "bondb001_2001",
      "stanm004_2017",
      "judga001_2017"
    ),
    stringsAsFactors = FALSE
  )

  name_df = Lahman::Master %>%
    select(nameLast, nameFirst, retroID) %>%
    mutate(nameAbbv = stringr::str_sub(nameFirst, 1, 1)) %>%
    mutate(nameKey=paste(nameAbbv, nameLast, sep='.')) %>%
    rename(person_key = retroID) %>%
    select(person_key, nameKey)


  plot_df = dfX %>%
    merge(top9_df) %>%
    merge(name_df, by="person_key")

  plot_df = plot_df %>%
    mutate(B_PA = ifelse(is.na(B_PA), B_AB+B_BB, B_PA)) %>%
    mutate(k = paste(nameKey, season)) %>%
    group_by(k) %>%
    arrange(k,game_date) %>%
    mutate(i=row_number()) %>%
    ungroup



}

rs_ra_data = function(conn = NULL, df=NULL) {

  if (is.null(conn)) {
    conn <- dbConnect(
      RPostgres::Postgres(),
      password=Sys.getenv("PSQL_PASS"),
      user=Sys.getenv("PSQL_USER"),
      port=Sys.getenv("PSQL_PORT"),
      dbname='retrosheet')
  }

  if (is.null(df)) {
    df = dbGetQuery(conn, 'select * from daybyday_teams_primary')
  }

  dfX = df %>%
    filter(season_phase == 'R') %>%
    select(game_key:p_r) %>%
    mutate(season=lubridate::year(game_date),
           k=paste(team_key, season, sep='_'))

  dfX = dfX %>% filter(season>=1975)

  top4_df = data.frame(
    k = c(
      "CLE_1999",
      "NYA_1998",
      "HOU_2017",
      "MIL_1982"
      ),
    stringsAsFactors = FALSE
  )


  plot_df = dfX %>%
    merge(top4_df, by="k")

  plot_df = plot_df %>%
    group_by(k) %>%
    arrange(k,game_date) %>%
    mutate(season_game_number=row_number()) %>%
    ungroup

}

sim_data = function () {

  set.seed(101)
  ngroup = 4
  npt = 100

  x1 = rnorm(ngroup * npt)
  x2 = rnorm(ngroup * npt)
  g1 = rep(letters[1:ngroup], each=npt)

  t1 = rep(1:npt, ngroup)

  t2 = as.vector(
    do.call(cbind, lapply(1:ngroup, function(i) {
      sample(1:npt, npt)
    }))
  )

  t3 = as.vector(
    do.call(cbind, lapply(1:ngroup, function(i) {
      sample(1:(10*npt), npt)
    }))
  )

  df1 = data.frame(x1 = x1,
                   x2 = x2,
                   g1 = g1,
                   t1 = t1,
                   t2 = t2,
                   t3 = t3
  )

}


