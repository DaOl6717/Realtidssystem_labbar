-- Cyclic scheduler
-- Written by David Olmedo & Filip Hellgren

with Ada.Calendar.Formatting;
with Ada.Text_IO;  use Ada.Text_IO;
With Ada.Calendar; use Ada.Calendar;

procedure cyclic_scheduler is
   Message    : constant String := "Cyclic scheduler";
   Start_Time : Time := Clock;
   Now        : Time := Clock;         -- Current time
   F1_Next    : Time := Start_Time;    -- Next start time for F1
   F3_Next    : Time := F1_Next + 0.5; -- Next start time for F3

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
      Message : constant String := "f3 executing, time is now";
   begin
      Put (Message);
      Put_Line (Duration'Image (Clock - Start_Time));
   end f3;
begin
   Put_Line (Message);
   loop
      Now := Clock;  -- Update clock
      if (Now >= F1_Next) then
         -- When we are in intervall for next F1 execution, call F1 & F2
         F1_Next := F1_Next + 1.0; -- Calculating F1's next execution
         f1;
         f2;
      end if;

      if (Now >= F3_Next) then
         -- When we are in intervall for next F3 execution, call F3
         F3_Next := F3_Next + 2.0; -- Calculating F3's next execution
         f3;
      end if;
   end loop;
end cyclic_scheduler;
