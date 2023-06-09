# Set up working directory and libraries
setwd("~/Projects/unfao-fert-crop")

library(reshape)
library(tidyverse)
library(RColorBrewer)
library(scales)
library(ggrepel)
# library(WriteXLS)


# http://www.fao.org/economic/ess/environment/data/chemical-and-mineral-fertilizers/en/

# --------- Set options ---------------------

options(scipen = 100, digits = 6)


# --------- Theme, scales, etc
light.grey <- "#dddddd"
light.grey.line <- element_line(linewidth = 0.3, color = light.grey)

theme_set(theme_light(base_family = "sans"))
theme.base <- theme(panel.border = element_blank()
                    , panel.grid.major = element_blank()
                    , panel.grid.minor = element_blank()
                    , axis.ticks.x = element_blank()
                    , axis.ticks.y = element_blank()
                    , text = element_text(size = 5)
                    , strip.background = element_rect(fill = "#eeeeee")
                    , strip.text = element_text(colour = "#000000")
                    # , axis.line.x = light.grey.line
)

# -- User-defined functions.



# -------------- Data shape & summary ----------------------------
# dim()
# head()
# 
# stat.desc()
# 
# summary()
# median()
# 
# str()
# describe()
# describe()
# 
# 
# glimpse()



