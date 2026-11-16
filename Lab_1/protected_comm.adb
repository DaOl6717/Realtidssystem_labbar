--Process commnication: Ada lab part 4

with Ada.Calendar;
with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Numerics.Float_Random;
use Ada.Calendar;
use Ada.Text_IO;

procedure protected_comm is
   Message   : constant String := "Protected object";
   Delay_Gen : Ada.Numerics.Float_Random.Generator;
   Size      : constant Integer := 10;
   type Buffer_T is array (1 .. Size) of Integer;
   protected buffer is
      entry Put (X : Integer; Stop : out Boolean);
      entry Get (X : out Integer);
      procedure Finished;
   private
      -- change/add your local declarations here
      Num_Elem : Integer := 0;

      Items : Buffer_T;
      First : Integer := 1;
      Last  : Integer := 1;

      Stopping : Boolean := False;
   end buffer;

   task producer is
   end producer;

   task consumer is
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

   protected body buffer is
      entry Put (X : Integer; Stop : out Boolean)
        when(Num_Elem < Size or Stopping)
      is
      begin
         if (Stopping = True) then
            Stop := True;
         else
            Num_Elem := Num_Elem + 1;
            Items (Last) := X;
            if (Last >= Size) then
               Last := 1;
            else
               Last := Last + 1;
            end if;
            Stop := False;
         end if;

      end Put;

      entry Get (X : out Integer) when Num_Elem > 0 is
      begin
         Num_Elem := Num_Elem - 1;
         X := Items (First);
         if (First >= Size) then
            First := 1;
         else
            First := First + 1;
         end if;

      end Get;

      procedure Finished is
      begin
         Stopping := True;
      end;
   end buffer;

   task body producer is
      Message    : constant String := "producer executing";
      Rand_Delay : Duration;
      Num        : Integer;
      Stop       : Boolean;
      -- change/add your local declarations here
   begin
      Put_Line (Message);
      loop
         Rand_Delay := Duration (Rand_Float (0.1, 0.4));

         delay (Rand_Delay);
         Num := Rand_Integer (0, 20);

         buffer.Put (Num, Stop);

         if (Stop) then
            Put_Line ("Stopping producer");
            exit;
         end if;
         Put ("Putting number: ");
         Put_Line (Integer'Image (Num));

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
         Rand_Delay := Duration (Rand_Float (0.2, 0.8));
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
      buffer.Finished;

   exception
      when TASKING_ERROR =>
         Put_Line ("Buffer finished before producer");
         Put_Line ("Ending the consumer");
   end consumer;
begin
   Put_Line (Message);
end protected_comm;
