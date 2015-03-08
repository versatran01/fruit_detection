%% selectTrainingImages.m
% Prompt the user to select training images via yes/no process.
close all;

INPUT_PATH = '/Volumes/External/Extracted';
NUM_REQUIRED = 200; % number of images we will stop at

[~,paths] = loadImages(INPUT_PATH,[],'noload',true);
% randomize the images
N = numel(paths);
idx = randperm(N);

f = [];
hImg = [];

good_images = {};
for i=1:N
    filepath = paths{idx(i)};
    I = imread(filepath);
    I = rot90(I);
    % get image
    if isempty(f)
        f = figure;
        hImg = imshow(I);
    else
        figure(f);
        set(hImg, 'cdata', I);
    end
    % prompt user to select
    a = input('Accept this image (y/n)? ', 's');
    if strcmpi(a,'y')
        fprintf('Kept.\n');
        good_images{end+1} = I;
    else
        fprintf('Discarded.\n');
    end
    if numel(good_images) == NUM_REQUIRED
        fprintf('Reached %i images. Stopping.\n', NUM_REQUIRED);
        break;
    end
end
