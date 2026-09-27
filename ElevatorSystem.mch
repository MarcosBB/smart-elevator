MACHINE ElevatorSystem

/* =====================================================================
   Sistema de Elevador Inteligente - Máquina Abstrata em B-Method
   -----------------------------------------------------------------

   MAX_FLOOR e NB_ELEVATORS agora são CONSTANTS da máquina de contexto
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
    FLOOR == 0..MAX_FLOOR;
    ELEVATOR == 1..NB_ELEVATORS;

    /* distância absoluta entre dois andares
       (max{xx-yy,yy-xx} evita IF-como-expressão, que só o ProB aceita
       e o Atelier-B rejeita) */
    abs_diff(xx,yy) == max({xx-yy,yy-xx});

    /* o elevador ee, na direção dd, ainda não "passou" pelo andar ff */
    is_aligned(ee,ff,dd) == (
        (dd=up   & ff >= position(ee)) or
        (dd=down & ff <= position(ee))
    );

    /* verdadeiro quando o elevador ee precisaria inverter (ou já passou)
       para atender uma chamada no andar ff, direção dd */
    is_penalized(ee,ff,dd) == (
        not(direction(ee) = none or (direction(ee) = dd & is_aligned(ee,ff,dd)))
    );

    /* converte o predicado is_penalized em 0 ou 1, para uso aritmético
       (card de um conjunto por compreensão é o idioma clássico de B
       para transformar um predicado em inteiro sem usar IF-expressão) */
    penalty(ee,ff,dd) == (
        MAX_FLOOR * card({xx | xx : {0} & is_penalized(ee,ff,dd)})
    );

    /* custo energético estimado de enviar o elevador ee para atender
       uma chamada de corredor no andar ff, direção dd:
         - elevador parado, ou já alinhado (mesma direção, ainda não
           passou): custo = distância
         - elevador desalinhado (precisaria inverter ou já passou):
           distância + penalidade extra (MAX_FLOOR) */
    cost(ee,ff,dd) == (
        abs_diff(position(ee),ff) + penalty(ee,ff,dd)
    )

VARIABLES
    position,       // andar atual de cada elevador
    direction,      // direção atual de cada elevador (up, down, none)
    door_open,      // estado das portas de cada elevador
    cabin_calls,    // destinos pedidos de dentro dos elevadores
    hall_up,        // chamadas de "subir" pendentes (não atribuídas)
    hall_down,      // chamadas de "descer" pendentes (não atribuídas)
    assign_up,      // chamadas de "subir" já atribuídas a um elevador
    assign_down     // chamadas de "descer" já atribuídas a um elevador

INVARIANT
    position    : ELEVATOR --> FLOOR    &
    direction   : ELEVATOR --> DIRECTION &
    door_open   : ELEVATOR --> BOOL      &
    cabin_calls : ELEVATOR <-> FLOOR     &
    hall_up     <: FLOOR                 &
    hall_down   <: FLOOR                 &
    assign_up   : FLOOR +-> ELEVATOR     &
    assign_down : FLOOR +-> ELEVATOR     &

    /* uma chamada está pendente OU já atribuída, nunca as duas coisas
       -> garante que cada chamada é servida por um único elevador,
          qualquer que seja o número de elevadores do sistema */
    hall_up   /\ dom(assign_up)   = {}   &
    hall_down /\ dom(assign_down) = {}   &

    /* requisitos de segurança elevados de PRE para o INVARIANT:
       não existe (nem pode existir em nenhum estado observável)
       chamada de subida no último andar, nem de descida no térreo */
    hall_up          <: 0..(MAX_FLOOR-1) &
    hall_down        <: 1..MAX_FLOOR     &
    dom(assign_up)   <: 0..(MAX_FLOOR-1) &
    dom(assign_down) <: 1..MAX_FLOOR     &

    /* portas só abrem com o elevador parado */
    !ee.(ee:ELEVATOR & door_open(ee)=TRUE => direction(ee)=none)

ASSERTIONS
    /* NB_ELEVATORS>=1 (garantido em PROPERTIES da máquina de contexto)
       assegura que ELEVATOR é não-vazio, logo a busca por um elevador
       de custo mínimo em AssignElevatorUp/AssignElevatorDown e por um
       andar-alvo mais próximo em MoveOneStep sempre tem testemunha.
       Deixado explícito aqui como lema de apoio ao provador; pode
       exigir uma prova interativa simples em Atelier-B. */
    NB_ELEVATORS >= 1

INITIALISATION
    position    := %ee.(ee:ELEVATOR|0)      ||
    direction   := %ee.(ee:ELEVATOR|none)   ||
    door_open   := %ee.(ee:ELEVATOR|FALSE)  ||
    cabin_calls := {}                        ||
    hall_up     := {}                        ||
    hall_down   := {}                        ||
    assign_up   := {}                        ||
    assign_down := {}

