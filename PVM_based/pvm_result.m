function []= pvm_result(filename)
%UNTITLED4 此处显示有关此函数的摘要
%   此处显示详细说明
dataDir = './';

resultsDir = 'ResultsSIGGRAPH2013/';
mkdir(resultsDir);
defaultPyrType = 'halfOctave'; % Half octave pyramid is default as discussed in paper
scaleAndClipLargeVideos = true; % With this enabled, approximately 4GB of memory is used

% Uncomment to use octave bandwidth pyramid: speeds up processing,
% but will produce slightly different results
%defaultPyrType = 'octave'; 

% Uncomment to process full video sequences (uses about 16GB of memory)
%scaleAndClipLargeVideos = false;

inFile = fullfile(dataDir, filename);
samplingRate = 30;
loCutoff = 6/60;
hiCutoff = 40/60;
alpha = 15;
sigma = 2;
pyrType = defaultPyrType;
phaseAmplify(inFile, alpha, loCutoff, hiCutoff, samplingRate, resultsDir, ...
'sigma', sigma, 'pyrType', pyrType);

end

