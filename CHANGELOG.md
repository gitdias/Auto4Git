# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Planejado
- Suporte para múltiplos repositórios remotos
- Modo dry-run para visualizar operações sem executar
- Integração com GitLab e Bitbucket
- Configuração via arquivo .auto4gitrc
- Modo verbose para debugging detalhado
- Suporte para hooks personalizados (pre-commit, post-push)
- Validação de Conventional Commits
- Geração automática de CHANGELOG

---

## [0.0.2] - 2026-02-17

### 🎉 Modo Interativo Implementado

Esta versão marca uma evolução significativa do Auto4Git, introduzindo o modo interativo como padrão e mantendo total compatibilidade com a versão anterior.

### Adicionado

#### Interface e Usabilidade
- **Modo interativo como padrão**
  - Execução simplificada com `./auto4git.sh` (sem argumentos obrigatórios)
  - Fluxo guiado passo a passo para tag, mensagem da tag e mensagem do commit
  - Interface visual aprimorada com banners ASCII e cores
  - Progressão clara com indicadores [1/5], [2/5], etc.

- **Input multi-linha melhorado**
  - Suporte para colar texto diretamente no terminal
  - Finalização com `Ctrl+D`
  - Alternativa: informar caminho de arquivo
  - Detecção inteligente entre texto direto e caminho de arquivo

- **Tutorial SSH didático completo**
  - Exibido automaticamente em caso de falha de autenticação
  - Passo a passo visual com 5 etapas detalhadas
  - Formatação em caixas coloridas para melhor legibilidade
  - Comandos prontos para copiar e colar
  - Links diretos para configuração no GitHub

#### Validações e Segurança
- **Validação de formato de tag**
  - Verifica versionamento semântico (v1.2.3, v2.0.0-beta, etc.)
  - Detecta tags duplicadas antes de criar
  - Mensagens de erro claras com sugestões de correção

- **Tag obrigatória**
  - Tag agora é sempre obrigatória (tanto em modo interativo quanto legado)
  - Sempre cria tag anotada com mensagem dedicada
  - Separação clara entre mensagem da tag e mensagem do commit

- **Melhorias na validação SSH**
  - Timeout de 10 segundos para evitar travamentos
  - Detecção mais robusta de falhas de autenticação
  - Mensagens de erro mais descritivas

#### Compatibilidade
- **Novo argumento `--tagmsg`**
  - Mantém compatibilidade total com v0.0.1
  - Sintaxe legado: `--tag <versão> --tagmsg <arquivo> --msg <arquivo>`
  - Todos os três argumentos são obrigatórios no modo legado

- **Detecção automática de modo**
  - Sem argumentos: modo interativo
  - Com argumentos: modo legado (compatibilidade v0.0.1)

### Modificado

#### Interface Visual
- **Banner inicial redesenhado**
  - Formato em caixa ASCII art
  - Versão centralizada e destacada
  - Identificação visual clara do Auto4Git

- **Organização de saída**
  - Seções bem delimitadas com linhas separadoras
  - Cores consistentes: Verde (sucesso), Amarelo (avisos), Azul (info), Vermelho (erros)
  - Ícones e símbolos para identificação rápida (✓, →, etc.)

- **Mensagens de progresso**
  - Indicadores numéricos claros [X/N]
  - Descrições mais detalhadas de cada etapa
  - Feedback imediato de sucesso/erro

#### Fluxo de Execução
- **Reorganização de validações**
  - SSH validado antes de Git
  - Identidade Git validada antes de URL remota
  - Modificações validadas por último

- **Separação de responsabilidades**
  - Função dedicada para modo interativo
  - Função dedicada para tutorial SSH
  - Validações modulares e reutilizáveis

### Corrigido
- **Detecção de chaves SSH**
  - Corrigida ordem de prioridade (ed25519 > rsa > ecdsa)
  - Melhor tratamento de erros ao adicionar chaves
  - Feedback mais claro quando senha é necessária

- **Validação de arquivos vazios**
  - Verifica não apenas existência mas também conteúdo
  - Mensagens de erro específicas para cada caso

- **Conversão HTTPS → SSH**
  - Prompt mais claro com cores destacadas (s/N)
  - Validação antes de permitir continuar com HTTPS

### Documentação
- **README.md atualizado**
  - Seção de modo interativo adicionada
  - Exemplos atualizados com novo fluxo
  - Troubleshooting expandido
  - Screenshots conceituais do fluxo

- **CHANGELOG.md criado**
  - Histórico completo desde v0.0.1
  - Formato Keep a Changelog
  - Categorias claras (Adicionado, Modificado, Corrigido)

### Desempenho
- **Otimizações de validação**
  - Timeout em conexões SSH para evitar espera infinita
  - Cache de detecção de usuário GitHub
  - Validações executadas apenas quando necessário

---

## [0.0.1] - 2026-02-14

### 🎉 Lançamento Inicial

Primeira versão estável do Auto4Git!

### Adicionado
- **Validação completa de SSH**
  - Verificação automática do ssh-agent
  - Carregamento automático de chaves SSH (ed25519, RSA, ECDSA)
  - Teste de conexão com GitHub antes de operações

- **Configuração de identidade Git**
  - Detecção automática de usuário GitHub
  - Detecção de email da chave SSH
  - Configuração interativa de nome e email
  - Opção de configuração global ou local

- **Gerenciamento de remote**
  - Detecção de URLs HTTPS
  - Conversão automática HTTPS → SSH
  - Validação de remote origin

- **Automação de commits**
  - Suporte para mensagens de commit em arquivo externo
  - Adição automática de todos os arquivos modificados
  - Validação de modificações antes do commit

- **Suporte a tags**
  - Criação de tags anotadas
  - Verificação de duplicação de tags
  - Push automático de tags para remote
  - Mensagem de tag idêntica ao commit

- **Interface de usuário**
  - Saída colorida (verde, amarelo, azul, vermelho)
  - Mensagens informativas em cada etapa
  - Indicadores de progresso [1/4], [2/4], etc.
  - Banner de apresentação
  - Resumo final de operações

- **Tratamento de erros**
  - Validação de argumentos
  - Verificação de existência de arquivos
  - Validação de formato de email
  - Timeout em conexões SSH
  - Mensagens de erro claras com dicas de solução

- **Documentação**
  - README.md completo
  - Exemplos de uso
  - Guia de solução de problemas
  - CHANGELOG.md estruturado

### Segurança
- Validação de autenticação SSH antes de push
- Verificação de identidade Git antes de commit
- Timeout de segurança em conexões SSH

---

## Convenções de Versionamento

Este projeto segue o [Versionamento Semântico](https://semver.org/lang/pt-BR/):

- **MAJOR** (X.0.0): Mudanças incompatíveis na API
- **MINOR** (0.X.0): Novas funcionalidades mantendo compatibilidade
- **PATCH** (0.0.X): Correções de bugs e melhorias

## Tipos de Mudanças

- **Adicionado** - para novas funcionalidades
- **Modificado** - para mudanças em funcionalidades existentes
- **Descontinuado** - para funcionalidades que serão removidas
- **Removido** - para funcionalidades removidas
- **Corrigido** - para correções de bugs
- **Segurança** - para vulnerabilidades corrigidas
- **Documentação** - para melhorias na documentação
- **Desempenho** - para otimizações de performance

---

[Unreleased]: https://github.com/gitdias/Auto4Git/compare/v0.0.2...HEAD
[0.0.2]: https://github.com/gitdias/Auto4Git/releases/tag/v0.0.2
[0.0.1]: https://github.com/gitdias/Auto4Git/releases/tag/v0.0.1
