classdef Masker < handle
    
    properties(Access=private)
        image
        mask
        % graphical UI objects
        hFig
        hImage
        hMask
    end
    
    methods
        function self = Masker(image, mask)
            if nargin < 2
                % initialize a new mask
                mask = false(size(image,1), size(image,2));
            end
            self.image = image;
            self.mask = mask;
            self.hFig = figure;
            self.configureInterface();           
            self.plotImage();
            self.attachCallbacks();
        end
    end 
end
