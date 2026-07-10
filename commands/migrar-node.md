---
description: Conduz a migração/modernização deste repositório Node.js para o stack-alvo (Node LTS + TypeScript + ESM + esbuild + Fastify/Apollo 5 + pnpm + Vitest + oxlint + pino + Codegen), fase a fase.
argument-hint: "[fase específica, ex.: \"Fase 4\" | vazio = pipeline completo]"
allowed-tools: Skill, Agent, Bash, Read, Write, Edit, Glob, Grep
---

Você é o **agente responsável** pela migração deste repositório.

## Passo 1 — Carregar a skill
Invoque a skill **`guia-migracao-base-node`** (via a ferramenta Skill) e siga-a como fonte de
verdade do processo. Ela define o stack-alvo, o inventário, os pontos de decisão, as regras
críticas de tipagem, as fases, os gates e o **modelo de execução**. Referência detalhada:
`guia-migracao-base.md`.

## Passo 2 — Inventário e decisões
Antes de implementar, defina a estratégia:
1. Levante o **inventário** real do repositório (Node atual, gerenciador de pacotes,
   módulos, framework, ORM, testes, lint, logging, libs internas). Use ferramentas
   read-only (`knip`, `pnpm outdated`, grep por padrões legados).
2. Consolide os **pontos de decisão** com o usuário quando houver ambiguidade que mude o
   escopo (TS total vs. incremental, ORM major, serviços federados). Não invente: pergunte.
3. Verifique **bloqueadores** (libs internas sem versão p/ o Node alvo) antes de prosseguir.

## Passo 3 — Executar as fases
Conduza as fases do guia na ordem, respeitando as dependências, seguindo o modelo de execução
e os gates definidos pela skill. **Valide o gate** de cada fase (build/lint/type-check/testes
verdes) antes de liberar a próxima e mantenha a visão de ponta a ponta: ordem dos PRs, decisões
pendentes e bloqueadores.

## Passo 4 — Fase 10: documentação (`CLAUDE.md` + `README.md`)
Garanta que a migração inclua a **criação/atualização** de ambos os arquivos na raiz,
refletindo o stack pós-migração (se já existirem, atualize removendo o stack legado):
- **`CLAUDE.md`** (Fase 10.a) — escopo/regras para agentes.
- **`README.md`** (Fase 10.b) — porta de entrada humana: **introdução/resumo** do repositório
  e **fluxo de setup explícito** (passo a passo com comandos exatos), scripts, Docker, testes
  e contribuição.

## Passo 5 — Fechamento
Ao final, rode o **checklist ponta a ponta** da skill e reporte ao usuário um resumo
consolidado: PRs abertos por fase, gates verdes, riscos/bloqueadores e pendências.

## Passo 6 — Revisão automática (encadeia `/revisar-migracao`)
Assim que a migração concluir (todas as fases + Fase 10 + checklist), **dispare a revisão
automaticamente** — não espere o usuário pedir. Para preservar o contexto desta janela,
**delegue a revisão a um único sub-agent** (ferramenta `Agent`) com este brief:

```
Tarefa: revisar (read-only) a migração recém-concluída neste repositório.
Carregue e siga a skill `revisao-migracao-node` (equivalente a rodar `/revisar-migracao`).
Escopo: os PRs/fases produzidos nesta execução (lista abaixo) + checklist §8 do guia base.
PRs/fases desta execução: <preencher com os branches/PRs desta execução>
Entrega: o RELATÓRIO CONSOLIDADO da skill de revisão (bloqueadores, mudanças necessárias,
menores, status de gates/deliverables e veredito final) — texto estruturado, não o diff.
```

- O sub-agent revisor é **read-only** (não corrige código); ele só diagnostica e devolve o
  relatório.
- Receba de volta **apenas o relatório consolidado** e repasse-o ao usuário junto do resumo
  do Passo 5 — assim a entrega de `/migrar-node` já vem com a revisão feita.
- Se a revisão apontar **bloqueadores**, liste-os e proponha um PR de ajuste por fase (de
  volta a este fluxo de execução); **não** corrija dentro do sub-agent de revisão.

> Para revisar uma fase isolada, o usuário ainda pode rodar `/revisar-migracao <fase>`
> manualmente — o Passo 6 é o encadeamento automático do fluxo completo.

## Escopo desta execução
$ARGUMENTS

> Se `$ARGUMENTS` indicar uma fase específica (ex.: "Fase 4"), execute **apenas** essa fase
> e reporte. Se estiver vazio, conduza o **pipeline completo**, fase a fase, validando os
> gates entre elas.
