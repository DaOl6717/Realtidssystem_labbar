with Ada.Calendar.Formatting;
with Ada.Text_IO;  use Ada.Text_IO;
With Ada.Calendar; use Ada.Calendar;

procedure cyclic_scheduler is
   procedure F1;
   procedure F2;
   procedure F3;

   procedure F1 is
      now : Time := Clock;
   begin
      Put_Line
        ("F1 executing, time is now: "
         & Ada.Calendar.Formatting.Image (Now, Include_Time_Fraction => true));
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

   Put_Line ("JABALABALOOO");
   F1;

end cyclic_scheduler;
