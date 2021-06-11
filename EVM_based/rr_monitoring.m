clc;
clear;

dataDir = '../data';
dataName = 'n_test17.mp4';
inFile = fullfile(dataDir,dataName);
obj = VideoReader(inFile);
write_obj = VideoWriter('tmp', 'MPEG-4');
write_obj.FrameRate = obj.FrameRate;
numFrames = obj.NumFrames;

face_frame = read(obj, 1);
faceDetector = vision.CascadeObjectDetector();
bbox = step(faceDetector, face_frame);
% 呼吸区域定位
index = find(bbox(:,3) == max(bbox(:,3)));
box = bbox(index,:);
width = box(3);
height = box(4);
% 列-行-宽-高
rr_box = [box(1)-width, box(2)+1.25*height, width*3, height*1.25];
% Draw the returned bounding box around the detected face.
face_frame = insertShape(face_frame, 'Rectangle', box,'LineWidth',5);
face_frame = insertShape(face_frame, 'Rectangle', rr_box,'LineWidth',5);
figure; imshow(face_frame); title('Detected face');
rr_region = round([rr_box(2), rr_box(2)+rr_box(4), ...
rr_box(1), rr_box(1)+rr_box(3)]);
if mod(rr_region(1) + rr_region(2), 2) == 0
    rr_region(1) = rr_region(1) - 1;
end
if mod(rr_region(3) + rr_region(4), 2) == 0
    rr_region(3) = rr_region(3) - 1;
end
% rr_region = [741, 988, 1033, 1626];
% MPEG格式的视频宽度高度为2的倍数
open(write_obj);
for i = 1:numFrames
    frame = read(obj, i);
    frame = frame(rr_region(1):rr_region(2), rr_region(3):rr_region(4),1);
    writeVideo(write_obj, frame);
end
close(write_obj);

resultsDir = 'ResultsSIGGRAPH2012';
fprintf('Processing %s\n', 'tmp.mp4');
tic
rr_signal = amplify_spatial_lpyr_temporal_butter('tmp.mp4',resultsDir,50,4, 50/60,60/60,30, 1);
toc
figure;

t = (1:numFrames - 10)/obj.frameRate;
plot(t, mean(transpose(rr_signal)), 'LineWidth', 1.5);
xlabel('时间 [s]', 'FontSize', 16, 'FontWeight','bold');
ylabel('呼吸信号', 'FontSize',16, 'FontWeight','bold');
ylim([-0.001, 0.001]);

               