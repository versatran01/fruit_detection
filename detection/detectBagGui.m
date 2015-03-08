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

% Last Modified by GUIDE v2.5 04-Mar-2015 10:34:38

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
handles.data.model_dir = 'models';
handles.data.original_image = [];
handles.data.detection_image = [];
handles.data.bboxPlots = [];

set(handles.play_pause_togglebutton, 'Enable', 'off')
set(handles.time_slider, 'Enable', 'off')
set(handles.reset_pushbutton, 'Enable', 'off')
set(handles.step_forward_pushbutton, 'Enable', 'off')
set(handles.step_backward_pushbutton, 'Enable', 'off')

% Load all model names from models dir
handles = updateModelListbox(handles);

% link axes of two axes
linkaxes([handles.original_axes, handles.detection_axes])

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
handles.data.bag_path = bag_path;
handles.data.bag = bag;
handles.data.total_time = total_time;
handles.data.image_topics = image_topics;
handles.data.tracker = FruitTracker();
guidata(hObject, handles);

% --- Executes on button press in play_pause_togglebutton.
function play_pause_togglebutton_Callback(hObject, eventdata, handles)
% hObject    handle to play_pause_togglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Max is depressed, hence play
if get(hObject, 'Value') == get(hObject, 'Max')
    set(hObject, 'String', 'Pause');
    while handles.data.bag.hasNext() && ...
            get(hObject, 'Value') == get(hObject, 'Max')
        [msg, meta] = handles.data.bag.read();
        if strcmp(meta.topic, '/color/image_raw')
            % todo: add time control
            image = rosImageToMatlabImage(msg);
            handles = process_image(image, handles);
            drawnow;
            pause(0.001);
            % Update time_slider value
            time_current = meta.time.time - handles.data.bag.time_begin;
            set(handles.time_slider, 'Value', time_current)
            set(handles.time_current_text, 'String', time_current)
        end
    end
else
    set(hObject, 'String', 'Play');
end
guidata(hObject, handles)

function handles = process_image(image, handles)
scale = 0.4;
image = imresize(image, scale);
CC = detectFruit(handles.data.model, image, scale);
mask = CC.image;

% draw original image
handles.data.original_image = ...
    draw_image_on(handles.original_axes, ...
                  handles.data.original_image, image);

%handles.data.tracker.track(CC, image);

% draw mask
handles.data.detection_image = ...
    draw_image_on(handles.detection_axes, ...
                  handles.data.detection_image, mask);

function bag_path_text_CreateFcn(hObject, eventdata, handles)

function original_axes_CreateFcn(hObject, eventdata, handles)

% --- Executes on slider movement.
function time_slider_Callback(hObject, eventdata, handles)
% hObject    handle to time_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

time_slider_value = get(hObject, 'Value');
set(handles.time_current_text, 'String', time_slider_value)

handles.data.bag.resetView('/color/image_raw', ...
                           handles.data.bag.time_begin ...
                           + time_slider_value);

set(handles.play_pause_togglebutton, 'Value', ...
    get(handles.play_pause_togglebutton, 'Min'))
set(handles.play_pause_togglebutton, 'String', 'Play')

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function time_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
           get(0,'defaultUicontrolBackgroundColor'))
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
if ispc && isequal(get(hObject,'BackgroundColor'), ...
                   get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in model_listbox.
function model_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to model_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = updateModelListbox(handles);

% Update handles structure
guidata(hObject, handles);
% Hints: contents = cellstr(get(hObject,'String')) returns model_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from model_listbox


% --- Executes during object creation, after setting all properties.
function model_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to model_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on
% Windows.--------------
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
                   get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Helper functions
function image_handle = draw_image_on(axes, image_handle, image)
if isempty(image_handle)
    image_handle = imagesc(image, 'Parent', axes);
    set(axes, 'YDir', 'normal');
else
    set(image_handle, 'CData', image);
end
drawnow;

function model_name = getModelFromModelListbox(handle)
model_ind = get(handle, 'Value');
all_models = get(handle, 'String');
model_name = all_models{model_ind};


function handles = updateModelListbox(handles)
model_names = getAllModelNames(handles.data.model_dir);
set(handles.model_listbox, 'String', model_names)
handles.data.model_name = getModelFromModelListbox(handles.model_listbox);
model = load([handles.data.model_dir, '/', handles.data.model_name]);
model = model.model;
handles.data.model = model;
errors_string = ...
    sprintf('rmse: %0.3f, acc: %0.3f\nprec: %0.3f, rec: %0.3f', ...
            model.errors(1), model.errors(2), model.errors(3), ...
            model.errors(4));
set(handles.model_errors_text, 'String', errors_string)
set(handles.model_text, 'String', handles.data.model_name)


function model_names = getAllModelNames(model_directory)
model_names = {};
listings = dir(model_directory);
k = 1;
for i = 1:numel(listings)
    listing = listings(i);
    if ~listing.isdir
        if ~isempty(strfind(listing.name, '.mat'))
            model_names{k} = listing.name;
            k = k + 1;
        end
    end
end


% --- Executes on button press in show_bbox_checkbox.
function show_bbox_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to show_bbox_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_bbox_checkbox
