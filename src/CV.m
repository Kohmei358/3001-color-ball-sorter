classdef CV
    %CV Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        state
        Camera
        image
        orbList        
    end
    
    methods
        function obj = CV()
            obj.orbList = OrbList();
            obj.Camera = Camera();
            obj.Camera.DEBUG = false;
            obj = obj.extrinsticCalibration();
            
%             disp("CV constructor, color to ALL")
            obj.orbList.activeColor = Color.ALL;
            obj.state = CVState.INIT;
        end
        
        function obj = extrinsticCalibration(obj)
            % Set up camera
            if obj.Camera.params == 0
                error("No camera parameters found!");
            end
            %outputs a transformation Matrix
            obj.Camera.cam_pose = obj.Camera.getCameraPose();
            
        end
        
        function obj = update(obj)
%             disp(obj.orbList.activeColor);
            switch(obj.state)
                case CVState.INIT %Step 1
%                     disp("CV = INIT");
                    obj.state = CVState.STEP1;
                case CVState.STEP1 %Step 1
%                     disp("CV = STEP1");
                    obj = obj.step1();
                    obj.state = CVState.STEP2;
                case CVState.STEP2 %Step 2
%                     disp("CV = STEP2");
                    [obj,noOrbs] = obj.step2();
                    if noOrbs == 1
                        obj.state = CVState.STEP1;
                    else
                        obj.state = CVState.STEP3;
                    end
                    
                case CVState.STEP3 %Step 2
%                     disp("CV = STEP3");
                    obj = obj.step3();
                    obj.state = CVState.STEP1;
                case CVState.IDLE %Step 3
%                     disp("CV = IDLE");
                    %Do nothing
            end
        end
        
        function obj = step1(obj)
            obj.image = snapshot(obj.Camera.cam);
        end
        
        function [obj, noOrbs] = step2(obj)
            [obj.image, ~] = undistortImage(obj.image, obj.Camera.params.Intrinsics, 'OutputView', 'full');
            
            noOrbs = 0;
            %use the mask of the active color
            switch obj.orbList.activeColor
                case Color.PINK
                    [obj.image,~] = pinkMask(obj.image);
                case Color.GREEN
                    [obj.image,~] = greenMask(obj.image);
                case Color.YELLOW
                    [obj.image,~] = yellowMask(obj.image);
                case Color.PURPLE
                    [obj.image,~] = purpleMask(obj.image);
                otherwise
%                     disp("No active color, therefor no centeroid")
                    noOrbs = 1;
            end
            
            %Dilate the black and white image
            obj.image = imdilate(obj.image,strel('square',10));
            
            %Erode the dilated image from previous step
            obj.image = imerode(obj.image, strel('square', 15));
            
        end
        
        function obj = step3(obj)
            
            %Label Image
            obj.image = bwlabel(obj.image);
            
            %find all blobs and their area and centeroids
            stats = regionprops('table', obj.image, 'Centroid','Area');
            
            %no blobs of active color? The orb is gone
            if isempty(stats)
                obj.orbList.deleteActiveOrb();
            else
                %find the biggest blob
                [biggestArea, index] = max(stats.Area);
                
                if(biggestArea > 1000)
                    
                    %get the centeroid [x y] of the biggest blob
                    biggestCenteroid = stats.Centroid(index,:);

                    %convert the pixel xy to task space and update the orb pos
                    newPos = obj.centeroidToTask(biggestCenteroid);

                    targetPos = 0;

                    switch obj.orbList.activeColor
                        case Color.PINK
                            targetPos = [75 -150 80];
                        case Color.GREEN
                            targetPos = [175 75 100];
                        case Color.YELLOW
                            targetPos = [75 150 80];
                        case Color.PURPLE
                            targetPos = [175 -75 100];
                    end

                    hasMoved  = mean(abs(obj.orbList.getActiveOrb().currentPos(1:2) -newPos(1:2))) > 7;

                    newOrb = Orb(obj.orbList.activeColor,newPos,targetPos,hasMoved);

                    obj.orbList = obj.orbList.addOrbToList(newOrb);
                else
                    obj.orbList.deleteActiveOrb();
                end
            end
        end
        
        function taskSpace = centeroidToTask(obj,targetPixel)
            %pixel to chekcer space
            checkerSapce = pointsToWorld(obj.Camera.params.Intrinsics,...
                obj.Camera.cam_pose(1:3,1:3), obj.Camera.cam_pose(1:3,4),...
                [targetPixel(1) targetPixel(2)]);
            
            %checker to task sapce
            taskSpace = ([checkerSapce(1) checkerSapce(2) 10] +...
                (obj.Camera.check2base(1:3, 4))') * obj.Camera.check2base(1:3,1:3);
            
            %offest from 2d vs 3d centeroid
            taskSpace(1) = taskSpace(1) + (-0.0366*taskSpace(1) + 9.33);
            taskSpace(2) = taskSpace(2) - (0.0521*taskSpace(2) + 2.01);
        end
        
        function obj = forceRefreshEveryColor(obj)
            
            obj.orbList = OrbList();
            
            obj.state = CVState.INIT;
            obj.orbList.activeColor = Color.PINK;
            i = 0;
            while(i < 10)
                obj = obj.update();
                i = i + 1;
            end
            
            obj.state = CVState.INIT;
            obj.orbList.activeColor = Color.GREEN;
            i = 0;
            while(i < 10)
                obj = obj.update();
                i = i + 1;
            end
            
            obj.state = CVState.INIT;
            obj.orbList.activeColor = Color.YELLOW;
            i = 0;
            while(i < 10)
                obj = obj.update();
                i = i + 1;
            end
            
            obj.state = CVState.INIT;
            obj.orbList.activeColor = Color.PURPLE;
            i = 0;
            while(i < 10)
                obj = obj.update();
                i = i + 1;
            end
            
            
            if isa(obj.orbList.purpleOrb,'Orb')
                obj.orbList.activeColor = Color.PURPLE;
            elseif isa(obj.orbList.greenOrb,'Orb')
                obj.orbList.activeColor = Color.GREEN;
            elseif isa(obj.orbList.yellowOrb,'Orb')
                obj.orbList.activeColor = Color.YELLOW;
            elseif isa(obj.orbList.pinkOrb,'Orb')
                obj.orbList.activeColor = Color.PINK;
            else
%                 disp("No Orbs in forceRefresh color set to ALl")
                obj.orbList.activeColor = Color.ALL;
            end
            
            
            
            
        end
        
        
    end
end

