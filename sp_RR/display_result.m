clear;
clc;
% 将结果显示在pvm增强后的视频中
load('rr15.mat');
obj = VideoReader('../video/video/test15-pvm.avi');
write_obj = VideoWriter('result_test_15', 'MPEG-4');
write_obj.FrameRate = obj.frameRate;
numFrames = obj.NumFrames;
t = (1:numFrames)/obj.frameRate;

open(write_obj);
figure;
% loc = [600, 1500];
loc = [50,50];
for i = 1:numFrames
    frame = read(obj, i);
    plot(t, rr_rate,'LineWidth', 1.5);
    hold on;
    plot(t(i), rr_rate(i), '*','LineWidth',8);
    axis off;
    hold off;
    saveas(gcf, 'tmp.png');
    tmp = imread('tmp.png');
    rect = size(tmp);
    frame(loc(1):loc(1)+rect(1)-1, loc(2):loc(2)+rect(2)-1, :) = tmp;
    writeVideo(write_obj, frame);
end
close(write_obj);


