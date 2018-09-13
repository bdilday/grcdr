
library(dplyr)
library(ggplot2)
set.seed(101)
df1 = data.frame(x1 = rnorm(100), x2 = rnorm(100))
df1$x3 = with(df1, x1**2 + abs(x2))
df1$x4 = 100 * df1$x1 ** 2

df1 %>% ggplot(aes(x=x1, y=x2, x3=x3)) + geom_tailscatter()
