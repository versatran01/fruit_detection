classdef Dataset < handle
    properties(Access=public)
        images = {};
        selections = {};
        masks = {};
        names = {};
    end
    
    methods(Access=private)
        function load(self, path)
            labels_path = strcat(path, '/labels.mat');
            if exist(labels_path, 'file')
                % we are loading an existing dataset
                fprintf('Loading existing labels: %s\n', labels_path);
                data = load(labels_path);
                dataset = data.dataset;
                N = numel(dataset.selections);
                fprintf('Will load %i images for dataset.\n', N);
                % copy data into class
                self.selections = dataset.selections;
                self.masks = dataset.masks;
                self.names = dataset.names;
                % load all images
                for i=1:N
                    name = self.names{i};
                    imgpath = sprintf('%s/%s',path,name);
                    self.images{i} = imread(imgpath);
                end
                self.images = reshape(self.images,...
                    numel(self.images), 1);
            else
                fprintf('Initializing a new dataset.\n');
                % this is a new dataset, try to load images
                [i,~,n] = loadImages(path,[],...
                    'verbose',true,'recursive',false);
                N = numel(i);
                fprintf('Loaded %i images.\n', N);
                self.images = i;
                self.names = n;
                self.selections = cell(N,1);
                self.masks = cell(N,1);
            end
        end
    end
    
    properties(Dependent)
        size
    end
    
    methods
        function self = Dataset(path)
            self.load(path);
        end
        
        function save(self, path, saveimages)
            if nargin < 3
                saveimages = false;
            end
            dataset = struct();
            dataset.selections = self.selections;
            dataset.masks = self.masks;
            dataset.names = self.names;
            % write to disk
            labels_path = strcat(path, '/labels.mat');
            save(labels_path,'dataset');
            if saveimages
                for i=1:self.size()
                    fullpath = strcat(path,'/',dataset.names{i});
                    imwrite(self.images{i}, fullpath);
                end
            end
        end
        
        function append(self, other)
            if ~isa(other,'Dataset')
                error('other must be of type Dataset');
            end
            for i=1:other.size()
                name = other.names{i};
                exists = find(ismember(self.names, name));
                if exists
                    error('Tried to add duplicates! Adding nothing.');
                end
            end
            self.images = vertcat(self.images, other.images);
            self.selections = vertcat(self.selections, other.selections);
            self.masks = vertcat(self.masks, other.masks);
            self.names = vertcat(self.names, other.names);
        end
        
        function removeImage(self, index)
            self.images(index) = [];
            self.selections(index) = [];
            self.masks(index) = [];
            self.names(index) = [];
        end
                
        function [indices, seldata] = findEmptyMasks(self, filter)
            if nargin < 2
                filter = 1;
            end
            indices = [];
            seldata = [];
            for i=1:self.size()
                M = self.masks{i};
                S = self.selections{i};
                for j=1:numel(M)
                    sel = S{j};
                    % matches the filter and is empty!
                    if sel(4) == filter
                        if isempty(M{j})
                            indices(end+1,:) = [i j];
                            seldata(end+1,:) = sel;
                        end
                    end
                end
            end
        end
        
        function launchLabler(self, index)
            if index > self.size()
                error('Invalid image index');
            end
            L = Labler();
            L.editImage(self.images{index}, self.names{index},...
                self.selections{index}, self.masks{index});
            while ~L.isFinished()
                drawnow;
            end
            L.close();
            self.selections{index} = L.getSelections();
            self.masks{index} = L.getMasks();
        end
        
        function value = get.size(self)
            value = numel(self.images);
        end
    end
end
