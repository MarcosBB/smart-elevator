# Regras de Negócio — Sistema de Elevador Inteligente (versão genérica, n elevadores)

> O número de andares e o de elevadores serão definidos pela edição dos valores das constantes **MAX_FLOOR** e **ELEVATOR_COUNT** respectivamente, na máquina de contexto, de modo que o sistema atenda genericamente a várias quantidades diferentes.
> Cada regra é rastreável a um elemento formal do modelo (parâmetro, variável, invariante ou operação).

## 1. Visão Geral

O sistema gerencia um grupo de **n elevadores** (n ≥ 1, configurável) que atendem dois tipos de solicitação — chamadas feitas nos andares (corredor) e chamadas feitas dentro da cabine (destino) — despachando, para cada chamada de corredor, exatamente um elevador, escolhido pelo critério de menor custo energético estimado entre os n elevadores disponíveis.

## 2. Atores

| Ator | Descrição |
|---|---|
| **Usuário no andar** | Aciona os botões de subir/descer no corredor. |
| **Usuário na cabine** | Aciona os botões de andar de destino dentro do elevador. |
| **Despachante (dispatcher)** | Componente do sistema que decide qual, entre os n elevadores, atende cada chamada de corredor. |
| **Elevador** | Executa o deslocamento e decide sua própria rota interna entre os destinos que já lhe foram atribuídos. |
| **Interface (aplicação cliente)** | Componente "burro", sem lógica de validação própria, que apenas repassa cliques/comandos às operações da máquina — por isso consulta as operações `_OK` antes de chamar a operação real. |

## 3. Regras de Negócio

### 3.1 Estrutura do sistema

**RN01 — Quantidade configurável de elevadores.**
O sistema opera com várias quantidades diferentes de elevadores, onde **ELEVATOR_COUNT** define a quantidade de elevadores.
*Modelo:* `ELEVATOR_COUNT` é uma **CONSTANT** da máquina de contexto `ElevatorContext`, restrita em `PROPERTIES` a `INTEGER & ELEVATOR_COUNT >= 1` (evita depender da preferência `MAXINT` do ProB, ao contrário de `NAT1`; a obrigação de prova correspondente é gerada e verificável no Atelier-B). `ElevatorSystem` a enxerga via `SEES ElevatorContext` e define, em `DEFINITIONS`, `ELEVATORS == 1..ELEVATOR_COUNT`.

**RN02 — Faixa de andares.**
Os andares são numerados de `0` (térreo) até `MAX_FLOOR`, também configurável por edifício.
*Modelo:* `MAX_FLOOR` é uma **CONSTANT** da máquina de contexto `ElevatorContext`, restrita em `PROPERTIES` a `INTEGER & MAX_FLOOR >= 1` e fixada por igualdade (`MAX_FLOOR = 9`, onde `9` pode ser qualquer valor concreto ≥ 1). `ElevatorSystem` define, em `DEFINITIONS`, `FLOORS == 0..MAX_FLOOR`.

### 3.2 Entrada de requisições

**RN03 — Duas origens de requisição.**
Uma requisição pode se originar de duas formas distintas:
(a) botão de corredor em um andar (subir ou descer);
(b) botão de destino dentro de uma cabine.
*Modelo:* operações `RequestHallUp` / `RequestHallDown` (origem a) e `RequestCabin` (origem b).

**RN04 — Botão de subir indisponível no último andar.**
O botão "subir" não pode ser acionado no andar mais alto (`MAX_FLOOR`), pois não há para onde subir.
*Modelo:* pré-condição `requested_floor < MAX_FLOOR` em `RequestHallUp`, reforçada como propriedade permanente do sistema pelo invariante `pending_up_calls <: 0..(MAX_FLOOR-1)` (nunca existe, em nenhum estado observável, uma chamada de subida pendente no último andar).

**RN05 — Botão de descer indisponível no térreo.**
O botão "descer" não pode ser acionado no andar `0`.
*Modelo:* pré-condição `requested_floor > 0` em `RequestHallDown`, reforçada pelo invariante `pending_down_calls <: 1..MAX_FLOOR`.

**RN06 — Não duplicação de chamadas de corredor.**
Uma chamada de subir/descer em um andar só pode ser registrada se ainda não existir pendente ou já atribuída para aquele mesmo andar e direção.
*Modelo:* pré-condições `requested_floor /: pending_up_calls & requested_floor /: dom(assigned_up_calls)` (e análogas para `down`).

