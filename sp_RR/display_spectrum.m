function display_spectrum(signal, Fs)
%display_spectrum 显示信号的频谱
T = 1/Fs;
L = length(signal);
t = (0:L-1)*T;
Y = fft(signal);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
figure;
p = plot(f,P1, 'LineWidth', 1.5);
dtt = p.DataTipTemplate;
dtt.DataTipRows(1).Label = 'f';
dtt.DataTipRows(2).Label = 'P';
dtt.FontSize = 15;
title('单边幅度谱', 'FontSize', 18, 'FontWeight','bold')
xlabel('f (Hz)', 'FontSize', 16)
ylabel('|P1(f)|', 'FontSize', 16)
end

