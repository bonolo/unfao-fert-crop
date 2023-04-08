grep -irh \"2021\",\"2021\" Production_Crops_Livestock_E_All_Data_\(Normalized\).csv >> crops2017-21.csv
grep -irh \"2020\",\"2020\" Production_Crops_Livestock_E_All_Data_\(Normalized\).csv >> crops2017-21.csv
grep -irh \"2019\",\"2019\" Production_Crops_Livestock_E_All_Data_\(Normalized\).csv >> crops2017-21.csv
grep -irh \"2018\",\"2018\" Production_Crops_Livestock_E_All_Data_\(Normalized\).csv >> crops2017-21.csv
grep -irh \"2017\",\"2017\" Production_Crops_Livestock_E_All_Data_\(Normalized\).csv >> crops2017-21.csv

grep -irh agave crops2017-21.csv > agave.csv
grep -irh \"2021\",\"2021\" agave.csv > agave2021.csv

grep -irh "China" crops2017-21.csv >> apac-countries.csv
grep -irh "China, mainland" crops2017-21.csv >> apac-countries.csv
grep -irh "Indonesia" crops2017-21.csv >> apac-countries.csv
grep -irh "Thailand" crops2017-21.csv >> apac-countries.csv
grep -irh "Viet Nam" crops2017-21.csv >> apac-countries.csv
grep -irh "Philippines" crops2017-21.csv >> apac-countries.csv
grep -irh "Myanmar" crops2017-21.csv >> apac-countries.csv
grep -irh "Cambodia" crops2017-21.csv >> apac-countries.csv
grep -irh "Japan" crops2017-21.csv >> apac-countries.csv
grep -irh "Republic of Korea" crops2017-21.csv >> apac-countries.csv
grep -irh "Malaysia" crops2017-21.csv >> apac-countries.csv
grep -irh "Australia" crops2017-21.csv >> apac-countries.csv

head -1 Production_Crops_Livestock_E_All_Data_\(Normalized\).csv > production_crops_expurgated.csv
cat agave2021.csv apac-countries.csv >> production_crops_expurgated.csv

rm apac-countries.csv
rm agave.csv
rm agave2021.csv
rm crops2017-21.csv
