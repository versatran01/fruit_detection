classdef Masker < handle
    
    properties(Access=private)
        % inputs
        image
        mask
        % state
        mode = 1;
        mouseState
        mouseClickPosition
        brushSize = 1;
        finished = false;
        % graphical UI objects/settings
        maskColor = [0 0.75 1];
        maskAlpha = 0.4;
        hFig
        hImage
        hMask
        hToolMenu
        hSizeMenu
        hButtons
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
           set(fig, 'CloseRequestFcn',...
               @(object,eventdata)self.closeRequest(object,eventdata));
        end
        
        function closeRequest(self, object, eventdata)
            delete(self.hFig);
            self.finished = true;
        end
        
        function mouseMove(self, object, eventdata)
            C = getMousePosition();
            % determine region
            sz = size(self.image);
            Cmin = ceil(C - self.brushSize*0.5);
            Cmax = floor(C + self.brushSize*0.5);
            Cmin = max(Cmin([2 1]), [1 1]);      % flip order
            Cmax = min(Cmax([2 1]), sz(1:2));    % flip order
            if self.mouseState
                if self.mode == 1
                    % insert
                    self.mask(Cmin(1):Cmax(1),...
                              Cmin(2):Cmax(2)) = 1;
                elseif self.mode == 2
                    % clear
                    self.mask(Cmin(1):Cmax(1),...
                              Cmin(2):Cmax(2)) = 0;
                end
                self.plotImage();
            end
        end
        
        function mouseDown(self, object, eventdata)
            selType = get(self.hFig,'SelectionType');
            if ~strcmp(selType,'normal')
                return; % ignore right clicks
            end
            self.mouseState = 1;
            self.mouseClickPosition = getMousePosition();
        end
        
        function mouseUp(self, object, eventdata)
            self.mouseState = 0;
        end
        
        function plotImage(self)
            set(0,'CurrentFigure',self.hFig);
            if isempty(self.hImage)
                hold off;
                self.hImage = imshow(self.image);
                hold on;
                % add solid top layer
                sz = size(self.image);
                full = ones(sz(1:2));
                color(:,:,1) = self.maskColor(1)*full;
                color(:,:,2) = self.maskColor(2)*full;
                color(:,:,3) = self.maskColor(3)*full;
                self.hMask = imshow(uint8(color*255));
                % make the window larger
                pos = get(self.hFig, 'Position');
                set(self.hFig,'Position',[pos(1:2) 560 420]);
                % zoom image
                set(gca,'Position',[0.2 0.2 0.6 0.6]);
            else
                % update existing images
                set(self.hImage, 'CData', self.image);
            end
            set(self.hMask, 'AlphaData', self.mask * self.maskAlpha);
        end
        
        function configureInterface(self)
            clf(self.hFig,'reset');
            set(self.hFig,'MenuBar', 'None');
            set(self.hFig,'Name','Masktron 9000');
            cb = @(obj,callbackdata)handleButton(self,obj,callbackdata);            
            self.hToolMenu = uicontrol('Style','popupmenu',...
                 'String',{'Add','Remove'},...
                 'Position',[20,16,120,25],'Callback',cb);
             self.hSizeMenu = uicontrol('Style','popupmenu',...
                 'String',{'1','3','5','10'},...
                 'Position',[160,16,120,25],'Callback',cb);
            self.hButtons{1} = uicontrol('Style', 'pushbutton',...
                                         'String', 'Done',...
                                         'Position', [300 20 80 25],...
                                         'Callback', cb);
        end
        
        function value = pointInImage(self, pt)
            sz = size(self.image);
            value = all(pt > [0 0] & pt <= sz([2 1]));
        end
        
        function handleButton(self, object, callbackdata)
            set(0,'CurrentFigure',self.hFig);
            if object == self.hToolMenu
                self.mode = get(object,'Value');
            elseif object == self.hSizeMenu
                value = get(object,'Value');
                str = object.String{value};
                num = str2double(str);
                self.brushSize = num;
            elseif object == self.hButtons{1}
                % done button
                close(self.hFig);
            end
        end
    end
    
    methods
        function self = Masker(image, mask)
            if nargin < 2
                % initialize a new mask
                mask = zeros(size(image,1), size(image,2));
            end
            self.image = image;
            self.mask = mask;
            self.hFig = figure;
            self.configureInterface();
            self.plotImage();
            self.attachCallbacks();
        end
        
        function value = isFinished(self)
            value = self.finished;
        end
        
        function value = getMask(self)
            value = self.mask;
        end
        
        function delete(self)
            if ishandle(self.hFig)
                close(self.hFig);
            end
        end
    end 
end
