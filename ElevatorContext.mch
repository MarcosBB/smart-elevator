MACHINE ElevatorContext

/* =====================================================================
   Máquina de contexto - Sistema de Elevador Inteligente
   -----------------------------------------------------------------
   Componentes estruturantes (SETS, CONSTANTS) do sistema, definidos
   com PROPERTIES para que o Atelier-B gere e verifique as obrigações
   de prova correspondentes (ex.: ELEVATOR_COUNT >= 1), em vez de macros
   DEFINITIONS não verificadas.

   PARA TESTAR COM UM NÚMERO DIFERENTE DE ELEVADORES OU ANDARES:
   basta editar os valores de MAX_FLOOR e ELEVATOR_COUNT em PROPERTIES
   abaixo. Como os valores são fixados por igualdade, o ProB2-UI não
   pede configuração manual de constantes ao carregar a máquina.
   ===================================================================== */

SETS
    /* idle = elevador parado (sem direção de movimento) */
    DIRECTION = {up, down, idle}

CONSTANTS
    MAX_FLOOR,          // último andar (os andares vão de 0 a MAX_FLOOR)
    ELEVATOR_COUNT      // quantidade de elevadores do prédio

PROPERTIES
    /* usa INTEGER + >=1 em vez de NAT1: NAT1 é o conjunto de naturais
       IMPLEMENTÁVEIS (1..MAXINT), dependente da preferência MAXINT do
       ProB — se MAXINT estiver configurado abaixo do valor escolhido
       aqui, as PROPERTIES ficam insatisfazíveis. Com INTEGER + >=1
       a restrição não depende de nenhuma preferência da ferramenta. */
    MAX_FLOOR      : INTEGER & MAX_FLOOR      >= 1  &
    ELEVATOR_COUNT : INTEGER & ELEVATOR_COUNT >= 1  &
    MAX_FLOOR      = 9                              &   /* <<< edite aqui o nº de andares (>=1) */
    ELEVATOR_COUNT = 4                                  /* <<< edite aqui o nº de elevadores (>=1) */

END
