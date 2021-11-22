#Run TWFE regressions to estimate the impact of the Peace
#Process on donation statistics
setwd("D:/Users/USER/Documents/UR 2021-2/MCPP/Project/donations_in_peace")

#Libraries
library(tidyverse)
library(sp)
library(gstat)
library(naniar)
library(fixest)
library(pander)
#Import Datasets
#Dataset at the municipality-year level with farc status and donation stats
all_mpios_panel <- read_csv('data/clean/panelfinal.csv')

#Generate after ceasefire dummy variable (yearly>2014)
all_mpios_panel <- all_mpios_panel%>%
  mutate(after2014=if_else(yearly>2014,1,0))

#Generate interaction between farc municipalities and after ceasefire
all_mpios_panel <- all_mpios_panel%>%
  mutate(FARC1=if_else(FARC1==1,1,0,missing = 0))%>%
  mutate(CEASEFIRExFARC=after2014*FARC1)%>%
  rename(Municipality=codmpio,
         Year=yearly)

#Run TWFE with municipality and year fixed effects, s.e clustered
#at the municipality level
donors_sum_mod = feols(donors_sum ~ CEASEFIRExFARC | Municipality + Year,
                   all_mpios_panel,vcov = ~Municipality)
donors_mean_mod = feols(donors_mean ~ CEASEFIRExFARC | Municipality + Year,
                   all_mpios_panel,vcov = ~Municipality)
amount_sum_mod = feols(log(amount_sum) ~ CEASEFIRExFARC | Municipality + Year,
                        all_mpios_panel,vcov = ~Municipality)
amount_mean_mod = feols(log(amount_mean) ~ CEASEFIRExFARC | Municipality + Year,
                        all_mpios_panel,vcov = ~Municipality)
#Make results' table
model_labels <- c("Total de donantes", "Donantes por cand.", "Monto total", "Monto por cand.")

etable(donors_sum_mod,donors_mean_mod,amount_sum_mod,amount_mean_mod,
       headers = model_labels,
       postprocess.df=pandoc.table.return,
       depvar=FALSE,
       digits.stats=3,
       fitstat=c('n','r2'),
       style="rmarkdown")
