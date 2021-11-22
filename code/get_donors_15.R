#Get the donors sheets for all corps (except JAL) for 2015
setwd("D:/Users/USER/Documents/UR 2021-2/MCPP/Project/donations_in_peace")

#Libraries
library(tidyverse)
library(httr)
library(rvest)
library(RSelenium)
library(readxl)

#Open the Rselenium browser 
#IMPORTANT: CHECK CHROME VERSION
driver <- rsDriver(browser = c("chrome"), chromever = "95.0.4638.69")
remote_driver <- driver[["client"]]

remote_driver$open()

#Navigate the web page
remote_driver$navigate("https://app.cnecuentasclaras.gov.co/CuentasClarasPublicoTer2015/Consultas/Candidatos/")

#Get list of all possible positions (corporations)
crps <- remote_driver$findElement(using='xpath', '//*[@id="comboInforme"]')
corps <- crps$selectTag() %>% .$value %>% length()

#Comment: There are differences between departamento-level positions 
#and municipality-level positions. Create two vectors: one that indexes
#Departamento level vectors and other for municipality
mpio_corps <- c(2) #add 4
dpto_corps <- c(3,5)

#Mpio Selector Function
mpio_fun <- function(mpio, dpto){
  #Get departamento name 
  dpto_name <- dpto
  #Open the municipality box
  mpiobox <- remote_driver$findElement(using = 'xpath', '//*[@id="comboMunicipio_chosen"]/a')
  mpiobox$clickElement()
  first <- '//*[@id="comboMunicipio_chosen"]/div/ul/li['
  second <- toString(mpio)
  third <- ']'
  final  <- paste0(first, second, third)
  selected_mpio <- remote_driver$findElement(using='xpath', final)
  #Get municipality name and click on it
  mpio_name <- selected_mpio$getElementText()[[1]]
  selected_mpio$clickElement()
  #Click on search
  search <- remote_driver$findElement(using='xpath', '//*[@id="BuscarFiltro"]')
  search$clickElement()
  Sys.sleep(8)
  #Get the name of all candidates
  html <- remote_driver$getPageSource()[[1]]
  cand_name <- read_html(html) %>%
    html_nodes("#tblDatos td:nth-child(3)") %>%
    html_text()
  #Get the political party of all candidates
  cand_party <- read_html(html) %>%
    html_nodes("#tblDatos td:nth-child(2)")%>%
    html_text()
  #Create a vector with the municipality name
  len <- cand_name%>%length()
  cand_mpio <- replicate(len, mpio_name)
  #Get name of departamento and create a vector with it
  cand_dpto <- replicate(len, dpto_name)
  #Get corporation
  cand_corp <- read_html(html) %>%
    html_nodes("#tblDatos td:nth-child(1)")%>%
    html_text()
  corp_name <- cand_corp[1]
  #Get the webpage number associated with each candidate
  numbers_nodes <- read_html(html)%>%
    html_nodes(".ui-corner-all")
  
  cand_number <- purrr::map(numbers_nodes,
                            xml_attrs)%>%
    bind_rows(.)%>%
    filter(!is.na(onclick))%>%
    mutate(onclick=str_remove_all(onclick,"return verInformacion"),
           onclick=str_remove_all(onclick,";|\\(|\\)"))%>%
    select(onclick)%>%
    as_vector(.)
  #Check the number of candidates:
  nocandidates <- read_html(html)%>%
    html_node("#tblDatos_info")%>%
    html_text()
  nocandidates <- nocandidates%>%
    str_remove_all(.,"Mostrando \\d* a \\d* de | registros")%>%
    strtoi(.)
  #Next Button
  nxt_btn <- remote_driver$findElement(using='xpath', '//*[@id="tblDatos_next"]')
  #Number of repetitions
  repetitions <- ceiling(nocandidates/10)
  x <- 1
  while(x<repetitions){
    Sys.sleep(1.25)
    #Click on the button
    nxt_btn$clickElement()
    html <- remote_driver$getPageSource()[[1]]
    cand_name2 <- read_html(html) %>%
      html_nodes("#tblDatos td:nth-child(3)") %>%
      html_text()
    #Get the political party of all candidates
    cand_party2 <- read_html(html) %>%
      html_nodes("#tblDatos td:nth-child(2)")%>%
      html_text()
    #Create a vector with the minicipality name
    len <- cand_name2%>%length()
    cand_mpio2 <- replicate(len, mpio_name)
    #Create a vector with the departamento name
    cand_dpto2 <- replicate(len, dpto_name)
    #Get corporation
    cand_corp2 <- read_html(html) %>%
      html_nodes("#tblDatos td:nth-child(1)")%>%
      html_text()
    Sys.sleep(2)
    #Get the webpage number associated to each candidate
    numbers_nodes2 <- read_html(html)%>%
      html_nodes(".ui-corner-all")
    
    cand_number2 <- purrr::map(numbers_nodes2,
                               xml_attrs)%>%
      bind_rows(.)%>%
      filter(!is.na(onclick))%>%
      mutate(onclick=str_remove_all(onclick,"return verInformacion"),
             onclick=str_remove_all(onclick,";|\\(|\\)"))%>%
      select(onclick)%>%
      as_vector(.)
    
    cand_name <- c(cand_name,cand_name2)
    cand_party <- c(cand_party,cand_party2)
    cand_corp <- c(cand_corp,cand_corp2)
    cand_mpio <- c(cand_mpio, cand_mpio2)
    cand_dpto <- c(cand_dpto,cand_dpto2)
    cand_number <- c(cand_number,cand_number2)
    x <- x+1
  }
  #Get dataset:
  mpio_data <- data.frame(corp=cand_corp,
                          dpto=cand_dpto,
                          mpio=cand_mpio,
                          name=cand_name, 
                          party=cand_party,
                          wp_no=cand_number)
  mpiopath <- paste0("data/auxiliar/names/2015/",
                     corp_name, "_",
                     dpto_name, "_", 
                     mpio_name,".csv")
  #Export in a csv
  write_csv(mpio_data, path = mpiopath)
  
  #Back Button 
  bck_btn <- remote_driver$findElement(using='xpath', '//*[@id="tblDatos_previous"]')
  
  #Go back to the first page
  j <- x
  while(j>0){
    bck_btn$clickElement()
    Sys.sleep(1)
    j=j-1
  }
}
#Dpto Selector Function
dpto_fun <- function(dpto){
  #Open the departamentos box
  dptobox <- remote_driver$findElement(using = 'xpath', '//*[@id="comboDepartamento_chosen"]/a')
  dptobox$clickElement()
  #Selector
  first  <- '//*[@id="comboDepartamento_chosen"]/div/ul/li['
  second <- toString(dpto)
  third  <- ']'
  final  <- paste0(first, second, third)
  selected_dpto <- remote_driver$findElement(using='xpath', final)
  dpto_name <- selected_dpto$getElementText()[[1]]
  selected_dpto$clickElement()
  Sys.sleep(1)
  
  #Number of municipalities
  mpios <- remote_driver$findElement(using='xpath', '//*[@id="comboMunicipio"]')
  mnpios <- mpios$selectTag() %>% .$value %>% length()
  nompios <- c(2:mnpios)
  
  lapply(nompios, mpio_fun, dpto=dpto_name)
  
}
#Depto function (for departamento-level corporations)
dpto2_fun <- function(dpto){
  #Open the departamento box
  dptobox <- remote_driver$findElement(using = 'xpath', '//*[@id="comboDepartamento_chosen"]/a')
  dptobox $clickElement()
  first <- '//*[@id="comboDepartamento_chosen"]/div/ul/li['
  second <- toString(dpto)
  third <- ']'
  final  <- paste0(first, second, third)
  selected_dpto <- remote_driver$findElement(using='xpath', final)
  #Get municipality name and click on it
  dpto_name <- selected_dpto$getElementText()[[1]]
  selected_dpto$clickElement()
  #Click on search
  search <- remote_driver$findElement(using='xpath', '//*[@id="BuscarFiltro"]')
  search$clickElement()
  Sys.sleep(10)
  #Get the name of all candidates
  html <- remote_driver$getPageSource()[[1]]
  cand_name <- read_html(html) %>%
    html_nodes("#tblDatos td:nth-child(3)") %>%
    html_text()
  #Get the political party of all candidates
  cand_party <- read_html(html) %>%
    html_nodes("#tblDatos td:nth-child(2)")%>%
    html_text()
  #Create a vector with the departamento name
  len <- cand_name%>%length()
  cand_dpto <- replicate(len, dpto_name)
  #Get corporation
  cand_corp <- read_html(html) %>%
    html_nodes("#tblDatos td:nth-child(1)")%>%
    html_text()
 corp_name <- cand_corp[1]
 #Get the webpage number associated with each candidate
 numbers_nodes <- read_html(html)%>%
   html_nodes(".ui-corner-all")
 
 cand_number <- purrr::map(numbers_nodes,
                       xml_attrs)%>%
   bind_rows(.)%>%
   filter(!is.na(onclick))%>%
   mutate(onclick=str_remove_all(onclick,"return verInformacion"),
          onclick=str_remove_all(onclick,";|\\(|\\)"))%>%
   select(onclick)%>%
   as_vector(.)
 #Check the number of candidates
 nocandidates <- read_html(html)%>%
   html_node("#tblDatos_info")%>%
   html_text()
 nocandidates <- nocandidates%>%
   str_remove_all(.,"Mostrando \\d* a \\d* de | registros")%>%
   strtoi(.)
 #Next and Back Buttons
 nxt_btn <- remote_driver$findElement(using='xpath', '//*[@id="tblDatos_next"]')
 bck_btn <- remote_driver$findElement(using='xpath', '//*[@id="tblDatos_previous"]')
 #Number of repetitions
 repetitions <- ceiling(nocandidates/10)
 x <- 1
 while(x<repetitions){
   #Click on the button
   nxt_btn$clickElement()
   Sys.sleep(1.5)
   html <- remote_driver$getPageSource()[[1]]
   cand_name2 <- read_html(html) %>%
     html_nodes("#tblDatos td:nth-child(3)") %>%
     html_text()
   #Get the political party of all candidates
   cand_party2 <- read_html(html) %>%
     html_nodes("#tblDatos td:nth-child(2)")%>%
     html_text()
   #Get the webpage number associated to each candidate
   numbers_nodes2 <- read_html(html)%>%
     html_nodes(".ui-corner-all")
   
   cand_number2 <- purrr::map(numbers_nodes2,
                         xml_attrs)%>%
     bind_rows(.)%>%
     filter(!is.na(onclick))%>%
     mutate(onclick=str_remove_all(onclick,"return verInformacion"),
            onclick=str_remove_all(onclick,";|\\(|\\)"))%>%
     select(onclick)%>%
     as_vector(.)
   
   #Create a vector with the departamento name
   len <- cand_name2%>%length()
   cand_dpto2 <- replicate(len, dpto_name)
   #Get corporation
   cand_corp2 <- read_html(html) %>%
     html_nodes("#tblDatos td:nth-child(1)")%>%
     html_text()
   cand_name <- c(cand_name,cand_name2)
   cand_party <- c(cand_party,cand_party2)
   cand_corp <- c(cand_corp,cand_corp2)
   cand_dpto <- c(cand_dpto,cand_dpto2)
   cand_number <- c(cand_number,cand_number2)
   x <- x+1
 }
     dpto_data <- data.frame(corp=cand_corp,
                             dpto=cand_dpto,
                             name=cand_name, 
                             party=cand_party,
                             wp_no=cand_number)
     dptopath <- paste0("data/auxiliar/names/2015/",corp_name, 
                        "_", dpto_name,".csv")
     #Export in a csv
     write_csv(dpto_data, path = dptopath)
     
     #Go back to the first page
     j <- x
     while(j>0){
       bck_btn$clickElement()
       j=j-1
     }
  }
