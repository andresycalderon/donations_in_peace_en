# Political donations in war and in peace

## Description and motivation
In October 2012, the Colombian government started peace negotiations with the FARC guerrilla. This process would result in a unilateral ceasefire by the armed group in December 2014, and eventually the signing of the peace agreement in 2016.

The effects of the peace process with the FARC guerrilla have been heterogeneous. Municipalities with presence of the armed group experienced a relative large decrease in the number of violent events after the creasefire, according to data from the Center of Resources to the Analysis of Conflicts (CERAC). They also improved education outcomes (Prem et al., 2021) and their fertility rate (Guerra-Cújar et al., 2021). However, the process also generated perverse incentives that augmented deforestation (Prem, Saavedra, et al., 2020), illicit crops (Prem, Vargas, et al., 2020), and the assassination of social leaders (Marín Llanes, 2020). 

What is the impact of the peace process on private investment? *A priori,* one would expect an increase in this variable because the reduction in conflict and the benefits of the peace agreement in the affected areas should improve the business confidence. An especial type of investment are donations to political campaings. In this project I seek to identify if political donations increased in municipalities with FARC presence after the ceasefire and the peace agreement.

Project presentation in PDF (in Spanish) can be found [here](presentation/presentacion.pdf)

## Methods
### Web Scraping
- The app Cuentas Claras (https://www.cnecuentasclaras.gov.co/) contains three websites (one per year) that allow to download information on campaings' finance for all the candidates to three local elections: 2011, 2015 and 2019.
  - 2011: https://app.cnecuentasclaras.gov.co/CuentasClarasTer2010/publicacioncandidatos.aspx 
  - 2015: https://app.cnecuentasclaras.gov.co/CuentasClarasPublicoTer2015/Consultas/Candidatos/
  - 2019: https://app.cnecuentasclaras.gov.co/CuentasClarasPublicoTer2019/Consultas/Candidatos/
- All the websites are built using JavaScript and CSS. I use the R library *RSelenium* to get the list of all mayor candidates in Colombian municipalities, and download the format 5.3B, which contains all private donations.
- These formats are in excel, and contain the name of the donor and the amount donated. The steps to download the information vary as follows:
  - For 2015 and 2019, the code gets the list of candidates, including an identifier. Then I used a loop to go to each candidate's page using their ID and download the list of donors. You can find the code for 2015 [here](code/get_donors_15.R) and the code for 2019 [here](code/get_donors_19.R).
  - I built two codes for 2011. [Get_donors_11](code/get_donors_11.R) goes through all websites with candidates to the municipality government, and downloads the datasets containing the donations. [Unify_donors_11](code/unify_donors_11.R) binds all the excel sheets and matches the donors with their candidates by name (given that for 2011 the electoral authority does not create and ID in Cuentas Claras). 
### Matching candidates and donors in Pandas 
- I used Python to create three databases (one per year) at the municipality level, containing the following variables of interest:
   - Total number of donors per municipality.
   - Average number of donors per candidate.
   - Total amount donated by municipality.
   - Average amount of donations per candidate.
- This process involved the following steps:
   - Match the candidates with their donors for 2015 and 2019 using the politician's identifier.
   - Calculate the total amount for each candidate-donor pair, and the total number of donors and amount per candidate.
   - Compute the variables of interest by municipality
- You cand find the Jupyter Notebook code [here](code/merge_donors_datasets.ipynb)
### Making plots and maps in R
- Con los datos de donación a nivel de municipio, construí las siguientes figuras en R:
  - Mapas que reflejan la distribución municipal de las variables de interés por año (Código [aquí](code/animated-map-donors.R)).
  - Top 10 municipios con los mayores valores en donación, según variable (Código [aquí](code/plot-rankofmpios.R)).
  - Evolución de las variables de interés en los tres años electorales, para los municipios con y sin presencia de las FARC en 2011 (Código [aquí](code/plot-evolutions-byfarc.R))
### Regresión lineal en R para estimar impacto del cese al fuego
- Usando la librería *Fixest*, estimé un modelo de diferencias en diferencias para identificar el impacto del cese al fuego sobre las estadísticas de donación. La ecuación a estimar es la siguiente:

<p align="center"> <img src="https://render.githubusercontent.com/render/math?math=Y_{it} = \alpha_i %2B \gamma_t %2B \beta (Ceasefire \times FARC) %2B \varepsilon_{it}"></p>
Esta ecuación incluye efectos fijos de municipio (i), y de año de elección (t). (Ceasefile x FARC) es una dummy que toma el valor de 1 para municipios con presencia de las FARC después de 2014, y 0 si no se cummplen ambas condiciones. 

## Hallazgos
### Distribución espacial de las variables de interés (2011)
Las siguientes gráficas muestran cómo se distribuyen espacialmente las variables de interés para el año 2011. Las figuras para el resto de años se encuentran en el siguiente [enlace](output/evol-by-municipality/)

En términos generales, los donantes se encuentran concentrados en las grandes ciudades. Lo mismo sucede con el monto donado. 

<img src="output/evol-by-municipality/donorssum-2011.png" width="500"> <img src="output/evol-by-municipality/donorsmean-2011.png" width="500">
<img src="output/evol-by-municipality/totalamount-2011.png" width="500"> <img src="output/evol-by-municipality/averageamount-2011.png" width="500">

Las siguientes figuras enseñan el top 10 de municipios sin (en azul) y con (en rojo) presencia de las FARC en 2011 según promedio de estadísticas de donación. Si bien estos rankings están formados en gran medida por ciudades capitales, también sobresalen algunos municipios intermedios.

<img src="output/top10_donors_sum_nonfarc.png" width="500"> <img src="output/top10_donors_sum_farc.png" width="500">
<img src="output/top10_donors_mean_nonfarc.png" width="500"> <img src="output/top10_donors_mean_farc.png" width="500">
<img src="output/top10_amount_sum_nonfarc.png" width="500"> <img src="output/top10_amount_sum_farc.png" width="500">

### Evaluación del impacto del cese al fuego sobre la donación privada

El modelo de diferencias en diferencias evalúa la evolución del *outcome* en el grupo de tratados (en este caso, municipios con presencia de las FARC) después del tratamiento, y la compara con la evolución en el grupo de control (en este caso, municipios sin presencia de las FARC). 

Para este estudio se esperaría que la donación creciera relativamente en los municipios con presencia de las FARC después del cese al fuego en 2014. Las siguientes figuras muestran la evolución del promedio de los cuatro outcomes de interés. Si bien se ve un crecimiento diferencial en el monto total donado por municipio, no es muy claro en las demás variables. Incluso, para 2019, vemos una disminución relativa en el monto de donación por candidato. 

<img src="output/evol_donors_sum_mean.png" width="500"><img src="output/evol_donors_mean_mean.png" width="500">
<img src="output/evol_amount_sum_mean.png" width="500"><img src="output/evol_amount_mean_mean.png" width="500">

#### Estimación del modelo de diferencias en diferencias:
Debido a que las gráficas no muestran un efecto claro del proceso de paz sobre las donaciones, se procede a estimar la ecuación de efectos fijos. La siguiente tabla muestra los coeficientes y sus respectivos errores estándar en paréntesis. 

Si bien los coeficientes estimados tienen signo positivo (a excepción del de donantes por candidato), ninguno es estadísticamente diferente de cero bajo un nivel de significancia menor al 10%. Por tanto, por lo menos para las donaciones a candidatos a alcaldía, no se puede concluir que el cese al fuego y el acuerdo de paz generaron aumentos en la inversión política. 


|       &nbsp;        | Total de donantes | Donantes por cand. |log(Monto total) |log(Monto por cand)|
|:-------------------:|:-----------------:|:------------------:|:---------------:|:-----------------:|
|                     |                   |                    |                 |                   |
| **CEASEFIRExFARC**  |   1.057 (1.403)   |  -0.1621 (0.4312)  | 0.0429 (0.1418) | 0.0408 (0.1300)   |
| **Fixed-Effects:**  |   -------------   |  ----------------  | --------------- | ----------------- |
|  **Municipality**   |        Yes        |        Yes         |       Yes       |        Yes        |
|      **Year**       |        Yes        |        Yes         |        Yes      |        Yes        |
| **_______________** |   _____________   |  ________________  | _______________ | _________________ |
| **S.E.: Clustered** |   by: Municip..   |  by: Municipality  | by: Municipal.. |  by: Municipal..  |
|  **Observations**   |       3,365       |       3,365        |      2,421      |       2,421       |
|       **R2**        |       0.779       |       0.547        |      0.726      |       0.676       |

### Agenda a futuro:
- Incorporar nuevas corporaciones (concejos y juntas de acción comunal)
- Añadir más variables que demuestren la inversión privada en los municipios

## Referencias
Guerra-Cújar, M. E., Prem, M., Rodríguez-Lesmes, P., & Vargas, J. F. (2021). A Peace Baby Boom? Evidence from Colombia’s Peace Agreement. https://doi.org/10.31235/osf.io/c2ypd

Marín Llanes, L. (2020). Unintended Consequences of Alternative Development Programs: Evidence From Colombia’s Illegal Crop Substitution. Documento CEDE, No. 40. https://doi.org/10.2139/ssrn.3706297

Prem, M., Saavedra, S., & Vargas, J. F. (2020). End-of-conflict deforestation: Evidence from Colombia’s peace agreement. *World Development, 129*, 104852. https://doi.org/https://doi.org/10.1016/j.worlddev.2019.104852

Prem, M., Vargas, J. F., & Mejía, D. (2020). The Rise and Persistence of Illegal Crops: Evidence from a Naïve Policy Announcement.

Prem, M., Vargas, J. F., & Namen, O. (2021). The Human Capital Peace Dividend. *Journal of Human Resources*. https://doi.org/10.3368/jhr.59.1.0320-10805R2 