OPERATIONS

    /* ---------- Requisito 2: botões de andar (subir/descer) ---------- */

    RequestHallUp(ff) =
        PRE
            ff : FLOOR & ff < MAX_FLOOR &
            ff /: hall_up & ff /: dom(assign_up)
        THEN
            hall_up := hall_up \/ {ff}
        END;

    bb <-- RequestHallUp_OK(ff) =
        PRE
            ff : INTEGER
        THEN
            IF ff : FLOOR THEN
                bb := bool(ff < MAX_FLOOR & ff /: hall_up & ff /: dom(assign_up))
            ELSE
                bb := FALSE
            END
        END;

    RequestHallDown(ff) =
        PRE
            ff : FLOOR & ff > 0 &
            ff /: hall_down & ff /: dom(assign_down)
        THEN
            hall_down := hall_down \/ {ff}
        END;

    bb <-- RequestHallDown_OK(ff) =
        PRE
            ff : INTEGER
        THEN
            IF ff : FLOOR THEN
                bb := bool(ff > 0 & ff /: hall_down & ff /: dom(assign_down))
            ELSE
                bb := FALSE
            END
        END;

    /* ---- Requisitos 4 e 5: despacho de UM elevador, o mais eficiente ----
       O quantificador universal !ee2.(ee2:ELEVATOR => ...) percorre todos
       os n elevadores, portanto a regra de escolha do mínimo custo é
       válida para qualquer número de elevadores configurado. ---- */

    AssignElevatorUp(ff) =
        PRE
            ff : hall_up
        THEN
            ANY ee WHERE
                ee : ELEVATOR &
                !ee2.(ee2:ELEVATOR => cost(ee,ff,up) <= cost(ee2,ff,up))
            THEN
                hall_up   := hall_up - {ff}          ||
                assign_up := assign_up \/ {ff|->ee}
            END
        END;

    bb <-- AssignElevatorUp_OK(ff) =
        PRE
            ff : INTEGER
        THEN
            IF ff : FLOOR THEN
                bb := bool(ff : hall_up)
            ELSE
                bb := FALSE
            END
        END;

    AssignElevatorDown(ff) =
        PRE
            ff : hall_down
        THEN
            ANY ee WHERE
                ee : ELEVATOR &
                !ee2.(ee2:ELEVATOR => cost(ee,ff,down) <= cost(ee2,ff,down))
            THEN
                hall_down   := hall_down - {ff}          ||
                assign_down := assign_down \/ {ff|->ee}
            END
        END;

    bb <-- AssignElevatorDown_OK(ff) =
        PRE
            ff : INTEGER
        THEN
            IF ff : FLOOR THEN
                bb := bool(ff : hall_down)
            ELSE
                bb := FALSE
            END
        END;

    /* ---------- Requisito 3: botões de destino dentro da cabine ---------- */

    RequestCabin(ee,ff) =
        PRE
            ee : ELEVATOR & ff : FLOOR &
            ff /= position(ee) & ff /: cabin_calls[{ee}]
        THEN
            cabin_calls := cabin_calls \/ {ee|->ff}
        END;

    bb <-- RequestCabin_OK(ee,ff) =
        PRE
            ee : INTEGER & ff : INTEGER
        THEN
            IF ee : ELEVATOR & ff : FLOOR THEN
                bb := bool(ff /= position(ee) & ff /: cabin_calls[{ee}])
            ELSE
                bb := FALSE
            END
        END;

    /* ---------- Requisito 3: elevador escolhe a melhor rota ---------- */

    MoveOneStep(ee) =
        PRE
            ee : ELEVATOR & door_open(ee) = FALSE
        THEN
            LET targets BE
                targets = cabin_calls[{ee}] \/ assign_up~[{ee}] \/ assign_down~[{ee}]
            IN
                IF targets /= {} & position(ee) /: targets THEN
                    ANY nf WHERE
                        nf : targets &
                        !ff2.(ff2:targets => abs_diff(position(ee),nf) <= abs_diff(position(ee),ff2))
                    THEN
                        IF nf > position(ee) THEN
                            position(ee)  := position(ee) + 1 ||
                            direction(ee) := up
                        ELSE
                            position(ee)  := position(ee) - 1 ||
                            direction(ee) := down
                        END
                    END
                END
            END
        END;

    bb <-- MoveOneStep_OK(ee) =
        PRE
            ee : INTEGER
        THEN
            IF ee : ELEVATOR THEN
                bb := bool(door_open(ee) = FALSE)
            ELSE
                bb := FALSE
            END
        END;

    /* ---------- chegada ao andar-alvo: abre portas e limpa chamadas ---------- */

    OpenDoors(ee) =
        PRE
            ee : ELEVATOR & door_open(ee) = FALSE &
            (
                position(ee) : cabin_calls[{ee}]     or
                position(ee) : assign_up~[{ee}]      or
                position(ee) : assign_down~[{ee}]
            )
        THEN
            door_open(ee) := TRUE                                  ||
            cabin_calls   := cabin_calls - {ee|->position(ee)}     ||
            assign_up     := assign_up   - {position(ee)|->ee}     ||
            assign_down   := assign_down - {position(ee)|->ee}     ||
            direction(ee) := none
        END;

    bb <-- OpenDoors_OK(ee) =
        PRE
            ee : INTEGER
        THEN
            IF ee : ELEVATOR THEN
                bb := bool(
                        door_open(ee) = FALSE &
                        (
                            position(ee) : cabin_calls[{ee}]  or
                            position(ee) : assign_up~[{ee}]   or
                            position(ee) : assign_down~[{ee}]
                        )
                      )
            ELSE
                bb := FALSE
            END
        END;

    CloseDoors(ee) =
        PRE
            ee : ELEVATOR & door_open(ee) = TRUE
        THEN
            door_open(ee) := FALSE
        END;

    bb <-- CloseDoors_OK(ee) =
        PRE
            ee : INTEGER
        THEN
            IF ee : ELEVATOR THEN
                bb := bool(door_open(ee) = TRUE)
            ELSE
                bb := FALSE
            END
        END

END
