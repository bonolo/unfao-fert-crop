# Run `unfao-fert-crop.R` first.
# That's where the library() calls and CSV reads live.
source('unfao-fert-crop.R')


# -- Load Fertilizer CSV files ---------------


# NUTRIENTS File (N, P & K. More specific breakdowns are in fertilizer product files)

fert.nutrient.df <- read.csv("csv/Inputs_FertilizersNutrient_E_All_Data_(Normalized).csv")
fert.nutrient.df <- filter(fert.nutrient.df, fert.nutrient.df$Area %in% c("Africa", "Americas", "Asia", "Europe", "Oceania"))
keeps <- c("Area", "Item", "Element", "Year", "Unit", "Value")
fert.nutrient.df <- fert.nutrient.df[keeps]

# Fix Nutrient Names
fert.nutrient.df$Item <- factor(fert.nutrient.df$Item
                       , levels = c("Nutrient nitrogen N (total)"
                                    , "Nutrient phosphate P2O5 (total)"
                                    , "Nutrient potash K2O (total)"), 
                       labels = c("Nitrogen (N)", "Phosphate (P2O5)", "Potash (K2O)"))

# Just take Agricultural Use
fert.nutrient.df <- fert.nutrient.df[fert.nutrient.df$Element == "Agricultural Use",]

# Update levels in filtered factors.
summary(fert.nutrient.df)
fert.nutrient.df$Item <- factor(fert.nutrient.df$Item)
fert.nutrient.df$Element <- factor(fert.nutrient.df$Element)
fert.nutrient.df$Area <- factor(fert.nutrient.df$Area)


# Fertilizer PRODUCTS File (more specific/granular)
fert.product.df <- read.csv("csv/Inputs_FertilizersProduct_E_All_Data_(Normalized).csv")

# Pad Item.Code and Element.Code to match FAOSTAT documentation
fert.product.df$Item.Code <- str_pad(fert.product.df$Item.Code, 4, "left", pad = "0")
fert.product.df$Element.Code <- str_pad(fert.product.df$Element.Code, 4, "left", pad = "0")

# unique(fert.product.df$Item)
# unique(fert.product.df$Area.Code)
# unique(fert.product.df$Area.Code, fert.product.df$Area)

# -- Data wrangling for reporting -----
# Malaysia  Urea and MOP... import (quantity & value), export (quantity & value), 
# MOP Item Code: 3104
# Urea Item Code: 3102
my.urea.mop.df <- subset(fert.product.df, Item.Code %in% c("3102", "3104")) %>%
  subset(Year == 2020) %>%
  subset(Area.Code == 458, select = c(2, 4, 6, 8:10)) # Malaysia

my.urea.mop.df <- cast(my.urea.mop.df, Area + Item + Year ~ Element + Unit, value.var = Value)
my.urea.mop.df$netQuantity <- my.urea.mop.df[,4] - my.urea.mop.df[,6]



# -- Data wrangling to prepare for plots -----

# http://www.fao.org/economic/ess/environment/data/chemical-and-mineral-fertilizers/en/
# Figure 1. Global N inputs to agricultural soils from 
# mineral and chemical synthetic fertilizers (2002–2017)

# Just nitrogen
n.df <- fert.nutrient.df[fert.nutrient.df$Item == "Nitrogen (N)",] %>%
  group_by(Area, Item, Year) %>%
  summarise(tons = sum(Value))

# Sum tons by year to join onto main data frame
totals.df <- n.df %>%
  group_by(Year) %>%
  summarise(year.sum = sum(tons))
n.df <- merge(x = n.df, y = totals.df)

# Sum tons by area to join onto main data frame
totals.df <- n.df %>%
  group_by(Area) %>%
  summarise(area.sum = sum(tons))
n.df <- merge(x = n.df, y = totals.df)

rm(totals.df)

# Calculate each row's percentage of group total
n.df$Pct.Year <- percent_format()(n.df$tons / n.df$year.sum)

# Order regions/areas by total tons and year
n.df <- n.df[order(-n.df$area.sum, n.df$year),]

# And apply ordering to 'levels'. I still don't get why levels and factors 
# don't automatically have the same order
n.df$Area <- factor(n.df$Area, levels = unique(n.df$Area))

# Add in cumulative summary by group
n.df$cumsum <- ave(n.df$tons, n.df$Year, FUN=cumsum)

