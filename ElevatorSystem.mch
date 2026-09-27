MACHINE ElevatorSystem

/* =====================================================================
   Sistema de Elevador Inteligente - Máquina Abstrata em B-Method
   -----------------------------------------------------------------

   MAX_FLOOR e ELEVATOR_COUNT são CONSTANTS da máquina de contexto
   ElevatorContext (ver esse arquivo), verificadas por PROPERTIES.
   Para mudar o nº de andares/elevadores, edite ElevatorContext.mch.

   Cada operação chamável pela interface possui uma operação-irmã
   "_OK" que apenas consulta se a chamada seria válida, sem alterar o
   estado (abordagem de design-by-contract com verificação explícita
   de pré-condição, já que a interface é "burra" e não deve conter
   lógica de validação própria).
   ===================================================================== */

SEES ElevatorContext

DEFINITIONS
    FLOORS    == 0..MAX_FLOOR;
    ELEVATORS == 1..ELEVATOR_COUNT;

    /* distância (em andares) entre dois andares
       (max{a-b,b-a} evita IF-como-expressão, que só o ProB aceita
       e o Atelier-B rejeita) */
    distance(from_floor, to_floor) == max({from_floor - to_floor, to_floor - from_floor});

    /* o elevador, andando na direção da chamada, ainda não "passou"
       pelo andar da chamada (ela está no caminho dele) */
    is_on_the_way(elevator, call_floor, call_direction) == (
        (call_direction = up   & call_floor >= current_floor(elevator)) or
        (call_direction = down & call_floor <= current_floor(elevator))
    );

    /* verdadeiro quando o elevador precisaria inverter o sentido (ou
       já passou do andar) para atender a chamada: ele não está parado
       nem vem na mesma direção com a chamada no caminho */
    needs_detour(elevator, call_floor, call_direction) == (
        not(
            travel_direction(elevator) = idle or
            (travel_direction(elevator) = call_direction &
             is_on_the_way(elevator, call_floor, call_direction))
        )
    );

    /* converte o predicado needs_detour em 0 ou MAX_FLOOR, para uso
       aritmético (card de um conjunto por compreensão é o idioma
       clássico de B para transformar um predicado em inteiro sem
       usar IF-expressão) */
    detour_penalty(elevator, call_floor, call_direction) == (
        MAX_FLOOR * card({marker | marker : {0} & needs_detour(elevator, call_floor, call_direction)})
    );

    /* custo energético estimado de enviar o elevador para atender
       uma chamada de corredor no andar call_floor, direção call_direction:
         - elevador parado, ou já vindo na mesma direção sem ter
           passado do andar: custo = distância
         - caso contrário (precisaria inverter ou já passou):
           distância + penalidade extra (MAX_FLOOR) */
    dispatch_cost(elevator, call_floor, call_direction) == (
        distance(current_floor(elevator), call_floor) +
        detour_penalty(elevator, call_floor, call_direction)
    )

VARIABLES
    current_floor,          // andar atual de cada elevador
    travel_direction,       // direção atual de cada elevador (up, down, idle)
    doors_open,             // se as portas de cada elevador estão abertas
    cabin_requests,         // destinos pedidos de dentro das cabines (elevador |-> andar)
    pending_up_calls,       // chamadas de "subir" ainda sem elevador atribuído
    pending_down_calls,     // chamadas de "descer" ainda sem elevador atribuído
    assigned_up_calls,      // chamadas de "subir" já atribuídas (andar |-> elevador)
    assigned_down_calls     // chamadas de "descer" já atribuídas (andar |-> elevador)

INVARIANT
    current_floor       : ELEVATORS --> FLOORS    &
    travel_direction    : ELEVATORS --> DIRECTION &
    doors_open          : ELEVATORS --> BOOL      &
    cabin_requests      : ELEVATORS <-> FLOORS    &
    pending_up_calls    <: FLOORS                 &
    pending_down_calls  <: FLOORS                 &
    assigned_up_calls   : FLOORS +-> ELEVATORS    &
    assigned_down_calls : FLOORS +-> ELEVATORS    &

    /* uma chamada está pendente OU já atribuída, nunca as duas coisas
       -> garante que cada chamada é servida por um único elevador,
          qualquer que seja o número de elevadores do sistema */
    pending_up_calls   /\ dom(assigned_up_calls)   = {} &
    pending_down_calls /\ dom(assigned_down_calls) = {} &

    /* requisitos de segurança elevados de PRE para o INVARIANT:
       não existe (nem pode existir em nenhum estado observável)
       chamada de subida no último andar, nem de descida no térreo */
    pending_up_calls         <: 0..(MAX_FLOOR-1) &
    pending_down_calls       <: 1..MAX_FLOOR     &
    dom(assigned_up_calls)   <: 0..(MAX_FLOOR-1) &
    dom(assigned_down_calls) <: 1..MAX_FLOOR     &

    /* portas só abrem com o elevador parado */
    !elevator.(elevator : ELEVATORS & doors_open(elevator) = TRUE =>
               travel_direction(elevator) = idle)

