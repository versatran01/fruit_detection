function [ map, map_smooth ] = generateYieldMap( bag_dir, row_counts, ...
    map_size, gps_origin, granularity  )
%GENERATEYIELDMAP Generate a yield map.
% `bag_dir` is the directory with input bagfiles w/ GPS coords.
% `row_counts` is the row counts with ROS timestamps.
% `gps_origin` is the origin in GPS coords (bottom left).
% `map_size` is the map dimensions in meters.
% the top left and bottom right coordinate of the map.
% `granularity` is the number of bins per meter.
if nargin < 3
    map_size = [300 300];
end
if nargin < 4
    gps_origin = [36.419511, -119.191104];
end
if nargin < 5
    granularity = 0.25;
end

% convert to bin count
map_width = map_size(1);
map_height = map_size(2);
bins_x = ceil(map_width * granularity);
bins_y = ceil(map_height * granularity);
map = zeros(bins_y, bins_x);

N = numel(row_counts);  % number of rows to process
for r=1:N
    row = row_counts(r).row;
    direction = row_counts(r).side;
    counts = row_counts(r).counts_per_image{1};
    num_images = numel(counts);
    
    fprintf('Processing row %i, direction %c (%i images)\n', ...
        row, direction, num_images);
    
    % need to see if we can load this bagfile
    header = sprintf('%c%i%c', 'r', row, direction);
    pattern = sprintf('%s.+.bag', header);
    [n,p] = getFilesMatching(bag_dir, pattern);
    if ~isempty(n)
        n = n{1};   % name
        p = p{1};   % path
        fprintf('Found matching bagfile: %s\n', n);
        
        % open bag file and select gps data
        bag = ros.Bag(p);
        msgs = bag.readAll({'/gps/fix'});
        fprintf('Loaded %i GPS messages\n', numel(msgs));
        
        % convert to MATLAB timeseries object
        ts = makeTimeseries(msgs);
        % interpolate to get GPS coordinates for images
        [coords,idx] = calculateCoords(ts, [counts.time]);
        counts = counts(idx);
        counts = [counts.counts];
        
        % correct to the origin and convert to meters w/ approximation
        coords = bsxfun(@minus, coords, gps_origin);
        coords = coords / 180 * pi * 6371000;   % order is [y x]
        
        % turn into bin coordinates - do linear interpolation
        bins = coords * granularity;
        bins_low = floor(bins);
        bins_high = ceil(bins);
        frac = bins - bins_low;     % linear interpolation factor
        
        out = outside(bins_low,size(map)) | outside(bins_high,size(map));
        if any(out)
            warning('Some bins (%i/%i) fall outside the map, make your map bigger',...
                nnz(out), numel(out));
        end
        bins_low = bins_low(~out,:);
        bins_high = bins_high(~out,:);
        counts = counts(~out)';
        
        % create indices
        ind_00 = sub2ind(size(map), bins_low(:,1), bins_low(:,2));
        ind_01 = sub2ind(size(map), bins_low(:,1), bins_high(:,2));
        ind_10 = sub2ind(size(map), bins_high(:,1), bins_low(:,2));
        ind_11 = sub2ind(size(map), bins_high(:,1), bins_high(:,2));
        
        map(ind_00) = map(ind_00) + counts .* (1-frac(:,1)) .* (1 - frac(:,2));
        map(ind_01) = map(ind_01) + counts .* (1-frac(:,1)) .* frac(:,2);
        map(ind_10) = map(ind_10) + counts .* frac(:,1) .* (1 - frac(:,2));
        map(ind_11) = map(ind_11) + counts .* frac(:,1) .* frac(:,2);
    else
        warn('Missing bagfile matching %s, skipping!', header);
    end
end
map = flipud(map);  % reverse into image order

% auto crop using filled pixels
[row,col] = find(map > 0);
min_row = min(row);
max_row = max(row);
min_col = min(col);
max_col = max(col);
w = max_col - min_col;
h = max_row - min_row;
map = imcrop(map,[min_col min_row w h]);

% blow it up
map_smooth = imresize(map, 10, 'cubic');
% clamp to 7
map_smooth(map_smooth > 5) = 5;
% blur it a lot
map_smooth = imfilter(map_smooth, fspecial('gaussian', [7 7]));

end

function [ts] = makeTimeseries(messages)
    N = numel(messages);
    times = zeros(N,1);
    coords = zeros(N,2);
    % pull out all messages
    for i=1:numel(messages)
        times(i) = messages{i}.header.stamp.time;
        coords(i,:) = [messages{i}.latitude messages{i}.longitude];
    end
    ts = timeseries(coords,times);
end

function [coords, idx] = calculateCoords(gps_ts, count_times)
% determine valid sample times:
idx = count_times < max(gps_ts.Time) & count_times > min(gps_ts.Time);
new_ts = resample(gps_ts, count_times(idx));
coords = new_ts.Data;
end

function [idx] = outside(bins, size)
    out = bsxfun(@le,bins,[0 0]) | bsxfun(@ge,bins,size+1);
    out = out(:,1) | out(:,2);
    idx = out;
end
