MACHINE ElevatorContext

/* =====================================================================
   Máquina de contexto - Sistema de Elevador Inteligente
   -----------------------------------------------------------------
   Componentes estruturantes (SETS, CONSTANTS) do sistema, definidos
   com PROPERTIES para que o Atelier-B gere e verifique as obrigações
   de prova correspondentes (ex.: NB_ELEVATORS >= 1), em vez de macros
   DEFINITIONS não verificadas.

   PARA TESTAR COM UM NÚMERO DIFERENTE DE ELEVADORES OU ANDARES:
   basta editar os valores de MAX_FLOOR e NB_ELEVATORS em PROPERTIES
   abaixo. Como os valores são fixados por igualdade, o ProB2-UI não
   pede configuração manual de constantes ao carregar a máquina.
   ===================================================================== */

SETS
    DIRECTION = {up, down, none}

CONSTANTS
    MAX_FLOOR,
    NB_ELEVATORS

PROPERTIES
    /* usa INTEGER + >=1 em vez de NAT1: NAT1 é o conjunto de naturais
       IMPLEMENTÁVEIS (1..MAXINT), dependente da preferência MAXINT do
       ProB — se MAXINT estiver configurado abaixo do valor escolhido
       aqui, as PROPERTIES ficam insatisfazíveis. Com INTEGER + >=1
       a restrição não depende de nenhuma preferência da ferramenta. */
    MAX_FLOOR    : INTEGER & MAX_FLOOR    >= 1  &
    NB_ELEVATORS : INTEGER & NB_ELEVATORS >= 1  &
    MAX_FLOOR    = 9                            &   /* <<< edite aqui o nº de andares (>=1) */
    NB_ELEVATORS = 4                                /* <<< edite aqui o nº de elevadores (>=1) */

END
