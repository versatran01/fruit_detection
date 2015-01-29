function [ models ] = trainKMeans( patches, M, verbose )
%TRAINKMEANS Train multi-scale K-means learned features.
% Generate M clusters from multi-scale examples in patches.
if nargin < 3
    verbose = true;
end
PATCH_SIZE = 8;
models = {};
parfor s=0:(numel(patches)-1)
    % scales: 1, 0.5, 0.25, etc...
    scale = 1 / (2^s);
    N = size(patches{s+1},4);
    X = reshape(patches{s+1},...
            PATCH_SIZE*PATCH_SIZE*size(patches{s+1},3), N);
    Xtrain = prepareData(X,-1,1);
    nnodes = ceil(M * scale);
    % train k-means at this level
    [~,C] = fkmeans(Xtrain',nnodes);
    C=C';
    W = reshape(C,PATCH_SIZE,PATCH_SIZE,size(patches{s+1},3),nnodes);
    models{s+1} = struct('weights',W,'scale',scale);
    if verbose
        fprintf('- Finished training scale %.2f\n',scale);
    end
end
end
