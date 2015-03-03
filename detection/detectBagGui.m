function varargout = detectBagGui(varargin)
% DETECTBAGGUI MATLAB code for detectBagGui.fig
%      DETECTBAGGUI, by itself, creates a new DETECTBAGGUI or raises the existing
%      singleton*.
%
%      H = DETECTBAGGUI returns the handle to a new DETECTBAGGUI or the handle to
%      the existing singleton*.
%
%      DETECTBAGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DETECTBAGGUI.M with the given input arguments.
%
%      DETECTBAGGUI('Property','Value',...) creates a new DETECTBAGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before detectBagGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to detectBagGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help detectBagGui

% Last Modified by GUIDE v2.5 02-Mar-2015 20:43:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @detectBagGui_OpeningFcn, ...
                   'gui_OutputFcn',  @detectBagGui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before detectBagGui is made visible.
function detectBagGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to detectBagGui (see VARARGIN)

% Choose default command line output for detectBagGui
handles.output = hObject;

set(handles.play_pause_togglebutton, 'Enable', 'off')
set(handles.time_slider, 'Enable', 'off')
set(handles.reset_pushbutton, 'Enable', 'off')
set(handles.step_forward_pushbutton, 'Enable', 'off')
set(handles.step_backward_pushbutton, 'Enable', 'off')

load('models/liblinear_ensemble.mat');
handles.model = model;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes detectBagGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = detectBagGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in open_bag_pushbutton.
function open_bag_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to open_bag_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[bag_name, bag_dir] = uigetfile('*.bag', 'Select bag file');
bag_path = [bag_dir, bag_name];
if bag_name
    set(handles.bag_path_text, 'String', bag_path);
end

if ~bag_name, return; end
% Open the bag and enable play_pause_togglebutton
bag = ros.Bag(bag_path);
bag.resetView(bag.topics);
set(handles.play_pause_togglebutton, 'Enable', 'on');

% List all topics that are sensor_msgs/Image
image_topics = {};
for i = 1:numel(bag.topics)
    if strcmp(bag.topicType(bag.topics{i}), 'sensor_msgs/Image')
        
        image_topics{end+1} = bag.topics{i};
    end
end
set(handles.topic_popupmenu, 'String', image_topics)

% Display time or total amount of messages?
% enable time slider
total_time = bag.time_end - bag.time_begin;
set(handles.time_slider, 'Min', 0)
set(handles.time_begin_text, 'String', 0)
set(handles.time_slider, 'Max', total_time)
set(handles.time_end_text, 'String', total_time)
set(handles.time_slider, 'Value', 0)
set(handles.time_current_text, 'String', 0)
set(handles.time_slider, 'Enable', 'on')

% Save to handles
handles.bag_path = bag_path;
handles.bag = bag;
handles.total_time = total_time;
handles.image_topics = image_topics;
guidata(hObject, handles);

% --- Executes on button press in play_pause_togglebutton.
function play_pause_togglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to play_pause_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Max is depressed, hence play
if get(hObject, 'Value') == get(hObject, 'Max')
    set(hObject, 'String', 'Pause');
    while handles.bag.hasNext()
        [msg, meta] = handles.bag.read();
        if strcmp(meta.topic, '/color/image_raw')
            % todo: add time control
            image = ros_image_msg_to_matlab_image(msg);
            process_image(image,handles);
            drawnow;
            pause(0.001);
            if get(hObject, 'Value') == get(hObject, 'Min')
                break;
            end
        end
    end
else
    set(hObject, 'String', 'Play');
end

function process_image(image, handles)
image = imresize(image, 0.25);
[mask,bboxes] = detectFruit(handles.model, image);

% draw original image
draw_image_on(handles.original_axes, image);
hold on;
pts = bboxToLinePoints(bboxes);
handles.bboxPlots = plot(squeeze(pts(:,1,:)), squeeze(pts(:,2,:)));
set(handles.bboxPlots,'LineWidth',3);

% draw mask
draw_image_on(handles.detection_axes, mask);

function bag_path_text_CreateFcn(hObject, eventdata, handles)

function original_axes_CreateFcn(hObject, eventdata, handles)

% --- Executes on slider movement.
function time_slider_Callback(hObject, eventdata, handles)
% hObject    handle to time_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

time_slider_value = get(hObject, 'Value');
set(handles.time_current_text, 'String', time_slider_value)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function time_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in step_backward_pushbutton.
function step_backward_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to step_backward_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in step_forward_pushbutton.
function step_forward_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to step_forward_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in reset_pushbutton.
function reset_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to reset_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in topic_popupmenu.
function topic_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to topic_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns topic_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from topic_popupmenu


% --- Executes during object creation, after setting all properties.
function topic_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to topic_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Helper functions
function draw_image_on(axes, image)
imagesc(image, 'Parent', axes);
set(axes, 'YDir', 'normal');


function matlab_image = ros_image_msg_to_matlab_image(ros_image_msg)
b = ros_image_msg.data(1:3:end);
g = ros_image_msg.data(2:3:end);
r = ros_image_msg.data(3:3:end);
b = reshape(b, ros_image_msg.width, ros_image_msg.height);
g = reshape(g, ros_image_msg.width, ros_image_msg.height);
r = reshape(r, ros_image_msg.width, ros_image_msg.height);
matlab_image = cat(3, r, g, b);
