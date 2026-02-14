#!/bin/bash

# Script de Upload Automatizado para Git com SSH
# Uso: ./git-upload.sh --msg arquivo.txt [--tag v1.0.0]

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
MSG_FILE=""
TAG=""
BRANCH=$(git branch --show-current 2>/dev/null)

# Função para exibir uso
show_usage() {
    echo "Uso: $0 --msg <arquivo> [--tag <versao>]"
    echo ""
    echo "Opções:"
    echo "  --msg    Arquivo com a mensagem de commit (obrigatório)"
    echo "  --tag    Tag para criar (opcional, ex: v1.0.0)"
    echo ""
    echo "Exemplos:"
    echo "  $0 --msg ../msg.txt"
    echo "  $0 --msg changelog.txt --tag v2.1.0"
    exit 1
}

# Função para verificar se estamos em um repositório Git
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}[ERRO]${NC} Não estamos em um repositório Git!"
        exit 1
    fi
}

# Função para verificar e configurar identidade Git
check_git_identity() {
    echo -e "${BLUE}[GIT]${NC} Verificando identidade do Git..."

    GIT_NAME=$(git config user.name)
    GIT_EMAIL=$(git config user.email)

    # Se não houver configuração global, verificar local
    if [ -z "$GIT_NAME" ]; then
        GIT_NAME=$(git config --global user.name)
    fi

    if [ -z "$GIT_EMAIL" ]; then
        GIT_EMAIL=$(git config --global user.email)
    fi

    # Se ainda não houver nome ou email, solicitar
    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        echo -e "${YELLOW}[AVISO]${NC} Identidade Git não configurada!"
        echo ""

        # Tentar obter do GitHub se possível
        GITHUB_USER=$(timeout 5 ssh -T git@github.com 2>&1 | grep -o "Hi [^!]*" | cut -d' ' -f2)

        if [ -z "$GIT_NAME" ]; then
            if [ -n "$GITHUB_USER" ]; then
                echo -e "${BLUE}[INFO]${NC} Usuário GitHub detectado: $GITHUB_USER"
                echo -ne "${YELLOW}[PERGUNTA]${NC} Nome para commits [$GITHUB_USER]: "
            else
                echo -ne "${YELLOW}[PERGUNTA]${NC} Digite seu nome para commits: "
            fi

            read -r input_name
            GIT_NAME="${input_name:-$GITHUB_USER}"

            if [ -z "$GIT_NAME" ]; then
                echo -e "${RED}[ERRO]${NC} Nome não pode ser vazio!"
                exit 1
            fi
        fi

        if [ -z "$GIT_EMAIL" ]; then
            # Tentar obter email da chave SSH
            SSH_EMAIL=$(ssh-add -L 2>/dev/null | grep -o "[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}" | head -n1)

            if [ -n "$SSH_EMAIL" ]; then
                echo -e "${BLUE}[INFO]${NC} Email detectado da chave SSH: $SSH_EMAIL"
                echo -ne "${YELLOW}[PERGUNTA]${NC} Email para commits [$SSH_EMAIL]: "
            else
                echo -ne "${YELLOW}[PERGUNTA]${NC} Digite seu email para commits: "
            fi

            read -r input_email
            GIT_EMAIL="${input_email:-$SSH_EMAIL}"

            if [ -z "$GIT_EMAIL" ]; then
                echo -e "${RED}[ERRO]${NC} Email não pode ser vazio!"
                exit 1
            fi

            # Validar formato de email básico
            if ! echo "$GIT_EMAIL" | grep -qE "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"; then
                echo -e "${RED}[ERRO]${NC} Formato de email inválido!"
                exit 1
            fi
        fi

        # Perguntar se quer configurar globalmente ou apenas localmente
        echo ""
        echo -e "${YELLOW}[PERGUNTA]${NC} Configurar para:"
        echo "  1) Apenas este repositório (local)"
        echo "  2) Todos os repositórios (global) - Recomendado"
        echo -ne "Escolha (1/2) [2]: "
        read -r config_scope

        config_scope="${config_scope:-2}"

        if [ "$config_scope" = "2" ]; then
            git config --global user.name "$GIT_NAME"
            git config --global user.email "$GIT_EMAIL"
            echo -e "${GREEN}✓${NC} Identidade configurada globalmente"
        else
            git config user.name "$GIT_NAME"
            git config user.email "$GIT_EMAIL"
            echo -e "${GREEN}✓${NC} Identidade configurada localmente"
        fi

        echo -e "${GREEN}[INFO]${NC} Nome: $GIT_NAME"
        echo -e "${GREEN}[INFO]${NC} Email: $GIT_EMAIL"
    else
        echo -e "${GREEN}✓${NC} Identidade Git configurada"
        echo -e "${GREEN}[INFO]${NC} Nome: $GIT_NAME"
        echo -e "${GREEN}[INFO]${NC} Email: $GIT_EMAIL"
    fi
}

