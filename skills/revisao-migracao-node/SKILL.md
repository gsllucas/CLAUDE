---
name: revisao-migracao-node
description: >
  Revisão/auditoria da implementação de uma migração Node.js conduzida pela skill
  `guia-migracao-base-node` (via `/migrar-node`). Use esta skill quando o usuário pedir para
  revisar, auditar ou validar os PRs/fases da migração, ou conferir se o repositório está
  aderente ao stack-alvo (Node LTS + TypeScript + ESM + esbuild + Fastify/Apollo 5 + pnpm +
  Vitest + oxlint + pino + Codegen). A revisão é read-only e orquestrada: cada PR/fase é
  revisado por um sub-agent dedicado, para não degradar o contexto da janela principal.
metadata:
  author: curia
  version: "1.0.0"
allowed-tools: Agent Bash Read Glob Grep
---

# Revisão da Migração Node.js → Node LTS + TypeScript

Skill de **revisão** (read-only) da implementação produzida pela migração orquestrada por
`/migrar-node` (skill `guia-migracao-base-node`). Verifica correção, completude e aderência
ao guia base por fase, fase a fase.

> **Fonte de verdade dos critérios:** o guia base embarcado na skill de execução —
> [`../guia-migracao-base-node/references/guia-migracao-base.md`](../guia-migracao-base-node/references/guia-migracao-base.md)
> (ou `guia-migracao-base.md` na raiz). Em especial: as **Regras críticas de tipagem**, as
> **Fases 0–10** e o **Checklist ponta a ponta** (seção 8). Esta skill não redefine os
> padrões — apenas os audita.

## Quando usar
- O usuário pede para **revisar/auditar/validar** a migração ou os PRs abertos por `/migrar-node`.
- Conferir se o repositório está **aderente ao stack-alvo** após a migração.
- Gate de qualidade antes de aprovar/mergear os PRs da migração.

> Esta skill **não corrige** código — ela **diagnostica e reporta**. A correção volta para a
> skill de execução (`guia-migracao-base-node`) num PR próprio.

---

## Modelo de revisão: ORQUESTRADOR + SUB-AGENTS (read-only)

Mesmo princípio da skill de execução: o agente principal **orquestra** e **delega a revisão
de cada PR/fase a um sub-agent dedicado**. O sub-agent lê o diff e o estado do repo, roda os
gates e retorna **apenas um veredito estruturado** — preservando o contexto da janela
principal.

**Orquestrador (janela principal):**
1. Levanta o **escopo da revisão**: quais PRs/branches/fases existem (via `gh`/`git`) ou o
   alvo passado em `$ARGUMENTS`.
2. Para cada PR/fase, **spawna um sub-agent revisor** (read-only) com um brief autocontido.
3. Coleta os vereditos, **consolida** por severidade e mapeia contra o checklist do guia.
4. Emite o **relatório final**: aprovados, mudanças necessárias, bloqueadores.

**Sub-agent revisor (contexto isolado):**
- Revisa **uma** fase/PR contra as dimensões abaixo. Roda os gates relevantes em modo
  read-only (sem alterar arquivos). Retorna veredito curto e estruturado, com achados
  citando arquivo:linha.

**Brief para o sub-agent revisor:**
```
Fase/PR em revisão: <nº/nome ou ref do PR>
O que verificar: <dimensões aplicáveis desta fase — ver abaixo>
Critérios: guia-migracao-base.md (regras críticas, fase correspondente, checklist §8)
Gates a rodar (read-only): <ex.: pnpm lint, pnpm type-check, pnpm test>
Entrega: veredito estruturado (status + achados com severidade + arquivo:linha).
```

**Veredito que o sub-agent retorna:**
```
Fase/PR: <ref>            Status: <aprovado | mudanças necessárias | bloqueado>
Gates: <pnpm lint ✓ | type-check ✗ | test ✓ | ...>
Achados:
  - [bloqueador|maior|menor] <descrição> — <arquivo:linha> — <correção sugerida>
Aderência ao guia: <ok | desvios>
```

---

## Dimensões de revisão

**Transversais (toda a migração):**
- **Regras críticas de tipagem:** zero `any` — `grep -rn ": any\b\|as any\|<any>" src` deve
  vir vazio; `typescript/no-explicit-any` ativo no oxlint. Tipos explícitos em models,
  `context`, resolvers, payloads. `tsconfig` com `strict: true`.
- **ESM nativo:** `"type":"module"`; sem `require(`/`__dirname` cru; loaders de `.graphql` em runtime.
- **Schema GraphQL = fonte de verdade:** tipos via Codegen, não duplicados à mão; sem drift.
- **Processo:** **uma mudança estrutural por PR**; commits **Conventional**; sem resíduo do
  stack legado (npm/yarn, Babel, Mocha, `console.*`, Apollo 2/3, `sequelize.import`).

**Por fase (0–10):**
| Fase | Verificar |
|---|---|
| 0 | `.nvmrc`/`engines.node` no alvo; libs internas compatíveis; `skills-lock.json` coerente |
| 1 | `pnpm-lock.yaml` (sem `package-lock`/`yarn.lock`); husky/nodemon removidos; oxlint configurado |
| 2 | `"type":"module"`, sem `babel*`; `esbuild.config.mjs`; `start` aponta p/ `dist/` |
| 3 | ORM/driver na versão alvo; sem `sequelize.import`; migrations rodam |
| 4 | Fastify + Apollo 5 via `@as-integrations/fastify`; auth/diretivas/data sources preservados |
| 5 | `fetch` nativo; `pino` (sem `console.*`/`winston`/`morgan`); deps mortas removidas (knip) |
| 6 | Vitest + coverage; testes migrados e **verdes** |
| 7 | Dockerfile `node:<alvo>` + pnpm; CI com stage lint + type-check + testes |
| 8 | `typescript@<alvo>`, `tsconfig` strict; `.ts`; `tsx watch`; `tsc --noEmit` limpo |
| 9 | Codegen (server-preset) gera sem drift; resolvers tipados |
| 10 | `CLAUDE.md` (escopo/regras) **e** `README.md` (intro + setup explícito) atualizados, sem stack legado |

**Gates ponta a ponta (replicar o checklist §8 do guia):**
`pnpm install --frozen-lockfile` · `pnpm lint` (incl. `no-explicit-any`) · `pnpm type-check`
· `pnpm codegen` (sem drift) · `pnpm build` + `pnpm start` · `pnpm test` · healthcheck 200 ·
contrato externo sem quebra · imagem Docker builda + migrations.

---

## Relatório consolidado (saída final do orquestrador)

```
# Revisão da migração — <repo>

Resumo: <X PRs revisados · Y aprovados · Z com mudanças · W bloqueados>

## Bloqueadores (impedem merge)
- [fase/PR] <achado> — <arquivo:linha> — <correção>

## Mudanças necessárias (maiores)
- ...

## Menores / sugestões
- ...

## Checklist ponta a ponta
- [x] pnpm lint  [ ] type-check  ...   (status real dos gates)
- [ ] CLAUDE.md   [ ] README.md   [ ] skills-lock.json

## Veredito
<aprovar | aprovar com ressalvas | reprovar até corrigir bloqueadores>
```

> Achados de correção devem voltar para a skill **`guia-migracao-base-node`** (um PR de
> ajuste por fase), nunca corrigidos aqui — esta revisão é read-only.
