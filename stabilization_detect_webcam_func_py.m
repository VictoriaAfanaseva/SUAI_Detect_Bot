function stabilization_detect_video_func_py(filename, name_f_path, MinimumBlobArea, MaximumBlobArea,imopen_streal, imclose_streal)
 
if nargin ~= 6
    MinimumBlobArea = 30;
    MaximumBlobArea = 1000;
    imopen_streal  = 2;
    imclose_streal = 30;
end

hVideoSrc0 = VideoReader(filename);
numframes = int16(fix(hVideoSrc0.FrameRate*hVideoSrc0.Duration)); %���������� ���� ������
hVideoSrc = vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');

imgA = step(hVideoSrc); % ������ ������ ����
imgB = step(hVideoSrc); % ������ ������ ����

ptThresh = 0.1; % ����������� �������� � ������������� ����� ����� � ���������� ��������
pointsA = detectFASTFeatures(imgA, 'MinContrast', ptThresh); % ����������� ����� ����� �
pointsB = detectFASTFeatures(imgB, 'MinContrast', ptThresh); % ����������� ����� ����� �

% ����� ������������
% ���������� ������������ ��� �����
[featuresA, pointsA] = extractFeatures(imgA, pointsA);
[featuresB, pointsB] = extractFeatures(imgB, pointsB);

% ������������� �������, ������� ���� ������� � ������� � ���������� ������
indexPairs = matchFeatures(featuresA, featuresB);
pointsA = pointsA(indexPairs(:, 1), :);
pointsB = pointsB(indexPairs(:, 2), :);

% ������ �������������� �� ������ ������������
[tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'affine');
imgBp = imwarp(imgB, tform, 'OutputView', imref2d(size(imgB)));
pointsBmp = transformPointsForward(tform, pointsBm.Location);

H = tform.T; % ���������� ����������  ��������
R = H(1:2,1:2); % ���������� ����������  ��������

% ��������� theta �� �������� �������� ���� ��������� ������������
theta = mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]);
% ��������� ������� �� �������� �������� ���� ���������� 
scale = mean(R([1 4])/cos(theta));
translation = H(3, 1:2);

% ����������� ������ ��������������
HsRt = [[scale*[cos(theta) -sin(theta); sin(theta) cos(theta)]; translation], [0 0 1]'];
tformsRT = affine2d(HsRt);

% ����� 
reset(hVideoSrc);                   

% ��������� ���� ������ �����
movMean = step(hVideoSrc);
imgB = movMean;
imgBp = imgB;
correctedMean = imgBp;
Hcumulative = eye(3);

% ������ ����
frame  = imgB; % ��������� ���� � ������� ������
level = graythresh(imgB); % ������� ���������� ����� ����������� � ������� ������ ���
frame= imbinarize(frame,level); % ����������� ����������� � �������� � ������� ������
past_frame = frame; % �������� ������� ���� ��� ���������� 

write_name = strcat(name_f_path, '_detect_stabl');
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
    % ������ ������ �����
    imgA = imgB; % z^-1
    imgAp = imgBp; % z^-1
    imgB = step(hVideoSrc);
    movMean = movMean + imgB;

    % ������ ������������� �� ����� A � ���� B � ����������� ��� s-R-t
    H = cvexEstStabilizationTform(imgA,imgB);%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    HsRt = cvexTformToSRT(H);
    Hcumulative = HsRt * Hcumulative;
    imgBp = imwarp(imgB,affine2d(Hcumulative),'OutputView',imref2d(size(imgB)));
    imWV = imfuse(imgAp,imgBp);

    frame = rgb2gray(imWV);% ��������� ���� � ������� ������
    level = graythresh(frame); % ������� ���������� ����� ����������� � ������� ������ ���
    frame = imbinarize(frame,level); % ����������� ����������� � �������� � ������� ������
    k=(frame - past_frame); % ������� ������� ����� ����� �������
    past_frame = frame; % �������� ������� ���� ��� ���������� 
    se = strel('square', imopen_streal); % ��������������� ����� �������� �� ����
    l = k;
    k = imopen(k, se); % ��������������� ����� �������� �� ���� 
    se = strel('square', imclose_streal);
    k = imclose(k,se); % ��������������� ��������
    k = imfill(k, 'holes');%��������� ����
               
    bbox = step(blobAnalysis, logical(k));  % ��������� ������� �� ����� �� ������������� �����
    result = insertShape(imWV, 'Rectangle', bbox, 'Color', 'red'); % ��������� �� �������� ��������� �����, 
    %�� �������������� ����������� ������� �� �����
    numObjects = size(bbox, 1); %������� ���������� �������� �� �����
    result = insertText(result, [10 10], ['Objects: ', sprintf('%d', numObjects)], 'BoxOpacity', 0.7,'FontSize', 20);
    writeVideo(v1,result); % ���������� ������������ ���� � ���������
    numframe = numframe + 1;
    
    figure(8)
    subplot(1,3,1)
    imshow(k);
    drawnow;
    
    subplot(1,3,2)
    imshow(imWV);
    drawnow;
    
    subplot(1,3,3)
    imshow(result);
    drawnow;
end
catch
release(hVideoSrc);
close(v1);
end

end

