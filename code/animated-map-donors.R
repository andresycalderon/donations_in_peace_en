#Animated map: Donation statistics for three local elections in Colombia
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

#Datasets and shapes
#Divipola (contains department and municipality codes)
divipola <- read_excel("data/maps/DIVIPOLA_202091.xls", skip = 4)%>%
  as_tibble()%>%rename(coddpto=`Código departamento`,
                       codmpio=`Código municipio`,
                       mpio=`Nombre municipio`,
                       dpto=`Nombre departamento`)%>%
  select(coddpto, codmpio, mpio, dpto)%>%
  mutate(mpio_m=str_replace_all(iconv(mpio, from = "UTF-8", to="ASCII//TRANSLIT")," ",""),
         dpto_m=str_replace_all(iconv(dpto, from = "UTF-8", to="ASCII//TRANSLIT")," ",""))%>%
  select(coddpto, codmpio, mpio_m, dpto_m)
#Shape files: mpio and depto
map <- read_sf("data/maps/mpio/MGN_MPIO_POLITICO.shp")
dptomap <- read_sf("data/maps/dptos/MGN_DPTO_POLITICO.shp")
#Destring the municipality code in the municipality map
map <- map%>%
  mutate(MPIO_CCNCT=as.numeric(MPIO_CCNCT))

#Political donation statistics by municipality
col_names11 <- c("codmpio","amount_sum","amount_mean","donors_sum","donors_mean")
col_names <- c("dpto","mpio","amount_sum","amount_mean","donors_sum","donors_mean")
donation_stats_2011 <- read_csv('data/clean/mpio_stats_2011.csv',
                                skip = 3,
                                col_names = col_names11)
donation_stats_2015 <- read_csv('data/clean/mpio_stats_2015.csv',
                                skip = 3,
                                col_names = col_names)
donation_stats_2019 <- read_csv('data/clean/mpio_stats_2019.csv',
                                skip = 3,
                                col_names = col_names)
#Bind 2015 and 2019 and 'normalize' the names of municipalities and departamentos
donation_stats_15_19 <- donation_stats_2015%>%
  mutate(yearly=2015)%>%
  bind_rows(donation_stats_2019)%>%
  mutate(yearly=if_else(is.na(yearly),2019,yearly))%>%
  mutate(mpio_m=str_replace_all(iconv(mpio, from = "UTF-8", to="ASCII//TRANSLIT")," ",""),
         dpto_m=str_replace_all(iconv(dpto, from = "UTF-8", to="ASCII//TRANSLIT")," ",""))

#Merge with divipola to get municipality codes
#Before: need to get some correction to municipality names
special_dptos <- c("CHOCO","CORDOBA","CAUCA","NARINO","SUCRE",
                   "CUNDINAMARCA","CASANARE","VALLE","CESAR",
                   "HUILA","MAGDALENA")
donation_stats_15_19 <- donation_stats_15_19%>%
  mutate(mpio_m=if_else(dpto_m%in%special_dptos,
                        str_remove_all(mpio_m,"\\(\\w*\\)"),
                        mpio_m))
