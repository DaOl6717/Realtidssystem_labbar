with Ada.Calendar.Formatting;
with Ada.Text_IO;  use Ada.Text_IO;
With Ada.Calendar; use Ada.Calendar;

procedure cyclic_scheduler is
   Message    : constant String := "Cyclic scheduler";
   Start_Time : Time := Clock;
   Now        : Time := Clock;
   F1_Next    : Time := Start_Time;
   F3_Next    : Time := F1_Next + 0.5;

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
      Now := Clock;
      if (Now >= F1_Next) then
         F1_Next := F1_Next + 1.0;
         f1;
         f2;
      end if;

      if (Now >= F3_Next) then
         F3_Next := F3_Next + 2.0;
         f3;
      end if;
   end loop;
end cyclic_scheduler;