**RN07 — Botão de destino na cabine.**
Dentro de um elevador, o usuário só pode solicitar um andar diferente do andar em que o elevador já está, e que ainda não conste como destino pendente daquele elevador.
*Modelo:* pré-condição `destination_floor /= current_floor(elevator) & destination_floor /: cabin_requests[{elevator}]` em `RequestCabin`.

### 3.3 Despacho de elevadores (atendimento único)

**RN08 — Uma chamada de corredor é atendida por exatamente um elevador, entre os n disponíveis.**
Cada chamada de subir/descer, uma vez atribuída, passa a ser de responsabilidade de um único elevador dentre os n existentes; nenhuma outra chamada pode ser atribuída ao mesmo par (andar, direção) até que essa seja atendida.
*Modelo:* `assigned_up_calls` e `assigned_down_calls` são **funções parciais** (`FLOORS +-> ELEVATORS`), o que impede, por construção — independentemente do valor de `ELEVATOR_COUNT` — que um mesmo andar/direção seja mapeado para mais de um elevador. A invariante `pending_up_calls ∩ dom(assigned_up_calls) = ∅` (e análoga para `down`) garante que uma chamada nunca está simultaneamente pendente e atribuída; os invariantes `dom(assigned_up_calls) <: 0..(MAX_FLOOR-1)` e `dom(assigned_down_calls) <: 1..MAX_FLOOR` garantem que nenhuma atribuição viola os limites de RN04/RN05.

**RN09 — Uma chamada é removida do estado "pendente" no momento da atribuição.**
Assim que um elevador é designado para uma chamada de corredor, ela deixa de aparecer como pendente para os demais elevadores.
*Modelo:* operações `AssignElevatorUp` / `AssignElevatorDown`, que movem o andar de `pending_up_calls`/`pending_down_calls` para `dom(assigned_up_calls)`/`dom(assigned_down_calls)` de forma atômica.

### 3.4 Roteamento interno do elevador

**RN10 — O elevador escolhe sua própria rota entre os destinos pendentes.**
Cada elevador, a cada movimento, avalia todos os seus alvos pendentes (destinos de cabine + chamadas de corredor a ele atribuídas) e se desloca em direção ao alvo mais próximo, evitando reversões desnecessárias.
*Modelo:* operação `MoveOneStep`, que calcula `targets = cabin_requests[{elevator}] ∪ assigned_up_calls~[{elevator}] ∪ assigned_down_calls~[{elevator}]` e escolhe o alvo de menor distância (comparada por `squared_distance`, que preserva a ordem entre distâncias sem gerar obrigação de boa definição).

**RN11 — Elevador não se move com as portas abertas.**
Um elevador só inicia deslocamento se suas portas estiverem fechadas.
*Modelo:* invariante `doors_open~[{TRUE}] <: travel_direction~[{idle}]` (todo elevador com porta aberta está parado); pré-condição `doors_open(elevator)=FALSE` em `MoveOneStep`.

**RN12 — Chegada ao andar-alvo abre as portas e limpa a chamada atendida.**
Ao alcançar um andar que é destino de cabine ou chamada de corredor atribuída a ele, o elevador abre as portas e remove essa chamada de sua lista de pendências.
*Modelo:* operação `OpenDoors`, que remove o par correspondente de `cabin_requests`, `assigned_up_calls` e `assigned_down_calls`.

**RN13 — Fechamento de portas antes de nova movimentação.**
As portas devem ser fechadas antes que o elevador possa se mover novamente.
*Modelo:* operação `CloseDoors`, pré-requisito implícito de `MoveOneStep` (que exige `doors_open=FALSE`).

### 3.5 Eficiência energética

**RN14 — Prioridade a elevadores já alinhados com a chamada.**
Na escolha do elevador para atender uma chamada de corredor, o sistema prioriza, entre os n elevadores, aqueles que já estão se movendo na mesma direção da chamada e ainda não ultrapassaram o andar solicitado — evitando desvios e reversões, que consomem mais energia.
*Modelo:* função `is_on_the_way(elevator, call_floor, call_direction)`, usada em `needs_detour` para determinar quando **não** aplicar penalidade em `dispatch_cost`.

**RN15 — Penalização de elevadores desalinhados.**
Um elevador parado longe do andar, ou em movimento na direção contrária, ou que já ultrapassou o andar solicitado, recebe uma penalidade adicional no cálculo de custo, tornando-o menos provável de ser escolhido.
*Modelo:* `needs_detour(elevator, call_floor, call_direction)` identifica essa condição; `detour_penalty(elevator, call_floor, call_direction) == MAX_FLOOR * BOOL_TO_NAT(bool(needs_detour(elevator, call_floor, call_direction)))` soma `MAX_FLOOR` à distância nesse caso (sem `IF`-como-expressão, para compatibilidade com o Atelier-B; `BOOL_TO_NAT = {FALSE |-> 0, TRUE |-> 1}` é constante da máquina de contexto); `dispatch_cost(elevator, call_floor, call_direction) == distance(current_floor(elevator), call_floor) + detour_penalty(elevator, call_floor, call_direction)`.

