with Ada.Text_IO;   use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with System;

with Webots_API; use Webots_API;

package body Tasks is
   -------------
   --  Tasks  --
   -------------

   type EventID is
     (RightPressed,
      RightReleased,
      LeftPressed,
      LeftReleased,
      UpPressed,
      UpReleased,
      DownPressed,
      DownReleased,
      EnteredLine,
      ExitedLine); -- Uppgift 2.2, fortsätt härifrån!

   protected Event is
      entry Wait (id : out EventID);
      procedure Signal (id : in EventID);
   private
      -- assign priority that is ceiling of the
      -- user tasks ’ priorities
      pragma Priority (System.Priority'Last - 2); -- ???
      current_id : EventID; -- event data
      signalled  : Boolean := false; -- flag for event signal
   end Event;

   protected body Event is
      entry Wait (id : out EventID) when Signalled is
      begin
         id := current_id;
         signalled := false;
      end Wait;
      procedure Signal (id : in EventID) is
      begin
         current_id := id;
         signalled := true;
      end Signal;
   end Event;

   task EventDispatcherTask is
      pragma Priority (System.Priority'Last - 1);

   end EventDispatcherTask;
   task body EventDispatcherTask is
      type KeysPressed is array (1 .. 4) of Boolean; -- left, right, up, down
      keys : KeysPressed := (others => False); -- initialize  all keys to false

      procedure NotifyChanges (button : ButtonID; arrayIndex : Integer) is
         prevVal       : Boolean;
         newVal        : Boolean;
         eventToSignal : EventID;
      begin
         prevVal := keys (arrayIndex);
         newVal := button_pressed (button);

         if (newVal = true and prevVal = false) then
            Put ("Button ");
            Put (ButtonID'Image (button));
            Put_Line (" down");
            -- Signal keyDownEvent
            case button is
               when LeftButton  =>
                  eventToSignal := LeftPressed;

               when RightButton =>
                  eventToSignal := RightPressed;

               when UpButton    =>
                  eventToSignal := UpPressed;

               when DownButton  =>
                  eventToSignal := DownPressed;
            end case;
            Event.Signal (eventToSignal);
         elsif (newVal = false and prevVal = true) then
            Put (("Button "));
            Put (ButtonID'Image (button));
            Put_Line (" RELEASED!");
            -- Signal keyUpEvent
            case button is
               when LeftButton  =>
                  eventToSignal := LeftReleased;

               when RightButton =>
                  eventToSignal := RightReleased;

               when UpButton    =>
                  eventToSignal := UpReleased;

               when DownButton  =>
                  eventToSignal := DownReleased;
            end case;
            Event.Signal (eventToSignal);
         end if;
         keys (arrayIndex) := newVal;
         return;
      end NotifyChanges;

   begin
      Put_Line ("Event Dispatcher running");
      while True loop
         NotifyChanges (LeftButton, 1);
         NotifyChanges (RightButton, 2);
         NotifyChanges (UpButton, 3);
         NotifyChanges (DownButton, 4);

         delay (0.010);
      end loop;

   end EventDispatcherTask;

   task MotorControlTask is
      -- define its priority higher than the main procedure --
      -- main procedure priority is declared at main.adb:9
   end MotorControlTask;

   task body MotorControlTask is
      RecentEvent : EventID;
      Speed       : Integer := 500;

      procedure SetMotors (left : Integer := 0; right : Integer := 0) is
      begin
         set_motor_speed (LeftMotor, left);
         set_motor_speed (RightMotor, right);
      end SetMotors;
   begin
      loop
         Event.Wait (RecentEvent);
         case RecentEvent is
            when RightPressed =>
               SetMotors (Speed, -Speed);

            when LeftPressed  =>
               SetMotors (-Speed, Speed);

            when UpPressed    =>
               SetMotors (Speed, Speed);

            when DownPressed  =>
               SetMotors (-Speed, -Speed);

            when others       =>
               SetMotors (0, 0);

         end case;
         exit when simulation_stopped;
      end loop;
   end MotorControlTask;

   -- Background procedure required for package
   procedure Background is

   begin

      while not simulation_stopped loop
         delay 0.25;
      end loop;
   end Background;

end Tasks;
