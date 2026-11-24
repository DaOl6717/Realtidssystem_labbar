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
      ExitedLine);

   protected Event is
      -- Protected ensures only one task at a time can access
      entry Wait (id : out EventID);
      procedure Signal (id : in EventID);
   private
      -- assign priority that is ceiling of the
      -- user tasks ’ priorities
      pragma Priority (System.Priority'Last - 2); -- ???
      currentID : EventID; -- event data
      signalled : Boolean := false; -- flag for event signal
   end Event;

   protected body Event is
      entry Wait (id : out EventID) when signalled is
         -- Using signalled as barrier
      begin
         id := currentID;
         signalled := false;
      end Wait;
      procedure Signal (id : in EventID) is
      begin
         currentID := id;
         signalled := true;
      end Signal;
   end Event;

   task EventDispatcherTask is
      pragma Priority (System.Priority'Last - 1);  -- Sets priority
   end EventDispatcherTask;
   task body EventDispatcherTask is
      type KeysPressed is array (1 .. 4) of Boolean; -- left, right, up, down
      keys           : KeysPressed :=
        (others => False); -- initialize  all keys to false
      lightThreshold : Integer := 350;
      isOnLine       : Boolean := False;

      procedure NotifyKeyChanges (button : ButtonID; arrayIndex : Integer) is
         prevVal       : Boolean;
         newVal        : Boolean;
         eventToSignal : EventID;
      begin
         prevVal := keys (arrayIndex);       -- Reads previous state of button
         newVal :=
           button_pressed (button);  -- Reads new button state from simulator

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
            Event.Signal
              (eventToSignal); -- Signals event to the protected object
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
            Event.Signal
              (eventToSignal); -- Signals event to the protected object
         end if;
         keys (arrayIndex) := newVal;
      end NotifyKeyChanges;

      function IsSensorValueOnLine (sensorValue : Integer) return Boolean is
      begin
         if (sensorValue < lightThreshold) then
            return True;
         else
            return False;
         end if;
      end IsSensorValueOnLine;

      procedure NotifyLineChanges is
         prevOnLine : Boolean;
         newOnLine  : Boolean;
         sensorVal  : Integer;
      begin
         sensorVal := read_light_sensor (LS2);
         prevOnLine := isOnLine;
         newOnLine := IsSensorValueOnLine (sensorVal);
         -- Put_Line (Integer'Image (sensorVal));

         if (prevOnLine = True and newOnLine = False) then
            -- Line left
            Event.Signal (ExitedLine);
         elsif (prevOnLine = False and newOnLine = True) then
            -- Line entered
            Event.signal (EnteredLine);
         end if;

         isOnLine := newOnLine;
      end NotifyLineChanges;

   begin
      Put_Line ("Event Dispatcher running");
      while True loop
         NotifyKeyChanges (LeftButton, 1);
         NotifyKeyChanges (RightButton, 2);
         NotifyKeyChanges (UpButton, 3);
         NotifyKeyChanges (DownButton, 4);
         NotifyLineChanges;
         delay (0.010);
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
      RecentEvent    : EventID;
      MaxSpeed       : Integer := 500;
      IsCrossingLine : Boolean := False;
      LastMove       : Integer :=
        0; -- 0 : (none), 1 : Forward, 2 : Reverse, 3 : Left, 4 : Right

      -- Helper: Makes it easier to control the motors
      procedure SetMotors (left : Integer := 0; right : Integer := 0) is
      begin
         set_motor_speed (LeftMotor, left);
         set_motor_speed (RightMotor, right);

      end SetMotors;

      procedure MoveForwards is
      begin
         SetMotors (MaxSpeed, MaxSpeed);
      end MoveForwards;

      procedure MoveBackwards is
      begin
         SetMotors (-MaxSpeed, -MaxSpeed);
      end MoveBackwards;

      procedure TurnLeft is
      begin
         SetMotors (-MaxSpeed, MaxSpeed);
      end TurnLeft;

      procedure TurnRight is
      begin
         SetMotors (MaxSpeed, -MaxSpeed);
      end TurnRight;

      procedure OnKeyPress (event : EventID) is
      begin
         case event is
            when UpPressed    =>
               MoveForwards;
               LastMove := 1;

            when DownPressed  =>
               MoveBackwards;
               LastMove := 2;

            when LeftPressed  =>
               TurnLeft;
               LastMove := 3;

            when RightPressed =>
               TurnRight;
               LastMove := 4;

            when others       =>
               SetMotors (0, 0);
         end case;
      end OnKeyPress;
   begin
      loop
         Event.Wait (RecentEvent);
         case RecentEvent is
            when EnteredLine =>
               Put_Line ("ON THE LINE");
               IsCrossingLine := True;

               case LastMove is
                  when 1      =>
                     -- Moved Forward
                     MoveBackwards;

                  when 2      =>
                     -- Moved Backward
                     MoveForwards;

                  when 3      =>
                     -- Turned left
                     TurnRight;

                  when 4      =>
                     -- Turned right
                     TurnLeft;

                  when others =>
                     null;

               end case;

            when ExitedLine  =>
               Put_Line ("EXCITED LINE");
               IsCrossingLine := False;
               SetMotors (0, 0);

            when others      =>
               if (IsCrossingLine = False) then
                  OnKeyPress (RecentEvent);
               end if;
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
