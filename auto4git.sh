#!/bin/bash

# ============================================================================
# Auto4Git - Git Automation with SSH
# ============================================================================
# Author:     Sandro Dias (gitdias)
# Contact:    pro.sandrodias@gmail.com
# Repository: https://github.com/gitdias/Auto4Git
# Version:    0.0.3
# License:    MIT
# ============================================================================
# Description: Automates commit, tag and push with full SSH validation
# Syntax:      ./auto4git.sh [--tag <version> --tagmsg <file> --msg <file>]
# ============================================================================

# Global variables
TAG=""
TAG_MSG=""
COMMIT_MSG=""
BRANCH=$(git branch --show-current 2>/dev/null)
VERSION="0.0.3"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Display ASCII art banner
show_banner() {
    echo ""
    echo "             _        _  _         _ _   "
    echo "  __ _ _   _| |_ ___ | || |   __ _(_) |_ "
    echo " / _\` | | | | __/ _ \| || |_ / _\` | | __|"
    echo "| (_| | |_| | || (_) |__   _| (_| | | |_ "
    echo " \__,_|\__,_|\__\___/   |_|  \__, |_|\__|"
    echo "─────────────────────────────|___/ v${VERSION}"
    echo ""
}

# Display usage/help
show_usage() {
    show_banner
    echo "Uso: $0 [opções]"
    echo ""
    echo "Modo Interativo (padrão):"
    echo "  $0"
    echo ""
    echo "Modo Legado (compatibilidade):"
    echo "  $0 --tag <versão> --tagmsg <arquivo> --msg <arquivo>"
    echo ""
    echo "Opções:"
    echo "  --tag      Versão da tag (ex: v1.0.0)"
    echo "  --tagmsg   Arquivo com mensagem da tag"
    echo "  --msg      Arquivo com mensagem do commit"
    echo "  -h, --help Exibe esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0"
    echo "  $0 --tag v1.2.3 --tagmsg release.txt --msg commit.txt"
    exit 0
}

# Read multi-line input or file path
read_input_or_file() {
    local prompt="$1"
    local example="$2"
    local result=""

    echo ""
    echo "[EXEMPLO] $example"
    echo ""
    echo "[ENTRADA] $prompt"
    echo "          Cole o texto (pressione Ctrl+D para finalizar)"
    echo "          OU informe o caminho do arquivo"
    echo ""

    # Read first line
    read -r first_line

    # Check if input is a file path
    if [ -f "$first_line" ]; then
        if [ ! -s "$first_line" ]; then
            echo "[ERRO] Arquivo vazio: $first_line"
            exit 1
        fi
        result=$(cat "$first_line")
        echo "[OK] Conteúdo lido do arquivo: $first_line"
    else
        # Treat as direct text input, read until Ctrl+D
        result="$first_line"
        while IFS= read -r line; do
            result="${result}"$'\n'"${line}"
        done
        echo "[OK] Texto capturado com sucesso"
    fi

    # Validate non-empty result
    if [ -z "$result" ]; then
        echo "[ERRO] Conteúdo não pode ser vazio!"
        exit 1
    fi

    echo "$result"
}

# Validate semantic version tag format
validate_tag_format() {
    local tag="$1"

    if ! echo "$tag" | grep -qE "^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$"; then
        echo "[ERRO] Formato de tag inválido: $tag"
        echo "[INFO] Use versionamento semântico: v1.2.3, v2.0.0-beta, etc."
        exit 1
    fi
}

# ============================================================================
# SSH TUTORIAL
# ============================================================================

show_ssh_tutorial() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  ERRO: Autenticação SSH com GitHub falhou!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "  TUTORIAL: Como Configurar SSH para GitHub"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "PASSO 1/5: Gerar Chave SSH"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "  Execute o comando:"
    echo "  \$ ssh-keygen -t ed25519 -C \"seu-email@example.com\""
    echo ""
    echo "  → Pressione Enter para aceitar o local padrão"
    echo "  → Digite uma senha forte (recomendado) ou deixe em branco"
    echo ""
    echo "PASSO 2/5: Iniciar ssh-agent"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "  Execute o comando:"
    echo "  \$ eval \"\$(ssh-agent -s)\""
    echo ""
    echo "PASSO 3/5: Adicionar Chave ao ssh-agent"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "  Execute o comando:"
    echo "  \$ ssh-add ~/.ssh/id_ed25519"
    echo ""
    echo "PASSO 4/5: Copiar Chave Pública"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "  Execute o comando:"
    echo "  \$ cat ~/.ssh/id_ed25519.pub"
    echo ""
    echo "  → Copie TODA a saída (de ssh-ed25519 até o email)"
    echo ""
    echo "PASSO 5/5: Adicionar Chave no GitHub"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "  1. Acesse: https://github.com/settings/keys"
    echo "  2. Clique em \"New SSH key\""
    echo "  3. Título: $(hostname) ($(date +%Y)) (ou outro descritivo)"
    echo "  4. Cole a chave pública copiada"
    echo "  5. Clique em \"Add SSH key\""
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "  TESTAR CONEXÃO:"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    echo "  Execute o comando:"
    echo "  \$ ssh -T git@github.com"
    echo ""
    echo "  → Deve retornar: \"Hi username! You've successfully...\""
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  Após configurar, execute o Auto4Git novamente!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

