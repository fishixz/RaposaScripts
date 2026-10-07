# RaposaScripts

Assistente de escrita com IA em um único script Lua.

## Fluxo

1. Executa o `RaposaAI.lua`.
2. Abre uma janela compacta, arrastável e redimensionável.
3. O usuário cola as próprias chaves Gemini, uma por linha.
4. O script valida as chaves informadas.
5. Uma chave válida é usada durante a sessão.
6. O chat é liberado.
7. Respostas da IA podem ser copiadas com dois cliques/toques.

As chaves ficam somente em memória durante a execução e não são gravadas no arquivo.

## Interface

- janela que não ocupa a tela inteira;
- arrastar pela barra superior;
- redimensionar pelo canto inferior direito;
- bolinha lateral para esconder/mostrar;
- chat com histórico curto;
- respostas curtas e objetivas por padrão;
- Google Search habilitado para perguntas que dependam de informações atuais.

## Rate limit

Quando a API responder com `429 RESOURCE_EXHAUSTED`, o script informa o tempo de espera no chat e tenta novamente automaticamente com a chave ativa, respeitando `Retry-After` quando o ambiente disponibiliza esse cabeçalho.

O script não alterna automaticamente entre chaves para contornar quotas ou limites de uso.
