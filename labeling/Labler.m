classdef Labler < handle
    
    properties(Access=private)
        image
        selecting = false;
        center
        radius
        selections = {};
        mode = 1;
        
        hFig
        hSelection
        hLabels
        hImage
        hButtons
        hToolMenu
    end
    
    methods(Access=private)
        function attachCallbacks(self, fig)
           set(fig, 'WindowButtonMotionFcn',...
               @(object,eventdata)self.mouseMove(object,eventdata));
           set(fig, 'WindowButtonDownFcn',...
               @(object,eventdata)self.mouseDown(object,eventdata));
           set(fig, 'WindowButtonUpFcn',...
               @(object,eventdata)self.mouseUp(object,eventdata));
           set(fig, 'KeyReleaseFcn',...
               @(object,eventdata)self.keyUp(object,eventdata));
        end
        
        function mouseMove(self, object, eventdata)
            C = getMousePosition();
            if self.selecting
                self.radius = norm(C - self.center);
                self.plotCircleSelection(self.radius, C);
            end
        end
        
        function mouseDown(self, object, eventdata)
            selType = get(self.hFig,'SelectionType');
            if ~strcmp(selType,'normal')
                return; % ignore right clicks
            end
            if self.mode == 1
                % selecting circle
                if ~self.selecting
                    self.center = getMousePosition();
                    self.selecting = true;
                end
            elseif self.mode == 3
                % creating mask
            end
        end
        
        function mouseUp(self, object, eventdata)
            self.selecting = false;
        end
        
        function keyUp(self, object, eventdata)
            if self.mode == 1 && ~self.selecting
                if ~isempty(self.radius)
                    % have a valid selection, capture it
                    self.captureSelection();
                end
            end
        end
        
        function plotCircleSelection(self, radius, mousePoint)
            points = createCirclePoints(self.center, radius);
            line = [self.center; mousePoint];
            if isempty(self.hSelection)
                set(0,'CurrentFigure',self.hFig);
                self.hSelection{1} = plot(points(:,1),points(:,2));
                self.hSelection{2} = plot(line(:,1), line(:,2));
                for i=1:2
                    set(self.hSelection{i},'LineWidth',3);
                    set(self.hSelection{i},'Color',[1 0 1]);
                end
            end
            set(self.hSelection{1},'xdata',points(:,1),'ydata',points(:,2));
            set(self.hSelection{2},'xdata',line(:,1),'ydata',line(:,2));
        end
        
        function plotSelections(self)
            for i=1:length(self.selections)
                sel = self.selections{i};   % [x y radius]
                points = createCirclePoints(sel(1:2), sel(3));
                if length(self.hLabels) >= i
                    set(self.hLabels(i),'xdata',points(:,1),...
                        'ydata',points(:,2));
                else
                    self.hLabels(end+1) = plot(points(:,1),points(:,2));
                    set(self.hLabels(end),'LineWidth',2);
                    set(self.hLabels(end),'Color',[0 1 1]);
                end 
            end
        end
        
        function plotImage(self, image)
            set(0,'CurrentFigure',self.hFig);
            hold off;
            self.hImage = imshow(image);
            hold on;
        end
        
        function configureInterface(self)
            set(self.hFig,'MenuBar', 'None');
            cb = @(obj,callbackdata)handleButton(self,obj,callbackdata);            
            self.hToolMenu = uicontrol('Style','popupmenu',...
                'String',{'Select','Zoom','Mask'},...
                'Position',[20,16,120,25],'Callback',cb);
            self.hButtons{1} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Zoom Reset',...
                                         'Position', [150 20 80 25],...
                                         'Callback', cb);
        end
        
        function handleButton(self, object, callbackdata)
            set(0,'CurrentFigure',self.hFig);
            if self.hButtons{1} == object
                % zoom reset button
                sz = size(self.image);
                axis([0 sz(2) 0 sz(1)]);
            elseif object == self.hToolMenu
                % tool menu
                self.switchMode(get(object, 'Value'));
            end 
        end
        
        function switchMode(self, mode)
            if self.mode ~= mode
                if mode == 2
                    zoom on;
                else
                    zoom off;
                end
                self.mode = mode;
            end
        end
        
        function captureSelection(self)
            self.selections{end+1} = [self.center self.radius];
            self.plotSelections();
        end
    end
    
    methods(Access=public)
        function self = Labler(image)
            self.image = image;
            self.hFig = figure;
            self.configureInterface();           
            self.plotImage(self.image);
            self.attachCallbacks(self.hFig);
        end
    end
end
