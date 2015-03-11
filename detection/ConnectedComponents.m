classdef ConnectedComponents < handle
    %CONNECTEDCOMPONENTS Store connected components.
    
    properties
        image       % mask of pixels used to find components
    end
    
    properties(Access=private)
        CC
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
    end
    
    methods
        function self = ConnectedComponents(image)
            if ~islogical(image)
                error('image should be logical');
            end
            self.image = image;
            self.CC = bwconncomp(image,8);
        end
        
        function discard(self, index)
            % update image
            strip = cell2mat( self.CC.PixelIdxList(index)' );
            self.image(strip) = false;
            % update CC
            self.CC.PixelIdxList(index) = [];
            self.CC.NumObjects = numel(self.CC.PixelIdxList);
        end
        
        function merge(self, map)
            % map should be square
            if size(map,1) ~= size(map,2)
                error('map must be square');
            end
            if ~islogical(map)
                error('map must be logical');
            end
            if nnz(map) ~= size(map,1)
                error('number of non-zeros must match size of map');
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
        end
        
        function reorder(self, indices)
            if numel(indices) ~= self.CC.NumObjects
                error('Dimension mismatch');
            end
            self.CC.PixelIdxList = self.CC.PixelIdxList(indices);
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
        end
        
        function [fig] = plot(self, bgimage, fig)
            if nargin < 3
                fig = figure;
            else
                set(0,'CurrentFigure',fig);
            end
            if nargin < 2
                bgimage = self.image;
            end
            imshow(bgimage);
            hold on;
            bbox = self.BoundingBox();
            for i=1:self.size()
                % draw the bounding box
                pts = bboxToLinePoints(bbox(i,:));
                pts_x = squeeze(pts(:,1,:));
                pts_y = squeeze(pts(:,2,:));
                h = plot(pts_x,pts_y,'b');
                set(h,'LineWidth',2);
                
                cx = bbox(i,1) + bbox(i,3)*0.5;
                cy = bbox(i,2) + bbox(i,4)*0.5;
                h = text(cx,cy,num2str(i));
                set(h, 'Color', [0 1 0]);
                set(h, 'FontSize', 13);
            end
        end
        
        function value = get.Area(self)
            props = regionprops(self.CC, 'Area');
            value = [props.Area]';
        end
        
        function value = get.BoundingBox(self)
            props = regionprops(self.CC, 'BoundingBox');
            value = vertcat(props.BoundingBox);
        end
        
        function value = get.BoundingArea(self)
            bbox = self.BoundingBox();
            value = bbox(:,3) .* bbox(:,4);
        end
        
        function value = get.Centroid(self)
            props = regionprops(self.CC, 'Centroid');
            value = vertcat(props.Centroid);
        end
                
        function value = get.size(self)
            value = self.CC.NumObjects;
        end
        
        function value = get.isempty(self)
            value = self.size() == 0;
        end
    end
    
end

