# Run `unfao-fert-crop.R` first.
# That's where the library() calls and CSV reads live.
source('unfao-fert-crop.R')

# -- Load CSV files -------

# FAO production crops
# crops.raw.csv.df <- read.csv("csv/Production_Crops_E_All_Data_(Normalized).csv")
crops.raw.csv.df <- read.csv("csv/production_crops_expurgated.csv")

# -------~~ Clean up crop file --------
# Just since 2014
crops.df <- crops.raw.csv.df[crops.raw.csv.df$Year > 2013, ]
# Turn Value = NA to value = 0
crops.df$Value[is.na(crops.df$Value)] <- 0
# 4 digit Item.Codes are broad categories
crops.df$category <- nchar(crops.df$Item.Code) == 4
# Pad Item.Code to match FAOSTAT documentation
crops.df$Item.Code <- str_pad(crops.df$Item.Code, 4, "left", pad = "0")
# Update levels in filtered factor(s).
# summary(crops.df)
crops.df$Item <- factor(crops.df$Item)

# -------~~ File w/ crop flags ("current", "interest", etc) --------
items.df <- read.csv("csv/items.csv")
# Pad Item.Code to match FAOSTAT documentation
items.df$Item.Code <- str_pad(items.df$Item.Code, 4, "left", pad = "0")

# setdiff(crops.df$Item, items.df$Item)

# Join flags to main data frame
crops.df <- crops.df %>% left_join(items.df[,c(-2)], by = c("Item.Code" = "Item.Code"))

rm(items.df)
# crops.df$vik.flag <- fct_explicit_na(crops.df$vik.flag)

# -------~~ File w/ country flags ("APAC", etc) --------
countries.df <- read.csv("csv/countries.csv")
# Join flags to main data frame
crops.df <- crops.df %>% left_join(countries.df)
rm(countries.df)


# -- Agave ----------------

agave.df <- filter(crops.df, crops.df$Item.Code == "0800")
agave.df <- filter(agave.df, agave.df$Area.Code < 5000)
agave.df <- filter(agave.df, agave.df$Value > 0)
agave.df <- filter(agave.df, agave.df$Year == 2021)

ggplot(data = agave.df[agave.df$Element.Code == 5312,]
       , aes(y = Value, x = reorder(Area, Value), fill = Area)) +
  geom_bar(stat = "identity", alpha = 0.6) +
  geom_text(aes(x = Area, y = Value + 750 , label = Value)) +
  scale_fill_brewer(palette = "Dark2") +
  theme.base +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)
        , legend.position = "none") +
  labs(title = "Agave: global market", subtitle = "Area planted - 2021 Source: FAOSTAT"
       , y = "hectares", x = "Country") +
  coord_flip()

rm(agave.df)

# -- Broadacre - APAC-----

# Top APAC producers of Sugarcane, Potato, Corn and Rice? Area by country. (Broad Acre)
broadacre.df <- subset(crops.df, broadacre == 1) %>%
  subset(Area.Code < 5000) %>%
  subset(Value > 0) %>%
  subset(Year == 2021) %>%
  subset(Grouping == "APAC") %>%
  subset(Element.Code == 5312)


breaks.c <- seq(from = 10, to = (max(broadacre.df$Value/1000000)) , by = 10)

broadacre.df$Item <- as.character(broadacre.df$Item)
# Newest data is all "Maize (corn)"
# broadacre.df[broadacre.df$Item == 'Maize',]$Item <- "Maize (corn)"

