function Yhat = predictEnsemble(model, X)

Yhat_all = [];

num_models = length(model.param);

for i = 1:num_models
    sub_model = model.param{i};
    Yhat = predictAll(sub_model, X);
    Yhat_all = [Yhat_all Yhat];
end
Yhat = Yhat_all * model.weights(:);
Yhat(Yhat > 1) = 1;
Yhat(Yhat < 0) = 0;
end

