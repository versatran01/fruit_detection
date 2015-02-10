function [ images, names ] = loadImages( path, pattern, verbose )
%LOADIMAGES Load all images (recursively) that match a file pattern.
% Example patterns:
%   '.+.(tiff|tif|jpg|jpeg|png|bmp|gif)' : Most common image files.
%   'img_[0-9]+.jpg' : JPG files with names like "img_001.jpg".
items = dir(path);
images = {};
names = {};
if nargin < 3
    verbose = false;
end
if isempty(pattern)
    pattern = '.+.(tiff|tif|jpg|jpeg|png|bmp|gif)';
end
if verbose
    fprintf('Loading directory %s\n', path);
end
for i=1:numel(items)
    name = items(i).name;
    if items(i).isdir
        % ignore the current directory and parent
        if ~strcmp(name,'.') && ~strcmp(name,'..')
            [sub, name] = loadImages(strcat(path,'/',name), pattern,...
                verbose);
            images = vertcat(images, sub);
            names = vertcat(names, name);
        end
    else
        matches = regexpi(name,pattern,'match');
        if ~isempty(matches)
            % found a match
            fullpath = strcat(path,'/',name);
            images{end+1} = imread(fullpath);
            names{end+1} = fullpath;
        end
    end
end
images = reshape(images, numel(images), 1);
names = reshape(names, numel(names), 1);
end
