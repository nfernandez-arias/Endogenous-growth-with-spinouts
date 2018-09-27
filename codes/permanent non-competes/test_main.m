%% Set parameters

pm = set_modelpar();
pa = set_algopar();
ig = set_init_guesses_global(pa,pm); 

%% 

model_out = solve_model(pa,pm,ig);

m = VideoWriter('myFile_M.avi');
open(m);
for f = 1:length(model_out.F)
    writeVideo(m,model_out.F(f).cdata)
end
close(m);

