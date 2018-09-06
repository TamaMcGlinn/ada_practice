with Ada.Text_IO;            use Ada.Text_IO;
with GNAT.Regpat;            use GNAT.Regpat;
with Ada.Strings.Bounded;    use Ada.Strings.Bounded;
with Ada.Strings.Unbounded;  use Ada.Strings.unbounded;
with StringUtil;             use StringUtil;
with Ada.Calendar;           use Ada.Calendar;

procedure Ageindays is

  package Month_String is new Ada.Strings.Bounded.Generic_Bounded_Length(9);

  -- Integer'Image returns a space followed by a string representing the number
  -- IntegerToString returns just the string representing the number
  function IntegerToString(number : in Integer) return String is
  begin
     declare
        image : String := number'Image;
     begin
        return image(2..image'Length);
     end;
  end IntegerToString;

  type Month_String_Array is array (Month_Number'Range) of Month_String.Bounded_String;

  function ToUnboundedStringArray(months : in Month_String_Array) return String_Array is
  begin
    declare
      Result : String_Array(Integer(Month_Number'First)..Integer(Month_Number'Last));
    begin
      for i in Month_Number'Range loop
        Result(Integer(i)) := To_Unbounded_String(Month_String.To_String(months(i)));
      end loop;
      return Result;
    end;
  end ToUnboundedStringArray;

  Months : Month_String_Array := (
                                  Month_String.To_Bounded_String("January"),
                                  Month_String.To_Bounded_String("February"),
                                  Month_String.To_Bounded_String("March"),
                                  Month_String.To_Bounded_String("April"),
                                  Month_String.To_Bounded_String("May"),
                                  Month_String.To_Bounded_String("June"),
                                  Month_String.To_Bounded_String("July"),
                                  Month_String.To_Bounded_String("August"),
                                  Month_String.To_Bounded_String("September"),
                                  Month_String.To_Bounded_String("October"),
                                  Month_String.To_Bounded_String("November"),
                                  Month_String.To_Bounded_String("December")
                                 );

  function GetMonthIndex(monthName : in Month_String.Bounded_String) return Month_Number is
  begin
    for i in Month_Number'Range loop
      if Month_String."="(monthName, Months(i)) then
        return i;
      end if;
    end loop;
    raise Program_Error;
  end GetMonthIndex;

  function IsLeapYear(year : Year_Number) return Boolean is
  begin
    return year mod 4 = 0 and (year mod 100 /= 0 or year mod 400 = 0);
  end IsLeapYear;

  function DaysInMonth(month : in Month_Number; year : in Year_Number) return Day_Number is
  begin
    if month = 2 then
      return (if IsLeapYear(year) then 29 else 28);
    end if;
    if month <= 7 then
      return (30 + (month mod 2));
    end if;
    return (31 - (month mod 2));
  end DaysInMonth;

  type InputStatus is (Good, Absurd);

  function GetBirthDay(input : in String; day : out Day_Number; month : out Month_Number; year : out Year_Number) return InputStatus is
  begin
    declare
      unboundedMonths : String_Array := ToUnboundedStringArray(Months);
      Re : constant Pattern_Matcher := Compile("(^(1|2|3)?\d)(th|nd|rd) of (" & StringJoin("|", unboundedMonths) & ") ((19|20)\d{2})$");
      Matches : Match_Array (0..5);
    begin
      Match(Re, Input, Matches);

      if Matches(0) = No_Match then
        return Absurd;
      end if;

      declare
        MonthString : Month_String.Bounded_String := Month_String.To_Bounded_String(Input(Matches(4).First .. Matches(4).Last)); 
      begin
        month := Integer(GetMonthIndex(MonthString));
      end;
      
      declare
        type YearInput is range 1900..2099;
        YearInteger : YearInput := YearInput'Value(Input(Matches(5).First .. Matches(5).Last));
      begin
        if YearInteger < 1901 or YearInteger > 2018 then
          return Absurd;
        end if;
        year := Year_Number(YearInteger);
      end;

      declare
        DayInteger : Integer range 0..39;
        DaysInBirthMonth : constant Day_Number := DaysInMonth(month, year);
      begin
        DayInteger := Integer'Value(Input(Matches(1).First .. Matches(1).Last));
        if DayInteger < Day_Number'First or DayInteger > DaysInBirthMonth then
          return Absurd;
        end if;
        day := Day_Number(DayInteger);
        return Good;
      end;
    end;
  end GetBirthDay;

  Today_Day : Day_Number;
  Today_Month : Month_Number;
  Today_Year : Year_Number;
begin
  declare
    TodayTime : Time := Clock;
    Today_Seconds : Day_Duration;
  begin
    Split(TodayTime, Today_Year, Today_Month, Today_Day, Today_Seconds);
  end;
  Put_Line("Today is " & IntegerToString(Integer(Today_Day)) & '/' & IntegerToString(Today_Month) & '/' & IntegerToString(Today_Year));

  Put_Line("What is your birthday?");
  Put_Line("Supported formats by example:");
  Put_Line("24th of September 1992");
  declare
  begin
    loop
      declare
        Input : constant String := Get_Line;
        BirthDay : Day_Number;
        BirthMonth : Month_Number;
        BirthYear : Year_Number;
        Result : InputStatus;
      begin
        exit when Input = "";
        Put("> ");
        Result := GetBirthDay(Input, BirthDay, BirthMonth, BirthYear);
        if Result = Absurd then
          Put_Line("Don't be absurd. Tell me your real birthday");
        else
          Put_Line("Birthday: " & IntegerToString(BirthDay) & '/' & IntegerToString(BirthMonth) & '/' & IntegerToString(BirthYear));
          declare
            type DifferenceYears is range Year_Number'First - Year_Number'Last..Year_Number'Last - Year_Number'First;
            type DifferenceMonths is range Month_Number'First - Month_Number'Last..Month_Number'Last - Month_Number'First;
            type DifferenceDays is range Day_Number'First - Day_Number'Last..Day_Number'Last - Day_Number'First;
            YearsOld : DifferenceYears := DifferenceYears(Today_Year - BirthYear);
            MonthsOld : DifferenceMonths := DifferenceMonths(Today_Month - BirthMonth);
            DaysOld : DifferenceDays := DifferenceDays(Today_Day - BirthDay);

            function PreviousMonth(month : in Month_Number) return Month_Number is
            begin
              return (if month = 1 then 12 else month - 1);
            end PreviousMonth;

          begin
            if DaysOld < 0 then
              MonthsOld := MonthsOld - 1;
              DaysOld := DifferenceDays(Integer(DaysOld) + Integer(DaysInMonth(PreviousMonth(BirthMonth), BirthYear)));
            end if;
            if MonthsOld < 0 then
              YearsOld := YearsOld - 1;
              MonthsOld := MonthsOld + 12;
            end if;
            Put_Line("You are" & YearsOld'Image & " years," & MonthsOld'Image & " months and" & DaysOld'Image & " days old.");
          end;
        end if;
      end;
    end loop;
  end;
end Ageindays;