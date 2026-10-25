/* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * -
*																			   *
* 					Proyecto HEC - Datos Anuarios DANE						   *
*						María José Fagua Ospina							 	   *
*					  Historia Económica de Colombia						   *
*																			   *
* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - * - */

clear all
set more off
cap log close

global dir   "C:\Users\majo_\OneDrive\Escritorio\Proyecto HEC" 
global bases  "$dir/Bases"      // carpeta con los .dta
global out  "$dir/salidas"

capture mkdir "$out"

set scheme s1mono            // esquema sencillo, fondo blanco
capture erase "$out/tablas_arroz_espinal.xlsx"

**# Del Espinal

* 1.1 Area cosechada por cultivo, 1989-1992 (ha)  [n. d. = missing]
clear
input int anio double(esp_arroz esp_algodon esp_sorgo)
1989 9047    .  3245
1990 7900 8900  6007
1991 5383 11648 3657
1992 4652 3300  3457
end
label var anio        "Año"
label var esp_arroz   "Arroz (ha)"
label var esp_algodon "Algodón (ha)"
label var esp_sorgo   "Sorgo (ha)"
save "$out/espinal_manual.dta", replace
export excel using "$out/tablas_arroz_espinal.xlsx", ///
    sheet("T6_3_Espinal_cultivos", replace) firstrow(varlabels)

* 1.2 Cifras de El Tiempo (no se sabe si sembrada o cosechada)
clear
input int anio double(arroz algodon)
1984 10338 13861
1994  8306  4723
end
label var anio    "Año"
label var arroz   "Arroz (ha)"
label var algodon "Algodón (ha)"
export excel using "$out/tablas_arroz_espinal.xlsx", ///
    sheet("T6_3b_ElTiempo", replace) firstrow(varlabels)

* 1.3 Poblacion de El Espinal
clear
input int anio double(rural pct_urbana)
1951 24818 27
1973  9612 77
end
gen total  = rural/(1 - pct_urbana/100)
gen urbana = total - rural
label var rural  "Rural"
label var urbana "Urbana"
save "$out/poblacion_manual.dta", replace
*/
*------------------------------------------------------------------------------
**# 2. Area, produccion y rendimiento del arroz en el Tolima

use "$bases/merge_tolima_nacional_anual.dta", clear
keep if inlist(anio, 1970, 1975, 1979, 1980, 1989, 1991)
gen rend_t_ha = arroz_rend_imp/1000          // n. d. desde 1985 (missing)
keep anio arroz_area arroz_prod rend_t_ha
label var anio       "Año"
label var arroz_area "Área (ha)"
label var arroz_prod "Producción (t)"
label var rend_t_ha  "Rendimiento (t/ha)"
format arroz_area arroz_prod %12.0fc
format rend_t_ha %4.1f
list, noobs sep(0)
export excel using "$out/tablas_arroz_espinal.xlsx", ///
    sheet("T6_1_Tolima_arroz", replace) firstrow(varlabels)
	
* Hasta 1984 area sembrada; desde 1985 area cosechada.

**# 3. Margen bruto aproximado 1970-1980 
*    margen = (precio * rendimiento - costo por ha) / costo por ha
*    precio en $/t, rendimiento en kg/ha, costo en $/ha. Sin renta ni intereses.
*------------------------------------------------------------------------------
use "$bases/merge_tolima_nacional_anual.dta", clear
gen rend_kg = cond(!missing(arroz_rend_imp), arroz_rend_imp, arroz_rend_calc)
gen margen_bruto = (arroz_precio*rend_kg/1000 - arroz_costo_ha)/arroz_costo_ha*100 ///
    if inrange(anio, 1970, 1980)
label var margen_bruto "Margen bruto aprox. (%)"
summarize margen_bruto
display as text "Minimo: " %5.1f r(min) "%   Maximo: " %5.1f r(max) "%"
list anio margen_bruto if !missing(margen_bruto), noobs sep(0)
preserve
    keep if !missing(margen_bruto)
    keep anio arroz_precio rend_kg arroz_costo_ha margen_bruto
    format margen_bruto %5.1f
    export excel using "$out/tablas_arroz_espinal.xlsx", ///
        sheet("T6_2_Margen_bruto", replace) firstrow(variables)
restore


**# 4. Gráfico Area de arroz, algodon y sorgo del Tolima, 1970-1992
*------------------------------------------------------------------------------
twoway (line arroz_area   anio, lwidth(medthick)) ///
       (line algodon_area anio, lwidth(medthick)) ///
       (line sorgo_area   anio, lwidth(medthick)), ///
    xline(1984.5, lpattern(dash) lcolor(gs8)) ///
    xlabel(1970(5)1990 1992) ylabel(, format(%9.0fc) angle(0)) ///
    xtitle("") ytitle("Hectáreas") ///
    title("Área de arroz, algodón y sorgo en el Tolima, 1970-1992") ///
    legend(order(1 "Arroz" 2 "Algodón" 3 "Sorgo") rows(1) position(6)) ///
    note("Hasta 1984: área sembrada; desde 1985: área cosechada (línea punteada).", size(small))
