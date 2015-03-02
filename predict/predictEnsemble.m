function Yhat = predictEnsemble(model, X)

Yhat_all = [];

num_models = length(model.param);

for i = 1:num_models
    sub_model = model.param{i};
    X_used = X(:, sub_model.feat_ind);
    Yhat = sub_model.predict(sub_model.param, X_used);
    Yhat_all = [Yhat_all Yhat];
end

Yhat = Yhat_all * model.weights(:);

end

