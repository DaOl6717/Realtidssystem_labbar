with Ada.Text_IO; use Ada.Text_IO;
With Ada.Calendar use Ada.Calendar;

procedure cyclic_scheduler is
   procedure F1;
   procedure F2;
   procedure F3;
   
   procedure F1 is
   now : Time;
   begin
      Put_Line("F1 executing, time is now: " & Duration'Image(now));
      null;
   end F1;

   procedure F2 is
   begin
      -- Skriv vad den ska göra här
      null;
   end F2;

   procedure F3 is
   begin
      -- Skriv vad den ska göra här
      null;
   end F3;

   begin

   Put_Line("JABALABALOOO");

end cyclic_scheduler;