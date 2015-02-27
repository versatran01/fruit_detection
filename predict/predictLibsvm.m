function Yhat = predictLibsvm( model, Xtest )
if model.nr_class == 2 && model.Parameters(2) == 0
    % linear, no kernel, with two classes
    % predict using matlab code in this case
    W = model.SVs' * model.sv_coef;
    Yval = Xtest * W - model.rho;
    % threshold
    Yout = Yval;
    Yout(Yval >= 0) = 1;
    Yout(Yval < 0) = 2;
    % convert to label
    Yhat = model.Label(Yout);
else
    N = size(Xtest, 1); 
    % first parameter is junk to be ignored
    Yhat = svmpredict(ones(N, 1), Xtest, model, '-b 1'); 
end
end
