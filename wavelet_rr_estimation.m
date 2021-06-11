clear;
clc;
% 小波去噪的呼吸监测[张言飞]
addpath('sp_RR');

dataDir = './data';
dataName = 'n_test15.mp4';
inFile = fullfile(dataDir,dataName);
% 人脸检测
faceDetector = vision.CascadeObjectDetector();
% Read a video frame and run the face detector.
obj = VideoReader(inFile);
first_frame = readFrame(obj);
bbox = step(faceDetector, first_frame);

% 呼吸区域定位
index = find(bbox(:,3) == max(bbox(:,3)));
box = bbox(index,:);
width = box(3);
height = box(4);
rr_box = [box(1), box(2)+1.5*height, width, height*0.5];

first_frame = insertShape(first_frame, 'Rectangle', box,'LineWidth',5);
first_frame = insertShape(first_frame, 'Rectangle', rr_box,'LineWidth',5);
figure; imshow(first_frame); title('Detected face');

rr_region = round([rr_box(2), rr_box(2)+rr_box(4), ...
    rr_box(1), rr_box(1)+rr_box(3)]);

numFrames = obj.NumFrames;
rr_rate = zeros(numFrames, 1);

tic
for i = 1:numFrames
   frame = read(obj, i);
   f = frame(rr_region(1):rr_region(2), rr_region(3):rr_region(4),1);
   rr = mean(mean(double(f)));
   rr_rate(i) = rr;
end

rr_rate = rr_rate - mean(rr_rate);
t = (1:numFrames)/obj.frameRate;

%% 小波去噪
xd2 = wdenoise(rr_rate, 5, 'Wavelet', 'sym8', ...
    'DenoisingMethod', 'UniversalThreshold', ...
    'ThresholdRule', 'Soft');
% 运行时间计算
toc
disp(['运行时间: ',num2str(toc)]);
% 结果显示
figure;
plot(t, xd2, 'LineWidth', 1.5);
xlabel('时间 [s]', 'FontSize', 16, 'FontWeight','bold');
ylabel('像素平均灰度', 'FontSize',16, 'FontWeight','bold');
if dataName(1) == 'n'
    ylim([-1.5, 1.5]);
end
%% 峰值检测
window_r = 10;

hold on;
for i = 1:numFrames
    flag = 1;
    for j = 1:window_r
        if i >= j + 1 && xd2(i - j) >= xd2(i)
            flag = 0;
        end
    end
    for j = 1:window_r
        if  i + j <= numFrames && xd2(i + j) >= xd2(i)
            flag = 0;
        end
    end
    if flag == 1
        plot(t(i), xd2(i), 'r*', 'LineWidth', 8);
    end
end
hold off;