# ============================================================================
# SSH VALIDATIONS
# ============================================================================

test_github_ssh() {
    echo "[SSH] Testando conexão SSH com GitHub..."

    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "[OK] Autenticação SSH com GitHub bem-sucedida!"
        USERNAME=$(timeout 10 ssh -T git@github.com 2>&1 | grep -o "Hi [^!]*" | cut -d' ' -f2)
        echo "[INFO] Conectado como: $USERNAME"
        return 0
    else
        echo "[ERRO] Falha na autenticação SSH com GitHub!"
        show_ssh_tutorial
        exit 1
    fi
}

check_ssh_agent() {
    echo "[SSH] Verificando ssh-agent..."

    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        echo "[INFO] Iniciando ssh-agent..."
        eval "$(ssh-agent -s)"
        echo "[OK] ssh-agent iniciado"
    else
        echo "[OK] ssh-agent está rodando"
    fi
}

check_ssh_keys_loaded() {
    echo "[SSH] Verificando chaves SSH..."

    if ssh-add -l > /dev/null 2>&1; then
        echo "[OK] Chaves SSH carregadas no agent"
        return 0
    fi

    echo "[INFO] Procurando chaves SSH..."

    # Priority order: ed25519 > rsa > ecdsa
    SSH_KEYS=(
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ecdsa"
    )

    for key in "${SSH_KEYS[@]}"; do
        if [ -f "$key" ]; then
            echo "[INFO] Encontrada: $key"
            echo "[INFO] Adicionando ao ssh-agent..."

            if ssh-add "$key" 2>/dev/null; then
                echo "[OK] Chave adicionada"
                return 0
            else
                ssh-add "$key"
                if [ $? -eq 0 ]; then
                    return 0
                fi
            fi
        fi
    done

    echo "[AVISO] Nenhuma chave encontrada no ssh-agent"
    echo "[INFO] Conexão SSH pode funcionar mesmo assim"
}

# ============================================================================
# GIT VALIDATIONS
# ============================================================================

check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "[ERRO] Não estamos em um repositório Git!"
        exit 1
    fi
}

check_git_identity() {
    echo "[GIT] Verificando identidade..."

    GIT_NAME=$(git config user.name)
    GIT_EMAIL=$(git config user.email)

    if [ -z "$GIT_NAME" ]; then
        GIT_NAME=$(git config --global user.name)
    fi

    if [ -z "$GIT_EMAIL" ]; then
        GIT_EMAIL=$(git config --global user.email)
    fi

    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        echo "[AVISO] Identidade Git não configurada"
        echo ""

        GITHUB_USER=$(timeout 5 ssh -T git@github.com 2>&1 | grep -o "Hi [^!]*" | cut -d' ' -f2)

        if [ -z "$GIT_NAME" ]; then
            if [ -n "$GITHUB_USER" ]; then
                echo "[INFO] Usuário GitHub detectado: $GITHUB_USER"
                echo -n "Nome para commits [$GITHUB_USER]: "
            else
                echo -n "Nome para commits: "
            fi

            read -r input_name
            GIT_NAME="${input_name:-$GITHUB_USER}"

            if [ -z "$GIT_NAME" ]; then
                echo "[ERRO] Nome não pode ser vazio!"
                exit 1
            fi
        fi

        if [ -z "$GIT_EMAIL" ]; then
            SSH_EMAIL=$(ssh-add -L 2>/dev/null | grep -o "[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}" | head -n1)

            if [ -n "$SSH_EMAIL" ]; then
                echo "[INFO] Email detectado: $SSH_EMAIL"
                echo -n "Email para commits [$SSH_EMAIL]: "
            else
                echo -n "Email para commits: "
            fi

            read -r input_email
            GIT_EMAIL="${input_email:-$SSH_EMAIL}"

            if [ -z "$GIT_EMAIL" ]; then
                echo "[ERRO] Email não pode ser vazio!"
                exit 1
            fi

            if ! echo "$GIT_EMAIL" | grep -qE "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"; then
                echo "[ERRO] Formato de email inválido!"
                exit 1
            fi
        fi

        echo ""
        echo "Configurar para:"
        echo "  1) Apenas este repositório (local)"
        echo "  2) Todos os repositórios (global) - Recomendado"
        echo -n "Escolha (1/2) [2]: "
        read -r config_scope

        config_scope="${config_scope:-2}"

        if [ "$config_scope" = "2" ]; then
            git config --global user.name "$GIT_NAME"
            git config --global user.email "$GIT_EMAIL"
            echo "[OK] Identidade configurada globalmente"
        else
            git config user.name "$GIT_NAME"
            git config user.email "$GIT_EMAIL"
            echo "[OK] Identidade configurada localmente"
        fi

        echo "[INFO] Nome: $GIT_NAME"
        echo "[INFO] Email: $GIT_EMAIL"
    else
        echo "[OK] Identidade configurada"
        echo "[INFO] Nome: $GIT_NAME"
        echo "[INFO] Email: $GIT_EMAIL"
    fi
}