# Função para verificar se o ssh-agent está rodando
check_ssh_agent() {
    echo -e "${BLUE}[SSH]${NC} Verificando ssh-agent..."

    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        echo -e "${YELLOW}[AVISO]${NC} ssh-agent não está rodando. Iniciando..."
        eval "$(ssh-agent -s)"
        echo -e "${GREEN}✓${NC} ssh-agent iniciado"
    else
        echo -e "${GREEN}✓${NC} ssh-agent já está rodando"
    fi
}

# Função para verificar se há chaves SSH carregadas
check_ssh_keys_loaded() {
    echo -e "${BLUE}[SSH]${NC} Verificando chaves SSH carregadas..."

    if ! ssh-add -l > /dev/null 2>&1; then
        echo -e "${YELLOW}[AVISO]${NC} Nenhuma chave SSH carregada no ssh-agent"
        echo -e "${BLUE}[INFO]${NC} Procurando chaves SSH disponíveis..."

        # Procurar por chaves SSH comuns
        SSH_KEYS=(
            "$HOME/.ssh/id_ed25519"
            "$HOME/.ssh/id_rsa"
            "$HOME/.ssh/id_ecdsa"
        )

        KEY_FOUND=false
        for key in "${SSH_KEYS[@]}"; do
            if [ -f "$key" ]; then
                echo -e "${BLUE}[INFO]${NC} Encontrada chave: $key"
                echo -e "${BLUE}[INFO]${NC} Adicionando chave ao ssh-agent..."

                if ssh-add "$key" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} Chave adicionada com sucesso"
                    KEY_FOUND=true
                    break
                else
                    echo -e "${YELLOW}[AVISO]${NC} Falha ao adicionar chave (pode precisar de senha)"
                    # Tentar adicionar com interação do usuário
                    ssh-add "$key"
                    if [ $? -eq 0 ]; then
                        KEY_FOUND=true
                        break
                    fi
                fi
            fi
        done

        if [ "$KEY_FOUND" = false ]; then
            echo -e "${RED}[ERRO]${NC} Nenhuma chave SSH encontrada!"
            echo -e "${YELLOW}[DICA]${NC} Execute: ssh-keygen -t ed25519 -C \"seu-email@example.com\""
            exit 1
        fi
    else
        echo -e "${GREEN}✓${NC} Chaves SSH carregadas:"
        ssh-add -l | sed 's/^/  /'
    fi
}

# Função para testar conexão SSH com GitHub
test_github_ssh() {
    echo -e "${BLUE}[SSH]${NC} Testando conexão SSH com GitHub..."

    # Timeout de 10 segundos para a conexão
    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✓${NC} Autenticação SSH com GitHub bem-sucedida!"
        # Extrair nome de usuário
        USERNAME=$(timeout 10 ssh -T git@github.com 2>&1 | grep -o "Hi [^!]*" | cut -d' ' -f2)
        echo -e "${GREEN}[INFO]${NC} Conectado como: $USERNAME"
        return 0
    else
        echo -e "${RED}[ERRO]${NC} Falha na autenticação SSH com GitHub!"
        echo -e "${YELLOW}[DICA]${NC} Verifique se adicionou sua chave SSH ao GitHub:"
        echo -e "${YELLOW}        ${NC}https://github.com/settings/keys"
        echo ""
        echo -e "${YELLOW}[DICA]${NC} Copie sua chave pública com:"

        # Mostrar qual chave pública usar
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            echo -e "${YELLOW}        ${NC}cat ~/.ssh/id_ed25519.pub"
        elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            echo -e "${YELLOW}        ${NC}cat ~/.ssh/id_rsa.pub"
        fi

        exit 1
    fi
}

# Função para verificar e converter URL remota para SSH
check_remote_url() {
    echo -e "${BLUE}[GIT]${NC} Verificando URL do repositório remoto..."

    REMOTE_URL=$(git config --get remote.origin.url)

    if [ -z "$REMOTE_URL" ]; then
        echo -e "${RED}[ERRO]${NC} Nenhum remote 'origin' configurado!"
        exit 1
    fi

    # Verificar se está usando HTTPS
    if echo "$REMOTE_URL" | grep -q "https://"; then
        echo -e "${YELLOW}[AVISO]${NC} Remote está configurado com HTTPS: $REMOTE_URL"

        # Converter HTTPS para SSH
        SSH_URL=$(echo "$REMOTE_URL" | sed 's|https://github.com/|git@github.com:|')

        echo -e "${BLUE}[INFO]${NC} Convertendo para SSH: $SSH_URL"
        echo -ne "${YELLOW}[PERGUNTA]${NC} Deseja alterar para SSH? (s/N): "
        read -r response

        if [[ "$response" =~ ^[Ss]$ ]]; then
            git remote set-url origin "$SSH_URL"
            echo -e "${GREEN}✓${NC} URL remota alterada para SSH"
        else
            echo -e "${RED}[ERRO]${NC} Este script requer SSH. Altere manualmente com:"
            echo -e "${YELLOW}        ${NC}git remote set-url origin $SSH_URL"
            exit 1
        fi
    else
        echo -e "${GREEN}✓${NC} Remote configurado com SSH: $REMOTE_URL"
    fi
}