donation_stats_15_19 <- donation_stats_15_19%>%
  mutate(mpio_m=if_else(mpio_m=="ANTIOQUIA","SANTAFEDEANTIOQUIA",mpio_m),
         mpio_m=if_else(mpio_m=="PURISIMA","PURISIMADELACONCEPCION",mpio_m),
         mpio_m=if_else(mpio_m=="TOLU","SANTIAGODETOLU",mpio_m),
         mpio_m=if_else(mpio_m=="GUICAN","GUICANDELASIERRA",mpio_m),
         mpio_m=if_else(mpio_m=="SANMIGUEL(LADORADA)"&dpto_m=="PUTUMAYO","SANMIGUEL",mpio_m),
         mpio_m=if_else(mpio_m=="VALLEDELGUAMUEZ(LAHORMIGA)","VALLEDELGUAMUEZ",mpio_m),
         mpio_m=if_else(mpio_m=="CARMENDEVIBORAL","ELCARMENDEVIBORAL",mpio_m),
         mpio_m=if_else(mpio_m=="PUERTONARELAMAGDALENA","PUERTONARE",mpio_m),
         mpio_m=if_else(mpio_m=="MANAUREBALCONDELCESAR(MANA","MANAUREBALCONDELCESAR",mpio_m),
         mpio_m=if_else(mpio_m=="YONDOCASABE","YONDO",mpio_m),
         mpio_m=if_else(mpio_m=="BOGOTAD.C.","BOGOTA,D.C.",mpio_m),
         mpio_m=if_else(mpio_m=="TIQUISIO(PTO.RICO)","TIQUISIO",mpio_m),
         mpio_m=if_else(mpio_m=="VILLADELEIVA","VILLADELEYVA",mpio_m),
         mpio_m=if_else(mpio_m=="ELCANTONDELSANPABLO(MAN.","ELCANTONDELSANPABLO",mpio_m),
         mpio_m=if_else(mpio_m=="ELCARMEN"&dpto_m=="CHOCO","CARMENDELDARIEN",mpio_m),
         mpio_m=if_else(mpio_m=="UBATE","VILLADESANDIEGODEUBATE",mpio_m),
         mpio_m=if_else(mpio_m=="SANMARTINDELOSLLANOS","SANMARTIN",mpio_m),
         mpio_m=if_else(mpio_m=="ELCARMEN"&dpto_m=="SANTANDER","ELCARMENDECHUCURI",mpio_m),
         mpio_m=if_else(mpio_m=="SINCE","SANLUISDESINCE",mpio_m),
         mpio_m=if_else(mpio_m=="TOLUVIEJO","SANJOSEDETOLUVIEJO",mpio_m),
         mpio_m=if_else(mpio_m=="ARMERO(GUAYABAL)","ARMERO",mpio_m),
         mpio_m=if_else(mpio_m=="BOGOTA","BOGOTA,D.C.",mpio_m),
         mpio_m=if_else(mpio_m=="CARTAGENA","CARTAGENADEINDIAS",mpio_m),
         mpio_m=if_else(mpio_m=="TUMACO","SANANDRESDETUMACO",mpio_m),
         mpio_m=if_else(mpio_m=="BUGA","GUADALAJARADEBUGA",mpio_m),
         mpio_m=if_else(mpio_m=="CURIMBO","CUMARIBO",mpio_m),
         mpio_m=if_else(mpio_m=="CERROSANANTONIO","CERRODESANANTONIO",mpio_m),
         mpio_m=if_else(mpio_m=="CHIBOLO","CHIVOLO",mpio_m),
         mpio_m=if_else(mpio_m=="PIENDAMO","PIENDAMO-TUNIA",mpio_m),
         mpio_m=if_else(mpio_m=="PAZDELRIO","PAZDERIO",mpio_m),
         mpio_m=if_else(mpio_m=="CUASPUD","CUASPUDCARLOSAMA",mpio_m),
         mpio_m=if_else(mpio_m=="LOPEZ","LOPEZDEMICAY",mpio_m),
         mpio_m=if_else(mpio_m=="SOTARA","SOTARAPAISPAMBA",mpio_m),
         mpio_m=if_else(mpio_m=="MOMPOS","SANTACRUZDEMOMPOX",mpio_m),
         mpio_m=if_else(mpio_m=="MARIQUITA","SANSEBASTIANDEMARIQUITA",mpio_m),
         mpio_m=if_else(mpio_m=="BOLIVAR" & dpto_m=="ANTIOQUIA","CIUDADBOLIVAR",mpio_m),
         mpio_m=if_else(mpio_m=="SANANDRES" & dpto_m=="ANTIOQUIA","SANANDRESDECUERQUIA",mpio_m),
         mpio_m=if_else(mpio_m=="SANPEDRO" & dpto_m=="ANTIOQUIA","SANPEDRODELOSMILAGROS",mpio_m),
         mpio_m=if_else(mpio_m=="SANVICENTE" & dpto_m=="ANTIOQUIA","SANVICENTEFERRER",mpio_m),
         mpio_m=if_else(mpio_m=="MANAURE" & dpto_m=="CESAR","MANAUREBALCONDELCESAR",mpio_m),
         dpto_m=if_else(dpto_m=="BOGOTAD.C.","BOGOTA,D.C.",dpto_m),
         dpto_m=if_else(dpto_m=="VALLE","VALLEDELCAUCA",dpto_m),
         dpto_m=if_else(mpio_m=="PROVIDENCIA"&dpto_m=="SANANDRES","ARCHIPIELAGODESANANDRES,PROVIDENCIAYSANTACATALINA",dpto_m))
donation_stats_15_19 <- donation_stats_15_19%>%left_join(divipola, 
                                             by=c("dpto_m","mpio_m"))

#Keep only municipality code and outcomes of interest. Destring code
donation_stats_15_19 <- donation_stats_15_19%>%
  select(codmpio,amount_sum,amount_mean,donors_sum,donors_mean,yearly)%>%
  mutate(codmpio=as.numeric(codmpio))

