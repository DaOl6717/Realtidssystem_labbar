-- Process commnication: Ada lab part 3
-- Written by David Olmedo & Filip Hellgren

with Ada.Calendar;
with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;
use Ada.Calendar;
use Ada.Text_IO;

procedure comm1 is
   Message   : constant String := "Process communication";
   Delay_Gen : Ada.Numerics.Float_Random.Generator;   -- Random delay generator
   task buffer is
      entry Put (X : Integer; Stop : out Boolean);
      entry Get (X : out Integer);
      entry Finished;
   end buffer;

   task producer is
   end producer;

   task consumer is
   end consumer;

   -- Generates a random float value between Min and Max
   function Rand_Float (Min : Float; Max : Float) return Float is
   begin
      return
        (Float (Ada.Numerics.Float_Random.Random (Delay_Gen)) * (Max - Min))
        + Min;
   end Rand_Float;

   -- Generates a random integer value between Min and Max
   function Rand_Integer (Min : Integer; Max : Integer) return Integer is
      subtype Random_Int is Integer range Min .. Max;
      package Int_Random is new Ada.Numerics.Discrete_Random (Random_Int);
      Int_Gen : Int_Random.Generator;
      N       : Random_Int;
   begin
      Int_Random.Reset (Int_Gen);
      N := Int_Random.Random (Int_Gen);
      return N;
   end Rand_Integer;

   task body buffer is
      Message  : constant String := "buffer executing";
      Num_Elem : Integer := 0;      -- Current number of elements in buffer
      Size     : Integer := 10;     -- Maxumum allowed number of elements in buffer

      type Buffer is array (1 .. Size) of Integer; -- Buffer of Integers

      -- Buffer initialisation
      Items : Buffer;
      First : Integer := 1;         -- First element index
      Last  : Integer := 1;         -- Last element index

      Stopping : Boolean := False;  -- To tell producer to terminate

   begin
      Put_Line (Message);
      loop
         if (Stopping) then
            -- When consumer signals buffer sum > 100
            accept Put (X : Integer; Stop : out Boolean) do
               Stop := True; -- Signal to producer to terminate
            end Put;
            Put_Line ("Stopping buffer");
            exit; -- Terminate buffer
         end if;

         select
            accept Finished;
            Stopping := True;
         or
            when Num_Elem < Size
            =>accept Put (X : Integer; Stop : out Boolean) do  -- Producer
               Num_Elem := Num_Elem + 1;                       -- Increase buffer size
               Items (Last) := X;
               -- If last element is populated, add to front buffer,
               -- enables a cyclic buffer structure    
               if (Last >= Size) then
                  Last := 1;
               else
                  Last := Last + 1;                            -- Append new element
               end if;
               Stop := False;
            end Put;
         or
            when Num_Elem > 0
            =>accept Get (X : out Integer) do                  -- Consumer
               Num_Elem := Num_Elem - 1;                       -- Decrease buffer size
               X := Items (First);
               if (First >= Size) then
                  First := 1;                                  -- Handles cyclic buffer
               else
                  First := First + 1;                          -- Sets new first
               end if;
            end Get;
         end select;
      end loop;
   end buffer;

   task body producer is
      Message    : constant String := "producer executing";
      Rand_Delay : Duration;  -- Producer delay
      Num        : Integer;   -- Value to insert into buffer
      Stop       : Boolean;
   begin
      Put_Line (Message);
      loop
         Rand_Delay := Duration (Rand_Float (0.0, 0.4));
         delay (Rand_Delay);

         Num := Rand_Integer (0, 20);

         buffer.Put (Num, Stop); -- Send value to buffer

         if (Stop) then
            Put_Line ("Stopping producer");
            exit; -- Terminate producer
         end if;
         Put ("Putting number: ");
         Put_Line (Integer'Image (Num));
      end loop;
   end producer;

   task body consumer is
      Message    : constant String := "consumer executing";
      Rand_Delay : Duration;
      Num        : Integer;      -- Value retreived from buffer
      Sum        : Integer := 0; -- Consumer sum, should terminate program when sum > 100
   begin
      Put_Line (Message);

      Main_Cycle : loop
         Rand_Delay := Duration (Rand_Float (0.2, 0.5));
         delay (Rand_Delay);
         buffer.Get (Num);       -- Retreive value from buffer
         Put ("Got number: ");
         Put_Line (Integer'Image (Num));

         Sum := Sum + Num;

         Put ("Consumer Sum: ");
         Put_Line (Integer'Image (Sum));
         if (Sum > 100) then
            Put_Line ("Finished!");
            exit Main_Cycle;
         end if;

      end loop Main_Cycle;

      Put_Line ("Stopping consumer");
      buffer.Finished; -- Signals to buffer to terminate producer and buffer

   exception
      when TASKING_ERROR =>
         Put_Line ("Buffer finished before producer");
         Put_Line ("Ending the consumer");
   end consumer;
begin
   Put_Line (Message);
end comm1;
