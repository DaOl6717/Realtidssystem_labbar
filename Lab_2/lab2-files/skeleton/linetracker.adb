with Ada.Text_IO;   use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with System;

with Webots_API; use Webots_API;

package body LineTracker is
   protected RobotState is
   private

   end RobotState;
   protected body RobotState is

   end RobotState;

   task MotorControlTask is
   end MotorControlTask;
   task body MotorControlTask is
      startTime : constant Time := Clock;
      period    : constant Time_Span := Milliseconds (500);
      next      : Time;
   begin
      next := startTime;
      loop
         next := next + period;
         delay until next;
      end loop;
   end MotorControlTask;

   task LineFollowingTask is
   end LineFollowingTask;
   task body LineFollowingTask is
      startTime : constant Time := Clock;
      period    : constant Time_Span := Milliseconds (500);
      next      : Time;
   begin
      next := startTime;
      loop
         next := next + period;
         delay until next;
      end loop;
   end LineFollowingTask;

   task DistanceTask is
   end DistanceTask;
   task body DistanceTask is
      startTime : constant Time := Clock;
      period    : constant Time_Span := Milliseconds (500);
      next      : Time;
   begin
      next := startTime;
      loop
         next := next + period;
         delay until next;
      end loop;
   end DistanceTask;

   task DisplayTask is
   end DisplayTask;
   task body DisplayTask is
      startTime : constant Time := Clock;
      period    : constant Time_Span := Milliseconds (500);
      next      : Time;
   begin
      next := startTime;
      loop
         next := next + period;
         delay until next;
      end loop;
   end DisplayTask;

   procedure Background is

   begin
      while not simulation_stopped loop
         delay 0.25;
      end loop;
   end Background;
end LineTracker;