check_remote_url() {
    echo "[GIT] Verificando URL remota..."

    REMOTE_URL=$(git config --get remote.origin.url)

    if [ -z "$REMOTE_URL" ]; then
        echo "[ERRO] Nenhum remote 'origin' configurado!"
        exit 1
    fi

    if echo "$REMOTE_URL" | grep -q "https://"; then
        echo "[AVISO] Remote está em HTTPS"
        echo "[INFO] Atual: $REMOTE_URL"

        SSH_URL=$(echo "$REMOTE_URL" | sed 's|https://github.com/|git@github.com:|')
        echo "[INFO] SSH: $SSH_URL"

        echo -n "Converter para SSH? (s/N): "
        read -r response

        if [[ "$response" =~ ^[Ss]$ ]]; then
            git remote set-url origin "$SSH_URL"
            echo "[OK] URL alterada para SSH"
        else
            echo "[ERRO] Este script requer SSH!"
            echo "[DICA] Execute: git remote set-url origin $SSH_URL"
            exit 1
        fi
    else
        echo "[OK] Remote em SSH"
        echo "[INFO] $REMOTE_URL"
    fi
}

check_modifications() {
    echo "[GIT] Verificando modificações..."

    if [ -z "$(git status --porcelain)" ]; then
        echo "[AVISO] Não há modificações para commitar"
        exit 0
    fi

    echo "[OK] Modificações detectadas"
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

interactive_mode() {
    echo "════════════════════════════════════════"
    echo "  Modo Interativo"
    echo "════════════════════════════════════════"

    # STEP 1: TAG
    echo ""
    echo "────────────────────────────────────────"
    echo "  PASSO 1/3: Definir Tag"
    echo "────────────────────────────────────────"
    echo ""
    echo "[EXEMPLO] v2.9.1, v1.0.0-beta, v3.2.1-rc.1"
    echo ""
    echo -n "Digite a versão da tag: "
    read -r TAG

    if [ -z "$TAG" ]; then
        echo "[ERRO] Tag é obrigatória!"
        exit 1
    fi

    validate_tag_format "$TAG"

    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "[ERRO] A tag $TAG já existe!"
        echo "[DICA] Use: git tag -d $TAG"
        exit 1
    fi

    echo "[OK] Tag definida: $TAG"

    # STEP 2: TAG MESSAGE
    echo ""
    echo "────────────────────────────────────────"
    echo "  PASSO 2/3: Mensagem da Tag"
    echo "────────────────────────────────────────"

    TAG_MSG=$(read_input_or_file \
        "Mensagem da tag:" \
        "Release $TAG - Novos recursos\n\n- feat: Nova funcionalidade\n- fix: Correção de bug")

    # STEP 3: COMMIT MESSAGE
    echo ""
    echo "────────────────────────────────────────"
    echo "  PASSO 3/3: Mensagem do Commit"
    echo "────────────────────────────────────────"

    COMMIT_MSG=$(read_input_or_file \
        "Mensagem do commit:" \
        "chore: Atualiza versão para $TAG\n\nPrepara release $TAG")

    echo ""
    echo "[OK] Informações coletadas!"
    echo ""
}

# ============================================================================
# MAIN PROCESSING
# ============================================================================

LEGACY_MODE=false
TAG_MSG_FILE=""
COMMIT_MSG_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --tag)
            TAG="$2"
            LEGACY_MODE=true
            shift 2
            ;;
        --tagmsg)
            TAG_MSG_FILE="$2"
            shift 2
            ;;
        --msg)
            COMMIT_MSG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "[ERRO] Opção desconhecida: $1"
            show_usage
            ;;
    esac
