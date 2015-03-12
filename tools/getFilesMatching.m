function [ names, paths ] = getFilesMatching( directory, pattern )
%GETFILESMATCHING Get files matching regex `pattern` located at the path
% provided in `directory`.
% todo: add recursive option
items = dir(directory);
names = {};
paths = {};
for i=1:numel(items)
    name = items(i).name;
    if ~items(i).isdir
        matches = regexpi(name, pattern, 'match');
        if ~isempty(matches)
            % found a match
            fullpath = strcat(directory, '/', name);
            names{end+1} = name;
            paths{end+1} = fullpath;
        end
    end
end