**RN16 — Seleção do elevador de menor custo entre os n disponíveis.**
Entre os n elevadores do sistema, o sistema sempre escolhe, para atender uma chamada de corredor, aquele com o menor valor de `dispatch_cost` para aquele andar e direção. Essa comparação é feita por um quantificador universal que percorre todo o conjunto `ELEVATORS`, portanto continua válida qualquer que seja o número de elevadores configurado.
*Modelo:* operações `AssignElevatorUp` / `AssignElevatorDown`, que selecionam `chosen_elevator` tal que `∀other_elevator·(other_elevator:ELEVATORS ⇒ dispatch_cost(chosen_elevator,call_floor,call_direction) ≤ dispatch_cost(other_elevator,call_floor,call_direction))`. A existência de tal `chosen_elevator` (viabilidade do `ANY`) depende de `ELEVATORS` ser não vazio, garantido pela cláusula `ASSERTIONS ELEVATOR_COUNT >= 1`.

### 3.6 Interface e validação de chamadas

**RN17 — A interface nunca chama uma operação fora de sua pré-condição.**
Como a interface (gráfica ou por prompt) não contém lógica de validação própria, cada operação que altera o estado do sistema possui uma operação-irmã de consulta que informa, sem alterar o estado, se a chamada seria válida naquele momento. A interface deve sempre consultar essa operação de verificação antes de invocar a operação real.
*Modelo:* para cada operação `Op` chamável pela interface, existe `is_valid <-- Op_OK(...)` (`RequestHallUp_OK`, `RequestHallDown_OK`, `AssignElevatorUp_OK`, `AssignElevatorDown_OK`, `RequestCabin_OK`, `MoveOneStep_OK`, `OpenDoors_OK`, `CloseDoors_OK`), com pré-condição praticamente total (apenas tipagem básica dos parâmetros) e corpo que devolve `TRUE`/`FALSE` conforme a pré-condição da operação real estaria satisfeita.

## 4. Tabela de Rastreabilidade

| Regra | Elemento do modelo B |
|---|---|
| RN01 | `CONSTANTS ELEVATOR_COUNT` (`ElevatorContext`, `PROPERTIES: INTEGER & >= 1`); `ELEVATORS == 1..ELEVATOR_COUNT` |
| RN02 | `CONSTANTS MAX_FLOOR` (`ElevatorContext`, `PROPERTIES: INTEGER & >= 1`, fixado por igualdade); `FLOORS == 0..MAX_FLOOR` |
| RN03 | `RequestHallUp`, `RequestHallDown`, `RequestCabin` |
| RN04 | pré-condição `requested_floor < MAX_FLOOR` (`RequestHallUp`) + invariante `pending_up_calls <: 0..(MAX_FLOOR-1)` |
| RN05 | pré-condição `requested_floor > 0` (`RequestHallDown`) + invariante `pending_down_calls <: 1..MAX_FLOOR` |
| RN06 | pré-condições de não duplicação |
| RN07 | pré-condição em `RequestCabin` |
| RN08 | tipo `FLOORS +-> ELEVATORS`; invariantes de disjunção e de domínio (`dom(assigned_up_calls) <: 0..(MAX_FLOOR-1)`, `dom(assigned_down_calls) <: 1..MAX_FLOOR`) |
| RN09 | `AssignElevatorUp`, `AssignElevatorDown` |
| RN10 | `MoveOneStep`, `targets` |
| RN11 | invariante `doors_open~[{TRUE}] <: travel_direction~[{idle}]` |
| RN12 | `OpenDoors` |
| RN13 | `CloseDoors` |
| RN14 | `is_on_the_way` (usada em `needs_detour`) |
| RN15 | `needs_detour`, `detour_penalty`, `BOOL_TO_NAT` |
| RN16 | quantificador de minimalidade em `AssignElevatorUp/Down`, sobre todo `ELEVATORS`; viabilidade garantida por `ASSERTIONS ELEVATOR_COUNT >= 1` |
| RN17 | operações `_OK` (`RequestHallUp_OK`, `RequestHallDown_OK`, `AssignElevatorUp_OK`, `AssignElevatorDown_OK`, `RequestCabin_OK`, `MoveOneStep_OK`, `OpenDoors_OK`, `CloseDoors_OK`) |
