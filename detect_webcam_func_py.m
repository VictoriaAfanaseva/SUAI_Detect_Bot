function detect_video_func_py(filename, name_f_path, MinimumBlobArea, MaximumBlobArea,imopen_streal, imclose_streal)
 
if nargin ~= 6
    MinimumBlobArea = 80;
    MaximumBlobArea = 1000;
    imopen_streal  = 2;
    imclose_streal = 30;
end

v = VideoReader(filename);
numframes = int16(fix(v.FrameRate*v.Duration)); %Количество всех кадров

% первый кадр
video = readFrame(v);
frame  = rgb2gray (video(:,:,:)); % переведем кадр в оттенки серого
level = graythresh(frame); % получим нлобальный порог изображений с помощью метода Оцу
frame= imbinarize(frame,level); % преобразуем изображение в бинарное с помощью порога
past_frame = frame; % сохраним текущий кадр как предыдущий 

write_name = strcat(name_f_path, '_detect');
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
    video = readFrame(v);
    frame  = rgb2gray (video(:,:,:)); % переведем кадр в оттенки серого
    level = graythresh(frame); % получим нлобальный порог изображений с помощью метода Оцу
    frame= imbinarize(frame,level); % преобразуем изображение в бинарное с помощью порога

    k=(frame - past_frame); % получим разницу между двумя кадрами
    past_frame = frame; % сохраним текущий кадр как предыдущий 
    se = strel('square', imopen_streal); % морфологический метод очищение от шума
    l = k;
    k = imopen(k, se); % морфологический метод очищение от шума 
    se = strel('square', imclose_streal);
    k = imclose(k,se); % морфологическое закрытие      
    bbox = step(blobAnalysis, logical(k));  % вычисляем объекты на маске по заготовленому блобу
    result = insertShape(video, 'Rectangle', bbox, 'Color', 'red'); % добавляем на исходный видеокадр рамку, 
    %по местоположению выделенного объекта на маске
    numObjects = size(bbox, 1); %считаем количество объектов на кадре
    result = insertText(result, [10 10], ['Objects: ', sprintf('%d', numObjects)], 'BoxOpacity', 0.7,'FontSize', 20);
    writeVideo(v1,result); % записываем получившийся кадр в видеофайл
    numframe = numframe + 1;
    
    
end
catch
close(v1);
end

end

