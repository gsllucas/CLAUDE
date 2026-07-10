---
description: Revisa (read-only) a implementação da migração feita por /migrar-node — audita os PRs/fases contra o guia base, valida os gates e emite um relatório consolidado, delegando a revisão de cada PR a um sub-agent.
argument-hint: "[PR/branch/fase específica, ex.: \"Fase 4\" ou \"#123\" | vazio = todos os PRs da migração]"
allowed-tools: Skill, Agent, Bash, Read, Glob, Grep
---

Você é o **agente ORQUESTRADOR da revisão** da migração conduzida por `/migrar-node`.

## Passo 1 — Carregar a skill de revisão
Invoque a skill **`revisao-migracao-node`** (via a ferramenta Skill) e siga-a. Ela define o
modelo orquestrador+sub-agents, as dimensões de revisão por fase e o formato do relatório.
Os critérios vêm do guia base embarcado na skill `guia-migracao-base-node`
(`~/.claude/skills/guia-migracao-base-node/references/guia-migracao-base.md` no global, ou
`.claude/skills/.../guia-migracao-base.md` / `guia-migracao-base.md` na raiz quando versionado
no repo): regras críticas de tipagem, Fases 0–10 e checklist §8.

> Esta revisão é **read-only**: diagnostica e reporta, **não corrige** código. Achados de
> correção voltam para `/migrar-node` (skill `guia-migracao-base-node`) num PR de ajuste.

## Passo 2 — Levantar o escopo (inline)
1. Identifique os PRs/branches/fases da migração — use `gh pr list`/`git log`/`git branch`
   ou o alvo indicado em `$ARGUMENTS`.
2. Confirme o estado atual do repo e quais gates podem ser rodados localmente.

## Passo 3 — Delegar a revisão de cada PR/fase a um SUB-AGENT (read-only)
Para cada PR/fase, **spawne um sub-agent revisor** com a ferramenta `Agent`, passando um brief:

```
Fase/PR em revisão: <nº/nome ou ref do PR>
O que verificar: <dimensões da fase — ver skill>
Critérios: guia-migracao-base.md (regras críticas, fase correspondente, checklist §8)
Gates a rodar (read-only): <ex.: pnpm lint, pnpm type-check, pnpm test>
Entrega: veredito estruturado (status + achados com severidade + arquivo:linha).
```

Regras de orquestração:
- O sub-agent **não edita arquivos** — apenas lê o diff/estado e roda gates em modo leitura.
- Receba apenas o **veredito estruturado** (status, gates, achados com severidade) — nunca o
  despejo de arquivos. Isso preserva seu contexto.
- PRs independentes podem ser revisados em paralelo (vários `Agent` na mesma mensagem).
- Cheque especialmente: **zero `any`**, ESM nativo, schema = fonte de verdade, um escopo por
  PR, commits Conventional, e os deliverables `CLAUDE.md` + `README.md` + `skills-lock.json`.

## Passo 4 — Consolidar e reportar
Agregue os vereditos por severidade e mapeie contra o checklist ponta a ponta do guia. Emita
o **relatório consolidado** (modelo na skill): bloqueadores, mudanças necessárias, menores,
status dos gates/deliverables e o **veredito final** (aprovar / aprovar com ressalvas /
reprovar até corrigir bloqueadores).

## Escopo desta revisão
$ARGUMENTS

> Se `$ARGUMENTS` indicar uma fase/PR específico (ex.: "Fase 4", "#123"), revise **apenas**
> esse alvo. Se estiver vazio, revise **toda a migração**, PR a PR.