#Position selector function (municipality-level positions)
corp_fun <- function(corp){
  first  <- '//*[@id="comboInforme"]/option['
  second <- toString(corp)
  third  <- ']'
  final  <- paste0(first, second, third)
  selected_corp <- remote_driver$findElement(using='xpath', final)
  selected_corp_name <- selected_corp$getElementText()[[1]]
  selected_corp$clickElement()
  
  Sys.sleep(2)
  corp <- remote_driver$findElement(using='xpath', '//*[@id="comboClasificacion"]/option[2]')
  corp$clickElement()
  
  #Get list of all possible deparments
  Sys.sleep(1)
  dptos <- remote_driver$findElement(using='xpath', '//*[@id="comboDepartamento"]')
  deptos <- dptos$selectTag() %>% .$value %>% length()
  nodeptos <- c(2:deptos)
  
  #Run dpto function
  lapply(nodeptos, dpto_fun)
}
#Position selector function (departamento-level positions)
corp2_fun <- function(corp){
  first  <- '//*[@id="comboInforme"]/option['
  second <- toString(corp)
  third  <- ']'
  final  <- paste0(first, second, third)
  selected_corp <- remote_driver$findElement(using='xpath', final)
  selected_corp_name <- selected_corp$getElementText()[[1]]
  selected_corp$clickElement()
  
  Sys.sleep(2)
  corp <- remote_driver$findElement(using='xpath', '//*[@id="comboClasificacion"]/option[2]')
  corp$clickElement()
  
  #Get list of all possible deparments
  Sys.sleep(1)
  dptos <- remote_driver$findElement(using='xpath', '//*[@id="comboDepartamento"]')
  deptos <- dptos$selectTag() %>% .$value %>% length()
  nodeptos <- c(2:deptos)
  
  #Exclude Bogoga
  nodeptos <- nodeptos[nodeptos!=6]
  
  #Run dpto function
  lapply(nodeptos, dpto2_fun)
}
#Run corp functions
lapply(mpio_corps, corp_fun)
lapply(dpto_corps, corp2_fun)

