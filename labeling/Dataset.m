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
                % todo: add this logic...
            end
        end
        
        function append(self, other)
            if ~isa(other,'Dataset')
                error('other must be of type Dataset');
            end
            self.images = vertcat(self.images, other.images);
            self.selections = vertcat(self.selections, other.selections);
            self.masks = vertcat(self.masks, other.masks);
            self.names = vertcat(self.names, other.names);
        end
        
        function value = get.size(self)
            value = numel(self.images);
        end
    end
end
