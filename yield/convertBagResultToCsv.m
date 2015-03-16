function convertBagResultToCsv(bag_results, output_dir)
if nargin < 2, output_dir = pwd; end

headers = {'sec', 'nsec', 'counts'};

for i = 1:numel(bag_results)
    bag_result = bag_results(i);
    row = bag_result.row;
    side = bag_result.side;
    counts_per_image = bag_result.counts_per_image{1};
    
    file_name = sprintf('%c%d%c.csv', 'r', row, side);
    secs = [counts_per_image.sec]';
    nsecs = [counts_per_image.nsec]';
    counts = [counts_per_image.counts]';
    output = [secs, nsecs, counts];
    file_path = fullfile(output_dir, file_name);
    csvwrite_with_headers(file_path, output, headers);
    fprintf('Write to %s.\n', file_path);
end
end