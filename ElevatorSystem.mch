MACHINE ElevatorSystem

/* =====================================================================
   Sistema de Elevador Inteligente - Máquina Abstrata em B-Method
   -----------------------------------------------------------------
   
   PARA TESTAR COM UM NÚMERO DIFERENTE DE ELEVADORES OU ANDARES:
   basta editar os valores de MAX_FLOOR e NB_ELEVATORS nas definições
   (DEFINITIONS) e recarregar a máquina no ProB2-UI — nenhuma
   outra alteração no arquivo é necessária.

   (Nota: os valores são definições concretas para evitar a etapa de
   configuração de constantes do ProB2-UI.)

   Requisitos cobertos:
   1) N elevadores (configurável em DEFINITIONS)  -> NB_ELEVATORS
   2) ...
   ===================================================================== */
   
SETS
    DIRECTION = {up, down, none}

DEFINITIONS
    MAX_FLOOR == 9;                         /* <<< edite aqui o nº de andares */
    NB_ELEVATORS == 4;                      /* <<< edite aqui o nº de elevadores */
    FLOOR == 0..MAX_FLOOR;
    ELEVATOR == 1..NB_ELEVATORS;

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
    assign_down : FLOOR +-> ELEVATOR     

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
    Dummy = skip
    
END