#Append 2011 to 2015 and 2019, adding the yearly variable
donation_stats <- mutate(donation_stats_2011,yearly=2011)%>%
  bind_rows(donation_stats_15_19)

#Divide the amount variables by 1 million
donation_stats <- donation_stats%>%
  mutate(amount_sum=amount_sum/1000000,
         amount_mean=amount_mean/1000000)

#Export the final dataset to use it as an input in other 
#codes
write_csv(donation_stats, 'data/clean/mpio_stats_11_19.csv')

#Generate map functions:

#For total donors
map_function_donors_sum <- function(year){
  #Filter data (selecting only the information by year)
  filtered_data <- donation_stats%>%filter(yearly==year)
  mapa <- map%>%
    left_join(filtered_data,by=c("MPIO_CCNCT"="codmpio"))
  #Replace with zeroes donation variables if they're missing
  don_stats_vtr <- c("amount_sum","amount_mean",
                     "donors_sum","donors_mean")
  mapa <- mapa%>%
    mutate_at(don_stats_vtr,~replace(., is.na(.), 0))
  #Map with all municipalities
  main <- mapa%>%
    ggplot()+
    geom_sf(aes(fill=donors_sum), lwd=0)+
    geom_sf(data = dptomap, fill=NA, color="mediumpurple1", lwd=0.5)+
    scale_fill_gradient(
      na.value = "grey80",
      limits=c(0,80),
      oob=scales::squish,
      name= "Total donantes\npor municipio"
    )+theme_void()+ggtitle(toString(year))+
    theme(
      legend.position = c(.85,.85),
      plot.title = element_text(size = 35)
    )
  #Adding the inset (plus black rectangle)
  main <- main+
    geom_rect(
      xmin = -77.094614,
      ymin = 3.046507,
      xmax = -72.392663,
      ymax = 8.451483,
      fill = NA, 
      colour = "black",
      size = 0.6
    )
  
  ggdraw(main)+
    draw_plot({
      main+coord_sf(
        xlim = c(-77.094614, -72.392663),
        ylim = c(3.046507, 8.451483), 
        expand = FALSE)+
        theme(legend.position = "none",
              plot.title = element_blank())
    },
    x=0.58,
    y=0,
    width = 0.4,
    height = 0.4)
  
  path <- 'output/evol-by-municipality/donorssum-'
  name1 <- paste0(path,toString(year),".png")
  name2 <- paste0(path,toString(year),".pdf")
  ggsave(name1,height = 30, width = 30, units = "cm")
  ggsave(name2,height = 30, width = 30, units = "cm")
}
#For average number of donors per candidate
map_function_donors_mean <- function(year){
  #Filter data (selecting only the information by year)
  filtered_data <- donation_stats%>%filter(yearly==year)
  mapa <- map%>%
    left_join(filtered_data,by=c("MPIO_CCNCT"="codmpio"))
  #Replace with zeroes donation variables if they're missing
  don_stats_vtr <- c("amount_sum","amount_mean",
                     "donors_sum","donors_mean")
  mapa <- mapa%>%
    mutate_at(don_stats_vtr,~replace(., is.na(.), 0))
  
  main <- mapa%>%
    ggplot()+
    geom_sf(aes(fill=donors_mean), lwd=0)+
    geom_sf(data = dptomap, fill=NA, color="#FFEE82", lwd=0.5)+
    scale_fill_gradient(
      na.value = "grey80",
      high = "#F7B056",
      low = "#433413",
      limits=c(0,30),
      oob=scales::squish,
      name= "Donantes promedio\npor candidato"
    )+theme_void()+ggtitle(toString(year))+
    theme(
      legend.position = c(.85,.85),
      plot.title = element_text(size = 35)
    )
  #Adding the inset (plus black rectangle)
  main <- main+
    geom_rect(
      xmin = -77.094614,
      ymin = 3.046507,
      xmax = -72.392663,
      ymax = 8.451483,
      fill = NA, 
      colour = "black",
      size = 0.6
    )
  
  ggdraw(main)+
    draw_plot({
      main+coord_sf(
        xlim = c(-77.094614, -72.392663),
        ylim = c(3.046507, 8.451483), 
        expand = FALSE)+
        theme(legend.position = "none",
              plot.title = element_blank())
    },
    x=0.58,
    y=0,
    width = 0.4,
    height = 0.4)
  path <- 'output/evol-by-municipality/donorsmean-'
  name1 <- paste0(path,toString(year),".png")
  name2 <- paste0(path,toString(year),".pdf")
  ggsave(name1,height = 30, width = 30, units = "cm")
  ggsave(name2,height = 30, width = 30, units = "cm")
  
}

