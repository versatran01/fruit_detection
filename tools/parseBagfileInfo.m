function [ info ] = parseBagfileInfo( tsv_path, bagfile_dir, varargin )
%PARSEBAGFILEINFO Parse the bagfile info TSV and retrieve bagfile info.
%   `tsv_path` is the path to the tab-separated value file.
%   `bagfile_dir` is the directory with the bagfiles.
defaults.verbose = true;
options = propval(varargin, defaults);

if ~exist(tsv_path,'file')
    error('File %s does not exist.', tsv_path);
end

data = fileread(tsv_path);
% break up the data w/ textscan
scanned = textscan(data,'%s%s%s%s%s%q', 'delimiter', '\t');
if numel(scanned) ~= 6
    error('Expected 6 columns. Check your data format');
end
% throw away the titles of columns
for i=1:numel(scanned)
    col = scanned{i};
    scanned{i} = col(2:end);
end

% pull out the info and convert to useful format
rows = cellfun(@str2num, scanned{1});
startTimes = cellfun(@str2num, scanned{4});
endTimes = cellfun(@str2num, scanned{5});

% check times
if any(startTimes < 0 | endTimes < 0)
    error('TSV file contains negative times - this is invalid');
end

directions = cellfun(@lower, scanned{2});   % convert to lowercase
inputNames = scanned{3};
numInputs = numel(inputNames);

% some extra outputs:
fileNames = cell(numInputs,1);
paths = cell(numInputs,1);
found = false(numInputs, 1);

% iterate through names and find corresponding bagfile
for i=1:numInputs
    inputNames{i} = strtrim(inputNames{i});
    name = inputNames{i};
    
    % strip off the front of the name for details
    filebits = regexpi(name, ...
        '(?<type>[a-z]{1})(?<row>[0-9]+)(?<direction>[a-z]{1})_', 'names');
    % check if the file name is valid
    if ~all( isfield(filebits,{'type','row','direction'}) )
        error('Invalid bagfile name: %s', name);
    end
    filebits.direction = lower(filebits.direction);
    
    if rows(i) ~= str2double( filebits.row )
        error('TSV file row (%i) does not match bagfile (%s)', ...
            rows(i), filebits.row);
    end
    if ~strcmp( directions(i), filebits.direction )
        error('TSV file direction (%s) does not match bagfile (%s)', ...
            directions{i}, filebits.direction);
    end
    
    % generate a pattern to search for at our target directory
    header = sprintf('%c%i%c', filebits.type, ...
        rows(i), directions(i));
    pattern = sprintf('%s.+.bag', header);
    [n,p] = getFilesMatching(bagfile_dir, pattern);
    
    % generate warnings/errors if appropriate
    nresults = numel(n);
    if nresults == 0
        msg = sprintf('No matching file for %s in folder %s',...
            header, bagfile_dir);
        warning(msg);
    elseif nresults >= 1
        % take only the first match in this case and warn the user
        n = n{1};
        p = p{1};
        if nresults > 1
            msg = sprintf('Found multiple matches for %s. Result %s will be used', ...
                header, n);
            warning(msg);
        end
        
        if options.verbose
            fprintf('* Found bagfile matching %s: %s\n', header, p);
        end
    end
    
    if ~isempty(n)
        found(i) = true; % found this file
        fileNames{i} = n;
        paths{i} = p;
    end
end

% generate output
rows = num2cell(rows);
startTimes = num2cell(startTimes);
endTimes = num2cell(endTimes);
found = num2cell(found);
directions = num2cell(directions);
info = struct('inputName', inputNames, 'direction', directions,...
    'fileName', fileNames, 'path', paths, 'found', found, 'row', rows, ...
    'startTime', startTimes, 'endTime', endTimes);
end
