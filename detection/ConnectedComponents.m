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
        
        function merge(self, indices)
            
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
    end
    
end

