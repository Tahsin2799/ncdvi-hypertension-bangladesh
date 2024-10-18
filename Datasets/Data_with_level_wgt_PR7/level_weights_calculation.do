// stage 1
*** 1 *************************** 
bysort hv023: egen a_c_h = count(hv021)
*** 2 *************************** 
gen A_h = 0 
replace A_h = 7  if hv023 == 1
replace A_h = 15  if hv023 == 2
replace A_h = 49  if hv023 == 3
replace A_h = 16  if hv023 == 4
replace A_h = 17  if hv023 == 5
replace A_h = 59  if hv023 == 6
replace A_h = 26  if hv023 == 7
replace A_h = 26  if hv023 == 8
replace A_h = 52  if hv023 == 9
replace A_h = 9  if hv023 == 10
replace A_h = 19  if hv023 == 11
replace A_h = 58  if hv023 == 12
replace A_h = 19  if hv023 == 13
replace A_h = 58  if hv023 == 14
replace A_h = 6  if hv023 == 15
replace A_h = 21  if hv023 == 16
replace A_h = 62  if hv023 == 17
replace A_h = 24  if hv023 == 18
replace A_h = 61  if hv023 == 19
replace A_h = 9  if hv023 == 20
replace A_h = 13  if hv023 == 21
replace A_h = 49  if hv023 == 22
*** 3 *************************** 
gen M_h = 0 
replace M_h = 210  if hv023 == 1
replace M_h = 450  if hv023 == 2
replace M_h = 1470  if hv023 == 3
replace M_h = 480  if hv023 == 4
replace M_h = 510  if hv023 == 5
replace M_h = 1770  if hv023 == 6
replace M_h = 780  if hv023 == 7
replace M_h = 780  if hv023 == 8
replace M_h = 1560  if hv023 == 9
replace M_h = 270  if hv023 == 10
replace M_h = 570  if hv023 == 11
replace M_h = 1740  if hv023 == 12
replace M_h = 570  if hv023 == 13
replace M_h = 1740  if hv023 == 14
replace M_h = 180  if hv023 == 15
replace M_h = 630  if hv023 == 16
replace M_h = 1860  if hv023 == 17
replace M_h = 720  if hv023 == 18
replace M_h = 1830  if hv023 == 19
replace M_h = 270  if hv023 == 20
replace M_h = 390  if hv023 == 21
replace M_h = 1470  if hv023 == 22
*** 4 *************************** 
quietly summarize hv001 
gen m_c=r(N) 
*** 5 *************************** 
gen M = 20,250 
*** 6 *************************** 
gen S_h = 30 
*** 7 *************************** 
gen DHSwt = hv005 / 1000000


// stage 2 
*** 1 ***************************
gen d_HH = DHSwt * (M/m_c) 
*** 2 ***************************
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h)) 
scalar alpha = 0.5 
gen wt2 = (A_h/a_c_h)*(f^alpha) 
*** 3 *************************** 
gen wt1 = d_HH/wt2 