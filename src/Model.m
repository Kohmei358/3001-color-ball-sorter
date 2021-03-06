classdef Model
    %MODEL handles all calcuations and display of the ball and stick model
    
    properties
        mainAxes
        poses
        transforms
        velo
        state;
    end
    
    methods
        
        function obj = Model()
            %MODEL Construct an instance of this class
            %Make axes window
            obj.mainAxes = axes('Position',[0.1 0.1 0.8 0.8]);
            title(obj.mainAxes,'3001 Virtual Arm');
            xlabel(obj.mainAxes,'X Axis');
            ylabel(obj.mainAxes,'Y Axis');
            zlabel(obj.mainAxes,'Z Axis');
            xlim(obj.mainAxes,[-220 220]);
            ylim(obj.mainAxes,[-220 220]);
            zlim(obj.mainAxes,[0 300]);
            
            view(3)
            view(0,90)

            obj.state = ModelState.INIT;
        end
        
        function [obj,robot] = update(obj,robot)
            
            switch(obj.state)
                case ModelState.STEP1
                    currentPos = robot.getPositions();
                    currentAngVelo = robot.getVelocities();
                    currentVelo = robot.fdk3001(currentPos, currentAngVelo);
                    obj.calcPose(currentPos,currentVelo);
                    obj.state = ModelState.PRERENDER;
                    
                case State.STEP2 
                    obj.plotGraph();
                    obj.state = ModelState.STEP3;
                    
                case State.STEP3 
                    obj.state = ModelState.STEP1;
                    model.render();
            end
        end
        
        %Plotting the stick model
        function obj = calcPose(obj,jointAngles,velo)
            %Loop that updates the ball and stick model
            
            kine = Kinematics(95,100,100,[-90,90;-46,90;-86,63]);
            
            %Values from DH table
            T0to2 = kine.DHtoMatrix(jointAngles(1),95,0,-90);
            T2to3 = kine.DHtoMatrix(jointAngles(2)-(90), 0,100,0);
            T3to4 = kine.DHtoMatrix(jointAngles(3)+(90),0,100,0);
            
            %concatinate all 3 transforms
            obj.transforms = cat(3,T0to2, T2to3, T3to4);
            obj.poses = zeros(4,4,size(obj.transforms,3));
            
            %for all 4 frames
            for i = (1:3)
                if(i == 1) %For the first frame the pose is the transform
                    obj.poses(:,:,i) = obj.transforms(:,:,i);
                else %for everything else post mutiply with previous pose
                    obj.poses(:,:,i) = obj.poses(:,:,i-1) * obj.transforms(:,:,i);
                end
            end
            
            obj.velo = velo;
        end
        
        function obj = plotGraph(obj)
            
            %now all poses and frames are ready
            cla %clear only data from figure
            hold on
            lastPos = obj.poses(:,:,3);
            disp(obj.velo(1:3,:))
            quiver3(obj.mainAxes,lastPos(1,4),lastPos(2,4),lastPos(3,4),obj.velo(1),obj.velo(2),obj.velo(3),0.015,'LineWidth',5);
            
            x = zeros(4,1);
            y = zeros(4,1);
            z = zeros(4,1);
            
            %first triad always at base
            triad('Parent',obj.mainAxes,'Scale',30,'LineWidth',3);
            
            %create triads at each frame
            warning('off', 'MATLAB:hg:DiceyTransformMatrix');
            for i = (1:3)
                triad('Parent',obj.mainAxes,'Scale',30,'LineWidth',3,'Matrix',obj.poses(:,:,i));
                x(i+1) = obj.poses(1,4,i);
                y(i+1) = obj.poses(2,4,i);
                z(i+1) = obj.poses(3,4,i);
            end
            
            %plot the ball and stick and label stuff
            plot3(obj.mainAxes,x,y,z,'-o','LineWidth',4,'MarkerSize',10,'MarkerFaceColor',[0.5,0.5,0.5]);grid on;
            hold off
        end
        
        function render(~)
            drawnow;
        end
        
        
    end
end

