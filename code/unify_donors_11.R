#Import all the excel files with all candidates names and 
#their donors. Then, match the names to get the corporation,location and party
library(tidyverse)
library(readxl)
library(writexl)

#Municipality-level elections 2011
setwd("D:/Users/USER/Documents/UR 2021-2/MCPP/Project/donations_in_peace")

#Import all downloaded datasets - all corporations
path <- "data/auxiliar/names/2011"
files <- list.files(path, pattern ="*.xls", full.names = TRUE)

import_function <- function(file){
  base <- read_excel(file, range = cell_limits(c(13,4),c(NA,NA)))%>%
    select(name=`Nombre de la Persona Natural o Jurídica`,
           amount=Valor)%>%
    filter(name!="TOTAL"&!is.na(name))%>%
    mutate(candidate=str_replace_all(file,path, ""))
  base$amount <- as.numeric(base$amount)
  base
}

df.list <- lapply(files, import_function)
donors <- bind_rows(df.list)
#Get the name of the candidate
donors <- donors%>%
  mutate(candidate=str_replace_all(candidate, ".xls",""))%>%
  mutate(candidate=str_replace_all(candidate,"_\\d{8}_\\d{2,3}",""))%>%
  mutate(candidate=str_replace_all(candidate,"_"," "))%>%
  mutate(candidate=str_replace_all(candidate,"\\s{2,3}"," "))%>%
  mutate(candidate=str_replace_all(candidate,"\\s{1,2}"," "))%>%
  mutate(candidate=str_replace_all(candidate,"\\d",""))%>%
  mutate(candidate=str_to_upper(candidate))%>%
  mutate(clean_name=str_replace_all(candidate," ",""),
         clean_name=str_remove_all(clean_name,"/"))

#Merge candidates with location and party information (allcandidates names)
candidatesnames <- read_csv("data/auxiliar/allcandidatesnames11.csv")%>%
  filter(corp=="Alcaldía")%>%
  rename(candidate=name)%>%
  mutate(clean_name=str_replace_all(candidate," ",""))

#Merge donors table with municipalities
#Drop candidates names that are in two municipalities 
#keep only the observations with valid donors
candidatesnames <- candidatesnames %>%
  mutate(wrong=if_else(clean_name=="CARLOSENRIQUEDIAZHERRERA"&mpio=="COPACABANA",1,0),
         wrong=if_else(clean_name=="CARLOSGUILLERMOPEÑALOPERA"&mpio=="ENTRERRIOS",1,wrong),
         wrong=if_else(clean_name=="JOHNJAIROCORREA"&mpio=="CAREPA",1,wrong),
         wrong=if_else(clean_name=="JORGEELIECERFLOREZ"&mpio=="CHIGORODO",1,wrong),
         wrong=if_else(clean_name=="MAURICIOCHAPARROALARCON"&mpio=="CUITIVA",1,wrong),
         wrong=if_else(clean_name=="ALBERTOHERRERA"&mpio=="CURILLO",1,wrong),
         wrong=if_else(clean_name=="CLAUDIAPATRICIAGARCIALOPEZ"&mpio=="NEIRA",1,wrong),
         wrong=if_else(clean_name=="EDGARCASTILLO"&mpio=="MERCADERES",1,wrong),
         wrong=if_else(clean_name=="FRANCISCOLOPEZLOPEZ"&mpio=="CHIQUIZA",1,wrong),
         wrong=if_else(clean_name=="JUANCARLOSFLOREZ"&mpio=="RICAURTE",1,wrong),
         wrong=if_else(clean_name=="RODOLFODIAZDIAZ"&mpio=="MOGOTES",1,wrong),
         wrong=if_else(clean_name=="WILLIAMHERRERA"&mpio=="GAMBITA",1,wrong),)%>%
  filter(wrong==0)

full_donors <- donors%>%
  left_join(candidatesnames, by="clean_name")
