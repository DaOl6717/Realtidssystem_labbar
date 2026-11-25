-- Line Tracking Robot: Ada lab part 3
-- Written by David Olmedo & Filip Hellgren

with Ada.Text_IO;   use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with System;

with Webots_API; use Webots_API;

package body LineTracker is

   type ActionID is
     (TurnLeft, TurnRight, MoveForward);  -- Defines robot actions

   MaxSpeed : Integer := 500; -- Max robot forwards/backwards speed

   protected RobotState is
      procedure SetAction (NewAction : ActionID);
      function GetAction return ActionID;
      procedure SetTargetSpeed (NewSpeed : Integer);
      function GetTargetSpeed return Integer;
      procedure SetObstacleDistance (NewDist : Integer);
      function GetObstacleDistance return Integer;

   private
      TargetSpeed      : Integer := MaxSpeed;
      ObstacleDistance : Integer := 0;
      CurrentAction    : ActionID := MoveForward;
   end RobotState;
   protected body RobotState is
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
      StartTime     : constant Time := Clock;
      Period        : constant Time_Span := Milliseconds (50);
      Next          : Time;
      ForwardSpeed  : Integer := RobotState.GetTargetSpeed;
      TurnSpeed     : Integer := 100;
      CurrentAction : ActionID := RobotState.GetAction;

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

   task LineFollowingTask is
   end LineFollowingTask;
   task body LineFollowingTask is
      StartTime          : constant Time := Clock;
      Period             : constant Time_Span := Milliseconds (50);
      Next               : Time;
      LightThreshold     : constant Integer := 350;
      LeftSensorOnLine   : Boolean;
      MiddleSensorOnLine : Boolean;
      RightSensorOnLine  : Boolean;

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

   task DistanceTask is
   end DistanceTask;
   task body DistanceTask is
      StartTime  : constant Time := Clock;
      Period     : constant Time_Span := Milliseconds (20);
      Next       : Time;
      Distance   : Integer;
      TargetDist : Integer := 200;

      function CalcTargetSpeed (Distance : Integer) return Integer is
         TargetSpeed : Integer := 0;
         Smoothing   : Float := 0.005;
         Margin      : Integer := 30;
         DistDiff    : Integer;
      begin
         DistDiff := TargetDist - Distance;

         if (Distance < 70) then
            return MaxSpeed;
         else
            if (DistDiff < Margin and DistDiff > -Margin) then
               return 0;
            end if;
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
         Distance := read_distance_sensor;
         RobotState.SetTargetSpeed (CalcTargetSpeed (Distance));
         Next := Next + Period;
         delay until Next;
      end loop;
   end DistanceTask;

   task DisplayTask is
   end DisplayTask;
   task body DisplayTask is
      StartTime : constant Time := Clock;
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