graph export "$out/fig1_area_cultivos_tolima.png", replace width(2000)

**# 5.Gráfico Participacion de El Espinal en el arroz del Tolima
*------------------------------------------------------------------------------
use "$bases/merge_tolima_nacional_anual.dta", clear
merge 1:1 anio using "$out/espinal_manual.dta", keep(match) nogenerate
gen share_espinal = esp_arroz/arroz_area*100
label var share_espinal "Participación de El Espinal (%)"
list anio esp_arroz arroz_area share_espinal, noobs sep(0)   // 1989 = 10,5%

twoway line share_espinal anio, lwidth(medthick) ///
    || scatter share_espinal anio, mlabel(share_espinal) mlabformat(%4.1f) ///
       mlabposition(12) msymbol(O) legend(off) ///
    xlabel(1989(1)1992) ylabel(0(2)12, angle(0)) ///
    xtitle("") ytitle("% del área de arroz del Tolima") ///
    title("Participación de El Espinal en el arroz del Tolima") ///
    note("Área cosechada de arroz.", size(small))
graph export "$out/fig2_participacion_espinal.png", replace width(2000)

preserve
    keep anio esp_arroz arroz_area share_espinal
    label var anio "Año"
    label var esp_arroz "Arroz El Espinal (ha)"
    label var arroz_area "Arroz Tolima (ha)"
    format share_espinal %5.1f
    export excel using "$out/tablas_arroz_espinal.xlsx", ///
        sheet("Fig2_participacion", replace) firstrow(varlabels)
restore

**# 6. Gráfico Barras apiladas de cultivos de El Espinal
*------------------------------------------------------------------------------
use "$out/espinal_manual.dta", clear
graph bar (asis) esp_arroz esp_algodon esp_sorgo, over(anio) stack ///
    ylabel(, format(%9.0fc) angle(0)) ytitle("Hectáreas") ///
    title("Cultivos de El Espinal, 1989-1992") ///
    legend(order(1 "Arroz" 2 "Algodón" 3 "Sorgo") rows(1) position(6)) ///
    note("Algodón 1989: n. d. (no disponible).", size(small))
graph export "$out/fig3_cultivos_espinal.png", replace width(2000)

**# 7. Gráfico Poblacion urbana y rural de El Espinal, 1951-1973
*------------------------------------------------------------------------------
use "$out/poblacion_manual.dta", clear
graph bar (asis) rural urbana, over(anio) stack ///
    ylabel(, format(%9.0fc) angle(0)) ytitle("Habitantes") ///
    title("Población urbana y rural de El Espinal") ///
    legend(order(1 "Rural" 2 "Urbana") rows(1) position(6)) ///
    note("Urbana derivada de la participación reportada (27% en 1951; 77% en 1973).", size(small))
graph export "$out/fig4_poblacion_espinal.png", replace width(2000)


