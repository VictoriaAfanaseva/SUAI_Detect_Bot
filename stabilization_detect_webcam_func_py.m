function stabilization_detect_video_func_py(filename, name_f_path, MinimumBlobArea, MaximumBlobArea,imopen_streal, imclose_streal)
 
if nargin ~= 6
    MinimumBlobArea = 30;
    MaximumBlobArea = 1000;
    imopen_streal  = 2;
    imclose_streal = 30;
end

hVideoSrc0 = VideoReader(filename);
numframes = int16(fix(hVideoSrc0.FrameRate*hVideoSrc0.Duration)); %Количество всех кадров
hVideoSrc = vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');

imgA = step(hVideoSrc); % читаем первый кадр
imgB = step(hVideoSrc); % читаем второй кадр

ptThresh = 0.1; % минимальное различие в интенсивности между углом и окружающей областью
pointsA = detectFASTFeatures(imgA, 'MinContrast', ptThresh); % обнаружение углов кадра А
pointsB = detectFASTFeatures(imgB, 'MinContrast', ptThresh); % обнаружение углов кадра А

% поиск соответствий
% извлечение дескрипторов для углов
[featuresA, pointsA] = extractFeatures(imgA, pointsA);
[featuresB, pointsB] = extractFeatures(imgB, pointsB);

% сопоставление функций, которые были найдены в текущем и предыдущем кадрах
indexPairs = matchFeatures(featuresA, featuresB);
pointsA = pointsA(indexPairs(:, 1), :);
pointsB = pointsB(indexPairs(:, 2), :);

% оценка преобразования из шумных соответствий
[tform, pointsBm, pointsAm] = estimateGeometricTransform(pointsB, pointsA, 'affine');
imgBp = imwarp(imgB, tform, 'OutputView', imref2d(size(imgB)));
pointsBmp = transformPointsForward(tform, pointsBm.Location);

H = tform.T; % извлечение подматрицы  масштаба
R = H(1:2,1:2); % извлечение подматрицы  поворота

% вычислить theta из среднего значения двух возможных арктангенсов
theta = mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]);
% вычислить масштаб из среднего значения двух вычислений 
scale = mean(R([1 4])/cos(theta));
translation = H(3, 1:2);

% воссоздание нового преобразования
HsRt = [[scale*[cos(theta) -sin(theta); sin(theta) cos(theta)]; translation], [0 0 1]'];
tformsRT = affine2d(HsRt);

% сброс 
reset(hVideoSrc);                   

% обработка всех кадров видео
movMean = step(hVideoSrc);
imgB = movMean;
imgBp = imgB;
correctedMean = imgBp;
Hcumulative = eye(3);

% первый кадр
frame  = imgB; % переведем кадр в оттенки серого
level = graythresh(imgB); % получим нлобальный порог изображений с помощью метода Оцу
frame= imbinarize(frame,level); % преобразуем изображение в бинарное с помощью порога
past_frame = frame; % сохраним текущий кадр как предыдущий 

write_name = strcat(name_f_path, '_detect_stabl');
v1 = VideoWriter(write_name,'MPEG-4'); % создание переменной для записи видео
open(v1); %Открытие файла на запись

% Обнаружим объекты, на нашем видео они в любом случае будут занимать не
% менее 300 пикселей
blobAnalysis = vision.BlobAnalysis...
    ('BoundingBoxOutputPort', true, ...
    'AreaOutputPort', false, ...
    'CentroidOutputPort', false, ...
    'MinimumBlobArea', MinimumBlobArea, ...
    'MaximumBlobArea', MaximumBlobArea);

numframe = 1;
try
while numframes > numframe
    % чтение нового кадра
    imgA = imgB; % z^-1
    imgAp = imgBp; % z^-1
    imgB = step(hVideoSrc);
    movMean = movMean + imgB;

    % Оценка преобразуется из кадра A в кадр B и подгоняется как s-R-t
    H = cvexEstStabilizationTform(imgA,imgB);%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    HsRt = cvexTformToSRT(H);
    Hcumulative = HsRt * Hcumulative;
    imgBp = imwarp(imgB,affine2d(Hcumulative),'OutputView',imref2d(size(imgB)));
    imWV = imfuse(imgAp,imgBp);

    frame = rgb2gray(imWV);% переведем кадр в оттенки серого
    level = graythresh(frame); % получим нлобальный порог изображений с помощью метода Оцу
    frame = imbinarize(frame,level); % преобразуем изображение в бинарное с помощью порога
    k=(frame - past_frame); % получим разницу между двумя кадрами
    past_frame = frame; % сохраним текущий кадр как предыдущий 
    se = strel('square', imopen_streal); % морфологический метод очищение от шума
    l = k;
    k = imopen(k, se); % морфологический метод очищение от шума 
    se = strel('square', imclose_streal);
    k = imclose(k,se); % морфологическое закрытие
    k = imfill(k, 'holes');%Заполните дыру
               
    bbox = step(blobAnalysis, logical(k));  % вычисляем объекты на маске по заготовленому блобу
    result = insertShape(imWV, 'Rectangle', bbox, 'Color', 'red'); % добавляем на исходный видеокадр рамку, 
    %по местоположению выделенного объекта на маске
    numObjects = size(bbox, 1); %считаем количество объектов на кадре
    result = insertText(result, [10 10], ['Objects: ', sprintf('%d', numObjects)], 'BoxOpacity', 0.7,'FontSize', 20);
    writeVideo(v1,result); % записываем получившийся кадр в видеофайл
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