#Drop wrong observations after match (Martha Cecilia Herrera)
full_donors <- full_donors%>%
  mutate(wrong_dup=if_else(clean_name=="MARTHACECILIAHERRERA"&name=="ADRIAN BEDOYA CANO"&mpio=="VENECIA",1,0),
         wrong_dup=if_else(clean_name=="MARTHACECILIAHERRERA"&name=="LUIS GONZALO MARTINEZ"&mpio=="SANTUARIO",1,wrong_dup))%>%
  filter(wrong_dup==0)
#Correct those candidtates without matched location and corporation (173 obs, 51 candidates)
#Generate the dataset
unmatched_c <- c("ROSA EMILIA MORENO VELASQUEZ","ANGEL ALBERTO ROYS MEJIA","RAFAEL RICARDO CEBALLOS SIERRA","VICTOR MANUEL GOMEZ CORTEZ","CRISTINA OTALVARO IDARRAGA",
                 "BERNARDO ANTONIO RESTREPO CATAÑO","MERLY SANCHEZ POVEDA","NAYDU ESPERANZA BURBANO ORDOÑEZ","CECILIO MORENO ARROYO","FELIX GUTIERREZ CORDOBA",
                 "JOSE MANUEL QUINTERO MEDINA","JUAN CARLOS CASALLAS RIVAS","FREDYS PALACIOS RAMIREZ","CARMEN ESTHER ACOSTA MARRIAGA","HUBER PARADA QUINTERO","JOSE DAVID BELTRAN OBANDO",
                 "JESUS ANTONIO PEÑA MARTINEZ","CLARA INES SAAVEDRA BEJARANO","YILIO PEREA CUESTA","FREDY ENRRIQUE CASTRO GOMEZ","JAIME ALONSO BOLAÑOS BOLAÑOS","ORLANDO MARTINEZ AVILA",
                 "DORCY MAYLY DOMINGUEZ JARAMILLO","REINEL JOSE LOBO GALVIS","DARWIN JAIR CORDOBA ASPRILLA","YESID HERIBERTO LIÑAN CAMACHO","OSCAR GILDARDO OCAMPO CUERVO","OMAR ALFONSO DIAZ GUTIERREZ",
                 "PEDRO VICENTE SALAMANCA MORENO","DORIS ACERO DE VERA","RODOLFO ANDREY PLAZAS MAHECHA","JOSE MARTIN PEÑUELA BELTRAN","ANCIZAR SOTO MEJIA","AMAURY ALBERTO MONTES SALCEDO",
                 "JESUS EDISSON RAMIREZ MARTINEZ","JULIO CESAR SALAS BALDOVINO","LUISANDRO GIRALDO BETANCUR","RAMON DANIEL REALES MOLINARES","OSCAR HERNANDO SIERRA ZULETA","ISMAEL QUINTERO TIBADUIZA",	
                 "JAIDY NEIRA LOPEZ","JORGE ELIECER MORALES HERNANDEZ","GINA YISETH SALAZAR LEMUS","LEDIN ANDREY GAUTA FLOREZ","MARIA PEREZ ","LUIS ARMANDO CALDAS FLORIAN","YESID JASSIR VERGARA",
                 "DIEGO ALBERTO PEÑA CRUZ","LUIS ALEJANDRO CHACON CUBILLOS","FERNEY ADEL BERTEL ROJAS")
