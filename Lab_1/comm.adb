--Process commnication: Ada lab part 3

with Ada.Calendar;
with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;
use Ada.Calendar;
use Ada.Text_IO;

procedure comm1 is
   Message   : constant String := "Process communication";
   Delay_Gen : Ada.Numerics.Float_Random.Generator;
   task buffer is
      entry Put (X : Integer);
      entry Get (X : out Integer);
      entry Finished;
      -- add your task entries for communication
   end buffer;

   task producer is
      entry Finished;
      -- add your task entries for communication
   end producer;

   task consumer is
      -- add your task entries for communication
   end consumer;

   function Rand_Float (Min : Float; Max : Float) return Float is
   begin
      return
        (Float (Ada.Numerics.Float_Random.Random (Delay_Gen)) * (Max - Min))
        + Min;
   end Rand_Float;

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
      -- change/add your local declarations here
      Num_Elem : Integer := 0;
      Size     : Integer := 10;

      type Buffer is array (1 .. Size) of Integer;

      Items : Buffer;
      First : Integer := 1;
      Last  : Integer := 1;

   begin
      Put_Line (Message);
      loop
         -- add your task code inside this loop
         select
            accept Finished;
            Put_Line ("Stopping buffer");
            exit;
         or
            when Num_Elem < Size
            =>accept Put (X : Integer) do
               Num_Elem := Num_Elem + 1;
               Items (Last) := X;
               if (Last >= Size) then
                  Put_Line ("WRAP AROUND LAST");
                  Last := 1;
               else
                  Last := Last + 1;
               end if;

            end Put;
         or
            when Num_Elem > 0
            =>accept Get (X : out Integer) do
               Num_Elem := Num_Elem - 1;
               X := Items (First);
               if (First >= Size) then
                  Put_Line ("WRAP AROUND FIRST");
                  First := 1;
               else
                  First := First + 1;
               end if;
            end Get;
         end select;
      end loop;
   end buffer;

   task body producer is
      Message    : constant String := "producer executing";
      Rand_Delay : Duration;
      Num        : Integer;
      -- change/add your local declarations here
   begin
      Put_Line (Message);
      loop
         Rand_Delay := Duration (Rand_Float (0.0, 0.4));
         select
            accept Finished;
            Put_Line ("Stopping producer");
            exit;
         or
            delay (Rand_Delay);
            Num := Rand_Integer (0, 20);

            buffer.Put (Num);
            Put ("Putting number: ");
            Put_Line (Integer'Image (Num));
         end select;

      end loop;
   end producer;

   task body consumer is
      Message    : constant String := "consumer executing";
      Rand_Delay : Duration;
      Num        : Integer;
      Sum        : Integer := 0;
      -- change/add your local declarations here
   begin
      Put_Line (Message);

      Main_Cycle : loop
         -- add your task code inside this loop
         Rand_Delay := Duration (Rand_Float (0.2, 0.5));
         delay (Rand_Delay);
         buffer.Get (Num);
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

      -- add your code to stop executions of other tasks
      Put_Line ("Stopping consumer");
      producer.Finished;
      buffer.Finished;

   exception
      when TASKING_ERROR =>
         Put_Line ("Buffer finished before producer");
         Put_Line ("Ending the consumer");
   end consumer;
begin
   Put_Line (Message);
end comm1;
