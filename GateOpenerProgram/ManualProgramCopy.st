(*
Decided to leave the program unchanged even though I switched the wiring to not use PLC relays 3 and 4. 
Saving these for future additions like a lock 
But will just let them actuate with this version of the program for now. They just won't do anything

Gate control with ONE pushbutton and 12v wireless remote plus NO limit switches or lock in this version

GateState:
0 = STOPPED
1 = DEADTIME
2 = OPENING
3 = CLOSING

LastDir:
1 = last direction was OPEN
2 = last direction was CLOSE

NextDir:
1 = open next
2 = close next
*)

(* Send Data to Modbus Parameters For Ignition *)
CloseRelay_Mod   := CloseRelay;
OpenRelay_Mod    := OpenRelay;
MoveUnits_Mod    := MoveUnits;
GateUnlocked_Mod := GateUnlocked;
RF_Input_Mod     := RF_Input;

(* ---------- Rising edge detection (RF or Ignition) ---------- *)
// Combines physical RF input and Ignition HMI signal into a single combined state
Combined_Input := RF_Input OR IgnitionStartSignal_Mod;

// Detect rising edge from either input source
RF_Pulse := Combined_Input AND NOT RF_Last;
RF_Last  := Combined_Input;

(* ---------- Latch button press ONLY IF gate is unlocked ---------- *)
IF RF_Pulse AND GateUnlocked THEN
    RF_Latched := TRUE;
END_IF;

(* ---------- Interlock: Force stop if lock is re-engaged ---------- *)
IF NOT GateUnlocked THEN
    GateState  := 0;      // Force state to STOPPED
    MoveUnits  := 0;      // Reset motion counters
    DeadUnits  := 0;
    RF_Latched := FALSE;  // Clear any pending button triggers
END_IF;


(* ---------- Timing tick ---------- *)
TickCount := TickCount + 1;

IF TickCount >= UnitTicks THEN
    TickCount := 0;

    (* ---------- Button behavior ---------- *)
    IF RF_Latched THEN
        RF_Latched := FALSE;

        // Double-check lock state before executing transition
        IF GateUnlocked THEN
            CASE GateState OF

                0:  (* stopped -> start opposite of last completed/commanded direction *)
                    IF LastDir = 1 THEN
                        NextDir := 2;   (* last was open, next close *)
                    ELSE
                        NextDir := 1;   (* last was close, next open *)
                    END_IF;

                    GateState := 1;     (* go to deadtime first *)
                    DeadUnits := 0;
                    MoveUnits := 0;

                1:  (* already in deadtime -> ignore/cancel *)
                    GateState := 0;
                    DeadUnits := 0;
                    MoveUnits := 0;

                2:  (* opening -> stop *)
                    GateState := 0;
                    MoveUnits := 0;

                3:  (* closing -> stop *)
                    GateState := 0;
                    MoveUnits := 0;

            END_CASE;
        END_IF;
    END_IF;


    (* ---------- Deadtime handling ---------- *)
    IF GateState = 1 THEN
        DeadUnits := DeadUnits + 1;

        IF DeadUnits >= DeadTimeUnits THEN
            DeadUnits := 0;
            MoveUnits := 0;

            IF NextDir = 1 THEN
                GateState := 2;     (* opening *)
                LastDir   := 1;
            ELSE
                GateState := 3;     (* closing *)
                LastDir   := 2;
            END_IF;

        END_IF;
    END_IF;


    (* ---------- Motion timing ---------- *)
    IF GateState = 2 THEN
        MoveUnits := MoveUnits + 1;

        IF MoveUnits >= OpenTimeUnits THEN
            GateState := 0;
            MoveUnits := 0;
        END_IF;

    ELSIF GateState = 3 THEN
        MoveUnits := MoveUnits + 1;

        IF MoveUnits >= CloseTimeUnits THEN
            GateState := 0;
            MoveUnits := 0;
        END_IF;

    ELSE
        MoveUnits := 0;
    END_IF;

END_IF;


(* ---------- Outputs ---------- *)
CASE GateState OF

    2:  (* OPENING *)
        OpenRelay  := GateUnlocked; (* Double protection on outputs *)
        CloseRelay := FALSE;

    3:  (* CLOSING *)
        OpenRelay  := FALSE;
        CloseRelay := GateUnlocked; (* Double protection on outputs *)

    ELSE
        OpenRelay  := FALSE;
        CloseRelay := FALSE;
END_CASE;