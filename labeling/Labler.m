classdef Labler < handle
    
    properties(Access=private)
        % inputs
        image
        labelStrings
        % mode
        selecting = false;
        mode = 1;
        finished = false;
        currentLabel = 1;
        % selections
        center
        radius
        selections = {};
        % graphical UI objects
        hFig
        hSelection
        hLabels
        hImage
        hButtons
        hToolMenu
        hLabelMenu
        hContextMenu
    end
    
    methods(Access=private)
        function attachCallbacks(self)
           fig = self.hFig;
           set(fig, 'WindowButtonMotionFcn',...
               @(object,eventdata)self.mouseMove(object,eventdata));
           set(fig, 'WindowButtonDownFcn',...
               @(object,eventdata)self.mouseDown(object,eventdata));
           set(fig, 'WindowButtonUpFcn',...
               @(object,eventdata)self.mouseUp(object,eventdata));
           set(fig, 'KeyReleaseFcn',...
               @(object,eventdata)self.keyUp(object,eventdata));
           set(fig, 'CloseRequestFcn',...
               @(object,eventdata)self.closeRequest(object,eventdata));
        end
        
        function mouseMove(self, object, eventdata)
            C = getMousePosition();
            if self.selecting
                self.radius = norm(C - self.center);
                if self.radius > 3
                    self.plotCircleSelection(self.radius, C);
                end
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
                    self.radius = 0;
                    self.selecting = true;
                end
            end
        end
        
        function mouseUp(self, object, eventdata)
            self.selecting = false;
        end
        
        function keyUp(self, object, eventdata)
            if int32(eventdata.Character) == 13
                % newline/enter
                if self.mode == 1 && ~self.selecting
                    if ~isempty(self.radius)
                        self.captureSelection();
                    end
                end
            end
        end
        
        function closeRequest(self, object, eventdata)
            delete(self.hFig);
            self.finished = true;
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
                end 
                set(self.hLabels(i),'LineWidth',2);
                if sel(4)==1
                    % todo: make this an option
                    color = [1 0 0];
                else
                    color = [0 1 1];
                end
                set(self.hLabels(i),'Color',color);
            end
        end
        
        function plotImage(self)
            set(0,'CurrentFigure',self.hFig);
            hold off;
            self.hImage = imshow(self.image);
            hold on;
        end
        
        function configureInterface(self)
            clf(self.hFig,'reset');
            set(self.hFig,'MenuBar', 'None');
            set(self.hFig,'Name','Labeltron 9000');
            cb = @(obj,callbackdata)handleButton(self,obj,callbackdata);            
            self.hToolMenu = uicontrol('Style','popupmenu',...
                'String',{'Select','Zoom'},...
                'Position',[20,16,120,25],'Callback',cb);
            self.hLabelMenu = uicontrol('Style','popupmenu',...
                'String',self.labelStrings,...
                'Position',[150,16,120,25],'Callback',cb);
            set(self.hLabelMenu,'Value',self.currentLabel);
            self.hButtons{1} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Zoom Reset',...
                                         'Position', [300 20 80 25],...
                                         'Callback', cb);
            self.hButtons{2} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Done',...
                                         'Position', [400 20 80 25],...
                                         'Callback', cb);
            set(self.hFig, 'Units', 'normalized', 'Position', [0,0,1,1]);
        end
        
        function handleButton(self, object, callbackdata)
            set(0,'CurrentFigure',self.hFig);
            if self.hButtons{1} == object
                % zoom reset button
                sz = size(self.image);
                axis([0 sz(2) 0 sz(1)]);
            elseif self.hButtons{2} == object
                close(self.hFig); % quit
            elseif object == self.hToolMenu
                % tool menu
                self.switchMode(get(object, 'Value'));
            elseif object == self.hLabelMenu
                % label menu
                self.currentLabel = get(object, 'Value');
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
            set(self.hToolMenu, 'Value', mode);
        end
        
        function captureSelection(self)
            self.selections{end+1} = [self.center self.radius... 
                                      self.currentLabel];
            self.plotSelections();
        end
    end
    
    methods(Access=public)
        function self = Labler(image, labelStrings, selections)
            if nargin < 3
                selections = {};
            end
            self.image = image;
            self.labelStrings = labelStrings;
            self.hFig = figure;
            self.selections = selections;
            self.configureInterface();           
            self.plotImage();
            self.plotSelections();
            self.attachCallbacks();
        end
        
        function value = isFinished(self)
            value = self.finished;
        end
        
        function value = getSelections(self)
            value = self.selections;
        end
        
        function delete(self)
            if ishandle(self.hFig)
                close(self.hFig);
            end
        end
    end
end
