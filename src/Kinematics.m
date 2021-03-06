classdef Kinematics
    %KINEMATICS is responible for convering DH tables to matries
    %and for running and FK neeed
    
    properties
        % l1, l2 and l3 are link lengths of our robot in mm.
        l1 = 0;
        l2 = 0;
        l3 = 0;
        jointLimits %for safety calculations in the arm workspace
    end
    
    methods
        %constructor
        function obj = Kinematics(joint1Length,joint2Length,joint3Length,jointMinMax)
            obj.l1 = joint1Length;
            obj.l2 = joint2Length;
            obj.l3 = joint3Length;
            obj.jointLimits = jointMinMax;
            
        end
        
        %inverse kinematics function: xyz is a 1x3 matrix containing the x, y and z position 
        function theta = ik3001(obj, xyz)
            %1x3 matrix holding 3 theta values corresponding to the motor 1
            %2 and 3.
            theta = zeros(1,3);
            x = xyz(1);
            y = xyz(2);
            z = xyz(3);
            
            
            sqrtX2y2 = sqrt(x^2+y^2);
            z1d1 = z - obj.l1;
            r = sqrt(sqrtX2y2^2 + z1d1^2);
            
            a2 = atan2d(z1d1,sqrtX2y2);
            
            D1 = (obj.l2^2 + r^2 - obj.l3^2) / (2*obj.l2*r);
            D3 = (obj.l2^2 + obj.l3^2 - r^2) / (2*obj.l2*obj.l3);
            
            C1 = sqrt(1-D1^2);
            C3 = sqrt(1-D3^2);
            
            a1a = atan2d(C1,D1);
            a1b = atan2d(-C1,D1);
            
            a3a = atan2d(C3,D3);
            a3b = atan2d(-C3,D3);
            
            theta1 = atan2d(y,x);
            
            theta2a = 90-a1a-a2;
            theta2b = (90)-a1b-a2;
            
            theta3a = (90)-a3a;
            theta3b = (90)-a3b;
            
            
            %Safety checking
            Safe1 = obj.isindLimit(1,theta1);
            Safe2a = obj.isindLimit(2,theta2a);
            Safe2b = obj.isindLimit(2,theta2b);
            Safe3a = obj.isindLimit(3,theta3a);
            Safe3b = obj.isindLimit(3,theta3b);
            
            %deciding the value for theta1 theta2 and theta3
            if Safe1 == 0
                error("Theta 1 was not safe. Value: "+ string(theta1));
            else
                theta(1) = theta1;
            end
            
            if Safe2a == 0 && Safe2b == 0
                error("Theta 2 was not safe. Value: "+ string(theta2a)...
                    + " and " + string(theta2b));
            elseif Safe2a == 1 && Safe2b == 1
                theta(2) = min(theta2a,theta2b);
            elseif Safe2a == 1 && Safe2b == 0
                theta(2) = theta2a;
            elseif Safe2a == 0 && Safe2b == 1
                theta(2) = theta2b;
            else
                error("Unknown error.");
            end
            
            if Safe3a == 0 && Safe3b == 0
                error("Theta 3 was not safe. Value: "+ string(theta3a)...
                    + " and " + string(theta3b));
            elseif Safe3a == 1 && Safe3b == 1
                theta(3) = max(theta3a,theta3b);
            elseif Safe3a == 1 && Safe3b == 0
                theta(3) = theta3a;
            elseif Safe3a == 0 && Safe3b == 1
                theta(3) = theta3b;
            else
                error("Unknown error.");
            end
            
            if(theta(1) < 0)
                theta(1) = theta(1) -5;
            end
            
        end
        
        
        %FK3001 reutnrs a 3x1 matrix for the end effector position w.r.t. the origin based on a 3x1
        %matrix of joint angles
        function tipPos = FKtoTip(obj,jointAngles)
            
            jointAngles = (jointAngles);
            T0to2 = obj.DHtoMatrix(jointAngles(1),95,0,-90);
            T2to3 = obj.DHtoMatrix(jointAngles(2)-(90), 0,100,0);
            T3to4 = obj.DHtoMatrix(jointAngles(3)+(90),0,100,0);
            
            FinalMatrix = T0to2 * T2to3 * T3to4;
            
            tipPos = zeros(3,1);
            tipPos(1) = FinalMatrix(1,4);
            tipPos(2) = FinalMatrix(2,4);
            tipPos(3) = FinalMatrix(3,4);
        end
        
        function tipPos = SymbFKtoTip(obj,t1, t2, t3, d1, d2,d3,a1,a2,a3,alp1,alp2,alp3)
            
            T0to2 = obj.SymbDHtoMatrix(t1,d1,a1,alp1);
            T2to3 = obj.SymbDHtoMatrix(t2,d2,a2,alp2);
            T3to4 = obj.SymbDHtoMatrix(t3,d3,a3,alp3);
            
            FinalMatrix = T0to2 * T2to3 * T3to4;
            syms o;
            tipPos = [o o o]';
            tipPos(1) = FinalMatrix(1,4);
            tipPos(2) = FinalMatrix(2,4);
            tipPos(3) = FinalMatrix(3,4);
        end
        
        %Turning a row in DH table into transformation matrix.
        function Tmatrix = DHtoMatrix(~,Theta,D,A,Alpha)
            Tmatrix = zeros(4,'double');
            
            %Row 1
            Tmatrix(1,1) = cosd(Theta);
            Tmatrix(1,2) = -sind(Theta)*cosd(Alpha);
            Tmatrix(1,3) = sind(Theta)*sind(Alpha);
            Tmatrix(1,4) = A*cosd(Theta);
            
            %Row 2
            Tmatrix(2,1) = sind(Theta);
            Tmatrix(2,2) = cosd(Theta)*cosd(Alpha);
            Tmatrix(2,3) = -cosd(Theta)*sind(Alpha);
            Tmatrix(2,4) = A*sind(Theta);
            
            %Row 3
            Tmatrix(3,2) = sind(Alpha);
            Tmatrix(3,3) = cosd(Alpha);
            Tmatrix(3,4) = D;
            
            Tmatrix(4,4) = 1;
        end
        
        function Tmatrix = SymbDHtoMatrix(~,Theta,D,A,Alpha)
            syms o
            Tmatrix = [o o o o;
                        o o o o;
                        o o o o;
                        o o o o;];
            
            %Row 1
            Tmatrix(1,1) = cosd(Theta);
            Tmatrix(1,2) = -sind(Theta)*cosd(Alpha);
            Tmatrix(1,3) = sind(Theta)*sind(Alpha);
            Tmatrix(1,4) = A*cosd(Theta);
            
            %Row 2
            Tmatrix(2,1) = sind(Theta);
            Tmatrix(2,2) = cosd(Theta)*cosd(Alpha);
            Tmatrix(2,3) = -cosd(Theta)*sind(Alpha);
            Tmatrix(2,4) = A*sind(Theta);
            
            %Row 3
            Tmatrix(3,1) = 0;
            Tmatrix(3,2) = sind(Alpha);
            Tmatrix(3,3) = cosd(Alpha);
            Tmatrix(3,4) = D;
            
            Tmatrix(4,1) = 0;
            Tmatrix(4,2) = 0;
            Tmatrix(4,3) = 0;
            Tmatrix(4,4) = 1;
        end
        
        %Safety checking function.
        function safe = isindLimit(obj,joint, angleRad)
            safe = 0;
            if  angleRad > obj.jointLimits(joint,1) && angleRad < obj.jointLimits(joint,2)
                safe = 1;
            end
        end
        
        
        
    end
end

