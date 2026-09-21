# Smart Elevator

Especificação formal de um sistema inteligente de controle de múltiplos elevadores, desenvolvida para a disciplina de Métodos Formais.

## Sobre o projeto

O Smart Elevator modela o funcionamento de um conjunto de elevadores que atende solicitações de usuários em diferentes andares. A coordenação é descrita formalmente para que o comportamento do sistema possa ser analisado, validado e verificado segundo regras matemáticas precisas.

Neste projeto, o termo **sistema** refere-se ao modelo do controle dos elevadores, enquanto **especificação formal** refere-se à descrição desse sistema na linguagem do Método B.

## Objetivos

- Representar o estado dos elevadores, dos andares e das solicitações de transporte.
- Coordenar vários elevadores para atender chamadas de forma eficiente.
- Evitar situações inválidas, como um elevador estar em dois andares ao mesmo tempo.
- Garantir que as operações respeitem as invariantes definidas no modelo.
- Usar técnicas de Métodos Formais para aumentar a confiança na especificação.


## Abordagem formal

O sistema é descrito pelo **Método B**, uma abordagem baseada em máquinas abstratas, estados, operações, invariantes e provas de consistência.

De forma geral, o modelo contém:

- **Variáveis de estado:** posição, direção e situação de cada elevador, além das chamadas pendentes.
- **Invariantes:** propriedades que devem permanecer verdadeiras durante toda a execução do sistema.
- **Operações:** ações permitidas, como solicitar um elevador, mover um elevador e operar suas portas.
- **Pré-condições:** condições necessárias para que uma operação possa ser executada.
- **Inicialização:** estado inicial válido para todos os elevadores e solicitações.

As operações só podem alterar o estado quando suas condições são satisfeitas. Assim, o comportamento permitido pelo modelo é restrito às situações consideradas válidas pelas regras formais.


## Verificação

O modelo pode ser analisado com ferramentas compatíveis com o Método B, como o ProB ou o Atelier B, para explorar estados, verificar invariantes e apoiar a validação das operações.

## Contexto acadêmico

Este projeto foi desenvolvido como atividade da disciplina de Métodos Formais. Seu objetivo principal é aplicar especificação e verificação formal a um problema de controle concorrente: a coordenação de vários elevadores que compartilham chamadas, andares e recursos.

## Autores
- Marcos Beraldo Barros
- Elildes Fortaleza Santos

