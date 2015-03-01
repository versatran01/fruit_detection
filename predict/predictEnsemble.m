function Yhat = predictEnsemble(model, X, weights)

Yhat_all = [];

num_models = length(model.sub_models);

for i = 1:num_models
    sub_model = model.sub_models{i};
    Yhat = sub_model.predict(sub_model, X);
    Yhat_all = [Yhat_all Yhat];
end

Yhat = Yhat_all * weights(:);

end

