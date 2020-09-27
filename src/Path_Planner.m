classdef Path_Planner
    properties
        queueOfPaths
        isPathDone
        pathPoints
        I
        numberOfPoints
        totalDuration
        segmentStartTime
        onSegment
        segmentDuration
    end
    
    methods
        function obj = Path_Planner()
            obj.queueOfPaths = queue;
        end
        
        function lin = linear_traj(~, startP, endP, viaP)
            t = linspace(0,1,viaP)';
            lin = (1-t)*startP + t*endP;
        end
        
        function obj = startNextPath(obj)
            if obj.queueOfPaths.Depth <= 0
                error("No more paths left. Please enqueue more");
            end
            pathData = obj.queueOfPaths.dequeue();
            type = pathData(9);
            typeString = ":Linear";
            if type == 3
                typeString = "Cubic";
            elseif type == 5
                typeString = "Quintic";
            end
            obj = obj.startPath(pathData(1:3),pathData(4:6),pathData(7),pathData(8),typeString);
        end
        
        function obj = startPath(obj,P1,P2,totalDuration,numberOfPoints,trajectoryType)
            obj.pathPoints = obj.linear_traj(P1,P2,numberOfPoints);
            obj.I = Interpolator(trajectoryType,totalDuration/ (numberOfPoints-1));
            obj.numberOfPoints = numberOfPoints;
            obj.totalDuration = totalDuration;
            obj.onSegment = 1;
            obj.segmentStartTime = tic;
            obj.segmentDuration = obj.totalDuration / (obj.numberOfPoints - 1);
        end
        
        function obj = startNextSegment(obj)
            obj.segmentStartTime = tic;
            obj.onSegment = obj.onSegment + 1;
%             disp("Moving to next segment: ");
%             disp(obj.onSegment);
        end
        
        function [obj, isPathDone, setPoint] = update(obj)
%             disp("Running Update");
            if obj.onSegment >= obj.numberOfPoints
                isPathDone = 1;
                setPoint = [100 0 195];
            else
                isPathDone = 0;
%                 disp("Segment Duration:") 
%                 disp(segmentDuration)
%                 disp("Start time") 
%                 disp(toc(obj.segmentStartTime))
                
                scalar = obj.I.get(toc(obj.segmentStartTime));
                setPoint = ((obj.pathPoints(obj.onSegment+1,:)-...
                    obj.pathPoints(obj.onSegment,:)).* scalar + obj.pathPoints(obj.onSegment,:));
                
                if(toc(obj.segmentStartTime) > obj.segmentDuration)
                    obj = obj.startNextSegment();
                end
%                 disp("Current Segment segment: ");
%                 disp(obj.onSegment);
            end
        end
    end
end

