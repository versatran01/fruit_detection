%% extractColorImages.m
% Script to extract color images from ROS bagfiles.
clear rosbag_wrapper;
clear ros.Bag;
clear;
close all;

BAGFILE_FOLDER = '/Volumes/D512/ground/rectified';
OUTPUT_FOLDER = '/Volumes/External/Extracted/rectified';
TOPIC = '/color/image_rect_color';
SKIP_IMAGES = 1;

bagfile_names = {};
bagfile_paths = {};

items = dir(BAGFILE_FOLDER);
for i=1:numel(items)
    name = items(i).name;
    if ~items(i).isdir
        matches = regexpi(name,'.+.(bag)','match');
        if ~isempty(matches)
            fullpath = strcat(BAGFILE_FOLDER,'/',name);
            bagfile_paths{end+1} = fullpath;
            bagfile_names{end+1} = name;
        end
    end
end

fprintf('Found %i bagiles in %s\n',...
    numel(bagfile_paths), BAGFILE_FOLDER);

for i=1:numel(bagfile_paths)
    filepath = bagfile_paths{i};
    name = bagfile_names{i};
    fprintf('Loading %s\n', name);
    bag = ros.Bag.load(filepath);
    bag.resetView({TOPIC});
    % create output directory
    output_folder = strcat(OUTPUT_FOLDER,'/',name);
    if ~exist(output_folder,'dir')
        fprintf('Creating folder %s\n', output_folder);
        mkdir(output_folder);
    end
    count = 0;
    while bag.hasNext()
        % read the next image
        [msg, ~] = bag.read();
        output_path = sprintf('%s/%.4i.png', output_folder, count);
        count=count+1;
        if mod(count, SKIP_IMAGES) == 0
            % transform image
            img = reshape(msg.data, 3, msg.width, msg.height);
            img = permute(img, [3 2 1]);
            img = img(:, :, [3 2 1]); % convert to rgb
            imwrite(img, output_path);
            fprintf('Wrote %s to disk\n', output_path);
        end
    end
    fprintf('Processed %i images\n', count);
end
