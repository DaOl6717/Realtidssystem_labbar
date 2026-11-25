-- Line Tracking Robot: Ada lab part 3
-- Written by David Olmedo & Filip Hellgren

with Ada.Text_IO;   use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with System;

with Webots_API; use Webots_API;

package body LineTracker is

   type ActionID is
     (TurnLeft, TurnRight, MoveForward);  -- Defines robot actions

   MaxSpeed : Integer := 500;             -- Max robot forwards/backwards speed

   protected RobotState is
      -- Procedures to set the next state or get the current
      procedure SetAction (NewAction : ActionID);
      function GetAction return ActionID;
      procedure SetTargetSpeed (NewSpeed : Integer);
      function GetTargetSpeed return Integer;
      procedure SetObstacleDistance (NewDist : Integer);
      function GetObstacleDistance return Integer;

   private
      TargetSpeed      : Integer := MaxSpeed;      -- The speed when no obstacles are detected
      ObstacleDistance : Integer := 0;             -- Initial obstacle distance
      CurrentAction    : ActionID := MoveForward;  -- The default action
   end RobotState;
   protected body RobotState is
      -- Procedures for retreiving/setting robot states
      procedure SetAction (NewAction : ActionID) is
      begin
         CurrentAction := NewAction;
      end SetAction;
      function GetAction return ActionID is
      begin
         return CurrentAction;
      end GetAction;
      procedure SetTargetSpeed (NewSpeed : Integer) is
      begin
         TargetSpeed := NewSpeed;
      end SetTargetSpeed;
      function GetTargetSpeed return Integer is
      begin
         return TargetSpeed;
      end GetTargetSpeed;
      procedure SetObstacleDistance (NewDist : Integer) is
      begin
         ObstacleDistance := NewDist;
      end SetObstacleDistance;
      function GetObstacleDistance return Integer is
      begin
         return ObstacleDistance;
      end GetObstacleDistance;
   end RobotState;

   task MotorControlTask is
   end MotorControlTask;
   task body MotorControlTask is
      StartTime     : constant Time := Clock;                  -- Get current time
      Period        : constant Time_Span := Milliseconds (50); -- Set task period
      Next          : Time;
      ForwardSpeed  : Integer := RobotState.GetTargetSpeed;
      TurnSpeed     : Integer := 100;                          -- Turn speed always 100
      CurrentAction : ActionID := RobotState.GetAction;        -- What action to do

      -- Helper: Set motor speed
      procedure SetMotors (Left : Integer := 0; Right : Integer := 0) is
      begin
         set_motor_speed (LeftMotor, Left);
         set_motor_speed (RightMotor, Right);

      end SetMotors;

      procedure MoveForwards is
      begin
         SetMotors (ForwardSpeed, ForwardSpeed);
      end MoveForwards;

      procedure MoveBackwards is
      begin
         SetMotors (-ForwardSpeed, -ForwardSpeed);
      end MoveBackwards;

      procedure TurnLeft is
      begin
         SetMotors (-TurnSpeed, TurnSpeed);
      end TurnLeft;

      procedure TurnRight is
      begin
         SetMotors (TurnSpeed, -TurnSpeed);
      end TurnRight;
   begin
      Next := StartTime;
      loop
         -- Read the latest action and speed from the shared state
         CurrentAction := RobotState.GetAction;
         ForwardSpeed := RobotState.GetTargetSpeed;

         case CurrentAction is
            when MoveForward =>
               MoveForwards;

            when TurnLeft    =>
               TurnLeft;

            when TurnRight   =>
               TurnRight;

            when others      =>
               null;
         end case;
         Next := Next + Period;
         delay until Next;
      end loop;
   end MotorControlTask;

   -- Adjusts the robot's course to follow a line
   task LineFollowingTask is
   end LineFollowingTask;
   task body LineFollowingTask is
      StartTime          : constant Time := Clock;                   -- Get current time
      Period             : constant Time_Span := Milliseconds (50);  -- Set task period
      Next               : Time;
      LightThreshold     : constant Integer := 350;
      LeftSensorOnLine   : Boolean;
      MiddleSensorOnLine : Boolean;
      RightSensorOnLine  : Boolean;

      -- Helper: Returns if sensor is on line 
      function IsSensorValueOnLine (SensorValue : Integer) return Boolean is
      begin
         if (SensorValue < LightThreshold) then
            return True;
         else
            return False;
         end if;
      end IsSensorValueOnLine;
   begin
      Next := StartTime;
      loop
         -- Get values for the light sensors
         LeftSensorOnLine := IsSensorValueOnLine (read_light_sensor (LS1));
         MiddleSensorOnLine := IsSensorValueOnLine (read_light_sensor (LS2));
         RightSensorOnLine := IsSensorValueOnLine (read_light_sensor (LS3));

         if (MiddleSensorOnLine) then
            -- Forward
            RobotState.SetAction (MoveForward);
         elsif (not LeftSensorOnLine) then
            -- Right
            RobotState.SetAction (TurnRight);
         elsif (not RightSensorOnLine) then
            -- Left
            RobotState.SetAction (TurnLeft);
         end if;

         Next := Next + Period;
         delay until Next;
      end loop;
   end LineFollowingTask;

   -- Adjusts speed depending on the distance to an obstacle in front of the robot
   task DistanceTask is
   end DistanceTask;
   task body DistanceTask is
      StartTime  : constant Time := Clock;                  -- Current time
      Period     : constant Time_Span := Milliseconds (20); -- Set task period
      Next       : Time;
      Distance   : Integer;                                 -- Latest distance sensor reading
      TargetDist : Integer := 200;                          -- The distance the robot tries to keep

      -- Helper: Calculates the robot's forwards/backwards speed
      function CalcTargetSpeed (Distance : Integer) return Integer is
         TargetSpeed : Integer := 0;   -- Speed to return
         Smoothing   : Float := 0.005; -- Scales how strongly the speed reacts to the error
         Margin      : Integer := 30;  -- Dead zone around the target when the robot stops
         DistDiff    : Integer;        -- How far the reading is from the target
      begin
         DistDiff := TargetDist - Distance;

         -- Below 70 is treated as no obstacle, got value from testing in the simulator
         if (Distance < 70) then
            return MaxSpeed;
         else
            -- Inside dead zone, stop the robot
            if (DistDiff < Margin and DistDiff > -Margin) then
               return 0;
            end if;
            -- Increased speed with increased distance, but no more than MaxSpeed
            TargetSpeed :=
              Integer (Float (DistDiff) * Smoothing * Float (MaxSpeed));
            if (TargetSpeed > MaxSpeed) then
               return MaxSpeed;
            elsif (TargetSpeed < -MaxSpeed) then
               return -MaxSpeed;
            else
               return TargetSpeed;
            end if;
         end if;
      end CalcTargetSpeed;
   begin
      Next := StartTime;
      loop
         -- Read distance value, calculate the speed, store it for the motor task
         Distance := read_distance_sensor;
         RobotState.SetTargetSpeed (CalcTargetSpeed (Distance));
         Next := Next + Period;
         delay until Next;
      end loop;
   end DistanceTask;

   -- Prints the robot's current status to console
   task DisplayTask is
   end DisplayTask;
   task body DisplayTask is
      StartTime : constant Time := Clock;
      -- Task period set to every second to not spam the console and not use too many CPU cycles
      Period    : constant Time_Span := Milliseconds (1000);
      Next      : Time;

      procedure PrintSpeed is
         CurrentSpeed : Integer := RobotState.GetTargetSpeed;
      begin
         Put ("Current speed: ");
         Put_Line (Integer'Image (CurrentSpeed));
      end PrintSpeed;

      procedure PrintObstacleDistance is
         CurrentDistance : Integer := RobotState.GetObstacleDistance;
      begin
         Put ("Current distance: ");
         Put_Line (Integer'Image (CurrentDistance));
      end PrintObstacleDistance;

      procedure PrintCurrentAction is
         Action : ActionID := RobotState.GetAction;
      begin
         Put ("Current Action: ");
         case Action is
            when TurnLeft    =>
               Put_Line ("Turn Left");

            when TurnRight   =>
               Put_Line ("Turn Right");

            when MoveForward =>
               Put_Line ("Move Forward");

            when others      =>
               Put_Line ("Unknown action");
         end case;
      end PrintCurrentAction;
   begin
      Next := StartTime;
      loop
         -- Print all three status values
         PrintSpeed;
         PrintObstacleDistance;
         PrintCurrentAction;

         Next := Next + Period;
         delay until Next;
      end loop;
   end DisplayTask;

   procedure Background is
   begin
      while not simulation_stopped loop
         delay 0.25;
      end loop;
   end Background;
end LineTracker;
