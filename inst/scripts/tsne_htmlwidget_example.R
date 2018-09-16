
library(dplyr)
library(ggplot2)
library(grcdr)
library(caret)

set.seed(101)
df1 = data.frame(x1 = rnorm(100), x2 = rnorm(100))
df1$x3 = rnorm(100)
df1$x4 = rnorm(100)
df1$id = row.names(df1)

df1$g = ifelse(df1$x1 > 0, 1, 0)
tsne_coords = c("x1", "x2", "x3", "x4")

get_data = function() {
  dfX = readr::read_csv("https://gist.github.com/bdilday/28621eb7b91f42d7b90d56475f098cf3/raw/0216fb7fe917695db4b5e90070d90dd3116a6dcf/war_data.csv")

}


transform_data = function(war_df,
                          baseline_value = 0,
                          exp_tau = 100,
                          off_def_split = 0.5,
                          max_year = 21,
                          pca=TRUE,
                          pca_scale=TRUE,
                          theta=0,
                          check_duplicates=FALSE,
                          max_iter=1000,
                          player_limit = 300)
{

  pl_lkup = Lahman::Master %>%
    select(playerID, bbrefID, nameFirst, nameLast)
  pl_lkup$nameAbbv = paste(stringr::str_sub(pl_lkup$nameFirst, 1, 1), pl_lkup$nameLast, sep='')
  hofers = Lahman::HallOfFame %>%
    filter(inducted=="Y",
           category=="Player",
           votedBy %in% c("BBWAA", "Special Election")) %>%
    arrange(desc(votedBy)) %>%
    group_by(playerID) %>%
    summarise() %>%
    ungroup() %>%
    mutate(hof=TRUE)

  pos_df = war_df %>%
    group_by(playerID, POS) %>%
    summarise() %>%
    ungroup()

  off_v = off_def_split
  def_v = (1 - off_v)

  wrk = war_df %>%
    mutate(w = off_v * WAR_off + def_v * WAR_def, w = w * 2)

  wrk = wrk %>% dplyr::select(-POS) %>%
    group_by(playerID) %>%
    arrange(-w) %>%
    mutate(war_rank = row_number())

  pl_ids = unique(war_df$playerID)
  fillin_df =
    data.frame(playerID=rep(pl_ids, each=max_year),
               war_rank=rep(1:max_year, length(pl_ids)),
               stringsAsFactors = FALSE)

  wrk = wrk %>%
    dplyr::right_join(fillin_df, by=c("playerID", "war_rank")) %>%
    dplyr::left_join(pos_df, by="playerID")

  cc = which(is.na(wrk$w))
  if (length(cc) > 0) {
    wrk[cc,]$w = 0
  }

  war_weights_df = data.frame(war_rank = 1:max_year)
  war_weights_df$weight = exp(-(war_weights_df$war_rank-1)/exp_tau)

  wrk = wrk %>%
    inner_join(war_weights_df, by="war_rank") %>%
    group_by(playerID) %>%
    mutate(z=(w * weight)) %>%
    arrange(-z) %>%
    mutate(z_rank = row_number()) %>%
    ungroup() %>%
    left_join(pl_lkup, by="playerID") %>%
    select(playerID, POS, war_rank, w) %>%
    mutate(war_rank=sprintf("WAR_%02d", war_rank)) %>%
    left_join(hofers, by="playerID") %>%
    mutate(hof = ifelse(is.na(hof), FALSE, hof))


  filter_df = wrk %>%
    group_by(playerID) %>%
    summarise(sz = sum(w)) %>%
    arrange(-sz) %>%
    head(player_limit)

  wrk = wrk %>% merge(filter_df, by="playerID") %>%
    dplyr::select(-sz) %>%
    tidyr::spread(war_rank, w)

  dum_mod = caret::dummyVars(~POS, data=wrk)
  wrk = wrk %>% cbind(predict(dum_mod, newdata=wrk)) %>% dplyr::select(-POS)
  wrk = wrk %>% merge(pl_lkup, by="playerID")

  wrk = wrk %>%
    group_by(nameAbbv) %>%
    mutate(n=row_number()) %>%
    ungroup() %>%
    mutate(a=ifelse(n==1, "", as.character(n))) %>%
    mutate(nameAbbv = paste0(nameAbbv, a)) %>%
    dplyr::select(-a, -n)

  wrk
}

