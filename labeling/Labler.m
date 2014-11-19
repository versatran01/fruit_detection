classdef Labler < handle
    
    properties(Access=private)
        images
        selecting = false;
        center
        
        hFig
        hSelection
    end
    
    methods(Access=private)
        function attachCallbacks(self, fig)
           set(fig, 'WindowButtonMotionFcn',...
               @(object,eventdata)self.mouseMove(object,eventdata));
           set(fig, 'WindowButtonDownFcn',...
               @(object,eventdata)self.mouseDown(object,eventdata));
           set(fig, 'WindowButtonUpFcn',...
               @(object,eventdata)self.mouseUp(object,eventdata));
        end
        
        function mouseMove(self, object, eventdata)
            C = getMousePosition();
            if self.selecting
                radius = norm(C - self.center);
                self.plotCircleSelection(radius);
            end
        end
        
        function mouseDown(self, object, eventdata)
            % get position of click from current axes and enter selection
            C = getMousePosition();
            self.center = C;
            self.selecting = true;
        end
        
        function mouseUp(self, object, eventdata)
           	if self.selecting
            end
            self.selecting = false;
        end
        
        function plotCircleSelection(self, radius)
            points = createCirclePoints(self.center, radius);
            if isempty(self.hSelection)
                set(0,'CurrentFigure',self.hFig);
                self.hSelection = plot([],[]);
                set(self.hSelection,'LineWidth',2);
                set(self.hSelection,'Color',[0 0 0.8]);
            end
            set(self.hSelection,'xdata',points(:,1),'ydata',points(:,2));
        end
    end
    
    methods(Access=public)
        function self = Labler(images)
            self.images = images;
            self.hFig = figure;
        end
        
        function newSelection(self)
            self.hFig = figure;
            self.attachCallbacks(self.hFig);
        end
    end
end
