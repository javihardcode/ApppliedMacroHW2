function [lgdp, lemp, lwage, dates] = importdata(data_path)


% 1) Import Wage Rate
opts = spreadsheetImportOptions("NumVariables", 2);

opts.Sheet = "FRED Graph";
opts.DataRange = "A12:B192";

opts.VariableNames = ["LES1252881600Q", "EmployedFullTimeMedianUsualWeeklyRealEarningsWageAndSalaryWorke"];
opts.VariableTypes = ["datetime", "double"];

opts = setvaropts(opts, "LES1252881600Q", "InputFormat", "");

%wage = readtable("/Users/javierramosperez/Desktop/CEMFI/Master Economics and Finance/Applied Macroeconomics/PS2/LES1252881600Q.xls", opts, "UseExcel", false);
filename = fullfile(data_path,'LES1252881600Q.xls'); 
wage = readtable(filename, opts, "UseExcel", false);



% 2) Import Real GDP
opts = spreadsheetImportOptions("NumVariables", 2);

opts.Sheet = "FRED Graph";
opts.DataRange = "A12:B320";

opts.VariableNames = ["GDPC1", "RealGrossDomesticProductBillionsOfChained2017DollarsQuarterlySe"];
opts.VariableTypes = ["datetime", "double"];

opts = setvaropts(opts, "GDPC1", "InputFormat", "");

filename = fullfile(data_path,'GDPC1.xls'); 
gdp = readtable(filename, opts, "UseExcel", false);



% 3) Import Employment Level
opts = spreadsheetImportOptions("NumVariables", 2);

opts.Sheet = "FRED Graph";
opts.DataRange = "A12:B192";

opts.VariableNames = ["CE16OV", "EmploymentLevelThousandsOfPersonsQuarterlySeasonallyAdjusted"];
opts.VariableTypes = ["datetime", "double"];

opts = setvaropts(opts, "CE16OV", "InputFormat", "");

filename = fullfile(data_path,'CE16OV.xls'); 
empl = readtable(filename, opts, "UseExcel", false);




% Adjust dimensions and take logs 
% empl : 1979Q1 - 2024Q1
% wage : 1979Q1 - 2024Q1
% gdp  : 1947Q1 - 2024Q1 


lwage = log(  wage{:,2} ) ; 
lemp  = log( empl{:,2} ) ; 
lgdp  = log(gdp{129:end,2}) ; 

% lwage =   wage{:,2}  ; 
% lemp  = empl{:,2}  ; 
% lgdp  = gdp{129:end,2} ;

%y = [lgdp lemp lwage]; 

dates = empl{:,1} ; 

end 





