classdef DetectionPlotter < handle
    %DETECTIONPLOTTER Plot the previous frame and the current frame, and
    % their detections.
    
    properties(Access=private)
        % gui elements
        hFig
        hImages
        hBoxes
    end
    
    methods(Access=private)
        function [h] = plotBoundingBoxes(self, bbox, h)
            [X, Y] = bboxToPatchVertices(bbox);    
            if nargin < 3
                h = patch(X, Y, 'r', ...
                   'Parent', get(self.hFig,'CurrentAxes'), ...
                   'EdgeColor', [1 0 0], ...
                   'FaceAlpha', 0, ...
                   'LineWidth', 2);
            else
                set(h,'xdata', X, 'ydata',Y);
            end
        end
        
        function updatePlots(self, imagePrev, ccPrev,...
                imageCur, ccCur)
            boxPrev = ccPrev.BoundingBox();
            boxCur = ccCur.BoundingBox();
            boxCur(:,1) = bsxfun(@plus,boxCur(:,1),size(imagePrev,2));
            if isempty(self.hFig)
                % initialize new figure
                self.hFig = figure;
                self.hImages(1) = imshow(imagePrev);
                hold on;
                ax = axis;
                axis([ax(1) ax(2)*2 ax(3) ax(4)]);  % double wide
                self.hImages(2) = imshow(imageCur);
                xdata = get(self.hImages(1),'XData');
                xdata = [xdata(2) xdata(2)*2];
                set(self.hImages(2),'XData',xdata);
                % plot bounding boxes
                self.hBoxes(1) = self.plotBoundingBoxes(boxPrev);
                self.hBoxes(2) = self.plotBoundingBoxes(boxCur);
            else
                set(self.hImages(1),'CData',imagePrev);
                set(self.hImages(2),'CData',imageCur);
                self.plotBoundingBoxes(boxPrev, self.hBoxes(1));
                self.plotBoundingBoxes(boxCur, self.hBoxes(2));
            end
        end
    end
    
    methods
        function self = DetectionPlotter()
        end
        
        function setFrame(self, imagePrev, ccPrev,...
                imageCur, ccCur)
            self.updatePlots(imagePrev, ccPrev, imageCur, ccCur);
        end
    end
end
