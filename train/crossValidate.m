function [error_out] = crossValidate(observations, labels, k,...
    train_function, predict_function)
% CROSSVALIDATE Performs k-fold cross-validation on a model.
%
%   Returns the mean error of k-fold cross-validation on a model built
%   using 'observations' and 'labels', using train_function to build and 
%   predict_function to test the model on each fold.
%
%   USAGE: 
%       
%   [error] = crossValidate(X, Y, 10, @train_nb, @predict_nb)
%
%   The above example uses X = train.counts, Y = train.labels and 10 as the
%   number of folds to use.
%
%   The 'train_function' must have the following signature:
%   
%       function [model] = train(X_train, Y_train)
%
%   The 'predict_function' must have the following signature:
%
%       function [Y_pred] = predict(model, X_test)
%

% TODO: Modified this to assume single-class labels,
% correct for this later.

% seed random number generator with time
rng(cputime, 'twister');
% number of observations
N = size(observations, 1);
% generate an array containing the possible fold assignments
fold_asgn = repmat(1:k, 1, ceil(N / k));
% truncate any extra assignments resulting from rounding
fold_asgn = fold_asgn(1:N);
% permute the elements at random
fold_asgn = fold_asgn(randperm(N));
% format of errors: [rms,accuracy,precision,recall]
errs_rms = zeros(k,1);
errs_acc = zeros(k,1);
errs_pre = zeros(k,1);
errs_rec = zeros(k,1);
parfor i=1:k
    % collect training data for k'th fold
    indices_train = fold_asgn ~= i;
    indices_test = ~indices_train;
    X_train = observations(indices_train, :);
    Y_train = labels(indices_train, :);
    X_test = observations(indices_test, :);
    Y_test = labels(indices_test, :);
    % train the model WITHOUT metadata
    model = train_function(X_train, Y_train);
    % predict the test labels, given training data and test observations
    Y_pred = predict_function(model, X_test); 
    
    % calculate the errors for this fold    
    tp = nnz( Y_test & Y_pred );
    tn = nnz(~Y_test & ~Y_pred);
    fp = nnz(~Y_test & Y_pred);
    fn = nnz( Y_test & ~Y_pred);

    errs_rms(i) = rms(Y_test - Y_pred);       % rms error
    errs_acc(i) = (tp+tn) / (tp+tn+fp+fn);    % accuracy
    errs_pre(i) = tp / (tp + fp);             % precision
    errs_rec(i) = tp / (tp + fn);             % recall
    
    fprintf('- Finished fold %i\n', i);
end
% average the error
error_out = mean([errs_rms errs_acc errs_pre errs_rec], 1);
end