*------------------------------------------------------------------------------
* DE LA APERTURA DE 1991
*------------------------------------------------------------------------------
* 8.1 Tabla de precios de sustentacion / minimo de garantia del arroz ($/t)
use "$bases/precios_sustentacion_nacional_1987_1992.dta", clear
keep if producto == "arroz"
destring psust_sem1 psust_sem2, replace force
gen orden = anio
gen str8 periodo = string(anio)
gen minimo_garantia = psust_prom if anio == 1992
drop if anio == 1988                       // el PDF no lo muestra
set obs `=_N + 1'
replace periodo = "1991/92"        in L
replace minimo_garantia = 129000   in L
replace orden = 1991.5             in L
sort orden
keep periodo psust_sem1 psust_sem2 minimo_garantia
label var periodo         "Periodo"
label var psust_sem1      "Sustentación sem. I ($/t)"
label var psust_sem2      "Sustentación sem. II ($/t)"
label var minimo_garantia "Mínimo de garantía ($/t)"
format psust_sem1 psust_sem2 minimo_garantia %9.0fc
list, noobs sep(0)
export excel using "$out/tablas_arroz_espinal.xlsx", ///
    sheet("T7_1_Precios", replace) firstrow(varlabels)

* 8.2 Importaciones nacionales de cereales (t)
use "$bases/importaciones_cereales_algodon_1989_1992.dta", clear
keep if capitulo == "10 Cereales"
keep anio peso_neto_t
label var anio        "Año"
label var peso_neto_t "Importaciones de cereales (t)"
format peso_neto_t %12.0fc
list, noobs sep(0)
export excel using "$out/tablas_arroz_espinal.xlsx", ///
    sheet("T7_2_Importaciones", replace) firstrow(varlabels)
* Incluye trigo, maiz, arroz y sorgo: no mide el arroz solo.

* 8.3 Precio real y area de arroz del Tolima: variaciones citadas en el texto
use "$bases/merge_tolima_nacional_anual.dta", clear
sort anio
gen var_area_tol   = (arroz_area/arroz_area[_n-1] - 1)*100
gen var_precio_real = (arroz_precio_real_ipc88/arroz_precio_real_ipc88[_n-1] - 1)*100
label var arroz_precio_real_ipc88 "Precio sustentación real (pesos/t, IPC dic-1988=100)"
label var arroz_area              "Área arroz Tolima (ha)"
label var var_area_tol            "Var. área (%)"
label var var_precio_real         "Var. precio real (%)"
label var ipc_var_dic_pct         "Inflación dic-dic (%)"
* Esperado: area 1991 = -28%; precio real 1990 ~ -8%, 1991 ~ -16%;
*           inflacion 32,4% (1990) y 26,8% (1991)
list anio arroz_area var_area_tol arroz_precio_real_ipc88 var_precio_real ///
     ipc_var_dic_pct if inrange(anio, 1989, 1992), noobs sep(0)
preserve
    keep if inrange(anio, 1989, 1992)
    keep anio arroz_area var_area_tol arroz_precio_real_ipc88 var_precio_real ipc_var_dic_pct
    format var_area_tol var_precio_real ipc_var_dic_pct %5.1f
    format arroz_area arroz_precio_real_ipc88 %9.0fc
    export excel using "$out/tablas_arroz_espinal.xlsx", ///
        sheet("T7_3_Apertura_variaciones", replace) firstrow(varlabels)
restore

*------------------------------------------------------------------------------
**# 9. Gráfico usando el panel: precio de sustentacion real y area de arroz del Tolima  (linea vertical en 1991)

twoway line arroz_precio_real_ipc88 anio if inrange(anio, 1988, 1992), ///
    lwidth(medthick) xline(1991, lpattern(dash) lcolor(gs8)) ///
    xlabel(1988(1)1992) ylabel(, format(%9.0fc) angle(0)) ///
    xtitle("") ytitle("Pesos por tonelada") ///
    title("Precio de sustentación real") ///
    subtitle("IPC dic-1988 = 100", size(small)) ///
    name(g_precio, replace)

twoway line arroz_area anio if inrange(anio, 1988, 1992), ///
    lwidth(medthick) xline(1991, lpattern(dash) lcolor(gs8)) ///
    xlabel(1988(1)1992) ylabel(, format(%9.0fc) angle(0)) ///
    xtitle("") ytitle("Hectáreas cosechadas") ///
    title("Área de arroz del Tolima") ///
    name(g_area, replace)

graph combine g_precio g_area, rows(1) xsize(10) ysize(4.5) ///
    title("La apertura de 1991: precio real y área de arroz") ///
    note("Desde fines de 1991 el IDEMA pasa de precios de sustentación a mínimos de garantía.", size(small))
graph export "$out/fig5_apertura_precio_area.png", replace width(2400)



**# 10. Tabla Cobertura de las bases (seccion "Sobre los datos")
clear
set obs 5
gen str30 base      = ""
gen str110 variables = ""
gen str30 cobertura = ""
replace base = "Tolima anual" in 1
replace variables = "Área, producción y rendimiento (arroz, algodón, sorgo, maíz, ajonjolí, tabaco); costos y precios" in 1
replace cobertura = "1970-1992" in 1
replace base = "Cultivos municipales" in 2
replace variables = "Arroz, algodón, sorgo por municipio y semestre" in 2
replace cobertura = "1981, 1982, 1989-1992" in 2
replace base = "Población y censos agropecuarios" in 3
replace variables = "Población 1951, 1964, 1973; uso de la tierra 1960 y 1970" in 3
replace cobertura = "Municipal" in 3
replace base = "Jornales" in 4
replace variables = "Jornal agrícola trimestral, Espinal y Tolima" in 4
replace cobertura = "1980-1984" in 4
replace base = "Nacional" in 5
replace variables = "Cultivos 1987-92, salarios, precios de sustentación, importaciones" in 5
replace cobertura = "1979-1992" in 5
label var base      "Base"
label var variables "Variables"
label var cobertura "Cobertura"
list, noobs sep(0) abbreviate(30)
export excel using "$out/tablas_arroz_espinal.xlsx", ///
    sheet("T10_Cobertura", replace) firstrow(varlabels)
