classdef ConnectedComponents < handle
    %CONNECTEDCOMPONENTS Store connected components.
    
    properties
        image       % mask of pixels used to find components
    end
    
    properties(Access=private)
        CC
        props
    end
    
    properties(Dependent)
        Area
        Centroid
        BoundingBox
        BoundingArea
        size
        isempty
    end
    
    methods(Access=private)
        function recompute(self)
            self.props = regionprops(self.CC, 'Area', ...
                'Centroid', 'BoundingBox');
        end
    end
    
    methods
        function self = ConnectedComponents(image)
            if ~islogical(image)
                error('image should be logical');
            end
            self.image = image;
            self.CC = bwconncomp(image,8);
            self.recompute();
        end
        
        function discard(self, index)
            % update image
            strip = cell2mat( self.CC.PixelIdxList(index)' );
            self.image(strip) = false;
            % update CC
            self.CC.PixelIdxList(index) = [];
            self.CC.NumObjects = numel(self.CC.PixelIdxList);
            self.recompute();
        end
        
        function merge(self, map)
            % map should be square
            if size(map,1) ~= size(map,2)
                error('map must be square');
            end
            if ~islogical(map)
                error('map must be logical');
            end
            % now update the CC structure
            nCC = struct('Connectivity', self.CC.Connectivity,...
                'ImageSize', self.CC.ImageSize);
            nCC.PixelIdxList = {};
            for i=1:size(map,1)
                cols = find(map(i,:));
                if ~isempty(cols)
                    % retrieve the pixels assigned to this group
                    cells = self.CC.PixelIdxList(cols)';
                    % merge them
                    nCC.PixelIdxList{end+1} = cell2mat(cells);
                end
            end
            nCC.NumObjects = numel(nCC.PixelIdxList);
            self.CC = nCC;
            self.recompute();
        end
        
        function sort(self, key, order)
            if nargin < 3
                order = 'descend';
            end
            if ~ischar(key)
                error('key must be string');
            end
            value = self.(key);
            % sort by values
            [~,idx] = sort(value, order);
            self.CC.PixelIdxList = self.CC.PixelIdxList(idx);
            self.recompute();
        end
        
        function [fig] = plot(self)
            fig = figure;
            imshow(self.image);
            hold on;
            bbox = self.BoundingBox();
            for i=1:self.size()
                % draw the bounding box
                pts = bboxToLinePoints(bbox(i,:));
                pts_x = squeeze(pts(:,1,:));
                pts_y = squeeze(pts(:,2,:));
                h = plot(pts_x,pts_y,'b');
                set(h,'LineWidth',2);
            end
        end
        
        function value = get.Area(self)
            value = [self.props.Area]';
        end
        
        function value = get.BoundingBox(self)
            value = vertcat(self.props.BoundingBox);
        end
        
        function value = get.BoundingArea(self)
            bbox = self.BoundingBox();
            value = bbox(:,3) .* bbox(:,4);
        end
        
        function value = get.Centroid(self)
            value = vertcat(self.props.Centroid);
        end
        
        function value = get.size(self)
            value = self.CC.NumObjects;
        end
        
        function value = get.isempty(self)
            value = self.size() == 0;
        end
    end
    
end

