function stabilization_video_func_py(filename, name_f_path)

v = VideoReader(filename);
numframes = int16(fix(v.FrameRate*v.Duration)); %Количество всех кадров
v = vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');

imgA = step(v); % читаем первый кадр
imgB = step(v); % читаем второй кадр

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
reset(v);                   

% обработка всех кадров видео
movMean = step(v);
imgB = movMean;
imgBp = imgB;
correctedMean = imgBp;
Hcumulative = eye(3);

write_name = strcat(name_f_path, '_stabl');
v1 = VideoWriter(write_name,'MPEG-4'); % создание переменной для записи видео
open(v1); %Открытие файла на запись

numframe = 1;
try
while numframes > numframe
    % чтение нового кадра
    imgA = imgB; % z^-1
    imgAp = imgBp; % z^-1
    imgB = step(v);
    movMean = movMean + imgB;

    % Оценка преобразуется из кадра A в кадр B и подгоняется как s-R-t
    H = cvexEstStabilizationTform(imgA,imgB);%встроенная функция
    HsRt = cvexTformToSRT(H);%встроенная функция
    Hcumulative = HsRt * Hcumulative;
    imgBp = imwarp(imgB,affine2d(Hcumulative),'OutputView',imref2d(size(imgB)));
    imWV = imfuse(imgAp,imgBp);
    writeVideo(v1,imWV); % записываем получившийся кадр в видеофайл
    numframe = numframe + 1;

end
catch
release(v);
close(v1);
end

end

