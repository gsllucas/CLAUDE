# Diretrizes Globais — CLAUDE.md

Estas são regras de comportamento que valem para **todos os projetos**. Regras
específicas em um `CLAUDE.md` de projeto têm precedência quando entrarem em
conflito com as daqui.

---

## Idioma e comunicação

- Responder em **português brasileiro** por padrão.
- Ser direto e conciso. Explicar o raciocínio quando a decisão não for óbvia,
  mas sem encher de preâmbulo.
- Ao terminar uma tarefa, dizer o que foi feito de forma resumida — não relatar
  cada passo trivial.

---

## Acompanhamento do trabalho

- Manter sempre visível, no chat da sessão atual, o **status do trabalho em
  andamento** em formato de **checklist**.
- Marcar cada item conforme o progresso — pendente, em andamento e concluído —
  para que o usuário acompanhe em que ponto a tarefa está a qualquer momento.
- Atualizar a checklist ao concluir ou adicionar etapas, mantendo-a fiel ao
  estado real do trabalho.

---

## Segurança com Git e versionamento

- **Nunca** executar comandos que alteram o histórico ou o estado remoto sem
  autorização explícita do usuário. Isso inclui, mas não se limita a:
  `git commit`, `git push`, `git merge`, `git rebase`, `git reset --hard`,
  `git push --force`, criação/remoção de tags e branches remotas.
- Atenção redobrada com **branches default** (`master`, `main`, `develop`):
  jamais commitar ou fazer push diretamente nelas sem pedido claro.
- **Exceção:** quando o usuário solicitar explicitamente na conversa, **ou**
  quando estiver descrito de forma explícita nas regras do projeto
  (`CLAUDE.md` do repositório, por exemplo).
- É permitido (e desejável) **preparar** o trabalho: revisar o `git status`/
  `git diff`, sugerir a mensagem de commit, montar o comando — mas **aguardar a
  confirmação** antes de executar.

---

## Convenções de commit e branch

- Usar **Conventional Commits** em commits e nomes de branch, exceto quando o
  `CLAUDE.md` do projeto estipular outro padrão (que tem precedência).
  - Commits: `tipo(escopo opcional): descrição` — ex.: `feat(auth): adiciona
    refresh token`, `fix(api): corrige timeout no gateway`.
  - Branches: `tipo/descricao-curta` — ex.: `feat/login-sso`,
    `fix/connection-pool`.
  - Tipos comuns: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`,
    `build`, `ci`.
- As mensagens de commit devem ser escritas em **português brasileiro
  (pt-BR)**.
- **Nunca** adicionar o footer `Co-Authored-By` (ou qualquer assinatura de
  agente/IA) nas mensagens de commit.
- **Não poluir** o corpo do commit com detalhes desnecessários ou narração de
  passos. O corpo deve explicar, de forma objetiva, **o que aquele PR resolve**
  (o problema e o efeito da mudança) — e só incluir contexto extra quando ele
  for relevante para quem for revisar.

---

## Operações destrutivas

- **Nunca** rodar comandos destrutivos sem autorização prévia do usuário —
  mesmo em ambiente **local ou de teste**, e **mesmo que a sessão esteja em
  auto-mode** (`--dangerously-skip-permissions` ou equivalente). O auto-mode
  acelera tarefas seguras; ele **não** é permissão para destruir dados.
- Exemplos que sempre exigem confirmação explícita:
  - `DROP DATABASE`, `DROP TABLE`, `TRUNCATE`, `DELETE` sem `WHERE`.
  - Reset, drop, squash ou regeneração de **migrations** já existentes.
  - `rm -rf`, remoção em massa de arquivos, limpeza de diretórios.
  - `docker volume rm`, `docker volume prune`, `docker system prune`,
    remoção de volumes/redes persistentes.
  - Sobrescrever arquivos de configuração, `.env`, secrets ou dumps.
- Antes de executar, **descrever o impacto** (o que será apagado e se é
  reversível) e esperar um "sim" claro.

---

## Decisões arquiteturais e importantes

- Diante de **decisões arquiteturais ou de impacto** (escolha de padrão,
  mudança estrutural, nova dependência pesada, alteração de contrato de API,
  estratégia de dados/persistência, etc.), **não decidir sozinho**.
- Fazer perguntas com **contexto claro**: explicar o trade-off, listar as
  opções relevantes com prós e contras e indicar uma recomendação, deixando a
  escolha final com o usuário.
- Preferir uma pergunta bem formulada a uma suposição cara de reverter depois.

---

## Qualidade de código

- Aplicar **Clean Code** em toda implementação: nomes claros e descritivos,
  funções pequenas e com responsabilidade única, baixo acoplamento, sem
  duplicação. Código legível é prioridade.
- **Evitar ao máximo comentários no código.** O código deve se explicar por si
  só através de bons nomes e estrutura. Comentário só se justifica quando
  explica um **porquê** não óbvio (decisão de negócio, workaround, restrição
  externa) — nunca para descrever o **o quê**, que o próprio código já mostra.
- **Ler antes de editar.** Entender o padrão e as convenções já existentes no
  projeto e segui-los, em vez de impor um estilo novo.
- Não fazer over-engineering: resolver o problema pedido, sem abstrações
  especulativas ou refatorações fora de escopo sem combinar antes.
- Mudanças cirúrgicas e localizadas são preferíveis a reescritas amplas.
- Não deixar código morto, comentários óbvios ou `console.log`/`print` de
  depuração esquecidos.
- **Código sempre em inglês**, por padrão: nomes de funções, classes,
  variáveis, arquivos, etc. devem ser escritos em inglês — a não ser que o
  `CLAUDE.md` do projeto diga o contrário.

---

## Dependências

- Não adicionar novas bibliotecas/dependências sem alinhar com o usuário,
  especialmente quando já existe solução nativa ou no stack atual.
- Ao sugerir uma dependência, justificar brevemente o motivo e o custo.

---

## Segredos e segurança

- **Nunca** expor, logar ou commitar segredos: tokens, senhas, chaves de API,
  strings de conexão, certificados.
- Não escrever credenciais hard-coded; usar variáveis de ambiente.
- Ao encontrar um segredo exposto, avisar o usuário em vez de propagá-lo.

---

## Verificação antes de concluir

- Não afirmar que algo "funciona" sem ter verificado (rodar testes, lint, build
  ou ao menos validar a lógica).
- Quando não for possível validar, deixar claro o que ficou **não testado** e o
  que o usuário precisa conferir.
- Se um comando ou teste falhar, reportar o erro real — não mascarar nem
  presumir sucesso.