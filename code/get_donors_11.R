#Download all files from the Cuentas Claras website
#All corporations (positions) - 2011 elections
setwd("D:/Users/USER/Documents/UR 2021-2/MCPP/Project/donations_in_peace")

#Libraries
library(tidyverse)
library(httr)
library(rvest)
library(RSelenium)

#Open the Rselenium browser
driver <- rsDriver(browser = c("chrome"), chromever = "95.0.4638.69")
remote_driver <- driver[["client"]]

remote_driver$open()

#Navigate the web page
remote_driver$navigate("https://app.cnecuentasclaras.gov.co/CuentasClarasTer2010/publicacioncandidatos.aspx")

#Comment: There are differences between departamento-level positions 
#and municipality-level positions. Create two vectors: one that indexes
#Departamento level vectors and other for municipality
mpio_corps <- c(3)
dpto_corps <- c(1,2)

#Downloader function
down_fun <- function(cand){
  first <- '//*[@id="ContentPlaceHolder1_grdConsulta_lnkF52Ax_'
  second <- toString(cand)
  third <- '"]'
  final <- paste0(first, second, third)
  selected_candidate <- remote_driver$findElement(using='xpath', final)
  selected_candidate$clickElement()
}
safe_down_fun <- function(cand){
  result <- try(down_fun(cand))
  if (class(result) == "try-error") { # if there is any error caught, return a blank dataframe and keep going
    cat("Error encountered for cand:", cand, "\n")
  } else { # if no error, keep going as normal to next zip
    return(result)
  }
}
#Mpio Selector Function
mpio_fun <- function(mpio, dpto){
  first_dpto <- '//*[@id="ContentPlaceHolder1_cboDepartamento"]/option['
  second_dpto <- toString(dpto)
  third <- ']'
  final_dpto  <- paste(first_dpto, second_dpto, third)
  #Get departamento name 
  selected_dpto <- remote_driver$findElement(using='xpath', final_dpto)
  dpto_name <- selected_dpto$getElementText()[[1]]
  first <- '//*[@id="ContentPlaceHolder1_cboMunicipio"]/option['
  second <- toString(mpio)
  final  <- paste0(first, second, third)
  selected_mpio <- remote_driver$findElement(using='xpath', final)
  #Get municipality name and click on it
  mpio_name <- selected_mpio$getElementText()[[1]]
  selected_mpio$clickElement()
  #Click on search
  search <- remote_driver$findElement(using='xpath', '//*[@id="ContentPlaceHolder1_btnBuscar"]')
  search$clickElement()
  #Errors! (for some municipalities)
  alert <- try(remote_driver$getAlertText(), silent=T)
  
  if(class(alert) != "try-error") {
    remote_driver$acceptAlert()
  } else {
    #Javascript (go to next page up to the limit)
      #If it has a null page (XXXXXXX), then stop the code
      page_body <- remote_driver$findElement(using='xpath',
                                             '/html/body')
      page_body_txt <- page_body$getElementText()[[1]]
  
        #Get number of candidates
        html <- remote_driver$getPageSource()[[1]]
        candidates <- read_html(html) %>%
          html_nodes("#ContentPlaceHolder1_grdConsulta") %>%
          html_table(fill=T)
        nocandidates <- candidates[[1]]$`Nombre Candidato`%>%length()
        candlist <- c(0:(nocandidates-1))
        lapply(candlist, safe_down_fun)
  }
}
#Dpto Selector Function
dpto_fun <- function(dpto){
  first  <- '//*[@id="ContentPlaceHolder1_cboDepartamento"]/option['
  second <- toString(dpto)
  third  <- ']'
  final  <- paste0(first, second, third)
  selected_dpto <- remote_driver$findElement(using='xpath', final)
  dpto_name <- selected_dpto$getElementText()[[1]]
  selected_dpto$clickElement()
  
  #Number of municipalities
  mpios <- remote_driver$findElement(using='xpath', '//*[@id="ContentPlaceHolder1_cboMunicipio"]')
  mnpios <- mpios$selectTag() %>% .$value %>% length()
  nompios <- c(2:mnpios)
  
  lapply(nompios, mpio_fun, dpto=dpto)
  
}
#Depto function (for departamento-level corporations)
dpto2_fun <- function(dpto){
  #Select departamento
  first  <- '//*[@id="ContentPlaceHolder1_cboDepartamento"]/option['
  second <- toString(dpto)
  third  <- ']'
  final  <- paste0(first, second, third)
  selected_dpto <- remote_driver$findElement(using='xpath', final)
  dpto_name <- selected_dpto$getElementText()[[1]]
  selected_dpto$clickElement()
  
  #Click on search
  search <- remote_driver$findElement(using='xpath', '//*[@id="ctl00_ContentPlaceHolder1_btnBuscar"]')
  search$clickElement()
  
  #Errors! (for some municipalities)
  alert <- try(remote_driver$getAlertText(), silent=T)
  
  if(class(alert) != "try-error") {
    remote_driver$acceptAlert()
  } else {
    #Javascript (go to next page up to the limit)
    x <- 1
    while(x<21){
      #If it has a null page (XXXXXXX), then stop the code
      page_body <- remote_driver$findElement(using='xpath',
                                             '/html/body')
      page_body_txt <- page_body$getElementText()[[1]]
      if(str_detect(page_body_txt,"XXXXXXXXX")==TRUE){
        j <- x
        while(j>1){
          remote_driver$goBack()
          j=j-1
        }
        x=22
      } else{
        #Get number of candidates
        html <- remote_driver$getPageSource()[[1]]
        candidates <- read_html(html) %>%
          html_nodes("#ctl00_ContentPlaceHolder1_grdConsulta") %>%
          html_table(fill=T)
        nocandidates <- candidates[[1]]$`Nombre Candidato`%>%length()
        candlist <- c(2:nocandidates)
        lapply(candlist, safe_down_fun)
        
        x <- x+1
        script <- paste0("__doPostBack('ctl00$ContentPlaceHolder1$grdConsulta','Page$",
                         toString(x),"')")
        remote_driver$executeScript(script)
      }
    }
  }
}
#Position selector function (departamento-level positions)
corp2_fun <- function(corp){
  #Select the option of municipality-level elections in 2011
  first  <- "//*/option[@value = '"
  second <- toString(corp)
  third  <- "']"
  final  <- paste0(first, second, third)
  selected_corp <- remote_driver$findElement(using='xpath', final)
  selected_corp_name <- selected_corp$getElementText()[[1]]
  selected_corp$clickElement()
  
  #Get list of all possible deparments
  dptos <- remote_driver$findElement(using='xpath', '//*[@id="ContentPlaceHolder1_cboDepartamento"]')
  deptos <- dptos$selectTag() %>% .$value %>% length()
  nodeptos <- c(2:deptos)
  
  #Run dpto function
  lapply(nodeptos, dpto2_fun)
}
#Position selector function (municipality-level positions)
corp_fun <- function(corp){
  #Select the option of municipality-level elections in 2011
  first  <- "//*/option[@value = '"
  second <- toString(corp)
  third  <- "']"
  final  <- paste0(first, second, third)
  selected_corp <- remote_driver$findElement(using='xpath', final)
  selected_corp_name <- selected_corp$getElementText()[[1]]
  selected_corp$clickElement()
  
  #Get list of all possible deparments
  dptos <- remote_driver$findElement(using='xpath', '//*[@id="ContentPlaceHolder1_cboDepartamento"]')
  deptos <- dptos$selectTag() %>% .$value %>% length()
  nodeptos <- c(4:deptos)
  
  #Run dpto function
  lapply(nodeptos, dpto_fun)
}
#Run corp functions
lapply(mpio_corps, corp_fun)
