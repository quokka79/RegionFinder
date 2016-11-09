function varargout = RegionFinder(varargin)
% REGIONFINDER MATLAB code for RegionFinder.fig
%      REGIONFINDER, by itself, creates a new REGIONFINDER or raises the existing
%      singleton*.
%
%      H = REGIONFINDER returns the handle to a new REGIONFINDER or the handle to
%      the existing singleton*.
%
%      REGIONFINDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REGIONFINDER.M with the given input arguments.
%
%      REGIONFINDER('Property','Value',...) creates a new REGIONFINDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RegionFinder_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RegionFinder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RegionFinder

% Last Modified by GUIDE v2.5 18-May-2015 17:57:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RegionFinder_OpeningFcn, ...
                   'gui_OutputFcn',  @RegionFinder_OutputFcn, ...
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

% --- Executes just before RegionFinder is made visible.
function RegionFinder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RegionFinder (see VARARGIN)

% Choose default command line output for RegionFinder
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

movegui('center');
% UIWAIT makes RegionFinder wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RegionFinder_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in btn_openfile.
function btn_openfile_Callback(hObject, eventdata, handles)
    set(handles.btn_openfile,'Enable','off');
    set(handles.btn_openfolder,'Enable','off');
    set(handles.uipanel5,'BackgroundColor',[0.94 0.94 0.94]);
    
    [FileName,PathName] = uigetfile({'*.*';'*.csv';'*.txt'},'Choose your data file');
    if PathName==0
        set(handles.btn_openfile,'Enable','on');
        set(handles.btn_openfolder,'Enable','on');
        return;
    end
    
    AutoSaveSnapShot(handles)
            
    data_delimiter = getmydelimiter(handles);

    cd(PathName);
    TableFileName = fullfile(PathName,FileName);
    
    DisplayFile(TableFileName,data_delimiter,handles);

        
