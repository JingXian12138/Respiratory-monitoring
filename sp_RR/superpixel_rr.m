clear;
clc;

dataDir = '../data';
dataName = 'n_test15.mp4';
inFile = fullfile(dataDir,dataName);
% 人脸检测
% Create a cascade detector object.
faceDetector = vision.CascadeObjectDetector();

% Read a video frame and run the face detector.
obj = VideoReader(inFile);
first_frame = readFrame(obj);
ff = first_frame;
bbox = step(faceDetector, first_frame);

% 呼吸区域定位
index = find(bbox(:,3) == max(bbox(:,3)));
box = bbox(index,:);
width = box(3);
height = box(4);

%% 检测呼吸率
% 列-行-宽-高
rr_box = [box(1)-width, box(2)+1.25*height, width*3, height*1.25];

% Draw the returned bounding box around the detected face.
first_frame = insertShape(first_frame, 'Rectangle', box,'LineWidth',5);
first_frame = insertShape(first_frame, 'Rectangle', rr_box,'LineWidth',5);
figure; imshow(first_frame); title('Detected face');

rr_region = round([rr_box(2), rr_box(2)+rr_box(4), ...
    rr_box(1), rr_box(1)+rr_box(3)]);

tic
ff = ff(rr_region(1):rr_region(2), rr_region(3):rr_region(4),1);
[L, N] = superpixels(ff, 32);
BW = boundarymask(L);

numFrames = obj.NumFrames;
rr_rate = zeros(numFrames, 1);

for i = 1:numFrames
   frame = read(obj, i);
   f = frame(rr_region(1):rr_region(2), rr_region(3):rr_region(4),1);
   rr = mean(double(f(BW)));
   rr_rate(i) = rr;
end

rr_rate = rr_rate - mean(rr_rate);
% IIR滤波
hd = myBandFilt;
rr_rate = filter(hd, rr_rate);
% 信号提取耗时
toc
disp(['运行时间: ',num2str(toc)]);
% 结果显示
figure;
t = (1:numFrames)/obj.frameRate;
plot(t, rr_rate, 'LineWidth', 1.5);
xlabel('时间 [s]', 'FontSize', 16, 'FontWeight','bold');
ylabel('像素平均灰度', 'FontSize',16, 'FontWeight','bold');
if dataName(1) == 'n'
    ylim([-1.5, 1.5]);
end

display_spectrum(rr_rate, obj.frameRate);
if dataName(1) == 'n'
    ylim([0, 0.8]);
else
    ylim([0, 0.1]);
end