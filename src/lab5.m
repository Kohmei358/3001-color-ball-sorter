%%
% RBE 3001 Lab 5 example code!
% Developed by Alex Tacescu (https://alextac.com)
%%
clc;
clear;
clear java;
format short

%% Flags
DEBUG = false;
STICKMODEL = false;
DEBUG_CAM = false;

CVLoopTime = 500; % In ms
ModelLoopTime = 500; % In ms

kine = Kinematics(95,100,100,[-90,90;-46,90;-86,63]);

%% Place Poses per color
purple_place = [150, -50, 11];
green_place = [150, 50, 11];
pink_place = [75, -125, 11];
yellow_place = [75, 125, 11];


%% Main Loop
try

%     % Set up camera
%     if cam.params == 0
%         error("No camera parameters found!");
%     end
%
%
%     %outputs a transformation Matrix
%     cam.cam_pose = cam.getCameraPose();
%     randompoint = pointsToWorld(cam.params.Intrinsics, cam.cam_pose(1:3,1:3), cam.cam_pose(1:3,4), [100 100]);
%     basePose = cam.cam_pose * cam.check2base;
%
%     disp("Cal Done");
%     pause;


%Initializing states
state = State.INIT;
nextState = State.INIT;


%Creating objects
orbList = OrbList();
robot = RobotStateMachine();

cv = CV(orbList);
model = Model();
homeObj = Home(robot,orbList);
approachObj = Approach(robot,orbList);
grabObj = Grab(robot,orbList);
travelObj = Travel(robot,orbList);
dropObj = Drop(robot);

timer = EventTimer();
CVTimer = EventTimer();
ModelTimer = EventTimer();


while true
    
    robot.update();
    
    if(CVTimer > CVLoopTime)
        cv.update();
        CVTimer.start();
    end
    
    if(ModelTimer > ModelLoopTime)
        model.update();
        ModelTimer.start();
    end
        
    switch(state)
        case State.INIT
            disp("INIT")
            homeObj.state = subState.INIT;
            state = State.HOME;
            %More init stuff here

        case State.HOME
            homeObj = homeObj.update();
            disp("HOME")
            if(homeObj.state == subState.DONE)
                disp("Home finished");
                nextState = State.APPROACH;
                state = State.DEBUG_WAIT;
                timer.setTimer(2000);
                apporachObj.state = subState.INIT;
            end

        case State.APPROACH
            approachObj = approachObj.update();
            if(approachObj.state == subState.DONE)
                nextState = State.GRAB;
                state = State.DEBUG_WAIT;
                timer.setTimer(2000);
                grabObj.state = subState.INIT;
            end

        case State.GRAB
            grabObj = grabObj.update();
            if(grabObj.state == subState.DONE)
                nextState = State.TRAVEL;
                state = State.DEBUG_WAIT;
                timer.setTimer(2000);
                travelObj.state = subState.INIT;
            end

        case State.TRAVEL
            travelObj = travelObj.update();
            if(travelObj.state == subState.DONE)
                nextState = State.DROP;
                state = State.DEBUG_WAIT;
                timer.setTimer(2000);
                dropObj.state = subState.INIT;
            end

        case State.DROP
            dropObj = dropObj.update();
            if(dropObj.state == subState.DONE)
                nextState = State.APPROACH;
                state = State.DEBUG_WAIT;
                timer.setTimer(2000);
                homeObj.state = subState.INIT;
            end

        case State.DEBUG_WAIT
            if(timer.isDone() == 1)
                state = nextState;
            end

    end
end


catch exception
    fprintf('\n ERROR!!! \n \n');
    disp(getReport(exception));
    disp('Exited on error, clean shutdown');
end

%% Shutdown Procedure
robot.shutdown()
cam.shutdown()