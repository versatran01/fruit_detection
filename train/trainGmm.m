function model = trainGmm(Xtrain, n_mixtures)
%TRAINGMM 
step = 1;
num_train = size(Xtrain, 1);
max_train = 20000;
if num_train > max_train
    step = floor(num_train / max_train);
end

options = statset('Display', 'final');
model = gmdistribution.fit(Xtrain(1:step:end, :), n_mixtures, ...
                           'Replicates', 3, ...
                           'SharedCov', false, ...
                           'Options', options);
end