#For total amount of donations

map_function_amount_sum <- function(year){
  #Filter data (selecting only the information by year)
  filtered_data <- donation_stats%>%filter(yearly==year)
  mapa <- map%>%
    left_join(filtered_data,by=c("MPIO_CCNCT"="codmpio"))
  #Replace with zeroes donation variables if they're missing
  don_stats_vtr <- c("amount_sum","amount_mean",
                     "donors_sum","donors_mean")
  mapa <- mapa%>%
    mutate_at(don_stats_vtr,~replace(., is.na(.), 0))
  
  main <- mapa%>%
    ggplot()+
    geom_sf(aes(fill=amount_mean), lwd=0)+
    geom_sf(data = dptomap, fill=NA, color="mediumpurple1", lwd=0.5)+
    scale_fill_gradient(
      na.value = "grey80",
      limits=c(0,100),
      low = "#303030",
      high = "#E3E3E3",
      oob=scales::squish,
      name= "Monto total donado\npor municipio"
    )+theme_void()+ggtitle(toString(year))+
    theme(
      legend.position = c(.85,.85),
      plot.title = element_text(size = 35)
    )
  #Adding the inset (plus black rectangle)
  main <- main+
    geom_rect(
      xmin = -77.094614,
      ymin = 3.046507,
      xmax = -72.392663,
      ymax = 8.451483,
      fill = NA, 
      colour = "black",
      size = 0.6
    )
  
  ggdraw(main)+
    draw_plot({
      main+coord_sf(
        xlim = c(-77.094614, -72.392663),
        ylim = c(3.046507, 8.451483), 
        expand = FALSE)+
        theme(legend.position = "none",
              plot.title = element_blank())
    },
    x=0.58,
    y=0,
    width = 0.4,
    height = 0.4)
  path <- 'output/evol-by-municipality/totalamount-'
  name1 <- paste0(path,toString(year),".png")
  name2 <- paste0(path,toString(year),".pdf")
  ggsave(name1,height = 30, width = 30, units = "cm")
  ggsave(name2,height = 30, width = 30, units = "cm")
}
#For average amount of donation per candidate
map_function_amount_mean <- function(year){
  #Filter data (selecting only the information by year)
  filtered_data <- donation_stats%>%filter(yearly==year)
  mapa <- map%>%
    left_join(filtered_data,by=c("MPIO_CCNCT"="codmpio"))
  #Replace with zeroes donation variables if they're missing
  don_stats_vtr <- c("amount_sum","amount_mean",
                     "donors_sum","donors_mean")
  mapa <- mapa%>%
    mutate_at(don_stats_vtr,~replace(., is.na(.), 0))

  main <- mapa%>%
    ggplot()+
    geom_sf(aes(fill=amount_mean), lwd=0)+
    geom_sf(data = dptomap, fill=NA, color="mediumpurple1", lwd=0.5)+
    scale_fill_gradient(
      na.value = "grey80",
      low = "#164313",
      high = "#52FF46",
      limits=c(0,50),
      oob=scales::squish,
      name= "Monto promedio donado\npor candidato"
    )+theme_void()+ggtitle(toString(year))+
    theme(
      legend.position = c(.85,.85),
      plot.title = element_text(size = 35)
    )
  #Adding the inset (plus black rectangle)
  main <- main+
    geom_rect(
      xmin = -77.094614,
      ymin = 3.046507,
      xmax = -72.392663,
      ymax = 8.451483,
      fill = NA, 
      colour = "black",
      size = 0.6
    )
  
  ggdraw(main)+
    draw_plot({
      main+coord_sf(
        xlim = c(-77.094614, -72.392663),
        ylim = c(3.046507, 8.451483), 
        expand = FALSE)+
        theme(legend.position = "none",
              plot.title = element_blank())
    },
    x=0.58,
    y=0,
    width = 0.4,
    height = 0.4)
  path <- 'output/evol-by-municipality/averageamount-'
  name1 <- paste0(path,toString(year),".png")
  name2 <- paste0(path,toString(year),".pdf")
  ggsave(name1,height = 30, width = 30, units = "cm")
  ggsave(name2,height = 30, width = 30, units = "cm")
}
#Apply functions
yearlist <- c(2011,2015,2019)
lapply(yearlist, map_function_donors_sum)
lapply(yearlist, map_function_donors_mean)
lapply(yearlist, map_function_amount_sum)
lapply(yearlist, map_function_amount_mean)