# Now, flip the order around so the largest is at the bottom
n.df <- n.df[order(n.df$area.sum, n.df$year),]
n.df$Area <- factor(n.df$Area, levels = unique(n.df$Area))

# Breaks and labels
year.breaks <- seq(from = min(n.df$Year), to = max(n.df$Year) , by = 2)
grid.breaks <- seq(from = min(n.df$Year), to = max(n.df$Year) , by = 1)
ton.breaks <- seq(from = 0, to = max(n.df$tons) + 19, by = 20)
area.sub = "mineral and chemical synthetic fertilizers"

vlines <- geom_vline(xintercept = grid.breaks, color = "#ffffff", size = rel(0.2))


# -- Start Plots ----------------

# Look at this for some ideas...
# https://www.r-graph-gallery.com/136-stacked-area-chart.html


# Base area plot
area.plot <- ggplot() +
  scale_x_continuous(breaks = year.breaks
                     , expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = ton.breaks) +
  scale_fill_brewer(palette="Set2") +
  theme.base +
  theme(axis.text.x = element_text(angle = 90, hjust = 0.5, vjust = 0.5
                                   , margin = margin(-10,0,0,0))) +
  labs(y = "Million tonnes")

# Labels for geom_text()
labels.df <- subset(n.df, Year %in% c(2005, 2020))

n.area.plot <- area.plot +
  geom_area(data = n.df, aes(x = Year, y = tons/1000000, fill = Area)) +
  vlines +
  # geom_text causes R to crash/lock up. Have tried this a zillion ways with no success.
  # it works without the area plot, though.
  # geom_text(data = labels.df, aes(x = Year, y = cumsum, label = Pct.Year)) +
  theme(legend.position = c(0.8, 0.3)) +
  labs(title = "Global Nitrogen inputs to agricultural soils", fill = "Region"
       , subtitle = area.sub)

n.area.plot


# Order fert.nutrient.df$Area by total usage of all Items.
totals.df <- fert.nutrient.df %>%
  group_by(Area) %>%
  summarise(area.sum = sum(Value))
fert.nutrient.df <- merge(x = fert.nutrient.df, y = totals.df)
rm(totals.df)

# Order regions/areas by total tons and year
fert.nutrient.df <- fert.nutrient.df[order(fert.nutrient.df$area.sum, fert.nutrient.df$Year),]
# And apply ordering to 'levels'.
fert.nutrient.df$Area <- factor(fert.nutrient.df$Area, levels = unique(fert.nutrient.df$Area))


# Area chart. Faceted. One chart per Item (type of nutrient)
area.plot +
  geom_area(data = fert.nutrient.df, aes(x = Year, y = Value/1000000, fill = Area)) +
  vlines +
  theme(legend.position = c(0.8, 0.6), panel.spacing.x = unit(1, "lines")) +
  labs(title = "Global Nutrient Inputs to Agricultural Soils", fill = "Region") +
  facet_wrap(facets = vars(Item))



# Area chart. Faceted. One chart per region (area)
# Tricky to sort Y axis by mean value in stacked area chart / geom_area
# Had to sort the data frame.
sort.df <- fert.nutrient.df %>%
  group_by(Item) %>%
  summarise(sum.Item = sum(Value)) %>%
  arrange(sum.Item)

fert.nutrient.df$Item <- factor(fert.nutrient.df$Item, levels = sort.df$Item)
rm(sort.df)

area.plot +
  geom_area(data = fert.nutrient.df, aes(x = Year, y = Value/1000000, fill = Item)) +
  vlines +
  theme(legend.position = c(0.8, 0.2), panel.spacing.x = unit(1, "lines")) +
  labs(title = "Global Nutrient Inputs to Agricultural Soils", fill = "Nutrient") +
  facet_wrap(facets = vars(Area))

# stacked & grouped bar chart
stack.bar.years <- c(2005, 2013, 2020)

stack.bar.df <- subset(fert.nutrient.df, Year %in% stack.bar.years)
stack.bar.df$Area2 <- reorder(stack.bar.df$Area, -stack.bar.df$Value)

ggplot(stack.bar.df, aes(fill = Item, y = Value, x = Year)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_x_continuous(name = "Year", breaks = stack.bar.years, labels = stack.bar.years) +
  theme.base +
  facet_wrap(nrow = 1, facets = vars(Area2)) #, strip.position = "bottom")

