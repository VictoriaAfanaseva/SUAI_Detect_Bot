function stabilization_video_func_py(filename, name_f_path)

v = VideoReader(filename);
numframes = int16(fix(v.FrameRate*v.Duration)); %���������� ���� ������
v = vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');

imgA = step(v); % ������ ������ ����
imgB = step(v); % ������ ������ ����

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
reset(v);                   

% ��������� ���� ������ �����
movMean = step(v);
imgB = movMean;
imgBp = imgB;
correctedMean = imgBp;
Hcumulative = eye(3);

write_name = strcat(name_f_path, '_stabl');
v1 = VideoWriter(write_name,'MPEG-4'); % �������� ���������� ��� ������ �����
open(v1); %�������� ����� �� ������

numframe = 1;
try
while numframes > numframe
    % ������ ������ �����
    imgA = imgB; % z^-1
    imgAp = imgBp; % z^-1
    imgB = step(v);
    movMean = movMean + imgB;

    % ������ ������������� �� ����� A � ���� B � ����������� ��� s-R-t
    H = cvexEstStabilizationTform(imgA,imgB);%���������� �������
    HsRt = cvexTformToSRT(H);%���������� �������
    Hcumulative = HsRt * Hcumulative;
    imgBp = imwarp(imgB,affine2d(Hcumulative),'OutputView',imref2d(size(imgB)));
    imWV = imfuse(imgAp,imgBp);
    writeVideo(v1,imWV); % ���������� ������������ ���� � ���������
    numframe = numframe + 1;

end
catch
release(v);
close(v1);
end

end

