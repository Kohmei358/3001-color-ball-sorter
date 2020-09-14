classdef Plotter
    %PLOTTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        file
    end
    
    methods
        function obj = Plotter(filename)
            fid = fopen(filename,'r');
            if fid == -1
                error('Cannot open log file.');
            end
            obj.file = fid;
        end
        
        function a = getMatrix(obj)
            a = readmatrix('log.txt');
        end
        function obj = close(obj)
            fclose(obj.file);
            obj.file = -1;
        end
    end
end

