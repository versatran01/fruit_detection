%% labelDataset.m
init;

dataset_path = uigetdir(DATASET_PATH, 'Select dataset directory');
if isempty(dataset_path) || (isnumeric(dataset_path) && dataset_path==0)
    return; % exit early
end

% load data
dataset = Dataset(dataset_path);
num_images = dataset.size();

prompt = {'Enter matrix size: '};
answer = inputdlg({'Enter start image: '},...
    'Inputbox 9000', 1, {'1'});
answer = answer{1};
answer = str2double(answer);
if answer > num_images || answer < 1
    error('Image number must fall in range [1,%i]\n', num_images);
else
    start = answer;
end

% prompt user to circle fruit
for n=start:num_images
    sel = dataset.selections{n};
    msk = dataset.masks{n};
    L = Labler(dataset.images{n}, sel, msk);
    while ~L.isFinished()
        drawnow; % refresh the UI
    end
    % get selections
    dataset.selections{n} = L.getSelections();
    dataset.masks{n} = L.getMasks();
    fprintf('Obtained %lu selections\n', numel(dataset.selections{n}));
    if L.didQuit()
        % user wants to exit early
        break;
    end
end

fprintf('Saving dataset to %s.\n', dataset_path);
dataset.save(dataset_path);
