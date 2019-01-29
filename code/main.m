clear;

%% Set parameters

% Model parameters 
modelpar = set_modelpar();

% Numerical representation parameters
numericalpar = set_numericalpar();

% Initial guesses
init_guesses = set_initguesses(modelpar,numericalpar);

%% Solve model

% Set tolerance and (optionally) num_iterations
tol = 10E-5;
num_iter = 1000;
eq_out = compute_eq(modelpar,tol,g0,tau0,sigma0,num_iter);

%% Plots