ASSERTIONS
    /* ELEVATOR_COUNT>=1 (garantido em PROPERTIES da máquina de contexto)
       assegura que ELEVATORS é não-vazio, logo a busca por um elevador
       de custo mínimo em AssignElevatorUp/AssignElevatorDown e por um
       andar-alvo mais próximo em MoveOneStep sempre tem testemunha.
       Deixado explícito aqui como lema de apoio ao provador; pode
       exigir uma prova interativa simples em Atelier-B. */
    ELEVATOR_COUNT >= 1

INITIALISATION
    current_floor       := %elevator.(elevator : ELEVATORS | 0)     ||
    travel_direction    := %elevator.(elevator : ELEVATORS | idle)  ||
    doors_open          := %elevator.(elevator : ELEVATORS | FALSE) ||
    cabin_requests      := {} ||
    pending_up_calls    := {} ||
    pending_down_calls  := {} ||
    assigned_up_calls   := {} ||
    assigned_down_calls := {}

OPERATIONS

    /* ---------- Requisito 2: botões de andar (subir/descer) ---------- */

    RequestHallUp(requested_floor) =
        PRE
            requested_floor : FLOORS & requested_floor < MAX_FLOOR &
            requested_floor /: pending_up_calls &
            requested_floor /: dom(assigned_up_calls)
        THEN
            pending_up_calls := pending_up_calls \/ {requested_floor}
        END;

    is_valid <-- RequestHallUp_OK(requested_floor) =
        PRE
            requested_floor : INTEGER
        THEN
            IF requested_floor : FLOORS THEN
                is_valid := bool(
                    requested_floor < MAX_FLOOR &
                    requested_floor /: pending_up_calls &
                    requested_floor /: dom(assigned_up_calls)
                )
            ELSE
                is_valid := FALSE
            END
        END;

    RequestHallDown(requested_floor) =
        PRE
            requested_floor : FLOORS & requested_floor > 0 &
            requested_floor /: pending_down_calls &
            requested_floor /: dom(assigned_down_calls)
        THEN
            pending_down_calls := pending_down_calls \/ {requested_floor}
        END;

    is_valid <-- RequestHallDown_OK(requested_floor) =
        PRE
            requested_floor : INTEGER
        THEN
            IF requested_floor : FLOORS THEN
                is_valid := bool(
                    requested_floor > 0 &
                    requested_floor /: pending_down_calls &
                    requested_floor /: dom(assigned_down_calls)
                )
            ELSE
                is_valid := FALSE
            END
        END;

    /* ---- Requisitos 4 e 5: despacho de UM elevador, o mais eficiente ----
       O quantificador universal !other_elevator.(... => ...) percorre
       todos os elevadores, portanto a regra de escolha do mínimo custo
       é válida para qualquer número de elevadores configurado. ---- */

    AssignElevatorUp(call_floor) =
        PRE
            call_floor : pending_up_calls
        THEN
            ANY chosen_elevator WHERE
                chosen_elevator : ELEVATORS &
                !other_elevator.(other_elevator : ELEVATORS =>
                    dispatch_cost(chosen_elevator, call_floor, up) <=
                    dispatch_cost(other_elevator,  call_floor, up))
            THEN
                pending_up_calls  := pending_up_calls - {call_floor} ||
                assigned_up_calls := assigned_up_calls \/ {call_floor |-> chosen_elevator}
            END
        END;

    is_valid <-- AssignElevatorUp_OK(call_floor) =
        PRE
            call_floor : INTEGER
        THEN
            IF call_floor : FLOORS THEN
                is_valid := bool(call_floor : pending_up_calls)
            ELSE
                is_valid := FALSE
            END
        END;

    AssignElevatorDown(call_floor) =
        PRE
            call_floor : pending_down_calls
        THEN
            ANY chosen_elevator WHERE
                chosen_elevator : ELEVATORS &
                !other_elevator.(other_elevator : ELEVATORS =>
                    dispatch_cost(chosen_elevator, call_floor, down) <=
                    dispatch_cost(other_elevator,  call_floor, down))
            THEN
                pending_down_calls  := pending_down_calls - {call_floor} ||
                assigned_down_calls := assigned_down_calls \/ {call_floor |-> chosen_elevator}
            END
        END;

    is_valid <-- AssignElevatorDown_OK(call_floor) =
        PRE
            call_floor : INTEGER
        THEN
            IF call_floor : FLOORS THEN
                is_valid := bool(call_floor : pending_down_calls)
            ELSE
                is_valid := FALSE
            END
        END;

    /* ---------- Requisito 3: botões de destino dentro da cabine ---------- */

    RequestCabin(elevator, destination_floor) =
        PRE
            elevator : ELEVATORS & destination_floor : FLOORS &
            destination_floor /= current_floor(elevator) &
            destination_floor /: cabin_requests[{elevator}]
        THEN
            cabin_requests := cabin_requests \/ {elevator |-> destination_floor}
        END;

    is_valid <-- RequestCabin_OK(elevator, destination_floor) =
        PRE
            elevator : INTEGER & destination_floor : INTEGER
        THEN
            IF elevator : ELEVATORS & destination_floor : FLOORS THEN
                is_valid := bool(
                    destination_floor /= current_floor(elevator) &
                    destination_floor /: cabin_requests[{elevator}]
                )
            ELSE
                is_valid := FALSE
            END
        END;

    /* ---------- Requisito 3: elevador escolhe a melhor rota ---------- */

    MoveOneStep(elevator) =
        PRE
            elevator : ELEVATORS & doors_open(elevator) = FALSE
        THEN
            LET targets BE
                /* todos os andares que este elevador precisa visitar */
                targets = cabin_requests[{elevator}]       \/
                          assigned_up_calls~[{elevator}]   \/
                          assigned_down_calls~[{elevator}]
            IN
                IF targets /= {} & current_floor(elevator) /: targets THEN
                    ANY nearest_target WHERE
                        nearest_target : targets &
                        !other_target.(other_target : targets =>
                            distance(current_floor(elevator), nearest_target) <=
                            distance(current_floor(elevator), other_target))
                    THEN
                        IF nearest_target > current_floor(elevator) THEN
                            current_floor(elevator)    := current_floor(elevator) + 1 ||
                            travel_direction(elevator) := up
                        ELSE
                            current_floor(elevator)    := current_floor(elevator) - 1 ||
                            travel_direction(elevator) := down
                        END
                    END
                END
            END
        END;

    is_valid <-- MoveOneStep_OK(elevator) =
        PRE
            elevator : INTEGER
        THEN
            IF elevator : ELEVATORS THEN
                is_valid := bool(doors_open(elevator) = FALSE)
            ELSE
                is_valid := FALSE
            END
        END;

    /* ---------- chegada ao andar-alvo: abre portas e limpa chamadas ---------- */

    OpenDoors(elevator) =
        PRE
            elevator : ELEVATORS & doors_open(elevator) = FALSE &
            (
                current_floor(elevator) : cabin_requests[{elevator}]      or
                current_floor(elevator) : assigned_up_calls~[{elevator}]  or
                current_floor(elevator) : assigned_down_calls~[{elevator}]
            )
        THEN
            doors_open(elevator)       := TRUE                                                  ||
            cabin_requests             := cabin_requests      - {elevator |-> current_floor(elevator)} ||
            assigned_up_calls          := assigned_up_calls   - {current_floor(elevator) |-> elevator} ||
            assigned_down_calls        := assigned_down_calls - {current_floor(elevator) |-> elevator} ||
            travel_direction(elevator) := idle
        END;

    is_valid <-- OpenDoors_OK(elevator) =
        PRE
            elevator : INTEGER
        THEN
            IF elevator : ELEVATORS THEN
                is_valid := bool(
                    doors_open(elevator) = FALSE &
                    (
                        current_floor(elevator) : cabin_requests[{elevator}]      or
                        current_floor(elevator) : assigned_up_calls~[{elevator}]  or
                        current_floor(elevator) : assigned_down_calls~[{elevator}]
                    )
                )
            ELSE
                is_valid := FALSE
            END
        END;

    CloseDoors(elevator) =
        PRE
            elevator : ELEVATORS & doors_open(elevator) = TRUE
        THEN
            doors_open(elevator) := FALSE
        END;

    is_valid <-- CloseDoors_OK(elevator) =
        PRE
            elevator : INTEGER
        THEN
            IF elevator : ELEVATORS THEN
                is_valid := bool(doors_open(elevator) = TRUE)
            ELSE
                is_valid := FALSE
            END
        END

END
