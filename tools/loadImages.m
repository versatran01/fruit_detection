function [images, names] = loadImages(path)
%LOADIMAGES Load all PNG and JPG files in directory 'path'.

images = {};
names = {};
items = dir(path);
for i=1:numel(items)
    name = items(i).name;
    low = lower(name);
    % load only things which are likely to be images
    if ~isempty(strfind(low,'.png')) || ~isempty(strfind(low,'.jpg'))
        I = imread(strcat(path,'/',name));
        images{end+1} = I;
        names{end+1} = name;
    end
end
end
