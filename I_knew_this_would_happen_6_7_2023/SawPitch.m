function [y, Fs] = SawPitch(freq, time, axes)
%take a frequency and time, plot the sine funtion and play the frequency
    dt = 0.0001;
    Fs = 1/dt;
    x = 0:dt:time;
    nu = 2*pi*freq;
    y = sawtooth(nu * x);
    plot(axes, x,y);
    sound(y, Fs);
end