(*
Gate control with ONE button and NO limit switches.

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

(* ---------- Rising edge detection ---------- *)
RF_Pulse := RF_Input AND NOT RF_Last;
RF_Last := RF_Input;

(* ---------- Latch button press so it cannot be missed ---------- *)
IF RF_Pulse THEN
    RF_Latched := TRUE;
END_IF;


(* ---------- Timing tick ---------- *)
TickCount := TickCount + 1;

IF TickCount >= UnitTicks THEN
    TickCount := 0;


    (* ---------- Button behavior ---------- *)
    IF RF_Latched THEN
        RF_Latched := FALSE;

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


    (* ---------- Deadtime handling ---------- *)
    IF GateState = 1 THEN
        DeadUnits := DeadUnits + 1;

        IF DeadUnits >= DeadTimeUnits THEN
            DeadUnits := 0;
            MoveUnits := 0;

            IF NextDir = 1 THEN
                GateState := 2;     (* opening *)
                LastDir := 1;
            ELSE
                GateState := 3;     (* closing *)
                LastDir := 2;
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
        OpenRelay    := TRUE;
        CloseRelay   := FALSE;
        OpenRelay_2  := TRUE;
        CloseRelay_2 := FALSE;

    3:  (* CLOSING *)
        OpenRelay    := FALSE;
        CloseRelay   := TRUE;
        OpenRelay_2  := FALSE;
        CloseRelay_2 := TRUE;

    ELSE
        OpenRelay    := FALSE;
        CloseRelay   := FALSE;
        OpenRelay_2  := FALSE;
        CloseRelay_2 := FALSE;

END_CASE;