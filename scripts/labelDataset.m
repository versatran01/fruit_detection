%% labelDataset.m
init;

num_images = numel(dataset_images);
fprintf('Working with %i images.\n', num_images);

% check if we have prior selections
labels_path = strcat(DATASET_PATH, '/labels.mat');
if exist(labels_path,'file')
    fprintf('Loading existing labels: %s\n', labels_path);
    load(labels_path);
    selections = labels.selections;
    masks = labels.masks; 
    fprintf('  - Selections for %i images.\n', numel(selections));
    fprintf('  - Masks for %i images.\n', numel(masks));
else
    fprintf('No existing labels to load.\n');
    % initialize new set of selections & labels
    selections = {};
    masks = {};
end

start = 1;
result = input('Start selections from which image? (1 ... N, 0 to skip): ');
if result == 0
    start = num_images+1;
elseif result > num_images || result < 1
    fprintf('Error: Image number must fall in range [1,%i]\n', num_images);
    return;
else
    start = result;
end

% prompt user to circle fruit
for n=start:num_images
    sel = {};
    if numel(selections) >= n
        % use existing selections if we have them
        sel = selections{n};
    end
    L = Labler(dataset_images{n}, 'orange', sel);
    while ~L.isFinished()
        drawnow; % refresh the UI
    end
    % get selections
    selections{n} = L.getSelections();
    fprintf('Obtained %lu selections\n', numel(selections{end}));
    
    % now mask selections
    fprintf('Sampling %i selections from image %i.\n',...
        numel(selections{n}), n);
    [samples,regions] = sampleSelectionsFromImage(dataset_images{n},...
        selections{n});
    image_masks = {};
    for m=1:numel(samples)
        M = Masker(samples{m});
        while ~M.isFinished()
            drawnow;
        end
        image_masks{m} = M.getMask();
    end
    masks{n} = image_masks;
end

