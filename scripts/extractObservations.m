function [observations] = extractObservations(dataset, imageProcessor,...
    varargin)
% EXTRACTOBSERVATIONS Create an Xpos and Xneg from a dataset.
%
% `dataset` is an instance of a dataset.
%
% `imageProcessor` is a function object which accepts an image and returns
%   the same image, potentially in a new feature space. 

defaults.scale = 0.5;
defaults.maxRatio = 5;
defaults.verbose = true;
options = propval(varargin, defaults);

if options.scale > 1 || options.scale < 0
    error('scale must fall in [0,1]');
elseif options.maxRatio < 0
    error('maxRatio must be > 0');
end

n_data = dataset.size();
Xpos = {};
Xneg = {};
for i = 1:n_data
    if options.verbose
        fprintf('Processing image %i...\n', i);
    end
    % apply scale factor
    img = imresize(dataset.images{i}, options.scale);
    img = im2double(img);
    % process with user supplied callback
    img = imageProcessor(img);
    % sample the examples
    [Xp, Xn] = sampleExamples(img, dataset.selections{i}, ...
                              dataset.masks{i}, options.scale);
    npos = size(Xp,1);
    nneg = size(Xn,1);
    maxPos = options.maxRatio*npos;
    if nneg > maxPos
        idx = randperm(nneg);
        idx = idx(1:maxPos);
        Xn = Xn(idx,:); % throw away some negative to bring down the ratio
    end
    Xpos{i} = Xp;
    Xneg{i} = Xn;
end

Xpos = cell2mat(Xpos');
Xneg = cell2mat(Xneg');
observations.Xpos = Xpos;
observations.Xneg = Xneg;
observations.datetime = datetime;
end
