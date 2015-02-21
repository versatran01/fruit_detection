function [ images, names ] = loadImages( path, pattern, varargin )
%LOADIMAGES Load all images (recursively) that match a file pattern.
% Example patterns:
%   '.+.(tiff|tif|jpg|jpeg|png|bmp|gif)' : Most common image files.
%   'img_[0-9]+.jpg' : JPG files with names like "img_001.jpg".
%
% Returns:
%   images - Cell array of images.
%   names - Full paths to the images.
%
% Options include:
%   verbose - Output the directory names as they are loaded.
%   noload - Skip loading images, only retrieve image paths.
%
defaults.verbose = true;
defaults.noload = false;
options = propval(varargin, defaults);
items = dir(path);
images = {};
names = {};
if isempty(pattern)
    pattern = '.+.(tiff|tif|jpg|jpeg|png|bmp|gif)';
end
if options.verbose
    fprintf('Loading directory %s\n', path);
end
for i=1:numel(items)
    name = items(i).name;
    if items(i).isdir
        % ignore the current directory and parent
        if ~strcmp(name,'.') && ~strcmp(name,'..')
            [sub, name] = loadImages(strcat(path,'/',name), pattern,...
                varargin);
            images = vertcat(images, sub);
            names = vertcat(names, name);
        end
    else
        matches = regexpi(name,pattern,'match');
        if ~isempty(matches)
            % found a match
            fullpath = strcat(path,'/',name);
            if ~options.noload
                images{end+1} = imread(fullpath);
            end
            names{end+1} = fullpath;
        end
    end
end
images = reshape(images, numel(images), 1);
names = reshape(names, numel(names), 1);
end
