# `unfao-fert-crop.R` holds library() calls and themes.
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
crops.df$Item <- factor(crops.df$Item)


# -------~~ File w/ crop flags ("current", "interest", etc) --------
items.df <- read.csv("csv/items.csv")

# Pad Item.Code to match FAOSTAT documentation
items.df$Item.Code <- str_pad(items.df$Item.Code, 4, "left", pad = "0")

# Join flags to main data frame
crops.df <- crops.df %>% left_join(items.df[,c(-2)], by = c("Item.Code" = "Item.Code"))

rm(items.df)


# -------~~ File w/ country flags ("APAC", etc) --------
countries.df <- read.csv("csv/countries.csv")

# Join flags to main data frame
crops.df <- crops.df %>% left_join(countries.df)

rm(countries.df)


# -- Agave ----------------

# just agave
# remove regions, only grab countries which produced agave in 2021
agave.df <- crops.df %>%
  filter(Item.Code == "0800" & Area.Code < 5000 & Value > 0 & Year == 2021)


agave.plot <-
  ggplot(data = agave.df[agave.df$Element.Code == 5312,]
    , aes(x = Value, y = reorder(Area, Value), fill = Area)) +
    theme.base +
    theme(legend.position = "none") +
    geom_col(alpha = 0.6) +
    geom_text(aes(x = Value + 750 , y = Area, label = Value), size = 1.5) +
    scale_fill_brewer(palette = "Dark2") +
    scale_x_continuous(labels = comma) + 
    labs(title = "Agave: global market", subtitle = "Area planted - 2021 Source: FAOSTAT",
         x = "Hectares", y = "Country")

agave.plot

ggsave("agave-global-bar.png", path = "plots", agave.plot,
       width = 1200, height = 860, device = png, units = c("px"))

rm(agave.df)

# -- Broadacre - APAC-----

# Get broadacre production of countries by area. Remove regions. Only APAC & 2021
# Sugarcane, Potato, Corn and Rice?
broadacre.df <- crops.df %>%
  filter(broadacre == 1 & Area.Code < 5000 & Value > 0 & Year == 2021
         & Grouping == "APAC" & Element.Code == 5312)

breaks.c <- seq(from = 10, to = (max(broadacre.df$Value/1000000)) , by = 10)

broadacre.df$Item <- as.character(broadacre.df$Item)
# Newest data is all "Maize (corn)"
# broadacre.df[broadacre.df$Item == 'Maize',]$Item <- "Maize (corn)"


broadacre.facet <- 
  ggplot(data = broadacre.df
    , aes(x = Value/1000000, y = reorder(Area, Value), fill = Area)) +
  geom_col(alpha = 0.8) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_fill_brewer(palette = "Set3") +
  geom_vline(xintercept = breaks.c, color = "#ffffff", linewidth = rel(0.3)) +
  theme.base +
  theme(legend.position = "none") +
  labs(title = "Area harvested - 2021 Source: FAOSTAT", x = "Million Hectares", y = "Country") +
  facet_wrap(facets = vars(Item))


broadacre.facet

ggsave(
  filename = "apac-broadacre-area-2021-higher-res.png",
  path = "plots",
  plot = broadacre.facet,
  device = "png",
  width = 1200, height = 860, units = c("px")
)

rm(breaks.c)

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
  geom_text(aes(x = year, y = total + 10000 , label = comma(total)), colour = "#444444", size = 1.5) +
  geom_hline(yintercept = breaks.c, color = "#ffffff", size = rel(0.3)) +
  scale_fill_brewer(palette = "Dark2") +
  scale_x_continuous("Year", breaks = years.v, labels = years.v) +
  scale_y_continuous("Volume (ST)", label = comma) +
  theme.base +
  theme(plot.title = element_text(hjust = 0.5)
        , panel.border = element_blank()
        , legend.position = "none"
        , strip.background = element_rect(fill = "#666666")
        ) +
    labs(title = "Broadacre Projection")

broadacre.bar

