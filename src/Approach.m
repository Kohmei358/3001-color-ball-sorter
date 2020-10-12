classdef Approach
    
     properties
        robot;
        state; 
     end
    
    methods
        function obj = Home(robot)
            obj.robot = robot;
        end
        
        function update(obj)
            
            switch(obj.state)
                case subStates.INIT
                    if OrbList.length > 0
                        obj.robot.pathPlanTo(OrbList.activeOrb.finalPos);
                        obj.state = subState.ARM_WAIT;
                    end    
                    
                case subStates.ARM_WAIT
                    if OrbList.activeOrb.hasMoved == 1 || OrbList.length == 0
                        obj.state = subStates.INIT;
                    else    
                        if obj.robot.isAtTarget() == 1
                            obj.state = subState.DONE;
                        end
                    end    
       
                case subStates.DONE
                    
                otherwise
                    disp("ERROR in Home State, Incorrect State Given");
            end
        end
    end
end