function DisplayFile(TableFileName,data_delimiter,handles)
    set(handles.select_delimiter,'BackgroundColor','w');
    set(handles.txt_loading,'String','Loading data...','Visible','on','BackgroundColor','y','ForegroundColor',[0 0.75 0.75],'FontSize',40);
    set(handles.edit_regioncounter,'Value',0);
    pause(0.2);
       
    FileID = fopen(TableFileName);
    try
        data=dlmread(TableFileName,data_delimiter, 1, 0); %read data from row 1 col 0 (skip row 0, headers)
    catch
        delim_str = getCurrentPopupString(handles.select_delimiter);
        msg = sprintf('%s', ...
                   'Problem reading file: You said it is ', ...
                   delim_str, ...
                   ' delimited, but this doesn''t seem to be the case. Check the setting for the ''Delimiter'' dropdown box and that it is correct for file ',TableFileName,'.');
        set(handles.txt_loading,'String',msg,'BackgroundColor','r','ForegroundColor','w','FontSize',14);
        set(handles.select_delimiter,'Enable','on');
        set(handles.edit_xCoordsCol,'Enable','on');
        set(handles.edit_yCoordsCol,'Enable','on');
        set(handles.edit_ChIDCol,'Enable','on');
        set(handles.uipanel5,'BackgroundColor',[1 0.6 0.78]);
        error(msg);
    end
    fclose(FileID);
    
    xCoordsColumn = str2double(get(handles.edit_xCoordsCol,'String'));
    yCoordsColumn = str2double(get(handles.edit_yCoordsCol,'String'));
    FrameIDColumn = str2double(get(handles.edit_FrameIDCol,'String'));
    DataScaling = str2double(get(handles.edit_datascale,'String'));
    ChanColumn = str2double(get(handles.edit_ChIDCol,'String'));
    
    if ChanColumn == 0
        data(:,end+1) = 1;
        ChanCount = 1;
        ChanColumn = size(data,2);
    else
        ChanCount = max(data(:,ChanColumn));
    end
    
    %delete first 2kframes from any channel
    if get(handles.chk_skipfirst2k,'Value')
        FramesToSkip = str2double(get(handles.skipfirstXframes,'String'));
        EarlyFrameIdx = find(data(:,FrameIDColumn)<= FramesToSkip);
        data(EarlyFrameIdx,:) = [];
    end
    
    if min(data(:,ChanColumn)) ~= 1
                msg = sprintf('%s', ...
                   'Your file references Channel ', ...
                   ChanCount, ...
                   ' but doesn''t come with any data for Channel 1. Please combine your data tables so all channels are in one file.');
        set(handles.txt_loading,'String',msg,'BackgroundColor','r','ForegroundColor','w','FontSize',14);
        error(msg);
    end
    
    if ChanCount == 1
        dataCh1 = data(data(:,ChanColumn)==1,xCoordsColumn:yCoordsColumn);
        dataCh1 = DataScaling .* dataCh1;
        DataSize1 = size(dataCh1,1);
        if DataSize1 > 30000
            dataCh1 = dataCh1(1:30000,:);
            TotalPoints = ['Showing 30,000 of ',num2str(DataSize1),' points.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints);
        else
            TotalPoints = [num2str(DataSize1),' points in image.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints);
        end
        
        axes(handles.preview_plot);
        scatter(dataCh1(:,1),dataCh1(:,2),1,[1,0.72,0],'.');       
        set(gca,'Color','k');
        
    elseif ChanCount == 2
        dataCh1 = data(data(:,ChanColumn)==1,xCoordsColumn:yCoordsColumn);
        dataCh1 = DataScaling .* dataCh1;
        DataSize1 = size(dataCh1,1);   
        if DataSize1 > 15000
            dataCh1 = dataCh1(1:15000,:);
            TotalPoints1 = ['Ch1: Showing 15,000 of ',num2str(DataSize1),' points.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints1);
        else
            TotalPoints1 = [num2str(DataSize1),' points in Ch1.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints1);
        end
        axes(handles.preview_plot);
        scatter(dataCh1(:,1),dataCh1(:,2),1,[1,0.72,0],'.');
        set(gca,'Color','k');
                
        dataCh2 = data(data(:,ChanColumn)==2,xCoordsColumn:yCoordsColumn);
        dataCh2 = DataScaling .* dataCh2;
        DataSize2 = size(dataCh2,1);   
        if DataSize2 > 15000
            dataCh2 = dataCh2(1:15000,:);
            TotalPoints2 = [get(handles.txt_warnlimitedpoints,'String'),' Ch2: Showing 15,000 of ',num2str(DataSize2),' points.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints2);
        else
            TotalPoints = [num2str(DataSize2),' points in Ch2.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints);
        end
        hold on
        axes(handles.preview_plot);
        scatter(dataCh2(:,1),dataCh2(:,2),1,[0,0.78,1],'.');
        set(gca,'Color','k');
        hold off
        
    elseif ChanCount == 3
        dataCh1 = data(data(:,ChanColumn)==1,xCoordsColumn:yCoordsColumn);
        dataCh1 = DataScaling .* dataCh1;
        DataSize1 = size(dataCh1,1);   
        if DataSize1 > 10000
            dataCh1 = dataCh1(1:10000,:);
            TotalPoints1 = ['Ch1: Showing 10,000 of ',num2str(DataSize1),' points.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints1);
        else
            TotalPoints1 = [num2str(DataSize1),' points in Ch1.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints1);
        end
        axes(handles.preview_plot);
        scatter(dataCh1(:,1),dataCh1(:,2),1,[1,0.72,0],'.');
        set(gca,'Color','k');
                
        dataCh2 = data(data(:,ChanColumn)==2,xCoordsColumn:yCoordsColumn);
        dataCh2 = DataScaling .* dataCh2;
        DataSize2 = size(dataCh2,1);   
        if DataSize2 > 10000
            dataCh2 = dataCh2(1:10000,:);
            TotalPoints2 = [get(handles.txt_warnlimitedpoints,'String'),' Ch2: Showing 10,000 of ',num2str(DataSize2),' points.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints2);
        else
            TotalPoints = [num2str(DataSize2),' points in Ch2.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints);
        end
        hold on
        axes(handles.preview_plot);
        scatter(dataCh2(:,1),dataCh2(:,2),1,[0,0.78,1],'.');
        set(gca,'Color','k');
        hold off
        
        dataCh3 = data(data(:,ChanColumn)==3,xCoordsColumn:yCoordsColumn);
        dataCh3 = DataScaling .* dataCh3;
        DataSize3 = size(dataCh3,1);   
        if DataSize3 > 10000
            dataCh3 = dataCh3(1:10000,:);
            TotalPoints2 = [get(handles.txt_warnlimitedpoints,'String'),' Ch3: Showing 10,000 of ',num2str(DataSize3),' points.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints2);
        else
            TotalPoints = [num2str(DataSize3),' points in Ch2.'];
            set(handles.txt_warnlimitedpoints,'String',TotalPoints);
        end
        hold on
        axes(handles.preview_plot);
        scatter(dataCh3(:,1),dataCh3(:,2),1,[1,0,0.72],'.');
        set(gca,'Color','k');
        hold off
    else
        msg = sprintf('%s', ...
                    'You seem to have ', ...
                    num2str(ChanCount), ...
                    ' channels in your data but I can only handle 3 at most. Check input settings!');
        set(handles.txt_loading,'String',msg,'BackgroundColor','r','ForegroundColor','w','FontSize',14);
        set(handles.select_delimiter,'Enable','on');
        set(handles.edit_xCoordsCol,'Enable','on');
        set(handles.edit_yCoordsCol,'Enable','on');
        set(handles.edit_ChIDCol,'Enable','on');
        set(handles.uipanel5,'BackgroundColor',[1 0.6 0.78]);
        error(msg);
    end
    
    % fix the axis sizing
    axislims = 1000*str2double(get(handles.select_imagesize,'String'));
    axis([0 axislims 0  axislims]);
    set(gca,'fontsize',8)
    set(gca,'XTick',0:2000:axislims);
    set(gca,'YTick',0:2000:axislims);
    
    clear data
    set(handles.txt_loading,'Visible','off');
    set(handles.text1, 'String',TableFileName);
    set(handles.btn_addregion,'Enable','on');
    set(handles.btn_clearall,'Enable','on');

    [TableFileNamePath TableFileName_Short TableFileNameExt] = fileparts(TableFileName);
    set(handles.edit_notes, 'String',TableFileName_Short);
    
    ImgNumber = str2double(get(handles.txt_ImageNumber,'String'));
    ImgNumber = ImgNumber + 1;
    set(handles.txt_ImageNumber,'String',num2str(ImgNumber));
    set(handles.select_delimiter,'Enable','off');
    set(handles.edit_xCoordsCol,'Enable','off');
    set(handles.edit_yCoordsCol,'Enable','off');
    set(handles.edit_regionsize,'Enable','off');
    set(handles.edit_ChIDCol,'Enable','off');
    set(handles.edit_FrameIDCol,'Enable','off');
    set(handles.LoadThunderstorm,'Enable','off');
    set(handles.LoadXY,'Enable','off');
    set(handles.LoadLASAFGSD,'Enable','off');
    set(handles.select_imagesize,'Enable','off');
    set(handles.edit_datascale,'Enable','off');
    
    clear data dataCh1 dataCh2 dataCh3

function str = getCurrentPopupString(hh)
    %# getCurrentPopupString returns the currently selected string in the popupmenu with handle hh

    %# could test input here
    if ~ishandle(hh) || strcmp(get(hh,'Type'),'popupmenu') || strcmp(get(hh,'Type'),'listbox')
    error('getCurrentPopupString needs a handle to a popupmenu or listbox as input')
    end

    %# get the string - do it the readable way
    list = get(hh,'String');
    val = get(hh,'Value');
    if iscell(list)
       str = list{val};
    else
       str = list(val,:);
    end

function data_delimiter = getmydelimiter(handles)
    delim_str = getCurrentPopupString(handles.select_delimiter);
    if strcmp(delim_str,'tab')
        data_delimiter = '\t';
    elseif strcmp(delim_str,'comma')
        data_delimiter = ',';
    elseif strcmp(delim_str,'space')
        data_delimiter = ' ';
    elseif strcmp(delim_str,'semicolon')
        data_delimiter = ';';
    elseif strcmp(delim_str,'colon')
        data_delimiter = ':';
    elseif strcmp(delim_str,'pipe')
        data_delimiter = '|';
    elseif strcmp(delim_str,'period')
        data_delimiter = '.';
    end    
    
function GetCoords(handles)
%     [xClick, yClick] = ginput(1);
    set(handles.btn_addregion,'Enable','off');
    roiWidth = str2double(get(handles.edit_regionsize,'String'));
    xLimits = get(gca,'XLim');
    yLimits = get(gca,'YLim');
    NewROI = imrect(handles.preview_plot,[(xLimits(1,2)/2)-roiWidth/2,(yLimits(1,2)/2)-roiWidth/2,roiWidth,roiWidth]);
    setResizable(NewROI,0);
    setColor(NewROI,'y');
    position = wait(NewROI);
    RegionsInThisImage = get(handles.edit_regioncounter,'Value') + 1;
    
    ImgNumber = str2double(get(handles.txt_ImageNumber,'String'));
    xCoord = floor(position(1)) + roiWidth/2;
    yCoord = floor(position(2)) + roiWidth/2;
    total_region_count = str2double(get(handles.txt_regioncount,'String'));
    total_region_count = total_region_count + 1;
    
    %Copy rectangle ID table
    % Column order: PlotRectangleID, PlotLabelID, ImageID,
    % RegionID,X,Y,Notes
    RectangleList = get(handles.tbl_rectangles,'UserData');
    RectangleNotes = get(handles.tbl_rectangle_notes,'UserData');
    
    % Col1 - PlotRectangleID
    RectangleList(total_region_count,1) = rectangle('Position',[xCoord-(roiWidth/2), yCoord-(roiWidth/2), roiWidth, roiWidth],'LineWidth',2,'LineStyle','--','EdgeColor',[0.3,1,0.3]);

    % Col2 - PlotLabelID
    str1 = [num2str(ImgNumber),'.',num2str(RegionsInThisImage)];
    RectangleList(total_region_count,2) = text(xCoord, yCoord,str1,'Color',[0.3,1,0.3],'FontSize',25,'FontWeight','bold','HorizontalAlignment','center');
    
    % Col3 - ImagelID
    RectangleList(total_region_count,3) = ImgNumber;
    
    % Col4 - RegionID
    RectangleList(total_region_count,4) = RegionsInThisImage;
    
    % Col5 - X coord
    RectangleList(total_region_count,5) = xCoord;
    
    % Col6 - Y coord
    RectangleList(total_region_count,6) = yCoord;
    
    % Col7 - Notes and names
    RectangleNotes{total_region_count,1} = get(handles.edit_notes,'String');
    
    % push the changes back to the main table
    set(handles.tbl_rectangles,'UserData',RectangleList);
    set(handles.tbl_rectangle_notes,'UserData',RectangleNotes);
        
    % Refresh the visible list of regions
    ListOfRegions = get(handles.list_regions,'String');
    if isempty(ListOfRegions)
        ListOfRegions = {['[',num2str(ImgNumber),'.',num2str(RegionsInThisImage),'] ',num2str(xCoord),' , ',num2str(yCoord),' - ',get(handles.edit_notes,'String')]};
        set(handles.btn_doexport,'Enable','on');
        set(handles.btn_snapshot,'Enable','on');
    else
        ListOfRegions{end+1,1}=['[',num2str(ImgNumber),'.',num2str(RegionsInThisImage),'] ',num2str(xCoord),' , ',num2str(yCoord),' - ',get(handles.edit_notes,'String')];
    end
       
    set(handles.txt_regioncount,'String',num2str(total_region_count));
    if total_region_count > 0
        set(handles.btn_deleteselected,'Enable','on');
    end
    set(handles.list_regions,'String',ListOfRegions);
    
    % Select the most-recently added region in the list of regions 
    set(handles.list_regions,'Value',total_region_count);
    set(handles.edit_regioncounter,'Value',RegionsInThisImage);
    
    delete(NewROI);
    set(handles.btn_addregion,'Enable','on');
    
    


% %     xClick = floor(xClick);
% %     yClick = floor(yClick);
%     RoIXY(end,:) = position;
% %     handles.RoiXY(end,:) = position;
%     set(handles.edit_xCoord,'String',num2str(xClick));
%     set(handles.edit_yCoord,'String',num2str(yClick));
%     region_size = str2num(get(handles.edit_regionsize,'String'));
%     region_temp = rectangle('Position',[(xClick - region_size/2),(yClick - region_size/2),region_size,region_size],'LineWidth',2,'LineStyle','--','EdgeColor','red');
%     
%     ListOfRegions = get(handles.list_regions,'String');
% if strcmp(ListOfRegions{1,1},'Listbox')
%     ListOfRegions = {[get(handles.edit_xCoord,'String'),',',get(handles.edit_yCoord,'String')]};
% else
%     ListOfRegions{end+1,1}=[get(handles.edit_xCoord,'String'),',',get(handles.edit_yCoord,'String')];
% end
% set(handles.list_regions,'String',ListOfRegions);
% set(handles.btn_doexport,'Enable','on');


% --- Executes on selection change in list_regions.
function list_regions_Callback(hObject, eventdata, handles)
% hObject    handle to list_regions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_regions contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_regions


% --- Executes during object creation, after setting all properties.
function list_regions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_regions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_xCoord_Callback(hObject, eventdata, handles)
% hObject    handle to edit_xCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_xCoord as text
%        str2double(get(hObject,'String')) returns contents of edit_xCoord as a double


% --- Executes during object creation, after setting all properties.
function edit_xCoord_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_xCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_yCoord_Callback(hObject, eventdata, handles)
% hObject    handle to edit_yCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_yCoord as text
%        str2double(get(hObject,'String')) returns contents of edit_yCoord as a double


% --- Executes during object creation, after setting all properties.
function edit_yCoord_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_yCoord (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_addregion.
function btn_addregion_Callback(hObject, eventdata, handles)
% hObject    handle to btn_addregion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.list_regions,'Enable','on');
set(handles.edit_regionsize,'Enable','off');
GetCoords(handles)


% --- Executes on button press in btn_deleteselected.
function btn_deleteselected_Callback(hObject, eventdata, handles)
set(handles.btn_deleteselected,'Enable','off');
pause(0.2);

selected_region_ID = get(handles.list_regions,'Value'); %getCurrentPopupString(handles.list_regions);

% Column order: PlotRectangleID, PlotLabelID, ImageID, RegionID,X,Y
RectangleList = get(handles.tbl_rectangles,'UserData');
RectangleNotes = get(handles.tbl_rectangle_notes,'UserData');

DoomedRectHandle = RectangleList(selected_region_ID,1);
DoomedLabelHandle = RectangleList(selected_region_ID,2);
AffectedImage = RectangleList(selected_region_ID,3);

if ~isempty(DoomedRectHandle) && ~isempty(DoomedLabelHandle) && ishandle(DoomedRectHandle) && ishandle(DoomedLabelHandle)
     %handles exist
     delete(DoomedRectHandle);
     delete(DoomedLabelHandle);
end

%delete it from the internal table of rectangles
RectangleList(selected_region_ID,:) = [];
RectangleNotes(selected_region_ID,:) = [];

% Reorder the remaining regions from this image
ThisRegionList = RectangleList(RectangleList(:,3)==AffectedImage,:);
ThisRegionList(:,4) = 1:size(ThisRegionList,1);
RectangleList(RectangleList(:,3)==AffectedImage,:) = ThisRegionList;

% send the changes to the main table
set(handles.tbl_rectangles,'UserData',RectangleList);
set(handles.tbl_rectangle_notes,'UserData',RectangleNotes);

if AffectedImage == str2double(get(handles.txt_ImageNumber,'String'))
    % update the plot label to reflect the new order
    for r = 1:size(ThisRegionList,1)
        TextHandle = ThisRegionList(r,2);
        NewText = [num2str(ThisRegionList(r,3)),'.',num2str(ThisRegionList(r,4))];
        set(TextHandle,'String',NewText);
    end
    
    set(handles.edit_regioncounter,'Value',max(ThisRegionList(:,4)));
end

% update the GUI list
for r = 1:size(RectangleList,1)
    NewListOfRegions(r,1) = {['[',num2str(RectangleList(r,3)),'.',num2str(RectangleList(r,4)),'] ',num2str(RectangleList(r,5)),' , ',num2str(RectangleList(r,6)),' - ',RectangleNotes{r,1}]};
end
set(handles.list_regions,'String',NewListOfRegions);

% update the counters
NewRegionCount = size(RectangleList,1);
set(handles.txt_regioncount,'String',num2str(NewRegionCount));



% update the text to reflect the new order

% Move selection Value to the one-above line
if selected_region_ID > 1
    lineabove_region_ID = selected_region_ID - 1;
else
    lineabove_region_ID = 1;
end
set(handles.list_regions,'Value',lineabove_region_ID);

if NewRegionCount == 0
    set(handles.btn_doexport,'Enable','off');
    set(handles.btn_snapshot,'Enable','off');
    set(handles.btn_deleteselected,'Enable','off');
    set(handles.edit_regionsize,'Enable','on');
else
    set(handles.btn_deleteselected,'Enable','on');
end
pause(0.2);


function AutoSaveSnapShot(handles)
    %autosave snapshot
    if get(handles.autosave_snapshot,'Value') == 1
        if ~strcmp(get(handles.list_regions,'String'),'')
            regionssofar = get(handles.list_regions,'String');
            lastregion = strsplit(regionssofar{end,1},{'[',']','.'},'CollapseDelimiters',true);
            if strcmp(lastregion(1,2),get(handles.txt_ImageNumber,'String'))
                AnyRegionsForCurrentImage = 1;
            else
                AnyRegionsForCurrentImage = 0;
            end
        else
            AnyRegionsForCurrentImage = 0;
        end
    
        if ~strcmp(get(handles.txt_ImageNumber,'String'),'0') && AnyRegionsForCurrentImage
            % do autosnapshot
            SuggestedFileName = ['Regions Map - Table ', get(handles.txt_ImageNumber,'String'),' - auto snapshot.png'];
            PathName = pwd;
            SnapshotName = fullfile(PathName,SuggestedFileName);
            set(handles.txt_loading,'String','Autosaving snapshot...','Visible','on');
            pause(0.2);
            SaveFigure = figure('Color',[1 1 1], 'visible', 'off', 'Renderer', 'OpenGL', 'Units', 'normalized');
            copyobj(handles.preview_plot, SaveFigure);
            set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10]);
            set(gca, 'Units','normalized');
            set(gca,'Position', [0 0 1 1]);
            set(gcf, 'InvertHardCopy', 'off'); % don't make a fucking white background, bitch.
            print(SaveFigure,'-dpng','-r300',SnapshotName);
            close(gcf);
            set(handles.txt_loading,'Visible','off');
        end
    end

    
% --- Manual Snapshot - Executes on button press in btn_snapshot.
function btn_snapshot_Callback(hObject, eventdata, handles)
    % do snapshot
    SuggestedFileName = ['Regions Map - Table ', get(handles.txt_ImageNumber,'String'),' - manual snapshot'];
    [FileName, PathName] = uiputfile('*.png', 'Save As',SuggestedFileName);
    if PathName==0, return; end
    SnapshotName = fullfile(PathName,FileName);
    set(handles.txt_loading,'String','Saving snapshot...','Visible','on');
    pause(0.2);
    SaveFigure = figure('Color',[1 1 1], 'visible', 'off', 'Renderer', 'OpenGL', 'Units', 'normalized');
    copyobj(handles.preview_plot, SaveFigure);
    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10]);
    set(gca, 'Units', 'normalized');
    set(gca,'Position', [0 0 1 1]);
    set(gcf, 'InvertHardCopy', 'off'); % don't make a fucking white background, bitch.
    print(SaveFigure,'-dpng','-r300',SnapshotName);
    close(gcf);
    set(handles.txt_loading,'Visible','off');
    

% --- Executes on button press in btn_doexport.
function btn_doexport_Callback(hObject, eventdata, handles)
    AutoSaveSnapShot(handles)
    savecoordstofile(handles)
%     saveProcSettings(handles)

function savecoordstofile(handles)
    ListOfRegions = get(handles.list_regions,'String');

    ListOfRegions2 = get(handles.tbl_rectangles,'UserData');
    ListOfDescs2 = get(handles.tbl_rectangle_notes,'UserData');
    DataScaling = str2double(get(handles.edit_datascale,'String'));

    PrepForExport = cell(size(ListOfRegions2,1),4);
    PrepForExport(:,1) = ListOfDescs2(:,1);
    PrepForExport(:,2) = num2cell(ListOfRegions2(:,3));
    PrepForExport(:,3) = num2cell(ListOfRegions2(:,5) ./ DataScaling);
    PrepForExport(:,4) = num2cell(ListOfRegions2(:,6) ./ DataScaling);

    InputDataFolder = pwd;

    [FileName, PathName] = uiputfile('*.txt','Save Coords File','coords.txt');
    if PathName==0, return; end
    fid = fopen(fullfile(PathName,FileName), 'w');
    for row = 1:size(PrepForExport,1)
        fprintf(fid, '%s\t%d\t%G\t%G\r\n', PrepForExport{row,:});
    end
    fclose(fid);
    % Copy input files to folder
    choice = questdlg('Would you like to copy and rename the input tables?', 'Copy & rename tables?','Yes','No','Yes');
    switch choice
        case 'Yes'
            ListOfFiles = get(handles.tbl_fileList,'UserData');

            % create a record of the renaming
            fid = fopen(fullfile(PathName,'Data Renaming Map.txt'), 'w');
            RenameList = ListOfFiles(:,1);
            fprintf(fid, '%s\t%s\r\n','Filename','Original Filename');

            for f = 1:size(ListOfFiles,1)
                [~, ~, ext] = fileparts(ListOfFiles{f,1});
                NewFileName = [num2str(f),ext];
                copyfile(fullfile(InputDataFolder,ListOfFiles{f,1}),fullfile(PathName,NewFileName));
                fprintf(fid, '%s\t%s\r\n', [num2str(f),ext], RenameList{f,:}); % save this rename to the record
            end

            fclose(fid);
    end

% function saveProcSettings(handles)
%     ListOfRegions = get(handles.list_regions,'String');
% 
%     ListOfRegions2 = get(handles.tbl_rectangles,'UserData');
%     ListOfDescs2 = get(handles.tbl_rectangle_notes,'UserData');
%     DataScaling = str2double(get(handles.edit_datascale,'String'));
% 
%     PrepForExport = cell(size(ListOfRegions2,1),4);
%     PrepForExport(:,1) = ListOfDescs2(:,1);
%     PrepForExport(:,2) = num2cell(ListOfRegions2(:,3));
%     PrepForExport(:,3) = num2cell(ListOfRegions2(:,5) ./ DataScaling);
%     PrepForExport(:,4) = num2cell(ListOfRegions2(:,6) ./ DataScaling);
% 
%     InputDataFolder = pwd;
% 
%     [FileName, PathName] = uiputfile('*.txt','Save ProcSettings File','ProcSettings.txt');
%     if PathName==0, return; end
%     fid = fopen(fullfile(PathName,FileName), 'w');
%     for row = 1:size(PrepForExport,1)
%         fprintf(fid, '%s\t%d\t%G\t%G\r\n', PrepForExport{row,:});
%     end
%     fclose(fid);

% 
% 
% for i=1:length(ListOfRegions)
%     RemainingStr = ListOfRegions{i,1};
%     for k = 1:5
%         [token, RemainingStr] = strtok(RemainingStr);
%         CoordsSplit{1,k} = token;
%     end
%     RemainingStr(1) = ''; %delete first space character
%     if size(RemainingStr,2) >  2
%         SaveRegions{i,1} = RemainingStr;
%     else
%         SaveRegions{i,1} = '-';
%     end
%     clear RemainingStr
%     FixTableID = strsplit(CoordsSplit{1,1},{'[',']','.'},'CollapseDelimiters',true);
%     SaveRegions{i,2} = FixTableID{1,2};
%     SaveRegions{i,3} = num2str(str2double(CoordsSplit{1,2})/ DataScaling); % save ROI centre x-coord
%     SaveRegions{i,4} = num2str(str2double(CoordsSplit{1,4})/ DataScaling); % save ROI centre y-coord
% end
% 
% [FileName, PathName] = uiputfile('*.txt','Save Coords File','coords.txt');
% if PathName==0, return; end
% fid = fopen(FileName, 'w');
% for row = 1:size(SaveRegions,1)
%     fprintf(fid, '%s\t%s\t%s\t%s\r\n', SaveRegions{row,:});
% end
% fclose(fid);



% --- Executes on button press in btn_clearall.
function btn_clearall_Callback(hObject, eventdata, handles)
set(handles.list_regions,'String',[]);
set(handles.tbl_rectangles,'UserData',[]);
set(handles.tbl_rectangle_notes,'UserData',[]);
set(handles.tbl_fileList,'UserData',[]);
set(handles.edit_regioncounter,'Value',0);
set(handles.edit_notes,'String','Cell 1 Treatment A');
set(handles.text1,'String','( no file selected yet )');
cla(handles.preview_plot,'reset');
set(handles.txt_ImageNumber,'String','0');
set(handles.txt_warnlimitedpoints,'String','');
set(handles.btn_doexport,'Enable','off');
set(handles.btn_snapshot,'Enable','off');
set(handles.btn_addregion,'Enable','off');
set(handles.btn_openfile,'Enable','on');
set(handles.btn_openfolder,'Enable','on');
set(handles.btn_deleteselected,'Enable','off');
set(handles.LoadThunderstorm,'Enable','on');
set(handles.LoadXY,'Enable','on');
set(handles.LoadLASAFGSD,'Enable','on');
set(handles.edit_regionsize,'Enable','on');
set(handles.txt_warnlimitedpoints,'String','( No points to display )');
set(handles.txt_regioncount,'String','0');
set(handles.select_delimiter,'BackgroundColor','w','Enable','on');
set(handles.edit_xCoordsCol,'BackgroundColor','w','Enable','on');
set(handles.edit_yCoordsCol,'BackgroundColor','w','Enable','on');
set(handles.edit_ChIDCol,'BackgroundColor','w','Enable','on');
set(handles.edit_FrameIDCol,'BackgroundColor','w','Enable','on');
set(handles.uipanel5,'BackgroundColor',[0.94 0.94 0.94]);
set(handles.select_imagesize,'BackgroundColor','w','Enable','on');
set(handles.edit_datascale,'BackgroundColor','w','Enable','on');
set(handles.autosave_snapshot,'value',1);
set(handles.preview_plot,'Color','k');

% hObject    handle to btn_clearall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_savepng.
function checkbox_savepng_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_savepng (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_savepng


% --- Executes on button press in checkbox_savetxt.
function checkbox_savetxt_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_savetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_savetxt


function edit_regionsize_Callback(hObject, eventdata, handles)
% hObject    handle to edit_regionsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_regionsize as text
%        str2double(get(hObject,'String')) returns contents of edit_regionsize as a double


% --- Executes during object creation, after setting all properties.
function edit_regionsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_regionsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_notes_Callback(hObject, eventdata, handles)
% hObject    handle to edit_notes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_notes as text
%        str2double(get(hObject,'String')) returns contents of edit_notes as a double


% --- Executes during object creation, after setting all properties.
function edit_notes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_notes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_exit.
function btn_exit_Callback(hObject, eventdata, handles)
    close(gcf);
% hObject    handle to btn_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on btn_openfile and none of its controls.
function btn_openfile_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to btn_openfile (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



function edit_xCoordsCol_Callback(hObject, eventdata, handles)
% hObject    handle to edit_xCoordsCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_xCoordsCol as text
%        str2double(get(hObject,'String')) returns contents of edit_xCoordsCol as a double


% --- Executes during object creation, after setting all properties.
function edit_xCoordsCol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_xCoordsCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_yCoordsCol_Callback(hObject, eventdata, handles)
% hObject    handle to edit_yCoordsCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_yCoordsCol as text
%        str2double(get(hObject,'String')) returns contents of edit_yCoordsCol as a double


% --- Executes during object creation, after setting all properties.
function edit_yCoordsCol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_yCoordsCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in select_delimiter.
function select_delimiter_Callback(hObject, eventdata, handles)
% hObject    handle to select_delimiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns select_delimiter contents as cell array
%        contents{get(hObject,'Value')} returns selected item from select_delimiter


% --- Executes during object creation, after setting all properties.
function select_delimiter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to select_delimiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ChIDCol_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ChIDCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ChIDCol as text
%        str2double(get(hObject,'String')) returns contents of edit_ChIDCol as a double


% --- Executes during object creation, after setting all properties.
function edit_ChIDCol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ChIDCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in autosave_snapshot.
function autosave_snapshot_Callback(hObject, eventdata, handles)
% hObject    handle to autosave_snapshot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autosave_snapshot



function edit_FrameIDCol_Callback(hObject, eventdata, handles)
% hObject    handle to edit_FrameIDCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_FrameIDCol as text
%        str2double(get(hObject,'String')) returns contents of edit_FrameIDCol as a double


% --- Executes during object creation, after setting all properties.
function edit_FrameIDCol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_FrameIDCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chk_skipfirst2k.
function chk_skipfirst2k_Callback(hObject, eventdata, handles)
% hObject    handle to chk_skipfirst2k (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chk_skipfirst2k



function skipfirstXframes_Callback(hObject, eventdata, handles)
% hObject    handle to skipfirstXframes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of skipfirstXframes as text
%        str2double(get(hObject,'String')) returns contents of skipfirstXframes as a double


% --- Executes during object creation, after setting all properties.
function skipfirstXframes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to skipfirstXframes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit_FrameIDCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_FrameIDCol as text
%        str2double(get(hObject,'String')) returns contents of edit_FrameIDCol as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_FrameIDCol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LoadXY.
function LoadXY_Callback(hObject, eventdata, handles)
% hObject    handle to LoadXY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.edit_xCoordsCol,'String','1');
set(handles.edit_yCoordsCol,'String','2');
set(handles.edit_ChIDCol,'String','3');
set(handles.edit_FrameIDCol,'String','0');
set(handles.edit_regionsize,'String','3000');
set(handles.select_delimiter,'Value',1);
set(handles.edit_datascale,'String','1');
set(handles.select_imagesize,'String','25.6');


% --- Executes on button press in LoadThunderstorm.
function LoadThunderstorm_Callback(hObject, eventdata, handles)
% hObject    handle to LoadThunderstorm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.edit_xCoordsCol,'String','3');
set(handles.edit_yCoordsCol,'String','4');
set(handles.edit_ChIDCol,'String','0');
set(handles.edit_FrameIDCol,'String','1');
set(handles.edit_regionsize,'String','3000');
set(handles.select_delimiter,'Value',2);
set(handles.edit_datascale,'String','1');
set(handles.select_imagesize,'String','40.96');

% --- Executes on button press in LoadLASAFGSD.
function LoadLASAFGSD_Callback(hObject, eventdata, handles)
% hObject    handle to LoadLASAFGSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.edit_xCoordsCol,'String','3');
set(handles.edit_yCoordsCol,'String','4');
set(handles.edit_ChIDCol,'String','0');
set(handles.edit_FrameIDCol,'String','1');
set(handles.edit_regionsize,'String','3000');
set(handles.select_delimiter,'Value',2);
set(handles.edit_datascale,'String','100');
set(handles.select_imagesize,'String','18.0');


% --- Executes on button press in btn_openfolder.
function btn_openfolder_Callback(hObject, eventdata, handles)
% hObject    handle to btn_openfolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.btn_openfile,'Enable','off');
    set(handles.btn_openfolder,'Enable','off');
    set(handles.uipanel5,'BackgroundColor',[0.94 0.94 0.94]);
    
    % Open the file containing the list of regions and their coordinates
    dirName = uigetdir;
    

    if dirName ~=0
        handles.InputDataFolder = dirName; % save this for later
        
        cd(dirName);
        GoodFileExt = {'.txt','.csv'};
        % get list of csv files
        dirData = dir(dirName);      % Get the data for the current directory
        dirIndex = [dirData.isdir];  % Find the index for directories
        fileList = {dirData(~dirIndex).name}';  % Get a list of the files
        fileList = sort_nat(fileList,'Ascend');

        % Weed out the unwanted files
        badFiles = [];
        for f = 1:length(fileList)
            [~, fname, ext] = fileparts(fileList{f,1});
            fname = lower(fname);
            if ~strcmp(ext,GoodFileExt{1,1}) && ~strcmp(ext,GoodFileExt{1,2})
                badFiles(end+1,1) = f;
            end
            if ~isempty(strfind(fname,'coords')) || ~isempty(strfind(fname,'procsettings')) || ~isempty(strfind(fname,'protocol'))
                badFiles(end+1,1) = f;
            end
        end
        fileList(badFiles) = [];
        
        % re-sort the files for natural sort order
        for g = 1:length(fileList)
            fnametmp = strsplit(fileList{g,1},'.');
            fileList{g,2} = str2double(fnametmp{1,1});
        end
        fileList = sortrows(fileList,2);
        
        set(handles.tbl_fileList,'UserData',fileList);
        set(handles.btn_nexttable,'Enable','on');
        data_delimiter = getmydelimiter(handles);
        TableFileName = fullfile(dirName,fileList{1,1});
        DisplayFile(TableFileName,data_delimiter,handles);
    else
        set(handles.btn_openfile,'Enable','on');
        set(handles.btn_openfolder,'Enable','on');
        set(handles.btn_nexttable,'Enable','off');
        return;
    end

% --- Executes on button press in btn_nexttable.
function btn_nexttable_Callback(hObject, eventdata, handles)
% hObject    handle to btn_nexttable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NextTable = 1 + str2double(get(handles.txt_ImageNumber,'String'));
PathName = pwd;
fileList = get(handles.tbl_fileList,'UserData');
data_delimiter = getmydelimiter(handles);
if NextTable < size(fileList,1)
    TableFileName = fullfile(PathName,fileList{NextTable,1});
    AutoSaveSnapShot(handles)
    DisplayFile(TableFileName,data_delimiter,handles);
elseif NextTable == size(fileList,1) % the next table is the last table
    TableFileName = fullfile(PathName,fileList{NextTable,1});
    AutoSaveSnapShot(handles)
    DisplayFile(TableFileName,data_delimiter,handles);
    set(handles.btn_nexttable,'String','Save & Finish');
else % there are no more tables to load so the only option now is to save
    AutoSaveSnapShot(handles)
    savecoordstofile(handles)
    saveProcSettings(handles)
    set(handles.btn_nexttable,'String','Next table...');
    set(handles.btn_nexttable,'Enable','off');
    btn_clearall_Callback(hObject, eventdata, handles);
end


% --- Executes on selection change in select_imagesize.
function select_imagesize_Callback(hObject, eventdata, handles)
% hObject    handle to select_imagesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns select_imagesize contents as cell array
%        contents{get(hObject,'Value')} returns selected item from select_imagesize


% --- Executes during object creation, after setting all properties.
function select_imagesize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to select_imagesize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_datascale_Callback(hObject, eventdata, handles)
% hObject    handle to edit_datascale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_datascale as text
%        str2double(get(hObject,'String')) returns contents of edit_datascale as a double


% --- Executes during object creation, after setting all properties.
function edit_datascale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_datascale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function LoadLASAFGSD_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LoadLASAFGSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function edit_regioncounter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_regioncounter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
