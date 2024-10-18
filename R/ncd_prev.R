library(ggplot2)
ncd <- data.frame(y=c(61,68,71,74,70),
                  x=factor(c(2000,2010,2015,2019,2023)))
ggplot(data=ncd) +
  geom_point(mapping = aes(x =x, y =y)) +
  geom_line(mapping = aes(x =1:5, y =y)) +
  xlab("Year") +
  ylab("Worldwide prevalence of NCD") +
  ylim(60,75) + theme_bw(base_size = 17)

ggsave("Figures/ncd_prev.jpg",
       limitsize = FALSE,
       width = 8.9,
       height = 5.425)