unmatched_m <- c("RIOSUCIO","RIOHACHA","RIOHACHA","UNGUIA","NEIRA","EBEJICO","TOGUI","YUMBO","RIOSUCIO","BUENAVISTA","RIOHACHA","YAGUARA","ALTO BAUDO","SANTA BARBARA DE PINTO",
                 "LA GLORIA","PUENTE NACIONAL","LA GLORIA","TOGUI","RIOSUCIO","BARRANCA DE UPIA","LA CRUZ","MONTERREY","UNGUIA","LA GLORIA","RIOSUCIO","SOLEDAD","MARQUETALIA","SITIONUEVO",
                 "LA SALINA","GUADUAS","RECETOR","SOACHA","NORCASIA","ALTOS DEL ROSARIO","GUADUAS","ALTOS DEL ROSARIO","MARQUETALIA","CALAMAR","GUADALUPE","LA SALINA","LA SALINA",
                 "MONTERREY","LA SALINA","CACOTA","BOGOTA","SAN PABLO DE BORBUR","CALAMAR","RECETOR","BARRANCA DE UPIA","BUENAVISTA")
unmatched_d <- c("CHOCO","LA GUAJIRA","LA GUAJIRA","CHOCO","CALDAS","ANTIOQUIA","BOYACA","VALLE DEL CAUCA","CHOCO","CORDOBA","LA GUAJIRA","HUILA",
                 "CHOCO","MAGDALENA","CESAR","SANTANDER","CESAR","BOYACA","CHOCO","META","NARIÑO","CASANARE","CHOCO","CESAR","CHOCO","ATLANTICO","CALDAS","MAGDALENA",
                 "CASANARE","CUNDINAMARCA","CASANARE","CUNDINAMARCA","CALDAS","BOLIVAR","CUNDINAMARCA","BOLIVAR","CALDAS","BOLIVAR","SANTANDER","CASANARE","CASANARE",
                 "CASANARE","CASANARE","NORTE DE SANTANDER","BOGOTÁ D.C.","BOYACA","BOLIVAR","CASANARE","META","CORDOBA")
unmatched_corp <- c("Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Concejo","Alcaldía","Concejo","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía",
                    "Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Concejo","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Concejo","Alcaldía","Alcaldía",
                    "Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Concejo","Concejo","Alcaldía","Concejo","Alcaldía","Concejo","Alcaldía","Alcaldía","Alcaldía","Alcaldía","Alcaldía")
unmatched_party <- c("PARTIDO CAMBIO RADICAL","MOVIMIENTO AUTORIDADES INDIGENAS DE COLOMBIA -AICO-","PARTIDO LIBERAL COLOMBIANO","PARTIDO CAMBIO RADICAL",
                     "PARTIDO CONSERVADOR COLOMBIANO","PARTIDO CAMBIO RADICAL","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-","MOVIMIENTO - MIRA -",
                     "MOVIMIENTO AFROVIDES - LA ESPERANZA DE UN PUEBLO","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-",
                     "PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-","PARTIDO CAMBIO RADICAL","PARTIDO VERDE","PARTIDO LIBERAL COLOMBIANO",
                     "PARTIDO DE INTEGRACION NACIONAL -PIN-","PARTIDO CAMBIO RADICAL","PARTIDO CONSERVADOR COLOMBIANO","PARTIDO LIBERAL COLOMBIANO",
                     "PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-","PARTIDO CAMBIO RADICAL","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-",
                     "MOVIMIENTO DE INCLUSION Y OPORTUNIDADES -MIO-","PARTIDO CONSERVADOR COLOMBIANO","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-","PARTIDO VERDE",
                     "MOVIMIENTO AUTORIDADES INDIGENAS DE COLOMBIA -AICO-","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-",
                     "PARTIDO ALIANZA SOCIAL INDEPENDIENTE - ASI","MOVIMIENTO AFROVIDES - LA ESPERANZA DE UN PUEBLO","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-",
                     "PARTIDO CAMBIO RADICAL","PARTIDO CONSERVADOR COLOMBIANO","PARTIDO VERDE","PARTIDO CAMBIO RADICAL","PARTIDO LIBERAL COLOMBIANO",
                     "PARTIDO LIBERAL COLOMBIANO","PARTIDO CONSERVADOR COLOMBIANO","PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-",
                     "PARTIDO SOCIAL DE UNIDAD NACIONAL -PARTIDO DE LA U-","MOVIMIENTO DE INCLUSION Y OPORTUNIDADES -MIO-","MOVIMIENTO DE INCLUSION Y OPORTUNIDADES -MIO-",
                     "PARTIDO LIBERAL COLOMBIANO","MOVIMIENTO DE INCLUSION Y OPORTUNIDADES -MIO-","PARTIDO CONSERVADOR COLOMBIANO","PARTIDO EJEMPLO",
                     "PARTIDO CONSERVADOR COLOMBIANO","PARTIDO DE INTEGRACION NACIONAL -PIN-","PARTIDO VERDE","PARTIDO VERDE","PARTIDO LIBERAL COLOMBIANO")
