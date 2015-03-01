function result = tuneLiblinear(Xtrain, Ytrain, nlevel, nfolds, cost, s, verbose)
% TUNELIBLINEAR Tune liblinear model with cross validation

if nargin < 7, verbose = false; end
if ~(nlevel ~= 1 || nlevel ~= 2)
	error('nlevel [%g] should be either 1 or 2', nlevel);
end

acc_col = 2;
pre_col = 3;
rec_col = 4;
best_cost_so_far = 0;

for level = 1:nlevel
	if level == 1
		cost_range = 10.^(-2:2);
    elseif level == 2
		if best_cost_so_far == 0
			error('Oops!');
		end
		cost_range = logspace(log10(best_cost_so_far) - 0.95, ...
			                  log10(best_cost_so_far) + 0.95, 20);
    end

	% Initialize cross validation rmse
	xval_errors = zeros(size(cost_range, 1), 4);

	for i = 1:numel(cost_range)
		c = cost_range(i);
		% From train and predict functions
		train_fun = @(x, y) trainLiblinear(x, y, s, c);
		predict_fun = @(mdl, x) predictLiblinear(mdl, x);
		% cross validate
		xval_errors(i, :) = crossValidate(Xtrain, Ytrain, nfolds, ...
                                          train_fun, predict_fun);
		if verbose
			fprintf('-- Finished evaluating c = %0.4f\n', c);
			fprintf('-- Accuracy/precision/recall on this value are %.3f/%.3f/%.3f\n', ...
				    xval_errors(i, acc_col), xval_errors(i, pre_col), ...
                    xval_errors(i, rec_col));
		end
	end

	% Using accuracy as the tuning parameter
	[~, best_idx] = max(xval_errors(:, acc_col));
	best_cost_so_far = cost_range(best_idx);
	best_errors_so_far = xval_errors(best_idx, :);

	if verbose
    	fprintf('** Level %i results:\n', level);
    	fprintf('Cost: %0.3f, RMS: %0.3f, Acc: %0.3f, Pre: %0.3f, Rec: %0.3f', ...
    		    best_cost_so_far, best_errors_so_far(1), ...
    		    best_errors_so_far(2), best_errors_so_far(3), ...
    		    best_errors_so_far(4));
    end
end

result.model = trainLiblinear(Xtrain, Ytrain, s, best_cost_so_far);
result.dimension = size(Xtrain, 2);
result.datetime = datetime;
result.cost = best_cost_so_far;
result.errors = best_errors_so_far;
result.predict = @(model, X) predictLiblinear(model, X);

end