done

# Banner
show_banner

# SSH VALIDATIONS
echo "════════════════════════════════════════"
echo "  Validação SSH"
echo "════════════════════════════════════════"
echo ""

test_github_ssh
check_ssh_agent
check_ssh_keys_loaded

echo ""

# GIT VALIDATIONS
echo "════════════════════════════════════════"
echo "  Validação Git"
echo "════════════════════════════════════════"
echo ""

check_git_repo
check_git_identity
check_remote_url
check_modifications

echo ""
echo "[INFO] Branch atual: $BRANCH"
echo ""

# OPERATION MODE
if [ "$LEGACY_MODE" = true ]; then
    echo "[INFO] Modo legado (argumentos)"

    if [ -z "$TAG" ] || [ -z "$TAG_MSG_FILE" ] || [ -z "$COMMIT_MSG_FILE" ]; then
        echo "[ERRO] No modo legado, --tag, --tagmsg e --msg são obrigatórios!"
        show_usage
    fi

    validate_tag_format "$TAG"

    if [ ! -f "$TAG_MSG_FILE" ]; then
        echo "[ERRO] Arquivo não encontrado: $TAG_MSG_FILE"
        exit 1
    fi

    if [ ! -f "$COMMIT_MSG_FILE" ]; then
        echo "[ERRO] Arquivo não encontrado: $COMMIT_MSG_FILE"
        exit 1
    fi

    if [ ! -s "$TAG_MSG_FILE" ]; then
        echo "[ERRO] Arquivo de tag vazio!"
        exit 1
    fi

    if [ ! -s "$COMMIT_MSG_FILE" ]; then
        echo "[ERRO] Arquivo de commit vazio!"
        exit 1
    fi

    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "[ERRO] A tag $TAG já existe!"
        exit 1
    fi

    TAG_MSG=$(cat "$TAG_MSG_FILE")
    COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

    echo "[OK] Tag: $TAG"
    echo "[OK] Mensagem da tag: $TAG_MSG_FILE"
    echo "[OK] Mensagem do commit: $COMMIT_MSG_FILE"
else
    interactive_mode
fi

# EXECUTION
echo ""
echo "════════════════════════════════════════"
echo "  Processamento"
echo "════════════════════════════════════════"
echo ""

echo "[STATUS] Arquivos modificados:"
git status --short
echo ""

echo "[1/5] Adicionando arquivos..."
if git add .; then
    echo "[OK] Arquivos adicionados"
else
    echo "[ERRO] Falha ao adicionar"
    exit 1
fi
echo ""

echo "[2/5] Criando commit..."
if echo "$COMMIT_MSG" | git commit -F -; then
    echo "[OK] Commit criado"
else
    echo "[ERRO] Falha no commit"
    exit 1
fi
echo ""

echo "[3/5] Criando tag: $TAG"
if echo "$TAG_MSG" | git tag -a "$TAG" -F -; then
    echo "[OK] Tag $TAG criada"
else
    echo "[ERRO] Falha na tag"
    exit 1
fi
echo ""

echo "[4/5] Enviando commit..."
if git push origin "$BRANCH"; then
    echo "[OK] Push do commit realizado"
else
    echo "[ERRO] Falha no push"
    exit 1
fi
echo ""

echo "[5/5] Enviando tag..."
if git push origin "$TAG"; then
    echo "[OK] Push da tag realizado"
else
    echo "[ERRO] Falha no push da tag"
    exit 1
fi
echo ""

# SUMMARY
echo "════════════════════════════════════════"
echo "  Concluído com Sucesso!"
echo "════════════════════════════════════════"
echo ""
echo "Branch:  $BRANCH"
echo "Tag:     $TAG"
echo "Commit:  ${COMMIT_MSG:0:50}..."
echo ""
echo "Todas as alterações foram enviadas!"
echo ""