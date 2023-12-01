%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File: sam.m
% Authors: Naia Dalal, Alexander Guess, Sovie Prasad Shekhar
% Course: ENG6 UC Davis, Spring Quarter 2023
% Description: This MATLAB file contains the main functions for our audio
% sampler program, ran through the app designer software.
%
% 6-7-2023 6:51 PM EDIT - AG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Sam
    % Defines all relevant properties used in this file
    properties
        fileName
        y
        sampleRate
        volume = 1;
        start
        startSec
        finish
        finishSec;
        filteredY
        feedbackY = 1;
        delayedY = 0;
        PlayableY
        switchFlipped
        multiplierInt = 1;
        equalizationGains = 1;
        
    end

    methods
        function obj = Sam()
            %AUDIOSAMPLE Construct an instance of this class
            %   Detailed explanation goes here
           
        end
        
        function obj = Load(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load: loads the sample and obtains useful variables for the
            % rest of the programs: filename, filepath, start time,
            % finish time, and the converted start time / finish time in
            % seconds.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [filename, filepath] = uigetfile({'*.wav', 'Wave files (*.wav)'}, 'Select File to Open')
            obj.fileName = filename
            [obj.y, obj.sampleRate] = audioread(fullfile(filepath, filename)); %read the file 
            obj.start = 1
            obj.finish = length(obj.y)
            obj.startSec = (obj.start-1)/obj.sampleRate
            obj.finishSec = (obj.finish-1)/obj.sampleRate
            
        end

        function obj = Play(obj, axes)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Plays the selected function with all modifications:
            % -Preserves original final, copies into obj.PlayableY
            % -Delay
            % -Chop
            % -Playback speed
            % -Reverse
            % -Equalization
            % -Graphing the sine waves
            % -Playing the audio
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.PlayableY = obj.y % copy the original array

            obj.PlayableY = obj.PlayableY + obj.delayedY; % add delay --
            obj.PlayableY = obj.PlayableY/max(abs(obj.PlayableY));
            %FIXME
            obj.PlayableY = obj.PlayableY .* obj.feedbackY; % Apply feedback
            obj.PlayableY = obj.PlayableY / max(abs(obj.PlayableY));
            obj.PlayableY = obj.volume .* obj.PlayableY %apply Volume 
            
            obj.PlayableY = obj.PlayableY(obj.start:obj.finish) %chop
            obj.PlayableY = obj.PlayableY(1:obj.multiplierInt:end); % PLAYBACK SPEED
            obj.PlayableY = obj.PlayableY * obj.equalizationGains; % Apply equalization
            


            if obj.switchFlipped == true
                obj.PlayableY = obj.PlayableY(end:-1:1); % reverse the array
            end

            sound(obj.PlayableY, obj.sampleRate); % PLAY THE SAMPLE

            t = (0:length(obj.PlayableY)-1) /obj.sampleRate; % Plots sample
            plot(axes, t,obj.PlayableY);

        end 
        

        function obj = Stop(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Stop: stops audio through MATLAB's native "clear" method
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            clear sound
        end
   
        function obj = Chop(obj, startTime, finishTime)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Chop: edits start and finish time (in seconds) of the audio
            % sampler based on user-selected timing.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            obj.startSec = startTime;
            obj.finishSec = finishTime;
            obj.start = (startTime * obj.sampleRate) + 1; %convert seconds to samples
            obj.finish = (finishTime * obj.sampleRate) + 1;
        end

        function obj = VolumeKnobChanged(obj, volumeKnob)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Volume: Edits the size of obj.volume which will be used to
            % modify the sample's volume.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.volume = volumeKnob * 0.05;
        end

        function obj = FeedbackKnobValueChanged(obj, feedbackKnob)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Feedback: adjusts the feedback based on an arbitrary level. 3
            % was chosen so that the function was less computationally
            % intensive, and therefore the program would run faster.
            % Effectively, the function isolated (most) amplitudes above
            % zero, which we've found to be percussion.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            filterOrder = 3; % ARBITRARY FILTER LEVEL; higher = more computationally intensive
            %
            normalizedCutoffFreq = feedbackKnob / (obj.sampleRate/2);
            obj.filteredY = fir1(filterOrder, normalizedCutoffFreq), 'low';
            obj.feedbackY = filter(obj.filteredY, 1, obj.y);
            %obj.feedbackY = obj.feedbackY(:, 1);
        end

        function obj = Direction(obj, switchFlipped)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Direction: reverses the audio when the switch is flipped.
            % Labels: forward, reverse.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if strcmp(switchFlipped, 'Forward')
                obj.switchFlipped = false;
            else
                obj.switchFlipped = true; % Reverse sample when the switch is switched to 'Reverse'
            end
            obj.switchFlipped
        end
        
        function obj = Export(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Export: exports the user-edited file. Uses the same filename.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            filename = obj.fileName;
            audiowrite(obj.fileName, rescale(obj.PlayableY, "InputMin", -1, "InputMax", 0.999), obj.sampleRate);
        end

        function obj = DelayKnobValueChanged(obj, delaySeconds)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Delay: Adds a delay to the sample in seconds.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            delaySamples = round(delaySeconds * obj.sampleRate); % HOW LONG TO DELAY THE SAMPLE BY
            obj.delayedY = [zeros(delaySamples, size(obj.y, 2)); obj.y];
            obj.delayedY = obj.delayedY(1:length(obj.y), :)
                       
            
        end

        function obj = UniversalEqualizerHz(obj, percent, hertz)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Equalizer: standard equalizer function; works for ALL
            % equalizer level, where the input hertz is adjusted based on
            % which meter is adjusted. Computes equalization for each
            % frequency.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.equalizationGains = ones(size(obj.PlayableY));
            percent = percent/100;
            for i = 1:numel(hertz)
                freqBins = find(abs(hertz(i) - linspace(0, 1, numel(obj.PlayableY))));
                obj.equalizationGains(freqBins) = percent(i);
            end
        
            obj.equalizationGains = obj.equalizationGains'; % Transpose the equalizationGains vector
            obj.equalizationGains = obj.equalizationGains(1, :);
            obj.equalizationGains = obj.equalizationGains(1, 1)
        
            % obj.PlayableY = obj.PlayableY .* obj.equalizationGains(freqBins);
        end

        function obj = Playbackspeed(obj, multiplier)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Playback speed: edits how fast the sample plays. Rounds to
            % the nearest integer (ceil()) to avoid an an error in matrix
            % indexing.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.multiplierInt = ceil(multiplier);
        end
        
    end
end