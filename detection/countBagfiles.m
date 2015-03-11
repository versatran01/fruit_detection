function [ bag_results ] = countBagfiles(bagfiles_dir, varargin)

% Input
% rows
% scales
% iterations
% model

input_parser = inputParser;

% We need to know how many rows are there
bag_helpers = parseBagfileInfo('data/trees.tsv', bagfiles_dir);

% Parse input arguments
default_rows = unique([bag_helpers.row]);
default_scales = 0.75;
default_iterations = 1;
default_model_name = 'cs_svc';
default_visualize = false;

input_parser.addParameter('rows', default_rows, ...
                          @(x) (all(isnumeric(x)) && all(x >= 1) && ...
                                all(ismember(x, default_rows))));
input_parser.addParameter('scales', default_scales, ...
                          @(x) (isnumeric(x) && all(x) > 0 && ...
                                all(x <= 1)));
input_parser.addParameter('iterations', default_iterations, ...
                          @(x) (isnumeric(x) && x >= 1));
input_parser.addParameter('model', default_model_name);
input_parser.addParameter('visualize', default_visualize);
                      
input_parser.parse(varargin{:});

% Get parsed input arguments
rows = input_parser.Results.rows;
scales = input_parser.Results.scales;
iterations = input_parser.Results.iterations;
model_name = input_parser.Results.model;
visualize = input_parser.Results.visualize;


% Notice that counts is a M-by-N matrix, where M is the size of scales and
% N is the size of iterations
bag_results = struct('row', {}, ...
                     'side', {}, ...
                     'counts', {}, ...
                     'scales', {}, ...
                     'iterations', {});

                 
all_rows = [bag_helpers.row];

% For each row
for i_row = 1:numel(rows)
    row = rows(i_row);
    bag_helper_row = bag_helpers(all_rows == row);
    
    checkBagHelper(bag_helper_row, row);
    
    % For each side
    for i_side = 1:numel(bag_helper_row)
        
        bag_helper_side = bag_helper_row(i_side);
        
        if ~bag_helper_side.found, continue; end
        
        side = bag_helper_side.direction;

        bag_result = struct('row', row, ...
                            'side', side, ...
                            'counts', zeros(numel(scales), iterations), ...
                            'scales', scales, ...
                            'iterations', iterations);
            
        % For each scale
        for i_scale = 1:numel(scales)
            scale = scales(i_scale);

             % For each iteration
             for i_iter = 1:iterations
                 iter = i_iter;
                 fprintf('Processing row: %g, side: %s, scale: %0.2f, iter: %g.\n', ...
                         row, side, scale, iter);
                 % Call main processing function
                 bag_helper = bag_helper_side;
                 duration = [bag_helper.startTime, bag_helper.endTime];
                 tracker = processBagfile(bag_helper.path, scale, ...
                                          model_name, duration, visualize);
                 
                 bag_result.counts(i_scale, i_iter) = ...
                     tracker.total_fruit_counts;
             end  % end each iteration
             
        end  % end each scale
        
        % Add to final results
        bag_results(end + 1) = bag_result;
        
    end  % end each side
                        
end  % end each row

end

function checkBagHelper(bag_helpers, row)

for i = 1:numel(bag_helpers)
    bag_helper = bag_helpers(i);
    assert(bag_helper.row == row, ...
           'BagHelper: row number %g does not match %g', ...
           bag_helper.row, row);
end

end

function processRow()
end

function processSide()
end

function processScale()
end

function processIteration()
end