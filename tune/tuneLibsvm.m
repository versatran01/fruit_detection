function [ result ] = tuneLibsvm(X,Y,~,nfolds,cost)
%TUNELIBSVM Tune the cost parameter of an SVM for best accuracy.
% Observations should be in rows of X and labels in rows of Y.
start=1;
if nargin == 5
    % initial cost is provided
    start=2;
end
for level=start:2
    % two levels of tuning, 5 sections per level
    if level==1
        range = 10.^(-2:2);
    else
        range = logspace(log10(cost)-0.6, log10(cost)+0.6, 5);
    end
    errors = [];
    for i=1:numel(range)
        c = range(i);
        % train all levels
        train_cb = @(x,y)trainLibsvm(x,y,0,c);
        predict_cb = @(mdl,x)predictLibsvm(mdl,x);
        % cross-validate
        errors(i,:) = crossValidate(X,Y,nfolds,train_cb,predict_cb);
        fprintf('- Finished evaluating c = %.4f\n', c);
        fprintf('- Accuracy on this fold is %.3f\n', errors(i,2));
    end
    % using the accuracy as the tuning parameter here (2nd column)
    [~,max_idx] = max(errors(:,2));
    % take this as the new cost
    cost = range(max_idx);
    errors = errors(max_idx,:);
    fprintf('\n** Tuning level %i results:\n',level);
    fprintf('\tRMS: %f\n',errors(1));
    fprintf('\tAccuracy: %f\n',errors(2));
    fprintf('\tPrecision: %f\n',errors(3));
    fprintf('\tRecall: %f\n',errors(4));
    fprintf('\tNew cost: %f\n', cost);
    
    if level == 2
        fprintf('Starting final training...\n');
        % last level, update result parameter
        result.model = trainLibsvm(X,Y,0,cost);
        result.datetime = datetime;
        result.cost = cost;
        result.errors = errors;
        result.predict = @(model, X)predictLibsvm(model, X);
    end
end
end
