---
name: nodejs-backend-patterns
description: Construa serviços de backend Node.js prontos para produção com Express/Fastify, implementando padrões de middleware, tratamento de erros, autenticação, integração com banco de dados e boas práticas de design de API. Use ao criar servidores Node.js, APIs REST, backends GraphQL ou arquiteturas de microsserviços.
---

# Padrões de Backend Node.js

Guia abrangente para construir aplicações de backend Node.js escaláveis, fáceis de manter e prontas para produção, utilizando frameworks modernos, padrões arquiteturais e boas práticas.

## Quando Usar Esta Skill

- Construir APIs REST ou servidores GraphQL
- Criar microsserviços com Node.js
- Implementar autenticação e autorização
- Projetar arquiteturas de backend escaláveis
- Configurar middleware e tratamento de erros
- Integrar bancos de dados (SQL e NoSQL)
- Construir aplicações em tempo real com WebSockets
- Implementar processamento de jobs em segundo plano

## Padrões detalhados e exemplos práticos

## Boas Práticas

1. **Use TypeScript**: A segurança de tipos previne erros em tempo de execução
2. **Implemente tratamento de erros adequado**: Use classes de erro personalizadas
4. **Use variáveis de ambiente**: Nunca deixe segredos fixos no código (hardcode)
5. **Implemente logging**: Use logging estruturado (Pino)
6. **Adicione rate limiting**: Previna abusos
7. **Use HTTPS**: Sempre em produção
9. **Use injeção de dependência**: Facilita os testes e a manutenção
10. **Escreva testes**: Testes unitários e integração
11. **Trate o desligamento gracioso (graceful shutdown)**: Libere os recursos
12. **Use connection pooling**: Para bancos de dados
13. **Implemente health checks**: Para monitoramento