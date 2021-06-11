% PHASEAMPLIFY(VIDFILE, MAGPHASE, FL, FH, FS, OUTDIR, VARARGIN) 
% 
% Takes input VIDFILE and motion magnifies the motions that are within a
% passband of FL to FH Hz by MAGPHASE times. FS is the videos sampling rate
% and OUTDIR is the output directory. 
%
% Optional arguments:
% attenuateOtherFrequencies (false)
%   - Whether to attenuate frequencies in the stopband  
% pyrType                   ('halfOctave')
%   - Spatial representation to use (see paper)
% sigma                     (0)            
%   - Amount of spatial smoothing (in px) to apply to phases 
% temporalFilter            (FIRWindowBP) 
%   - What temporal filter to use
% 

function [rr_signal] = phaseAmplify(vidFile, magPhase , fl, fh,fs, outDir, varargin)

    %% Read Video
    vr = VideoReader(vidFile);
    [~, writeTag, ~] = fileparts(vidFile);
    FrameRate = vr.FrameRate;    
    vid = vr.read();
%     face_frame = vid(:,:,1,1);
%     faceDetector = vision.CascadeObjectDetector();
%     bbox = step(faceDetector, face_frame);
%     % 呼吸区域定位
%     index = find(bbox(:,3) == max(bbox(:,3)));
%     box = bbox(index,:);
%     width = box(3);
%     height = box(4);
%     % 列-行-宽-高
%     rr_box = [box(1)-width, box(2)+1.25*height, width*3, height*1.25];
%     % Draw the returned bounding box around the detected face.
%     face_frame = insertShape(face_frame, 'Rectangle', box,'LineWidth',5);
%     face_frame = insertShape(face_frame, 'Rectangle', rr_box,'LineWidth',5);
% %     figure; imshow(face_frame); title('Detected face');
%     rr_region = round([rr_box(2), rr_box(2)+rr_box(4), ...
%     rr_box(1), rr_box(1)+rr_box(3)]);
%     vid = vid(rr_region(1):rr_region(2), rr_region(3):rr_region(4),:,:);
    [h, w, nC, nF] = size(vid);
%     figure;
%     imshow(vid(:,:,:,1));
    
    %% Parse Input
    p = inputParser();

    defaultAttenuateOtherFrequencies = false; %If true, use reference frame phases
    pyrTypes = {'octave', 'halfOctave', 'smoothHalfOctave', 'quarterOctave'}; 
    checkPyrType = @(x) find(ismember(x, pyrTypes));
    defaultPyrType = 'octave';
    defaultSigma = 0;
    defaultTemporalFilter = @FIRWindowBP;
    defaultScale = 1;
    defaultFrames = [1, nF];
    
    addOptional(p, 'attenuateOtherFreq', defaultAttenuateOtherFrequencies, @islogical);
    addOptional(p, 'pyrType', defaultPyrType, checkPyrType);
    addOptional(p,'sigma', defaultSigma, @isnumeric);   
    addOptional(p, 'temporalFilter', defaultTemporalFilter);
    addOptional(p, 'scaleVideo', defaultScale);
    addOptional(p, 'useFrames', defaultFrames);
    
    parse(p, varargin{:});

    refFrame = 1;
    attenuateOtherFreq = p.Results.attenuateOtherFreq;
    pyrType            = p.Results.pyrType;
    sigma              = p.Results.sigma;
    temporalFilter     = p.Results.temporalFilter;
    scaleVideo         = p.Results.scaleVideo;
    frames             = p.Results.useFrames;

    %% Compute spatial filters        
    vid = vid(:,:,:,frames(1):frames(2));
    [h, w, nC, nF] = size(vid);
    if (scaleVideo~= 1)
        [h,w] = size(imresize(vid(:,:,1,1), scaleVideo));
    end
    
    
    fprintf('Computing spatial filters\n');
    ht = maxSCFpyrHt(zeros(h,w));
    switch pyrType
        case 'octave'
            filters = getFilters([h w], 2.^[0:-1:-ht], 4);
            repString = 'octave';
            fprintf('Using octave bandwidth pyramid\n');        
        case 'halfOctave'            
            filters = getFilters([h w], 2.^[0:-0.5:-ht], 8,'twidth', 0.75);
            repString = 'halfOctave';
            fprintf('Using half octave bandwidth pyramid\n'); 
        case 'smoothHalfOctave'
            filters = getFiltersSmoothWindow([h w], 8, 'filtersPerOctave', 2);           
            repString = 'smoothHalfOctave';
            fprintf('Using half octave pyramid with smooth window.\n');
        case 'quarterOctave'
            filters = getFiltersSmoothWindow([h w], 8, 'filtersPerOctave', 4);
            repString = 'quarterOctave';
            fprintf('Using quarter octave pyramid.\n');
        otherwise 
            error('Invalid Filter Types');
    end

    [croppedFilters, filtIDX] = getFilterIDX(filters);
    
    %% Initialization of motion magnified luma component
    magnifiedLumaFFT = zeros(h,w,nF,'single');
    
    buildLevel = @(im_dft, k) ifft2(ifftshift(croppedFilters{k}.* ...
        im_dft(filtIDX{k,1}, filtIDX{k,2})));
    
    reconLevel = @(im_dft, k) 2*(croppedFilters{k}.*fftshift(fft2(im_dft)));


    %% First compute phase differences from reference frame
    numLevels = numel(filters);        
    fprintf('Moving video to Fourier domain\n');
    vidFFT = zeros(h,w,nF,'single');
    for k = 1:nF
        originalFrame = rgb2ntsc(im2single(vid(:,:,:,k)));
        tVid = imresize(originalFrame(:,:,1), [h w]);
        vidFFT(:,:,k) = single(fftshift(fft2(tVid)));
    end
    clear vid;
    
    rr_signal = zeros(numLevels, nF);
    for level = 2:numLevels-1
        %% Compute phases of level
        % We assume that the video is mostly static
        pyrRef = buildLevel(vidFFT(:,:,refFrame), level);        
        pyrRefPhaseOrig = pyrRef./abs(pyrRef);
        pyrRef = angle(pyrRef);        

        delta = zeros(size(pyrRef,1), size(pyrRef,2) ,nF,'single');
        fprintf('Processing level %d of %d\n', level, numLevels);
           
        
        for frameIDX = 1:nF
            filterResponse = buildLevel(vidFFT(:,:,frameIDX), level);
            pyrCurrent = angle(filterResponse);
            delta(:,:,frameIDX) = single(mod(pi+pyrCurrent-pyrRef,2*pi)-pi);                          
        end
        
        
        %% Temporal Filtering
        fprintf('Bandpassing phases\n');
        delta = temporalFilter(delta, fl/fs,fh/fs); 


        %% Apply magnification

        fprintf('Applying magnification\n');
        for frameIDX = 1:nF

            phaseOfFrame = delta(:,:,frameIDX);
            originalLevel = buildLevel(vidFFT(:,:,frameIDX),level);
            %% Amplitude Weighted Blur        
            if (sigma~= 0)
                phaseOfFrame = AmplitudeWeightedBlur(phaseOfFrame, abs(originalLevel)+eps, sigma);        
            end

            % Increase phase variation
            phaseOfFrame = magPhase *phaseOfFrame;  
            
            rr_signal(level, frameIDX) = mean(mean(abs(phaseOfFrame)));
        end
    end
end