ggsave(
  filename = "bar-plot-potential-higher-res.png",
  path = "plots",
  plot = broadacre.bar,
  device = "png",
  width = 1200, height = 860, units = c("px")
)

rm(breaks.c)

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
breaks.c <- seq(from = 25000000, to = (max(bar.df$mean.value)) , by = 25000000)

ggplot(bar.df, aes(x = mean.value, y = reorder(Item, mean.value), fill = Item)) +
  geom_col() +
  scale_fill_hue(c = 80, l = 80) +  # reduce saturation, increase luminance
  scale_x_continuous(labels = comma) + 
  geom_vline(xintercept = breaks.c, color = "#ffffff", linewidth = rel(0.3)) +
  theme.base +
  theme(legend.position = "none") +
  labs(title = "China: crops by area planted", subtitle = "Mean area planted, 2017 - 2021"
       , x = "Hectares", y = "Crop")

ggsave(
  filename = "china-crops-by-area.png",
  path = "plots",
  device = "png",
  width = 1200, height = 860, units = c("px")
)

rm(bar.df, breaks.c)


# -------~~ China specialty crops --------
specialty.df <- subset(crops.df, Area == "China") %>%
  subset(specialty == 1) %>%
  subset(Year == 2021) %>%
  subset(Element.Code == 5312) # 5419
  # subset(Element.Code == 5510)

breaks.c <- seq(from = 1000000, to = (max(specialty.df$Value)) , by = 1000000)

ggplot(data = specialty.df
       , aes(x = Value, y = reorder(Item, Value), fill = Item)) +
  geom_col(alpha = 0.3) +
  geom_vline(xintercept = breaks.c, color = "#ffffff", size = rel(0.5)) +
  geom_text(aes(x = 0, y = Item, label = Item), hjust = 0, size = 1.5) +
  scale_fill_manual(values = colorRampPalette(brewer.pal(8, "Set1"))(15)) +
  scale_x_continuous(label = comma) +
  theme.base +
  theme(legend.position = "none", axis.text.y=element_blank()) +
  labs(title = "China Specialty Crops : Area Harvested 2021",
       x = "Hectares", y = "Crop")

ggsave(
  filename = "china-specialty-crops-area.png",
  path = "plots",
  device = "png",
  width = 1200, height = 860, units = c("px")
)

rm(specialty.df, breaks.c)



# -------~~ Scatter plot --------
# https://www.r-statistics.com/tag/transpose/


# Re-Calculate median and mean
china.agg2.df <- china.df %>%
  group_by(category, vik.flag, Item, Element, Unit) %>%
  summarise(med.value = median(Value), mean.value = mean(Value), .groups = "keep")

scatter.df <- cast(china.agg2.df, category + vik.flag + Item ~ Element
                   , value = "mean.value", fun.aggregate = mean)
scatter.df <-  
  filter(scatter.df, vik.flag %in% c("current", "interest", "broadacre", "tree nuts"))

# New column name has a space, so remove it.
names(scatter.df)<-str_replace_all(names(scatter.df), c(" " = "."))

# Remove crops with no harvest
scatter.df <- filter(scatter.df, Area.harvested > 0)

labels.df <- scatter.df %>% 
  filter(vik.flag %in% c("current", "interest", "broadacre"))

ggplot(scatter.df[scatter.df$category == FALSE,]
       , aes(x = Area.harvested, y = Production, colour = vik.flag, label = Item)) +
  geom_point(size = 2) +
  geom_text_repel(data = labels.df, show.legend = FALSE) +
  scale_color_brewer(type = "qual", palette = "Set1", name = "Grouping") +
  scale_y_log10(label = comma) +
  scale_x_log10(label = comma) +
  # theme.base +
  labs(title = "China 2017-2021 median", subtitle = "log scale"
       , x = "Area harvested (ha)", y = "Production (tonnes)", colour = "group")
  
ggsave(
  filename = "china-scatter-plot.png",
  path = "plots",
  device = "png",
  dpi = "print",
  width = 3600, height = 2580, units = c("px")
)