# Função para verificar se há modificações
check_modifications() {
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}[AVISO]${NC} Não há modificações para commitar."
        exit 0
    fi
}

# Processar argumentos
while [ $# -gt 0 ]; do
    case "$1" in
        --msg)
            MSG_FILE="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo -e "${RED}[ERRO]${NC} Opção desconhecida: $1"
            show_usage
            ;;
    esac
done

# Validar argumentos obrigatórios
if [ -z "$MSG_FILE" ]; then
    echo -e "${RED}[ERRO]${NC} O arquivo de mensagem (--msg) é obrigatório!"
    show_usage
fi

# Verificar se o arquivo de mensagem existe
if [ ! -f "$MSG_FILE" ]; then
    echo -e "${RED}[ERRO]${NC} Arquivo não encontrado: $MSG_FILE"
    exit 1
fi

# Verificar se o arquivo não está vazio
if [ ! -s "$MSG_FILE" ]; then
    echo -e "${RED}[ERRO]${NC} O arquivo de mensagem está vazio: $MSG_FILE"
    exit 1
fi

# Ler mensagem do arquivo
COMMIT_MSG=$(cat "$MSG_FILE")

# Banner inicial
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Git Upload com Autenticação SSH${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verificações de SSH (ANTES das verificações Git)
check_ssh_agent
check_ssh_keys_loaded
test_github_ssh
echo ""

# Verificações do repositório Git
check_git_repo
check_git_identity
check_remote_url
check_modifications

echo -e "${GREEN}[INFO]${NC} Branch atual: $BRANCH"
echo ""

# Mostrar status antes do commit
echo -e "${YELLOW}=== Status atual ===${NC}"
git status --short
echo ""

# Adicionar todos os arquivos modificados
echo -e "${GREEN}[1/4]${NC} Adicionando arquivos modificados..."
if git add .; then
    echo -e "${GREEN}✓${NC} Arquivos adicionados com sucesso"
else
    echo -e "${RED}[ERRO]${NC} Falha ao adicionar arquivos"
    exit 1
fi
echo ""

# Fazer commit
echo -e "${GREEN}[2/4]${NC} Criando commit..."
if git commit -F "$MSG_FILE"; then
    echo -e "${GREEN}✓${NC} Commit criado com sucesso"
else
    echo -e "${RED}[ERRO]${NC} Falha ao criar commit"
    exit 1
fi
echo ""

# Criar tag se especificada
if [ -n "$TAG" ]; then
    echo -e "${GREEN}[3/4]${NC} Criando tag: $TAG"

    # Verificar se a tag já existe
    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo -e "${RED}[ERRO]${NC} A tag $TAG já existe!"
        echo -e "${YELLOW}[INFO]${NC} Use 'git tag -d $TAG' para removê-la localmente"
        exit 1
    fi

    if git tag -a "$TAG" -F "$MSG_FILE"; then
        echo -e "${GREEN}✓${NC} Tag $TAG criada com sucesso"
    else
        echo -e "${RED}[ERRO]${NC} Falha ao criar tag"
        exit 1
    fi
    echo ""
fi

# Fazer push
echo -e "${GREEN}[4/4]${NC} Enviando alterações para o repositório remoto..."
if git push origin "$BRANCH"; then
    echo -e "${GREEN}✓${NC} Push realizado com sucesso"
else
    echo -e "${RED}[ERRO]${NC} Falha ao fazer push"
    exit 1
fi

# Fazer push das tags se foram criadas
if [ -n "$TAG" ]; then
    echo -e "${GREEN}[EXTRA]${NC} Enviando tag para o repositório remoto..."
    if git push origin "$TAG"; then
        echo -e "${GREEN}✓${NC} Tag enviada com sucesso"
    else
        echo -e "${RED}[ERRO]${NC} Falha ao enviar tag"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Upload concluído com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Commit: ${COMMIT_MSG:0:50}..."
[ -n "$TAG" ] && echo -e "Tag: $TAG"
echo -e "Branch: $BRANCH"
echo ""