unmatched_obs <- tibble(unmatched_c,unmatched_corp,
                            unmatched_d,unmatched_m,unmatched_party)%>%
  rename(candidate.x=unmatched_c)
#Get municipal codes from other observations the full donors dataset
mpio_codes <- full_donors%>%
  ungroup()%>%
  select(mpio,dpto,codmpio,coddpto)%>%
  distinct(codmpio,.keep_all = TRUE)
unmatched_obs <- unmatched_obs%>%
  left_join(mpio_codes,by=c("unmatched_m"="mpio",
                            "unmatched_d"="dpto"))%>%
  mutate(codmpio=if_else(unmatched_m=="NEIRA","17486",codmpio),
         codmpio=if_else(unmatched_m=="TOGUI","15816",codmpio),
         codmpio=if_else(unmatched_m=="ALTO BAUDO","27025",codmpio),
         codmpio=if_else(unmatched_m=="LA CRUZ","52378",codmpio),
         codmpio=if_else(unmatched_m=="ALTOS DEL ROSARIO","13030",codmpio),
         codmpio=if_else(unmatched_m=="GUADALUPE","68320",codmpio),
         codmpio=if_else(unmatched_m=="SAN PABLO DE BORBUR","15681",codmpio),
         coddpto=if_else(is.na(coddpto)==TRUE,str_sub(codmpio,1,2),coddpto))%>%
  rename(unmatched_codmpio=codmpio,
         unmatched_coddpto=coddpto)
#Merge unmatched with full donors dataset
full_donors <- full_donors%>%
  left_join(unmatched_obs,by="candidate.x")
#Replace the missing variable values with the new ones
full_donors <- full_donors%>%
  mutate(mpio=if_else(is.na(unmatched_m)==FALSE,unmatched_m,mpio),
         dpto=if_else(is.na(unmatched_d)==FALSE,unmatched_d,dpto),
         corp=if_else(is.na(unmatched_corp)==FALSE,unmatched_corp,corp),
         codmpio=if_else(is.na(unmatched_codmpio)==FALSE,unmatched_codmpio,codmpio),
         coddpto=if_else(is.na(unmatched_coddpto)==FALSE,unmatched_coddpto,coddpto),
         party=if_else(is.na(unmatched_party)==FALSE,unmatched_party,party))
#Drop id (no obs), upper case donors' name, keep
#relevant variables and export dataset
final_data <- full_donors%>%
  ungroup()%>%
  select(name, amount, candidate=candidate.x, 
         corp, dpto, mpio, party, codmpio,coddpto)%>%
  mutate(name=str_to_upper(name))%>%
  arrange(corp,codmpio)
#Add departament codes to department-level corporations
department_codes <- final_data%>%
  filter(corp=="Alcaldía")%>%
  group_by(dpto,coddpto)%>%
  summarize(cuenta=n())%>%
  select(-cuenta)
final_data <- final_data%>%
  left_join(department_codes,by="dpto")%>%
  select(-coddpto.x)%>%
  rename(coddpto=coddpto.y)%>%
  mutate(candidate=str_remove_all(candidate,"/"))
#Export as csv and excel
write_csv(final_data, "data/auxiliar/names/donors_2011.csv")