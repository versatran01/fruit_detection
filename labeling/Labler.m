classdef Labler < handle
    
    properties(Access=private)
        image
        selecting = false;
        center
        
        hFig
        hSelection
        hImage
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
                self.plotCircleSelection(radius, C);
            end
        end
        
        function mouseDown(self, object, eventdata)
            selType = get(self.hFig,'SelectionType');
            if ~strcmp(selType,'normal')
                return; % ignore right clicks
            end
            if ~self.selecting
                self.center = getMousePosition();
                self.selecting = true;
            end
        end
        
        function mouseUp(self, object, eventdata)
           	if self.selecting
                fprintf('Ending selection\n');
            end
            self.selecting = false;
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
        
        function plotImage(self, image)
            set(0,'CurrentFigure',self.hFig);
            hold off;
            self.hImage = imshow(image);
            hold on;
        end
        
        function configureInterface(self)
            % hide menu and toolbar
            set(self.hFig,'MenuBar', 'None');
            
            % add buttons
            bg = uibuttongroup('Visible','off',...
                  'Position',[0 0 .2 1]);
              
            % Create three radio buttons in the button group.
            r1 = uicontrol(bg,'Style',...
                              'radiobutton',...
                              'String','Option 1',...
                              'Position',[10 350 100 30],...
                              'HandleVisibility','off');

            r2 = uicontrol(bg,'Style','radiobutton',...
                              'String','Option 2',...
                              'Position',[10 250 100 30],...
                              'HandleVisibility','off');

            r3 = uicontrol(bg,'Style','radiobutton',...
                              'String','Option 3',...
                              'Position',[10 150 100 30],...
                              'HandleVisibility','off');
            bg.Visible = 'on';
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
