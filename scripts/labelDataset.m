%% labelDataset.m
init;

% load data
dataset = Dataset(DATASET_PATH);

start = 1;
num_images = dataset.size();
iptstr = sprintf('Start selections from which image? (1 ... %i): ', num_images);
result = input(iptstr);
if result > num_images || result < 1
    fprintf('Error: Image number must fall in range [1,%i]\n', num_images);
    return;
else
    start = result;
end

% prompt user to circle fruit
for n=start:num_images
    sel = dataset.selections{n};
    msk = dataset.masks{n};
    L = Labler(dataset.images{n}, 'orange', sel, msk);
    while ~L.isFinished()
        drawnow; % refresh the UI
    end
    % get selections
    dataset.selections{n} = L.getSelections();
    dataset.masks{n} = L.getMasks();
    fprintf('Obtained %lu selections\n',... 
        numel(dataset.selections{n}));
    if L.didQuit()
        % user wants to exit early
        break;
    end
end

fprintf('Saving dataset to %s.\n', DATASET_PATH);
dataset.save(DATASET_PATH);
