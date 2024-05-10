% Load data
clear; clc; 
close all; 
% Hola rodri
% Hello World
% One last step simultaneous

data_path = '/Users/javierramosperez/Desktop/CEMFI/Master Economics and Finance/Applied Macroeconomics/PS2/data'; 


addpath /Users/javierramosperez/Desktop/GitHub/BVAR_/cmintools/
addpath /Users/javierramosperez/Desktop/GitHub/BVAR_/bvartools/



% 1. Import Data in Excel Format
[lgdp, lemp, lwage, dates] = importdata(data_path); 


y = [lwage lemp lgdp]; 


% 2. Optimal lag's lenght: minimize HQIC criteria
minlag =1; 
maxlag = 20;
optionsClassical.K  = 1;

HQICcritiria = zeros(maxlag-minlag , 1); 
laglenght    = (minlag:1:maxlag)'; 

for nlags=minlag:maxlag
  BVAR = bvar_(y, nlags, optionsClassical);
  HQICcritiria(nlags-minlag+1,1) = BVAR.InfoCrit.HQIC ; 
end	

[~ , q] = min(HQICcritiria) ; 
lags    = laglenght(q,1); 





%% 1) Cholesky Triangularization: different approaches: 

% Cholesky Order: Wages, Employment and GDP
y = [lwage lemp lgdp];
 
optionsClassical.K            = 100;
[CVAR1_Cholesky] = cvar_(y,lags,optionsClassical);  % Check size of var-covar matrix estimates

indx_sho              = 3;

% Order of variables in the plot: gdp, employment and wages
indx_var              = [3, 2, 1];
irfs_to_plot          = CVAR1_Cholesky.ir_boots(indx_var,:,indx_sho,:);
options.varnames      = {'Real GDP','Employment','Wages'};  
options.saveas_dir    = './plots';
options.saveas_strng  = 'Cholesky Classical';
options.shocksnames   = {'Technology'};  
options.conf_sig_2    = 0.90; 
options.nplots        = [3 1];
plot_irfs_(irfs_to_plot,options); 
%close; 



%% Minnesota Priors:

% Fabios's Example approach: Maximize sequentially

% 1) Maximizes over tau
hyperpara(1)    = 3;		  % tau
hyperpara(2)    = 0.5;		  % decay
hyperpara(3)    = 5;		  % lambda
hyperpara(4)    = 2;		  % mu
hyperpara(5)    = 2;		  % omega
% setting the options
options.index_est	   = 1:1;    % hyper-parameter over which maximize
options.max_compute    = 2;      % maximize  using Matlab fmincon function
options.lb             = 0.8;    % Lower bound
options.ub             = 10;     % Upper bound
[postmode,logmlike,~] = bvar_max_hyper(hyperpara,y,lags,options);

% Given optimal tau, maximizes over tau (again), decay and lambda

hyperpara(1)            = postmode(1); % use as starting value previous mode
options.index_est       = 1:3;         % set hyper-parameters over which maximize
options.lb              = [0.1 0.1 0.1]; % Lower bounds
options.ub              = [10 10 10];    % Upper bounds
[postmode1,log_dnsty,~] = bvar_max_hyper(hyperpara,y,lags,options);

%Take  optimal value for hyperparameter(1:3) and compute optimal values for tau, decay, lambda, mu (without  posterior  draws)
hyperpara(1:3)          = postmode1(1:3); % use as starting value previous mode
options.index_est       = 1:4;         % set hyper-parameters over which maximize
options.lb              = [0.1 0.1 0.1 0.1]; % Lower bounds
options.ub              = [10 10 10 10];    % Upper bounds
[postmode,log_dnsty1,~] = bvar_max_hyper(hyperpara,y,lags,options);
% then run BVAR with  optimal  parameters

options.K = 100; 
BVAR1_Minnesota_Cholesky                  = bvar_(y,lags,options);

% Step 3) Estimate IRF
indx_sho              = 3;
indx_var              = [3, 2, 1];

irfs_to_plot           = BVAR1_Minnesota_Cholesky.ir_draws(indx_var,:,indx_sho,:);

options.varnames      = {'Real GDP','Employment','Wages'};  
options.saveas_dir    = './plots';
options.saveas_strng  = 'Cholesky Minnesota';
options.shocksnames   = {'Technology'};  
options.conf_sig_2    = 0.90; 
options.nplots        = [3 1];

plot_irfs_(irfs_to_plot,options);


%% Inverse Wishart -conjugate- Priors:

%{

Javi: Friday 10 May



%}


% Step 1) Set priors from classical Reduced form VAR and estimate BVAR 

% Priors on parameters (Phi and Sigma )
optionsIW.priors.name     = 'Conjugate';
optionsIW.K               = 100; 
optionsIW.priors.Phi.mean = mean(CVAR1_Cholesky.Phi_ols,3);
optionsIW.priors.Phi.cov     = 1 * eye(size(optionsIW.priors.Phi.mean,1));

% Priors on Errors (e_ols)
optionsIW.priors.Sigma.scale = CVAR1_Cholesky.Sigma_ols; 
optionsIW.priors.Sigma.df = 3+1+1; % Ask about degrees of freedom!!!


BVAR1_IW_Cholesky  = bvar_(y,lags,optionsIW);

% Step 3) Estimate IRF

indx_sho              = 3;
indx_var              = [3, 2, 1];

irfs_to_plot           = BVAR1_IW_Cholesky.ir_draws(indx_var,:,indx_sho,:);
options.varnames      = {'Real GDP','Employment','Wages'};  
options.saveas_dir    = './plots';
options.saveas_strng  = 'Cholesky Conjugate';
options.shocksnames   = {'Technology'};  
options.conf_sig_2    = 0.90;  

plot_irfs_(irfs_to_plot,options);




%% FEVD Classical: 

%{

1) For each variable, loop over the draws from the posterior



%}


options.K    = 10;
BVAR_FEVD_Reduced = bvar_(y,lags,options) ; 

j = 3; % Shock
i = 1; % Variable
h = 10;

tic;
for k = 1:BVAR_FEVD_Reduced.ndraws 
    
    Phi   = BVAR_FEVD_Reduced.Phi_draws(:,:,k);
    Sigma = BVAR_FEVD_Reduced.Sigma_draws(:,:,k);
    
    Qbar = max_fevd(i, h, j, Phi, Sigma);

    [ir] = iresponse(Phi, Sigma, h, Qbar);
    
    
    BVAR.irQ_draws(:,:,:,k) = ir;
end

toc;


indx_sho              = 3;
indx_var              = [3, 2, 1];

irfs_to_plot          = BVAR.irQ_draws(indx_var,:,indx_sho,:);


% Customize the IRF plot
options.varnames      = {'Real GDP','Employment','Wages'};  
options.saveas_dir    = './plots';
options.saveas_strng  = 'Signs';
options.shocksnames   = {'Technology'};  
options.conf_sig_2    = 0.90;

plot_irfs_(irfs_to_plot,options); 





