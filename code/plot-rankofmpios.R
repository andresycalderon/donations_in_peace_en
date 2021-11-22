#Plot the top 10 municipalities by year, dividing them
#by the presence of FARC in 2011
setwd("D:/Users/USER/Documents/UR 2021-2/MCPP/Project/donations_in_peace")

#Libraries
library(tidyverse)
library(readxl)
library(lubridate)
library(sp)
library(gstat)
library(splancs)
library(spatstat)
library(RColorBrewer)
library(classInt)
library(sf)
library(cowplot)
library(gganimate)
library(plm)
library(naniar)
library(ggpubr)

#Import Datasets
#Dataset at the municipality-year level with farc status and donation stats
all_mpios_panel <- read_csv('data/clean/panelfinal.csv')
#Divipola (contains department and municipality codes)
divipola <- read_excel("data/maps/DIVIPOLA_202091.xls", skip = 4)%>%
  as_tibble()%>%rename(coddpto=`Código departamento`,
                       codmpio=`Código municipio`,
                       mpio=`Nombre municipio`,
                       dpto=`Nombre departamento`)%>%
  select(codmpio, mpio, dpto)%>%
  mutate(codmpio=as.numeric(codmpio))

#Take the average of all years by municipality
all_mpios_average <- all_mpios_panel%>%
  group_by(codmpio)%>%
  summarize_at(c("amount_sum","amount_mean","donors_sum",
                 "donors_mean","FARC1"),mean)%>%
  mutate(Presencia_FARC=if_else(FARC1==1,"Con Presencia","",missing="Sin Presencia"))

#Merge the final cross section with divipola to get the name of the municipality
all_mpios_average  <- all_mpios_average %>%
  left_join(divipola, by="codmpio")

#Divide the sample in FARC and non-farc municipalities
mpios_farc <- all_mpios_average%>%filter(FARC1==1)
mpios_nonfarc <- all_mpios_average%>%filter(is.na(FARC1))

#Plot function
plot_evol_fun <- function(var_index){
  #Generate vector of outcomes
  outcomes <- c('donors_sum','donors_mean',
                'amount_sum','amount_mean')
  #Generate vector of labels
  labels <- c('Promedio de donantes totales',
              'Promedio de donantes\npor candidato',
              'Promedio de monto total donado\n(millones de pesos)',
              'Promedio de monto por\ncandidato(millones de pesos)')
  #Keep only the first ten by the selected variable
  first_ten_farc <- mpios_farc%>%
    arrange(across(starts_with(outcomes[var_index]),desc))%>%
    slice_head(n=10)
  first_ten_nonfarc <- mpios_nonfarc%>%
    arrange(across(starts_with(outcomes[var_index]),desc))%>%
    slice_head(n=10)
  #Plot first ten for municipalities with FARC presence
  first_ten_farc%>%
    ggplot(aes_string("mpio",outcomes[var_index]))+
    geom_col(fill="#f8766d")+
    coord_flip()+
    xlab(NULL)+
    ylab(labels[[var_index]])+
    theme_bw()
  #Export
  path <- paste0('output/top10_',outcomes[var_index],'_farc.pdf')
  pathpng <- paste0('output/top10_',outcomes[var_index],'_farc.png')
  ggsave(filename = path,width = 20,height = 10,units = 'cm')
  ggsave(filename = pathpng,width = 20,height = 10,units = 'cm')
  
  #Plot first ten for municipalities without FARC presence
  first_ten_nonfarc%>%
    ggplot(aes_string("mpio",outcomes[var_index]))+
    geom_col(fill="#00bfc4")+
    coord_flip()+
    xlab(NULL)+
    ylab(labels[[var_index]])+
    theme_bw()
  #Export
  path <- paste0('output/top10_',outcomes[var_index],'_nonfarc.pdf')
  pathpng <- paste0('output/top10_',outcomes[var_index],'_nonfarc.png')
  ggsave(filename = path,width = 20,height = 10,units = 'cm')
  ggsave(filename = pathpng,width = 20,height = 10,units = 'cm')
}
#Apply functions
index_vtrs <- c(1:4)
lapply(index_vtrs, plot_evol_fun)