broadacre.facet <- ggplot(data = broadacre.df
       , aes(y = Value/1000000, x = reorder(Area, Value), fill = Area)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  # geom_text(aes(x = Area, y = (Value / 1000000)
  #               # , label = round(Value / 1000000, digits = 1))
  #               , label = signif(Value / 1000000, digits = 1))
  #           , color = "#666666", nudge_y = 4
  #           ) +
  geom_hline(yintercept = breaks.c, color = "#ffffff", size = rel(0.3)) +
  scale_fill_brewer(palette = "Set3") +
  scale_y_continuous(label=comma) +
  theme.base +
  theme(title = element_text(size = 14, hjust = 0.5)
        , axis.title = element_text(size = 12)
        , axis.text = element_text(size = 12)
        , axis.text.x = element_text(hjust = 1, vjust = 0.5)
        , legend.position = "none"
        , strip.background = element_rect(fill = "#666666")
        , strip.text = element_text(colour = "#ffffff")
        # , axis.ticks.y.bottom = element_line(colour = '#666666', size = rel(1.5), linetype = 'solid')
        ) +
    labs(title = "Area harvested - 2021 Source: FAOSTAT", y = "Million Hectares", x = "Country") +
  facet_wrap(facets = vars(Item)) +
  coord_flip()

ggsave(
  filename = "apac-broadacre-area-2021-higher-res.png",
  plot = broadacre.facet,
  device = "png",
  dpi = 500
)


# rm(broadacre.df, breaks.c)

# --~~ Broadacre potential (total) ----

# Estimates from the sales director.
years.v <- c(2023, 2024, 2025, 2026, 2027, 2028)
totals.v <- c(9346, 23365, 46730, 140190, 233650, 467299)

potential.df <- data.frame(year = as.integer(years.v), total = totals.v)
breaks.c <- seq(from = 100000, to = max(potential.df$total), by = (100000))
  
broadacre.bar <- ggplot(data = potential.df
       , aes(y = total, x = year, fill = as.factor(year))) +
  geom_bar(stat = "identity", alpha = 0.7) +
  geom_text(aes(x = year, y = total + 10000 , label = comma(total)), colour = "#444444") +
  geom_hline(yintercept = breaks.c, color = "#ffffff", size = rel(0.3)) +
  scale_fill_brewer(palette = "Dark2") +
  scale_x_continuous("Year", breaks = years.v, labels = years.v) +
  scale_y_continuous("Volume (ST)", label = comma) +
  theme(title = element_text(size = 14, hjust = 0.5)
        , axis.title = element_text(size = 12)
        , axis.text = element_text(size = 12)
        , panel.border = element_blank()
        , panel.grid.major = element_blank()
        , panel.grid.minor = element_blank()
        , axis.text.x = element_text(margin = margin(-15,0,5,0))
        , axis.text.y = element_text(margin = margin(0,-20,0,0))
        , axis.ticks = element_blank()
        , legend.position = "none"
        , strip.background = element_rect(fill = "#666666")
        , strip.text = element_text(colour = "#ffffff")
  )

ggsave(
  filename = "bar-plot-potential-higher-res.png",
  plot = broadacre.bar,
  device = "png",
  dpi = 500
)


# -- Data wrangling for China plots -----

# China
china.df <- filter(crops.df, crops.df$Area %in% c("China"))

# Calculate median and mean
# china.agg.df <- china.df[china.df$Element == "Area harvested",] %>%
china.agg.df <- china.df %>%
  # group_by(category, vik.flag, Item, Element, Unit) %>%
  group_by(category, Item, Element, Unit) %>%
  summarise(med.value = median(Value), mean.value = mean(Value))

# Sort by category and mean.value
china.agg.df <- china.agg.df[order(-china.agg.df$category, -china.agg.df$mean.value),]
# head(sort(china.agg.df$mean.value, decreasing = TRUE), n = 20)

china.df[rowSums(is.na(china.df)) > 0, ]
china.agg.df[rowSums(is.na(china.agg.df)) > 0, ]


# -- China Plots ----------------

bar.df <- china.agg.df[china.agg.df$category == TRUE, ]
bar.df <- bar.df[bar.df$Element == "Area harvested", ]

# -------~~ Bar chart of larger categories --------
ggplot(bar.df, aes(y = mean.value, x = reorder(Item, mean.value), fill = Item)) +
  geom_bar(stat = "identity") +
  scale_fill_hue(c = 80, l = 80) +  # reduce saturation, increase luminance
  # scale_fill_brewer(palette = "Dark2") +
  theme.base +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)
        , legend.position = "none") +
  labs(title = "China: crops by area planted", subtitle = "Mean area planted, 2017 - 2021"
       , y = "hectares", x = "Crop") +
  coord_flip()

rm(bar.df)


# -------~~ China specialty crops --------
specialty.df <- subset(crops.df, Area == "China") %>%
  subset(specialty == 1) %>%
  subset(Year == 2021) %>%
  subset(Element.Code == 5312) # 5419
  # subset(Element.Code == 5510)

breaks.c <- seq(from = 1000000, to = (max(specialty.df$Value)) , by = 1000000)

ggplot(data = specialty.df
       , aes(y = Value, x = reorder(Item, Value), fill = Item)) +
  geom_bar(stat = "identity", alpha = 0.6) +
  scale_fill_manual(values = colorRampPalette(brewer.pal(8, "Set1"))(15)) +
  scale_y_continuous(label = comma) +
  geom_hline(yintercept = breaks.c, color = "#ffffff", size = rel(0.5)) +
  theme.base +
  theme(legend.position = "none") +
  labs(title = "China Specialty Crops : Area Harvested 2021",
       x = "Crop", y = "Hectares") +
  coord_flip()

rm(specialty.df, breaks.c)



# -------~~ Scatter plot --------
# https://www.r-statistics.com/tag/transpose/


# Re-Calculate median and mean
china.agg2.df <- china.df %>%
  group_by(category, vik.flag, Item, Element, Unit) %>%
  # group_by(category, Item, Element, Unit) %>%
  summarise(med.value = median(Value), mean.value = mean(Value), .groups = "keep")

# china.agg2.df %>% drop_na(vik.flag)

scatter.df <- cast(china.agg2.df, category + vik.flag + Item ~ Element
                   , value = "mean.value", fun.aggregate = mean)
scatter.df <- scatter.df %>% 
  filter(vik.flag %in% c("current", "interest", "broadacre", "tree nuts"))

# New column name has a space, so remove it.
names(scatter.df)<-str_replace_all(names(scatter.df), c(" " = "."))

labels.df <- scatter.df %>% 
  filter(vik.flag %in% c("current", "interest", "broadacre"))

ggplot(scatter.df[scatter.df$category == FALSE,]
       , aes(x = Area.harvested, y = Production, colour = vik.flag, label = Item)) +
  geom_point(size = 2) +
  # geom_text_repel(labels.df, aes(x = Area.harvested, y = Production, label = Item)) +
  geom_text_repel(data = labels.df) +
  scale_color_brewer(type = "qual", palette = "Dark2") +
  scale_y_log10(label=comma) +
  scale_x_log10(label=comma) +
  # theme.base +
  labs(title = "China 2017-2021 median", subtitle = "log scale"
       , x = "Area harvested (ha)", y = "Production (tonnes)", colour = "group")
  
