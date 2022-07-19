function detect_video_func_py(filename, name_f_path, MinimumBlobArea, MaximumBlobArea,imopen_streal, imclose_streal)
 
if nargin ~= 6
    MinimumBlobArea = 80;
    MaximumBlobArea = 1000;
    imopen_streal  = 2;
    imclose_streal = 30;
end

v = VideoReader(filename);
numframes = int16(fix(v.FrameRate*v.Duration)); %���������� ���� ������

% ������ ����
video = readFrame(v);
frame  = rgb2gray (video(:,:,:)); % ��������� ���� � ������� ������
level = graythresh(frame); % ������� ���������� ����� ����������� � ������� ������ ���
frame= imbinarize(frame,level); % ����������� ����������� � �������� � ������� ������
past_frame = frame; % �������� ������� ���� ��� ���������� 

write_name = strcat(name_f_path, '_detect');
v1 = VideoWriter(write_name,'MPEG-4'); % �������� ���������� ��� ������ �����
open(v1); %�������� ����� �� ������

% ��������� �������, �� ����� ����� ��� � ����� ������ ����� �������� ��
% ����� 300 ��������
blobAnalysis = vision.BlobAnalysis...
    ('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, ...
    'CentroidOutputPort', false, ...
    'MinimumBlobArea', MinimumBlobArea, ...
    'MaximumBlobArea', MaximumBlobArea);

numframe = 1;
try
while numframes > numframe
    video = readFrame(v);
    frame  = rgb2gray (video(:,:,:)); % ��������� ���� � ������� ������
    level = graythresh(frame); % ������� ���������� ����� ����������� � ������� ������ ���
    frame= imbinarize(frame,level); % ����������� ����������� � �������� � ������� ������

    k=(frame - past_frame); % ������� ������� ����� ����� �������
    past_frame = frame; % �������� ������� ���� ��� ���������� 
    se = strel('square', imopen_streal); % ��������������� ����� �������� �� ����
    l = k;
    k = imopen(k, se); % ��������������� ����� �������� �� ���� 
    se = strel('square', imclose_streal);
    k = imclose(k,se); % ��������������� ��������      
    bbox = step(blobAnalysis, logical(k));  % ��������� ������� �� ����� �� ������������� �����
    result = insertShape(video, 'Rectangle', bbox, 'Color', 'red'); % ��������� �� �������� ��������� �����, 
    %�� �������������� ����������� ������� �� �����
    numObjects = size(bbox, 1); %������� ���������� �������� �� �����
    result = insertText(result, [10 10], ['Objects: ', sprintf('%d', numObjects)], 'BoxOpacity', 0.7,'FontSize', 20);
    writeVideo(v1,result); % ���������� ������������ ���� � ���������
    numframe = numframe + 1;
    
    
end
catch
close(v1);
end

end

