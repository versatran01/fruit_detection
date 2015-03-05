classdef ConnectedComponents < handle
    %CONNECTEDCOMPONENTS Store connected components.
    
    properties
        image
    end
    
    properties(Access=private)
        CC
    end
    
    properties(Dependent)
        Area
        Centroid
        BoundingBox
        size
    end
    
    methods
        function self = ConnectedComponents(image)
            if ~islogical(image)
                error('image should be logical');
            end
            self.image = image;
            self.CC = bwconncomp(image);
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
        
        function value = get.Area(self)
            props = regionprops(self.CC, 'Area');
            value = [props.Area]';
        end
        
        function value = get.BoundingBox(self)
            props = regionprops(self.CC, 'BoundingBox');
            value = vertcat(props.BoundingBox);
        end
        
        function value = get.Centroid(self)
            props = regionprops(self.CC, 'Centroid');
            value = vertcat(props.Centroid);
        end
        
        function value = get.size(self)
            value = self.CC.NumObjects;
        end
    end
    
end