#Close Selenium
remote_driver$close()


#--
#Join all the tables with 
#candidates' information
path <- "data/auxiliar/names/2015/"
files <- list.files(path, pattern ="*.csv", full.names = TRUE)

dflist <- lapply(files, read_csv)
candidates <- bind_rows(dflist)

#Detect and drop duplicates
candidates <- candidates%>%
  distinct(corp,dpto,mpio,name,party, .keep_all = TRUE)

#Export table
write_csv(candidates,
          path = 'data/auxiliar/allcandidatesnames15.csv')

#Download donors sheets
#Define download functions
download_donors_fun <- function(cand_number){
  temp = tempfile(fileext = ".xls")
  #Define URL containing the excel sheet
  basic_url <- 'https://app.cnecuentasclaras.gov.co/CuentasClarasPublicoTer2015/Consultas/Candidato/Formulario52xls/'
  cand_number_str <- paste0(cand_number)
  url <- paste0(basic_url,cand_number_str)
  #Download the file
  download.file(url,destfile = temp, mode='wb')
  #Import and process excel file to R
  donors_sheet <- read_excel(temp,
                             skip = 11)
  donors_sheet <- donors_sheet%>%
    select(name=`Nombre de la Persona Natural o Jurídica`,
           amount=Valor,
           id=`NIT o Cédula`,
           donation_dummy=Donación,
           credit_dummy=Crédito,
           prof=Profesión)%>%
    filter(!is.na(name) & name!="TOTAL")%>%
    mutate(amount=as.numeric(amount),
           cand_number=cand_number)
  
  if(nrow(donors_sheet)==0){
    donors_sheet <- tibble(name=NA_character_,
                           amount=NA_integer_,
                           id=NA_character_,
                           donation_dummy=NA_character_,
                           credit_dummy=NA_character_,
                           prof=NA_character_,
                           cand_number=NA_integer_)
  }
  donors_sheet
}
#Vector of candidate numbers
candidates_no_vtr <- candidates$wp_no%>%
  as_vector(.)
donors_raw <- lapply(candidates_no_vtr,
                     download_donors_fun)
donors_raw_df <- donors_raw%>%
  bind_rows(.)%>%
  filter(!is.na(cand_number))

write_csv(donors_raw_df,"data/auxiliar/names/donors_2015.csv")