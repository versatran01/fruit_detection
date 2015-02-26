function [ model, info ] = trainLibsvm( Xtrain, Ytrain, k, c )
% Trains a SVM using libsvm and evaluates on test data.
% Xtrain - train data
% Ytrain - train label
% k - k name
%           0 -- no k
%           1 -- linear: u'*v or polynomial: (gamma*u'*v + coef0)^degree
%           2 -- radial basis function: exp(-gamma*|u-v|^2)
%           3 -- sigmoid: tanh(gamma*u'*v + coef0)
% c      - cost parameter

if nargin < 3, k = 0; end   % Do not use k by default
if nargin < 4, c = 0.1; end % c = 1 by default
% Create libsvm_train option based on kernel
option = sprintf('-b 1 -t %d -c %g -m 1000 -q', k, c);
tic
% No k or builtin k
model = svmtrain(Ytrain, Xtrain, option);
time = toc;
% Save model info
info.option = option;
info.name   = 'libsvm';
info.time   = time;
info.cost   = c;
info.datetime = datetime;
end