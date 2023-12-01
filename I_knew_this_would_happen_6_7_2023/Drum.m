function Drum(bpm, beatPattern)
    %import sound effect
    [y, Fs] = audioread('DrumHit.wav');
    bpmi = 150; %bpm of original sound
    Fs = (bpm/bpmi) * Fs;
    
    %create a rest array
    tempSize = length(y);
    rest = zeros(tempSize, 1);
    drumBeat = [];
    for i = 1:8
        if beatPattern(i) == 1
            drumBeat = [drumBeat; y];
        else
            drumBeat = [drumBeat; rest];
        end
    end
    sound(drumBeat, Fs);
        
end
