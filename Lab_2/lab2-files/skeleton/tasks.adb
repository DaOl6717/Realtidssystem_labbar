with Ada.Text_IO;   use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with System;

with Webots_API; use Webots_API;

package body Tasks is
   -------------
   --  Tasks  --
   -------------

   -- Defines events
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
      ExitedLine); -- TODO: Uppgift 2.2, fortsätt härifrån!

   protected Event is
      -- Protected ensures only one task at a time can access
      entry Wait (id : out EventID);
      procedure Signal (id : in EventID);
   private
      -- Assigns the object's highest priority to 2 below the highest available priority
      pragma Priority (System.Priority'Last - 2); -- ÄR 2 ETT BRA VÄRDE??
      current_id : EventID;            -- Event data
      signalled  : Boolean := false;   -- Flag for event signal
   end Event;

   protected body Event is
      entry Wait (id : out EventID) when signalled is -- Using signalled as barrier
      begin
         id := current_id;    -- Copies stored event to caller
         signalled := false;  -- Prevents event from being read twice
      end Wait;
      procedure Signal (id : in EventID) is
      begin
         current_id := id;    -- Stores new event
         signalled := true;   -- Sets flag, opens barrier
      end Signal;
   end Event;

   task EventDispatcherTask is
      pragma Priority (System.Priority'Last - 1);  -- Sets priority
   end EventDispatcherTask;
   task body EventDispatcherTask is
      type KeysPressed is array (1 .. 4) of Boolean; -- [left, right, up, down]
      keys : KeysPressed := (others => False); -- Initialize  all keys to false

      -- Checks one button and signals an event if its state has changed
      procedure NotifyChanges (button : ButtonID; arrayIndex : Integer) is
         prevVal       : Boolean;   -- Previous button value (pressed or not pressed)
         newVal        : Boolean;   -- The new button value (pressed or not pressed)
         eventToSignal : EventID;   -- What event to signal
      begin
         prevVal := keys (arrayIndex);       -- Reads previous state of button
         newVal := button_pressed (button);  -- Reads new button state from simulator

         -- If button goes from released to pressed...
         if (newVal = true and prevVal = false) then
            Put ("Button ");
            Put (ButtonID'Image (button));
            Put_Line (" down");
            -- ... signal keyDownEvent for that button
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
            Event.Signal (eventToSignal); -- Signals event to the protected object
         -- ... or if button goes from pressed to released
         elsif (newVal = false and prevVal = true) then
            Put (("Button "));
            Put (ButtonID'Image (button));
            Put_Line (" RELEASED!");
            -- ... signal keyUpEvent for that button
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
            Event.Signal (eventToSignal); -- Signals event to the protected object
         end if;
         keys (arrayIndex) := newVal;
         return;  -- DET HÄR gör väl ingenting? lol
      end NotifyChanges;

   begin
      Put_Line ("Event Dispatcher running");
      while True loop   -- Polling
         -- Checks each button and links it to its position in the array of keys
         NotifyChanges (LeftButton, 1);
         NotifyChanges (RightButton, 2);
         NotifyChanges (UpButton, 3);
         NotifyChanges (DownButton, 4);

         delay (0.010); -- Limits polling rate to reduce CPU time
      end loop;

   end EventDispatcherTask;

   task MotorControlTask is
      -- define its priority higher than the main procedure --
      -- main procedure priority is declared at main.adb:9
      -- OBS! inte våra kommentarer och vi definierar inte ens prioritet 
      -- för den här funktionen? Antar att den använder ngn std prio då?
      -- TODO
   end MotorControlTask;

   task body MotorControlTask is
      RecentEvent : EventID;        -- Stores received event
      Speed       : Integer := 500; -- Sets motor speed

      -- Helper: Makes it easier to control the motors
      procedure SetMotors (left : Integer := 0; right : Integer := 0) is
      begin
         set_motor_speed (LeftMotor, left);
         set_motor_speed (RightMotor, right);
      end SetMotors;
   begin
      loop
         Event.Wait (RecentEvent);
         case RecentEvent is
            -- Rotate right, left, go forwards, go backwards
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
