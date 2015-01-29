%% labelDataset.m
close all;

% prompt user to circle fruit
selections = {};
for n=1:numel(dataset_images)
    L = Labler(dataset_images{n}, 'orange');
    while ~L.isFinished()
        drawnow; % refresh the UI
    end
    % get selections
    selections{end+1} = L.getSelections();
    fprintf('Obtained %lu selections\n', numel(selections{end}));
end

% now mask selections
