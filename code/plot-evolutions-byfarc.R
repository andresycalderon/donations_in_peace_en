#Plot the evolution of donation variables in FARC and non-FARC municipalities
setwd("D:/Users/USER/Documents/UR 2021-2/MCPP/Project/donations_in_peace")

#Libraries
library(tidyverse)
library(readxl)
library(lubridate)
library(ggmap)
library(maps)
library(maptools)
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
library(haven)

#Datasets and shapes
#Dataset that indicates the FARC presence status
farc_presence <- read_dta('data/auxiliar/farc_pres_by_mpio.dta')
#Normalize municipality name
farc_presence <- farc_presence%>%
  rename(coddpto=coddepto)%>%
  mutate(mpio_m=str_to_upper(str_replace_all(iconv(municipio, from = "UTF-8", to="ASCII//TRANSLIT")," ","")))
#Divipola (contains department and municipality codes)
divipola <- read_excel("data/maps/DIVIPOLA_202091.xls", skip = 4)%>%
  as_tibble()%>%rename(coddpto=`Código departamento`,
                       codmpio=`Código municipio`,
                       mpio=`Nombre municipio`,
                       dpto=`Nombre departamento`)%>%
  select(coddpto, codmpio, mpio, dpto)%>%
  mutate(mpio_m=str_replace_all(iconv(mpio, from = "UTF-8", to="ASCII//TRANSLIT")," ",""),
         dpto_m=str_replace_all(iconv(dpto, from = "UTF-8", to="ASCII//TRANSLIT")," ",""),
         coddpto=as.numeric(coddpto))%>%
  select(coddpto, codmpio, mpio_m, dpto_m)
#Shape files: mpio and depto
map <- read_sf("data/maps/mpio/MGN_MPIO_POLITICO.shp")
dptomap <- read_sf("data/maps/dptos/MGN_DPTO_POLITICO.shp")
#Political donation statistics by municipality (the three years of study)
donation_stats <- read_csv('data/clean/mpio_stats_11_19.csv')

#MAP: Municipalities by FARC Presence
#Merge farc presence with divipola to get municipality code
#Before: Correct some municipality names
farc_presence <- farc_presence%>%
  mutate(mpio_m=str_remove_all(mpio_m,"\\(\\d\\)"))%>%
  mutate(mpio_m=if_else(mpio_m=="LOPEZ","LOPEZDEMICAY",mpio_m),
         mpio_m=if_else(mpio_m=="PIENDAMO","PIENDAMO-TUNIA",mpio_m),
         mpio_m=if_else(mpio_m=="MANAURE" & coddpto==20,"MANAUREBALCONDELCESAR",mpio_m))
#Merge and keep only municipalities with FARC Presence
farc_presence <- farc_presence%>%
  left_join(divipola, by=c("coddpto","mpio_m"))%>%
  filter(FARC1==1)
#Merge with municipality map and assign Farc Presence=0 if missing
mapa_farc_shp <- map%>%
  left_join(farc_presence,by=c("MPIO_CCNCT"="codmpio"))%>%
  mutate(Presencia_FARC=if_else(FARC1==1,"Con Presencia","",missing="Sin Presencia"))
#Map of FARC presence
mapa_farc <- mapa_farc_shp%>%
  ggplot()+
  geom_sf(aes(fill=Presencia_FARC), lwd=0)+
  geom_sf(data = dptomap, fill=NA, color="mediumpurple1", lwd=0.5)+
  scale_fill_grey(name="Presencia de las\nFARC en 2011")+
  theme_void()

mapa_farc
#Export map
ggsave('output/farc_presence2011.png',height = 30, width = 30, units = "cm")
ggsave('output/farc_presence2011.pdf',height = 30, width = 30, units = "cm")

#Create a 3-year panel of all municipalities in Colombia
all_mpios <- divipola%>%
  select(codmpio)%>%
  mutate(codmpio=as.numeric(codmpio))
all_mpios_panel <- mutate(.data=all_mpios,yearly=2011)%>%
  bind_rows(all_mpios)%>%
  mutate(yearly=if_else(is.na(yearly),2015,yearly))%>%
  bind_rows(all_mpios)%>%
  mutate(yearly=if_else(is.na(yearly),2019,yearly))
#Replace NA's with zeroes in the balanced panel
don_stats_vtr <- c("amount_sum","amount_mean",
                   "donors_sum","donors_mean")
all_mpios_panel <- all_mpios_panel%>%
  left_join(donation_stats, by=c('codmpio','yearly'))%>%
  mutate_at(don_stats_vtr,~replace(., is.na(.), 0))

#Merge donation stats with farc presence (before: destring codmpio in farc_presence)
#Replace farc presence=0 if missing
farc_presence <- farc_presence%>%
  mutate(codmpio=as.numeric(codmpio))

all_mpios_panel <- all_mpios_panel%>%
  left_join(select(farc_presence,codmpio,FARC1),
            by="codmpio")%>%
  mutate(Presencia_FARC=if_else(FARC1==1,"Con Presencia","",missing="Sin Presencia"))
#Export panel to use it as inputs for other codes
write_csv(all_mpios_panel,'data/clean/panelfinal.csv')
#Compute mean and standard deviation of outcomes by year
#and FARC presence status
stats_by_farc_pres <- all_mpios_panel%>%
  group_by(Presencia_FARC,yearly)%>%
  summarize(amount_sum_sum=sum(amount_sum),
            amount_sum_mean=mean(amount_sum),
            amount_mean_mean=mean(amount_mean),
            donors_sum_sum=sum(donors_sum),
            donors_sum_mean=mean(donors_sum),
            donors_mean_mean=mean(donors_mean))

#Plot function
plot_evol_fun <- function(var_index){
  #Generate vector of outcomes
  outcomes <- c('donors_sum_mean','donors_mean_mean',
                'amount_sum_mean','amount_mean_mean')
  #Generate vector of labels
  labels <- c('Promedio de donantes totales',
              'Promedio de donantes\npor candidato',
              'Promedio de monto total donado\n(millones de pesos)',
              'Promedio de monto por\ncandidato(millones de pesos)')
  #Plot
  stats_by_farc_pres%>%
    ggplot(aes_string("yearly",outcomes[var_index],color="Presencia_FARC"))+
    geom_line()+
    geom_point()+
    scale_x_continuous(breaks = c(2011,2015,2019))+
    scale_color_discrete(name="Presencia de las\nFARC en 2011")+
    ylab(labels[var_index])+
    xlab('Año de elecciones municipales')+
    theme_bw()
  
  #Export plot
  path <- paste0('output/evol_',outcomes[var_index],'.pdf')
  pathpng <- paste0('output/evol_',outcomes[var_index],'.png')
  ggsave(filename = path,width = 20,height = 10,units = 'cm')
  ggsave(filename = pathpng,width = 20,height = 10,units = 'cm')
  
}
#Apply functions
index_vtrs <- c(1:4)
lapply(index_vtrs, plot_evol_fun)