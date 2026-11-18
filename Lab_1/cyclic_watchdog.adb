-- Cyclic scheduler with a watchdog:
-- Written by David Olmedo & Filip Hellgren

with Ada.Calendar;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Discrete_Random;
with Ada.Text_IO;

use Ada.Calendar;
use Ada.Text_IO;

procedure cyclic_watchdog is
   Message         : constant String := "Cyclic scheduler with watchdog";
   Start_Time      : Time := Clock;
   Now             : Time := Clock;
   F1_Next         : Time := Start_Time;
   Gen             : Ada.Numerics.Float_Random.Generator;
   F3_Next         : Time := F1_Next + 0.5;
   Deadline_Missed : Boolean := False;

   -- Generates a random float value between Min and Max
   function Rand_Float (Min : Float; Max : Float) return Float is
   begin
      return
        (Float (Ada.Numerics.Float_Random.Random (Gen)) * (Max - Min))
        + Min; -- Generates a random float between min and max
   end Rand_Float;

   procedure f1 is
      Message : constant String := "f1 executing, time is now";
   begin
      Put (Message);
      Put_Line (Duration'Image (Clock - Start_Time));
   end f1;

   procedure f2 is
      Message : constant String := "f2 executing, time is now";
   begin
      Put (Message);
      Put_Line (Duration'Image (Clock - Start_Time));
   end f2;

   procedure f3 is
      Message    : constant String := "f3 executing, time is now";
      Rand_Delay : Duration;
   begin
      Put (Message);
      Put_Line (Duration'Image (Clock - Start_Time));
      Rand_Delay := Duration (Rand_Float (0.2, 0.8));
      Put_Line (Duration'Image (Rand_Delay));
      delay (Rand_Delay);
   end f3;

   task Watchdog is
      -- Signals to help keep track of when a task starts/stops
      entry Start;
      entry Finished;
   end Watchdog;

   task body Watchdog is
      Deadline : Time;
   begin
      loop
         accept Start;
         Deadline := Clock + 0.5;
         select
            accept Finished; -- If we received finish, do nothing
         or
         -- Else delay until next deadline
            delay until Deadline;
            Put_Line ("F3 Exceeded its deadline!");
            Deadline_Missed := True; -- Activate resynchronisation
            accept Finished;
         end select;
      end loop;
   end Watchdog;

begin
   Put_Line (Message);
   loop
      -- When we are in intervall for next F1 execution, call F1 & F2
      if (Clock >= F1_Next) then
         F1_Next := F1_Next + 1.0;  -- Calculating F1's next execution
         f1;
         f2;
      end if;

      -- When we are in intervall for next F3 execution, call F3
      if (Clock >= F3_Next) then
         F3_Next := F3_Next + 2.0;
         Deadline_Missed := False;
         Watchdog.Start;
         f3;
         Watchdog.Finished;

         if (Deadline_Missed) then
            -- Resynchronisation
            declare
               Elapsed    : Duration := Clock - Start_Time;
               NextSecond : Duration;
               Ceiled     : Float;
            begin
               Ceiled := Float'Ceiling (Float (Elapsed));
               NextSecond :=
                 Duration (Ceiled);    -- Round to closest next second
               F1_Next :=
                 Start_Time + NextSecond; -- Calculate new start time for F1
               F3_Next :=
                 F1_Next + 0.5;           -- Calculate new start time for F3
               Put_Line ("Resynchronized!");
            end;
         end if;
      end if;
   end loop;
end cyclic_watchdog;
