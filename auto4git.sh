#!/bin/bash

# ============================================================================
# Auto4Git - Git Automation with SSH
# ============================================================================
# Author:     Sandro Dias (gitdias)
# Contact:    pro.sandrodias@gmail.com
# Repository: https://github.com/gitdias/Auto4Git
# Version:    0.0.5
# License:    MIT
# ============================================================================
# Description: Automates commit, tag and push with full SSH validation,
#              interactive mode, SSH setup wizard, and i18n support
# Syntax:      ./auto4git.sh [--tag <version> --msgtag <file> --msgcommit <file>]
# ============================================================================

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

TAG=""
TAG_MSG=""
COMMIT_MSG=""
BRANCH=$(git branch --show-current 2>/dev/null)
VERSION="0.0.5"
LOCALE=""

# ============================================================================
# I18N - LOCALE DETECTION
# ============================================================================

# Detect system locale and normalise to a supported locale code
detect_locale() {
    local sys_locale=""

    # Priority: LANG > LC_ALL > LC_MESSAGES > fallback
    sys_locale="${LANG:-${LC_ALL:-${LC_MESSAGES:-}}}"

    # Normalise: lowercase, replace hyphen with underscore, strip encoding suffix
    sys_locale=$(echo "$sys_locale" | tr '[:upper:]' '[:lower:]' | tr '-' '_' | cut -d'.' -f1)

    case "$sys_locale" in
        pt_br|pt)
            LOCALE="pt_BR"
            ;;
        en_us|en_gb|en_au|en_ca|en*)
            LOCALE="en_US"
            ;;
        *)
            # Default to pt_BR when system locale is unsupported
            LOCALE="pt_BR"
            ;;
    esac
}

# Translate a message key; falls back from pt_BR to en_US when key is missing
t() {
    local key="$1"
    local value=""

    # Try current locale first
    value=$(i18n_get "$LOCALE" "$key")

    # Fall back to en_US when key is not found and locale is not already en_US
    if [ -z "$value" ] && [ "$LOCALE" != "en_US" ]; then
        value=$(i18n_get "en_US" "$key")
    fi

    # Return the key itself as last resort so output is never silently empty
    echo "${value:-$key}"
}

# Retrieve a translated string for a given locale and key
i18n_get() {
    local locale="$1"
    local key="$2"

    case "${locale}::${key}" in

        # ------------------------------------------------------------------ #
        # GENERAL STATUS PREFIXES
        # ------------------------------------------------------------------ #
        "pt_BR::prefix.ok")             echo "[OK]" ;;
        "en_US::prefix.ok")             echo "[OK]" ;;
        "pt_BR::prefix.info")           echo "[INFO]" ;;
        "en_US::prefix.info")           echo "[INFO]" ;;
        "pt_BR::prefix.warn")           echo "[AVISO]" ;;
        "en_US::prefix.warn")           echo "[WARN]" ;;
        "pt_BR::prefix.error")          echo "[ERRO]" ;;
        "en_US::prefix.error")          echo "[ERROR]" ;;
        "pt_BR::prefix.hint")           echo "[DICA]" ;;
        "en_US::prefix.hint")           echo "[HINT]" ;;
        "pt_BR::prefix.status")         echo "[STATUS]" ;;
        "en_US::prefix.status")         echo "[STATUS]" ;;
        "pt_BR::prefix.ssh")            echo "[SSH]" ;;
        "en_US::prefix.ssh")            echo "[SSH]" ;;
        "pt_BR::prefix.git")            echo "[GIT]" ;;
        "en_US::prefix.git")            echo "[GIT]" ;;
        "pt_BR::prefix.example")        echo "[EXEMPLO]" ;;
        "en_US::prefix.example")        echo "[EXAMPLE]" ;;
        "pt_BR::prefix.input")          echo "[ENTRADA]" ;;
        "en_US::prefix.input")          echo "[INPUT]" ;;

        # ------------------------------------------------------------------ #
        # USAGE / HELP
        # ------------------------------------------------------------------ #
        "pt_BR::usage.title")           echo "Uso: $0 [opções]" ;;
        "en_US::usage.title")           echo "Usage: $0 [options]" ;;
        "pt_BR::usage.interactive")     echo "Modo Interativo (padrão):" ;;
        "en_US::usage.interactive")     echo "Interactive Mode (default):" ;;
        "pt_BR::usage.legacy")          echo "Modo Legado (compatibilidade):" ;;
        "en_US::usage.legacy")          echo "Legacy Mode (compatibility):" ;;
        "pt_BR::usage.options")         echo "Opções:" ;;
        "en_US::usage.options")         echo "Options:" ;;
        "pt_BR::usage.opt.tag")         echo "  --tag          Versão da tag (ex: v1.0.0)" ;;
        "en_US::usage.opt.tag")         echo "  --tag          Tag version (e.g.: v1.0.0)" ;;
        "pt_BR::usage.opt.msgtag")      echo "  --msgtag       Arquivo com mensagem da tag" ;;
        "en_US::usage.opt.msgtag")      echo "  --msgtag       File with tag message" ;;
        "pt_BR::usage.opt.msgcommit")   echo "  --msgcommit    Arquivo com mensagem do commit" ;;
        "en_US::usage.opt.msgcommit")   echo "  --msgcommit    File with commit message" ;;
        "pt_BR::usage.opt.help")        echo "  -h, --help     Exibe esta ajuda" ;;
        "en_US::usage.opt.help")        echo "  -h, --help     Show this help" ;;
        "pt_BR::usage.examples")        echo "Exemplos:" ;;
        "en_US::usage.examples")        echo "Examples:" ;;

        # ------------------------------------------------------------------ #
        # SSH VALIDATION
        # ------------------------------------------------------------------ #
        "pt_BR::ssh.testing")           echo "Testando conexão SSH com GitHub..." ;;
        "en_US::ssh.testing")           echo "Testing SSH connection to GitHub..." ;;
        "pt_BR::ssh.ok")                echo "Autenticação SSH com GitHub bem-sucedida!" ;;
        "en_US::ssh.ok")                echo "SSH authentication with GitHub successful!" ;;
        "pt_BR::ssh.connected_as")      echo "Conectado como:" ;;
        "en_US::ssh.connected_as")      echo "Connected as:" ;;
        "pt_BR::ssh.fail")              echo "Falha na autenticação SSH com GitHub!" ;;
        "en_US::ssh.fail")              echo "SSH authentication with GitHub failed!" ;;
        "pt_BR::ssh.agent_checking")    echo "Verificando ssh-agent..." ;;
        "en_US::ssh.agent_checking")    echo "Checking ssh-agent..." ;;
        "pt_BR::ssh.agent_starting")    echo "Iniciando ssh-agent..." ;;
        "en_US::ssh.agent_starting")    echo "Starting ssh-agent..." ;;
        "pt_BR::ssh.agent_started")     echo "ssh-agent iniciado" ;;
        "en_US::ssh.agent_started")     echo "ssh-agent started" ;;
        "pt_BR::ssh.agent_running")     echo "ssh-agent está rodando" ;;
        "en_US::ssh.agent_running")     echo "ssh-agent is running" ;;
        "pt_BR::ssh.keys_checking")    echo "Verificando chaves SSH..." ;;
        "en_US::ssh.keys_checking")    echo "Checking SSH keys..." ;;
        "pt_BR::ssh.keys_loaded")       echo "Chaves SSH carregadas no agent" ;;
        "en_US::ssh.keys_loaded")       echo "SSH keys loaded in agent" ;;
        "pt_BR::ssh.keys_searching")    echo "Procurando chaves SSH..." ;;
        "en_US::ssh.keys_searching")    echo "Searching for SSH keys..." ;;
        "pt_BR::ssh.key_found")         echo "Encontrada:" ;;
        "en_US::ssh.key_found")         echo "Found:" ;;
        "pt_BR::ssh.key_adding")        echo "Adicionando ao ssh-agent..." ;;
        "en_US::ssh.key_adding")        echo "Adding to ssh-agent..." ;;
        "pt_BR::ssh.key_added")         echo "Chave adicionada" ;;
        "en_US::ssh.key_added")         echo "Key added" ;;
        "pt_BR::ssh.no_keys")           echo "Nenhuma chave SSH encontrada" ;;
        "en_US::ssh.no_keys")           echo "No SSH key found" ;;
        "pt_BR::ssh.may_work")          echo "Conexão SSH pode funcionar mesmo assim" ;;
        "en_US::ssh.may_work")          echo "SSH connection may still work" ;;

        # ------------------------------------------------------------------ #
        # SSH WIZARD
        # ------------------------------------------------------------------ #
        "pt_BR::wizard.no_key_header")      echo "Nenhuma chave SSH foi encontrada no sistema." ;;
        "en_US::wizard.no_key_header")      echo "No SSH key was found on this system." ;;
        "pt_BR::wizard.no_key_detail")      echo "Uma chave SSH é necessária para autenticar com o GitHub." ;;
        "en_US::wizard.no_key_detail")      echo "An SSH key is required to authenticate with GitHub." ;;
        "pt_BR::wizard.ask_setup")          echo "Deseja configurar uma nova chave SSH agora? (S/n): " ;;
        "en_US::wizard.ask_setup")          echo "Would you like to set up a new SSH key now? (Y/n): " ;;
        "pt_BR::wizard.aborted")            echo "Configuração SSH ignorada. Execute novamente quando estiver pronto." ;;
        "en_US::wizard.aborted")            echo "SSH setup skipped. Run again when ready." ;;
        "pt_BR::wizard.title")              echo "  Assistente de Configuração SSH" ;;
        "en_US::wizard.title")              echo "  SSH Setup Wizard" ;;
        "pt_BR::wizard.menu_title")         echo "  Etapas de configuração:" ;;
        "en_US::wizard.menu_title")         echo "  Setup steps:" ;;
        "pt_BR::wizard.step_done")          echo "[✓]" ;;
        "en_US::wizard.step_done")          echo "[✓]" ;;
        "pt_BR::wizard.step_todo")          echo "[ ]" ;;
        "en_US::wizard.step_todo")          echo "[ ]" ;;
        "pt_BR::wizard.step_current")       echo "[→]" ;;
        "en_US::wizard.step_current")       echo "[→]" ;;
        "pt_BR::wizard.prompt_next")        echo "Pressione ENTER quando concluir esta etapa: " ;;
        "en_US::wizard.prompt_next")        echo "Press ENTER when done with this step: " ;;
        "pt_BR::wizard.skipped")            echo "Etapa ignorada." ;;
        "en_US::wizard.skipped")            echo "Step skipped." ;;
        "pt_BR::wizard.testing_conn")       echo "Testando conexão com GitHub..." ;;
        "en_US::wizard.testing_conn")       echo "Testing GitHub connection..." ;;
        "pt_BR::wizard.success")            echo "Chave SSH configurada e autenticação confirmada!" ;;
        "en_US::wizard.success")            echo "SSH key configured and authentication confirmed!" ;;
        "pt_BR::wizard.still_fail")         echo "Autenticação ainda falhou. Verifique os passos e tente novamente." ;;
        "en_US::wizard.still_fail")         echo "Authentication still failed. Review the steps and try again." ;;
        "pt_BR::wizard.exit_fail")          echo "Encerrando. Configure o SSH manualmente e execute novamente." ;;
        "en_US::wizard.exit_fail")          echo "Exiting. Configure SSH manually and run again." ;;

        # Wizard step labels (agora 5 etapas)
        "pt_BR::wizard.s1.label")           echo "Gerar chave SSH (ed25519)" ;;
        "en_US::wizard.s1.label")           echo "Generate SSH key (ed25519)" ;;
        "pt_BR::wizard.s2.label")           echo "Iniciar ssh-agent" ;;
        "en_US::wizard.s2.label")           echo "Start ssh-agent" ;;
        "pt_BR::wizard.s3.label")           echo "Adicionar chave ao ssh-agent" ;;
        "en_US::wizard.s3.label")           echo "Add key to ssh-agent" ;;
        "pt_BR::wizard.s4.label")           echo "Copiar chave pública e adicionar no GitHub" ;;
        "en_US::wizard.s4.label")           echo "Copy public key and add it to GitHub" ;;
        "pt_BR::wizard.s5.label")           echo "Testar conexão com GitHub" ;;
        "en_US::wizard.s5.label")           echo "Test GitHub connection" ;;

        # Wizard step 1 — interactive key generation
        "pt_BR::wizard.s1.email_prompt")    echo "  Digite o email para a chave SSH: " ;;
        "en_US::wizard.s1.email_prompt")    echo "  Enter the email for the SSH key: " ;;
        "pt_BR::wizard.s1.email_empty")     echo "Email não pode ser vazio!" ;;
        "en_US::wizard.s1.email_empty")     echo "Email cannot be empty!" ;;
        "pt_BR::wizard.s1.path_prompt")     echo "  Caminho da chave [~/.ssh/id_ed25519]: " ;;
        "en_US::wizard.s1.path_prompt")     echo "  Key path [~/.ssh/id_ed25519]: " ;;
        "pt_BR::wizard.s1.generating")      echo "  Gerando chave SSH..." ;;
        "en_US::wizard.s1.generating")      echo "  Generating SSH key..." ;;
        "pt_BR::wizard.s1.success")         echo "  Chave SSH criada com sucesso!" ;;
        "en_US::wizard.s1.success")         echo "  SSH key created successfully!" ;;
        "pt_BR::wizard.s1.fail")            echo "  Falha ao criar a chave SSH." ;;
        "en_US::wizard.s1.fail")            echo "  Failed to create the SSH key." ;;

        # Wizard step 2 — ssh-agent
        "pt_BR::wizard.s2.hint")           echo "  → Deve exibir: Agent pid XXXXX" ;;
        "en_US::wizard.s2.hint")           echo "  → Should display: Agent pid XXXXX" ;;

        # Wizard step 3 — ssh-add
        "pt_BR::wizard.s3.cmd")            echo "  \$ ssh-add ~/.ssh/id_ed25519" ;;
        "en_US::wizard.s3.cmd")            echo "  \$ ssh-add ~/.ssh/id_ed25519" ;;
        "pt_BR::wizard.s3.hint")           echo "  → Informe a senha se solicitado" ;;
        "en_US::wizard.s3.hint")           echo "  → Enter the passphrase if prompted" ;;

        # Wizard step 4 — unified: show pubkey + GitHub instructions
        "pt_BR::wizard.s4.intro")          echo "  Conteúdo da sua chave pública:" ;;
        "en_US::wizard.s4.intro")          echo "  Your public key content:" ;;
        "pt_BR::wizard.s4.hint_copy")      echo "  → Selecione e copie TODO o conteúdo acima (de ssh-ed25519 até o email)" ;;
        "en_US::wizard.s4.hint_copy")      echo "  → Select and copy the ENTIRE content above (from ssh-ed25519 to the email)" ;;
        "pt_BR::wizard.s4.browser")        echo "  Agora abra seu navegador preferido e execute os 5 passos abaixo com muita atenção:" ;;
        "en_US::wizard.s4.browser")        echo "  Now open your preferred browser and carefully follow the 5 steps below:" ;;
        "pt_BR::wizard.s4.i1")             echo "  A. Acesse: https://github.com/settings/keys" ;;
        "en_US::wizard.s4.i1")             echo "  A. Go to: https://github.com/settings/keys" ;;
        "pt_BR::wizard.s4.i2")             echo "  B. Clique em \"New SSH key\"" ;;
        "en_US::wizard.s4.i2")             echo "  B. Click \"New SSH key\"" ;;
        "pt_BR::wizard.s4.i3")             echo "  C. Título: DEFINA UM TÍTULO PARA A CHAVE" ;;
        "en_US::wizard.s4.i3")             echo "  C. Title: DEFINE A TITLE FOR THE KEY" ;;
        "pt_BR::wizard.s4.i4")             echo "  D. Cole a chave pública copiada no campo Key" ;;
        "en_US::wizard.s4.i4")             echo "  D. Paste the copied public key into the Key field" ;;
        "pt_BR::wizard.s4.i5")             echo "  E. Clique em \"Add SSH key\"" ;;
        "en_US::wizard.s4.i5")             echo "  E. Click \"Add SSH key\"" ;;

        # Wizard step 5 — connection test
        "pt_BR::wizard.s5.cmd")            echo "  \$ ssh -T git@github.com" ;;
        "en_US::wizard.s5.cmd")            echo "  \$ ssh -T git@github.com" ;;
        "pt_BR::wizard.s5.hint")           echo "  → Esperado: \"Hi username! You've successfully authenticated...\"" ;;
        "en_US::wizard.s5.hint")           echo "  → Expected: \"Hi username! You've successfully authenticated...\"" ;;
        "pt_BR::wizard.s5.auto")           echo "  (Este passo será executado automaticamente)" ;;
        "en_US::wizard.s5.auto")           echo "  (This step will be executed automatically)" ;;

        # ------------------------------------------------------------------ #
        # GIT VALIDATION
        # ------------------------------------------------------------------ #
        "pt_BR::git.not_repo")          echo "Não estamos em um repositório Git!" ;;
        "en_US::git.not_repo")          echo "Not inside a Git repository!" ;;
        "pt_BR::git.identity_check")    echo "Verificando identidade..." ;;
        "en_US::git.identity_check")    echo "Checking identity..." ;;
        "pt_BR::git.identity_warn")     echo "Identidade Git não configurada" ;;
        "en_US::git.identity_warn")     echo "Git identity not configured" ;;
        "pt_BR::git.github_user")       echo "Usuário GitHub detectado:" ;;
        "en_US::git.github_user")       echo "GitHub user detected:" ;;
        "pt_BR::git.name_prompt")       echo "Nome para commits" ;;
        "en_US::git.name_prompt")       echo "Name for commits" ;;
        "pt_BR::git.name_empty")        echo "Nome não pode ser vazio!" ;;
        "en_US::git.name_empty")        echo "Name cannot be empty!" ;;
        "pt_BR::git.email_detected")    echo "Email detectado:" ;;
        "en_US::git.email_detected")    echo "Email detected:" ;;
        "pt_BR::git.email_prompt")      echo "Email para commits" ;;
        "en_US::git.email_prompt")      echo "Email for commits" ;;
        "pt_BR::git.email_empty")       echo "Email não pode ser vazio!" ;;
        "en_US::git.email_empty")       echo "Email cannot be empty!" ;;
        "pt_BR::git.email_invalid")     echo "Formato de email inválido!" ;;
        "en_US::git.email_invalid")     echo "Invalid email format!" ;;
        "pt_BR::git.scope_prompt")      echo "Configurar para:" ;;
        "en_US::git.scope_prompt")      echo "Configure for:" ;;
        "pt_BR::git.scope_local")       echo "  1) Apenas este repositório (local)" ;;
        "en_US::git.scope_local")       echo "  1) This repository only (local)" ;;
        "pt_BR::git.scope_global")      echo "  2) Todos os repositórios (global) - Recomendado" ;;
        "en_US::git.scope_global")      echo "  2) All repositories (global) - Recommended" ;;
        "pt_BR::git.scope_choice")      echo "Escolha (1/2) [2]: " ;;
        "en_US::git.scope_choice")      echo "Choose (1/2) [2]: " ;;
        "pt_BR::git.identity_global")   echo "Identidade configurada globalmente" ;;
        "en_US::git.identity_global")   echo "Identity configured globally" ;;
        "pt_BR::git.identity_local")    echo "Identidade configurada localmente" ;;
        "en_US::git.identity_local")    echo "Identity configured locally" ;;
        "pt_BR::git.identity_ok")       echo "Identidade configurada" ;;
        "en_US::git.identity_ok")       echo "Identity configured" ;;
        "pt_BR::git.identity_name")     echo "Nome:" ;;
        "en_US::git.identity_name")     echo "Name:" ;;
        "pt_BR::git.identity_email")    echo "Email:" ;;
        "en_US::git.identity_email")    echo "Email:" ;;
        "pt_BR::git.remote_check")      echo "Verificando URL remota..." ;;
        "en_US::git.remote_check")      echo "Checking remote URL..." ;;
        "pt_BR::git.no_remote")         echo "Nenhum remote 'origin' configurado!" ;;
        "en_US::git.no_remote")         echo "No remote 'origin' configured!" ;;
        "pt_BR::git.remote_https")      echo "Remote está em HTTPS" ;;
        "en_US::git.remote_https")      echo "Remote is using HTTPS" ;;
        "pt_BR::git.remote_current")    echo "Atual:" ;;
        "en_US::git.remote_current")    echo "Current:" ;;
        "pt_BR::git.remote_ssh_url")    echo "SSH:" ;;
        "en_US::git.remote_ssh_url")    echo "SSH:" ;;
        "pt_BR::git.remote_convert")    echo "Converter para SSH? (s/N): " ;;
        "en_US::git.remote_convert")    echo "Convert to SSH? (y/N): " ;;
        "pt_BR::git.remote_converted")  echo "URL alterada para SSH" ;;
        "en_US::git.remote_converted")  echo "URL changed to SSH" ;;
        "pt_BR::git.requires_ssh")      echo "Este script requer SSH!" ;;
        "en_US::git.requires_ssh")      echo "This script requires SSH!" ;;
        "pt_BR::git.convert_hint")      echo "Execute: git remote set-url origin" ;;
        "en_US::git.convert_hint")      echo "Run: git remote set-url origin" ;;
        "pt_BR::git.remote_ok")         echo "Remote em SSH" ;;
        "en_US::git.remote_ok")         echo "Remote is using SSH" ;;
        "pt_BR::git.mods_check")        echo "Verificando modificações..." ;;
        "en_US::git.mods_check")        echo "Checking for modifications..." ;;
        "pt_BR::git.no_mods")           echo "Não há modificações para commitar" ;;
        "en_US::git.no_mods")           echo "No modifications to commit" ;;
        "pt_BR::git.mods_found")        echo "Modificações detectadas" ;;
        "en_US::git.mods_found")        echo "Modifications detected" ;;
        "pt_BR::git.branch")            echo "Branch atual:" ;;
        "en_US::git.branch")            echo "Current branch:" ;;

        # ------------------------------------------------------------------ #
        # INTERACTIVE MODE
        # ------------------------------------------------------------------ #
        "pt_BR::interactive.title")      echo "Modo Interativo" ;;
        "en_US::interactive.title")      echo "Interactive Mode" ;;
        "pt_BR::interactive.step1")      echo "PASSO 1/3: Definir Tag" ;;
        "en_US::interactive.step1")      echo "STEP 1/3: Define Tag" ;;
        "pt_BR::interactive.step2")      echo "PASSO 2/3: Mensagem da Tag" ;;
        "en_US::interactive.step2")      echo "STEP 2/3: Tag Message" ;;
        "pt_BR::interactive.step3")      echo "PASSO 3/3: Mensagem do Commit" ;;
        "en_US::interactive.step3")      echo "STEP 3/3: Commit Message" ;;
        "pt_BR::interactive.tag_prompt") echo "Digite a versão da tag: " ;;
        "en_US::interactive.tag_prompt") echo "Enter tag version: " ;;
        "pt_BR::interactive.tag_empty")  echo "Tag é obrigatória!" ;;
        "en_US::interactive.tag_empty")  echo "Tag is required!" ;;
        "pt_BR::interactive.tag_exists") echo "A tag já existe!" ;;
        "en_US::interactive.tag_exists") echo "Tag already exists!" ;;
        "pt_BR::interactive.tag_hint")   echo "Use: git tag -d" ;;
        "en_US::interactive.tag_hint")   echo "Use: git tag -d" ;;
        "pt_BR::interactive.tag_ok")     echo "Tag definida:" ;;
        "en_US::interactive.tag_ok")     echo "Tag defined:" ;;
        "pt_BR::interactive.collected")  echo "Informações coletadas!" ;;
        "en_US::interactive.collected")  echo "Information collected!" ;;
        "pt_BR::interactive.tag_eg")     echo "v2.9.1, v1.0.0-beta, v3.2.1-rc.1" ;;
        "en_US::interactive.tag_eg")     echo "v2.9.1, v1.0.0-beta, v3.2.1-rc.1" ;;
        "pt_BR::interactive.tagmsg_eg")  echo "Release %s - Novos recursos\n\n- feat: Nova funcionalidade\n- fix: Correção de bug" ;;
        "en_US::interactive.tagmsg_eg")  echo "Release %s - New features\n\n- feat: New functionality\n- fix: Bug fix" ;;
        "pt_BR::interactive.msg_eg")     echo "chore: Atualiza versão para %s\n\nPrepara release %s" ;;
        "en_US::interactive.msg_eg")     echo "chore: Update version to %s\n\nPrepare release %s" ;;

        # ------------------------------------------------------------------ #
        # INPUT HELPER
        # ------------------------------------------------------------------ #
        "pt_BR::input.paste")           echo "          Cole o texto (pressione Ctrl+D para finalizar)" ;;
        "en_US::input.paste")           echo "          Paste the text (press Ctrl+D to finish)" ;;
        "pt_BR::input.or_file")         echo "          OU informe o caminho do arquivo" ;;
        "en_US::input.or_file")         echo "          OR enter the file path" ;;
        "pt_BR::input.file_empty")      echo "Arquivo vazio:" ;;
        "en_US::input.file_empty")      echo "Empty file:" ;;
        "pt_BR::input.file_ok")         echo "Conteúdo lido do arquivo:" ;;
        "en_US::input.file_ok")         echo "Content read from file:" ;;
        "pt_BR::input.text_ok")         echo "Texto capturado com sucesso" ;;
        "en_US::input.text_ok")         echo "Text captured successfully" ;;
        "pt_BR::input.empty")           echo "Conteúdo não pode ser vazio!" ;;
        "en_US::input.empty")           echo "Content cannot be empty!" ;;
        "pt_BR::input.tagmsg_prompt")   echo "Mensagem da tag:" ;;
        "en_US::input.tagmsg_prompt")   echo "Tag message:" ;;
        "pt_BR::input.msg_prompt")      echo "Mensagem do commit:" ;;
        "en_US::input.msg_prompt")      echo "Commit message:" ;;

        # ------------------------------------------------------------------ #
        # TAG VALIDATION
        # ------------------------------------------------------------------ #
        "pt_BR::tag.invalid")           echo "Formato de tag inválido:" ;;
        "en_US::tag.invalid")           echo "Invalid tag format:" ;;
        "pt_BR::tag.semver_hint")       echo "Use versionamento semântico: v1.2.3, v2.0.0-beta, etc." ;;
        "en_US::tag.semver_hint")       echo "Use semantic versioning: v1.2.3, v2.0.0-beta, etc." ;;

        # ------------------------------------------------------------------ #
        # LEGACY MODE
        # ------------------------------------------------------------------ #
        "pt_BR::legacy.mode")           echo "Modo legado (argumentos)" ;;
        "en_US::legacy.mode")           echo "Legacy mode (arguments)" ;;
        "pt_BR::legacy.required")       echo "No modo legado, --tag, --msgtag e --msgcommit são obrigatórios!" ;;
        "en_US::legacy.required")       echo "In legacy mode, --tag, --msgtag and --msgcommit are required!" ;;
        "pt_BR::legacy.file_missing")   echo "Arquivo não encontrado:" ;;
        "en_US::legacy.file_missing")   echo "File not found:" ;;
        "pt_BR::legacy.file_empty")     echo "Arquivo de tag vazio!" ;;
        "en_US::legacy.file_empty")     echo "Tag file is empty!" ;;
        "pt_BR::legacy.commit_empty")   echo "Arquivo de commit vazio!" ;;
        "en_US::legacy.commit_empty")   echo "Commit file is empty!" ;;
        "pt_BR::legacy.tag_ok")         echo "Tag:" ;;
        "en_US::legacy.tag_ok")         echo "Tag:" ;;
        "pt_BR::legacy.tagmsg_ok")      echo "Mensagem da tag:" ;;
        "en_US::legacy.tagmsg_ok")      echo "Tag message:" ;;
        "pt_BR::legacy.msg_ok")         echo "Mensagem do commit:" ;;
        "en_US::legacy.msg_ok")         echo "Commit message:" ;;
        "pt_BR::legacy.unknown_opt")    echo "Opção desconhecida:" ;;
        "en_US::legacy.unknown_opt")    echo "Unknown option:" ;;

        # ------------------------------------------------------------------ #
        # PROCESSING STEPS
        # ------------------------------------------------------------------ #
        "pt_BR::proc.title")            echo "Processamento" ;;
        "en_US::proc.title")            echo "Processing" ;;
        "pt_BR::proc.modified")         echo "Arquivos modificados:" ;;
        "en_US::proc.modified")         echo "Modified files:" ;;
        "pt_BR::proc.adding")           echo "Adicionando arquivos..." ;;
        "en_US::proc.adding")           echo "Adding files..." ;;
        "pt_BR::proc.added")            echo "Arquivos adicionados" ;;
        "en_US::proc.added")            echo "Files added" ;;
        "pt_BR::proc.add_fail")         echo "Falha ao adicionar arquivos" ;;
        "en_US::proc.add_fail")         echo "Failed to add files" ;;
        "pt_BR::proc.committing")       echo "Criando commit..." ;;
        "en_US::proc.committing")       echo "Creating commit..." ;;
        "pt_BR::proc.committed")        echo "Commit criado" ;;
        "en_US::proc.committed")        echo "Commit created" ;;
        "pt_BR::proc.commit_fail")      echo "Falha no commit" ;;
        "en_US::proc.commit_fail")      echo "Commit failed" ;;
        "pt_BR::proc.tagging")          echo "Criando tag:" ;;
        "en_US::proc.tagging")          echo "Creating tag:" ;;
        "pt_BR::proc.tagged")           echo "Tag criada:" ;;
        "en_US::proc.tagged")           echo "Tag created:" ;;
        "pt_BR::proc.tag_fail")         echo "Falha na criação da tag" ;;
        "en_US::proc.tag_fail")         echo "Tag creation failed" ;;
        "pt_BR::proc.pushing")          echo "Enviando commit..." ;;
        "en_US::proc.pushing")          echo "Pushing commit..." ;;
        "pt_BR::proc.pushed")           echo "Push do commit realizado" ;;
        "en_US::proc.pushed")           echo "Commit pushed successfully" ;;
        "pt_BR::proc.push_fail")        echo "Falha no push" ;;
        "en_US::proc.push_fail")        echo "Push failed" ;;
        "pt_BR::proc.pushing_tag")      echo "Enviando tag..." ;;
        "en_US::proc.pushing_tag")      echo "Pushing tag..." ;;
        "pt_BR::proc.pushed_tag")       echo "Push da tag realizado" ;;
        "en_US::proc.pushed_tag")       echo "Tag pushed successfully" ;;
        "pt_BR::proc.push_tag_fail")    echo "Falha no push da tag" ;;
        "en_US::proc.push_tag_fail")    echo "Tag push failed" ;;

        # ------------------------------------------------------------------ #
        # SECTIONS
        # ------------------------------------------------------------------ #
        "pt_BR::section.ssh")           echo "  Validação SSH" ;;
        "en_US::section.ssh")           echo "  SSH Validation" ;;
        "pt_BR::section.git")           echo "  Validação Git" ;;
        "en_US::section.git")           echo "  Git Validation" ;;
        "pt_BR::section.done")          echo "  Concluído com Sucesso!" ;;
        "en_US::section.done")          echo "  Completed Successfully!" ;;

        # ------------------------------------------------------------------ #
        # SUMMARY
        # ------------------------------------------------------------------ #
        "pt_BR::summary.branch")        echo "Branch: " ;;
        "en_US::summary.branch")        echo "Branch: " ;;
        "pt_BR::summary.tag")           echo "Tag:    " ;;
        "en_US::summary.tag")           echo "Tag:    " ;;
        "pt_BR::summary.commit")        echo "Commit: " ;;
        "en_US::summary.commit")        echo "Commit: " ;;
        "pt_BR::summary.done")          echo "Todas as alterações foram enviadas!" ;;
        "en_US::summary.done")          echo "All changes have been pushed!" ;;

        # Default: return empty so the fallback chain can handle it
        *) echo "" ;;
    esac
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Clear screen without flicker using ANSI escape sequences
clear_screen() {
    printf '\033[2J\033[H'
}

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
    echo "$(t usage.title)"
    echo ""
    echo "$(t usage.interactive)"
    echo "  $0"
    echo ""
    echo "$(t usage.legacy)"
    echo "  $0 --tag <version> --msgtag <file> --msgcommit <file>"
    echo ""
    echo "$(t usage.options)"
    echo "$(t usage.opt.tag)"
    echo "$(t usage.opt.msgtag)"
    echo "$(t usage.opt.msgcommit)"
    echo "$(t usage.opt.help)"
    echo ""
    echo "$(t usage.examples)"
    echo "  $0"
    echo "  $0 --tag v1.2.3 --msgtag .msgtag --msgcommit .msgcommit"
    exit 0
}

# Read multi-line input or file path
read_input_or_file() {
    local prompt="$1"
    local example="$2"
    local result=""

    echo ""
    echo "$(t prefix.example) $example"
    echo ""
    echo "$(t prefix.input) $prompt"
    echo "$(t input.paste)"
    echo "$(t input.or_file)"
    echo ""

    read -r first_line

    if [ -f "$first_line" ]; then
        if [ ! -s "$first_line" ]; then
            echo "$(t prefix.error) $(t input.file_empty) $first_line"
            exit 1
        fi
        result=$(cat "$first_line")
        echo "$(t prefix.ok) $(t input.file_ok) $first_line"
    else
        result="$first_line"
        while IFS= read -r line; do
            result="${result}"$'\n'"${line}"
        done
        echo "$(t prefix.ok) $(t input.text_ok)"
    fi

    if [ -z "$result" ]; then
        echo "$(t prefix.error) $(t input.empty)"
        exit 1
    fi

    echo "$result"
}

# Validate semantic version tag format
validate_tag_format() {
    local tag="$1"

    if ! echo "$tag" | grep -qE "^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$"; then
        echo "$(t prefix.error) $(t tag.invalid) $tag"
        echo "$(t prefix.info) $(t tag.semver_hint)"
        exit 1
    fi
}

# ============================================================================
# SSH WIZARD
# ============================================================================

# Clear screen and render the wizard step status panel
_wizard_menu() {
    local current="$1"
    shift
    local states=("$@")

    clear_screen
    show_banner

    echo "════════════════════════════════════════"
    echo "$(t wizard.title)"
    echo "════════════════════════════════════════"
    echo "$(t wizard.menu_title)"
    echo "────────────────────────────────────────"

    local labels=(
        "$(t wizard.s1.label)"
        "$(t wizard.s2.label)"
        "$(t wizard.s3.label)"
        "$(t wizard.s4.label)"
        "$(t wizard.s5.label)"
    )

    for i in 0 1 2 3 4; do
        local marker
        if [ "${states[$i]}" = "done" ]; then
            marker="$(t wizard.step_done)"
        elif [ "$i" -eq "$current" ]; then
            marker="$(t wizard.step_current)"
        else
            marker="$(t wizard.step_todo)"
        fi
        echo "  $marker $((i+1)). ${labels[$i]}"
    done

    echo "────────────────────────────────────────"
    echo ""
}

# Interactive SSH setup wizard — executes real commands at each step
show_ssh_wizard() {
    clear_screen
    show_banner

    echo "════════════════════════════════════════"
    echo "$(t prefix.warn) $(t wizard.no_key_header)"
    echo "$(t prefix.info) $(t wizard.no_key_detail)"
    echo "════════════════════════════════════════"
    echo ""
    echo -n "$(t wizard.ask_setup)"
    read -r response

    # Accept S, s, Y, y or empty (default yes) — anything else aborts
    if [[ "$response" =~ ^[NnQq]$ ]]; then
        echo ""
        echo "$(t prefix.info) $(t wizard.aborted)"
        exit 0
    fi

    local states=("todo" "todo" "todo" "todo" "todo")
    local key_path="$HOME/.ssh/id_ed25519"

    # STEP 1 — Generate SSH key
    _wizard_menu 0 "${states[@]}"

    local ssh_email=""
    while [ -z "$ssh_email" ]; do
        echo -n "$(t wizard.s1.email_prompt)"
        read -r ssh_email
        if [ -z "$ssh_email" ]; then
            echo "$(t prefix.error) $(t wizard.s1.email_empty)"
        fi
    done

    echo -n "$(t wizard.s1.path_prompt)"
    read -r input_path
    [ -n "$input_path" ] && key_path="$input_path"

    echo ""
    echo "$(t prefix.info) $(t wizard.s1.generating)"
    echo ""

    ssh-keygen -t ed25519 -C "$ssh_email" -f "$key_path"

    if [ $? -eq 0 ] && [ -f "${key_path}.pub" ]; then
        echo ""
        echo "$(t prefix.ok) $(t wizard.s1.success)"
        states[0]="done"
    else
        echo ""
        echo "$(t prefix.error) $(t wizard.s1.fail)"
        exit 1
    fi

    echo ""
    echo -n "$(t wizard.prompt_next)"
    read -r _

    # STEP 2 — Start ssh-agent
    _wizard_menu 1 "${states[@]}"

    echo "$(t prefix.info) $(t ssh.agent_starting)"
    eval "$(ssh-agent -s)"
    echo "$(t prefix.ok) $(t ssh.agent_started)"
    echo "$(t wizard.s2.hint)"
    states[1]="done"

    echo ""
    echo -n "$(t wizard.prompt_next)"
    read -r _

    # STEP 3 — Add key to ssh-agent
    _wizard_menu 2 "${states[@]}"

    echo "$(t wizard.s3.cmd)"
    echo "$(t wizard.s3.hint)"
    echo ""
    ssh-add "$key_path"

    if [ $? -eq 0 ]; then
        states[2]="done"
        echo "$(t prefix.ok) $(t ssh.key_added)"
    else
        echo "$(t prefix.warn) $(t wizard.skipped)"
    fi

    echo ""
    echo -n "$(t wizard.prompt_next)"
    read -r _

    # STEP 4 — Show public key and GitHub instructions
    _wizard_menu 3 "${states[@]}"

    echo "$(t wizard.s4.intro)"
    echo "────────────────────────────────────────"
    cat "${key_path}.pub"
    echo "────────────────────────────────────────"
    echo ""
    echo "$(t wizard.s4.hint_copy)"
    echo ""
    echo "$(t wizard.s4.browser)"
    echo ""
    echo "$(t wizard.s4.i1)"
    echo "$(t wizard.s4.i2)"
    echo "$(t wizard.s4.i3)"
    echo "$(t wizard.s4.i4)"
    echo "$(t wizard.s4.i5)"
    states[3]="done"

    echo ""
    echo -n "$(t wizard.prompt_next)"
    read -r _

    # STEP 5 — Test GitHub connection
    _wizard_menu 4 "${states[@]}"

    echo "$(t prefix.ssh) $(t wizard.testing_conn)"
    echo ""
    echo "$(t wizard.s5.cmd)"
    echo "$(t wizard.s5.hint)"
    echo "$(t wizard.s5.auto)"
    echo ""

    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        states[4]="done"
        _wizard_menu 4 "${states[@]}"
        echo "$(t prefix.ok) $(t wizard.success)"
        echo ""
        return 0
    else
        echo "$(t prefix.error) $(t wizard.still_fail)"
        echo "$(t prefix.info) $(t wizard.exit_fail)"
        echo ""
        exit 1
    fi
}

# ============================================================================
# SSH VALIDATIONS
# ============================================================================

test_github_ssh() {
    echo "$(t prefix.ssh) $(t ssh.testing)"

    if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "$(t prefix.ok) $(t ssh.ok)"
        USERNAME=$(timeout 10 ssh -T git@github.com 2>&1 \
            | grep -o "Hi [^!]*" | cut -d' ' -f2)
        echo "$(t prefix.info) $(t ssh.connected_as) $USERNAME"
        return 0
    else
        echo "$(t prefix.error) $(t ssh.fail)"
        show_ssh_wizard
        exit 1
    fi
}

check_ssh_agent() {
    echo "$(t prefix.ssh) $(t ssh.agent_checking)"

    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        echo "$(t prefix.info) $(t ssh.agent_starting)"
        eval "$(ssh-agent -s)"
        echo "$(t prefix.ok) $(t ssh.agent_started)"
    else
        echo "$(t prefix.ok) $(t ssh.agent_running)"
    fi
}

check_ssh_keys_loaded() {
    echo "$(t prefix.ssh) $(t ssh.keys_checking)"

    if ssh-add -l > /dev/null 2>&1; then
        echo "$(t prefix.ok) $(t ssh.keys_loaded)"
        return 0
    fi

    echo "$(t prefix.info) $(t ssh.keys_searching)"

    # Priority order: ed25519 > rsa > ecdsa
    local SSH_KEYS=(
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ecdsa"
    )

    for key in "${SSH_KEYS[@]}"; do
        if [ -f "$key" ]; then
            echo "$(t prefix.info) $(t ssh.key_found) $key"
            echo "$(t prefix.info) $(t ssh.key_adding)"

            if ssh-add "$key" 2>/dev/null; then
                echo "$(t prefix.ok) $(t ssh.key_added)"
                return 0
            else
                ssh-add "$key"
                [ $? -eq 0 ] && return 0
            fi
        fi
    done

    echo "$(t prefix.warn) $(t ssh.no_keys)"
    show_ssh_wizard
}

# ============================================================================
# GIT VALIDATIONS
# ============================================================================

check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "$(t prefix.error) $(t git.not_repo)"
        exit 1
    fi
}

check_git_identity() {
    echo "$(t prefix.git) $(t git.identity_check)"

    GIT_NAME=$(git config user.name)
    GIT_EMAIL=$(git config user.email)

    [ -z "$GIT_NAME" ]  && GIT_NAME=$(git config --global user.name)
    [ -z "$GIT_EMAIL" ] && GIT_EMAIL=$(git config --global user.email)

    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        echo "$(t prefix.warn) $(t git.identity_warn)"
        echo ""

        GITHUB_USER=$(timeout 5 ssh -T git@github.com 2>&1 \
            | grep -o "Hi [^!]*" | cut -d' ' -f2)

        if [ -z "$GIT_NAME" ]; then
            if [ -n "$GITHUB_USER" ]; then
                echo "$(t prefix.info) $(t git.github_user) $GITHUB_USER"
                echo -n "$(t git.name_prompt) [$GITHUB_USER]: "
            else
                echo -n "$(t git.name_prompt): "
            fi
            read -r input_name
            GIT_NAME="${input_name:-$GITHUB_USER}"
            [ -z "$GIT_NAME" ] && {
                echo "$(t prefix.error) $(t git.name_empty)"
                exit 1
            }
        fi

        if [ -z "$GIT_EMAIL" ]; then
            SSH_EMAIL=$(ssh-add -L 2>/dev/null \
                | grep -o "[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}" \
                | head -n1)

            if [ -n "$SSH_EMAIL" ]; then
                echo "$(t prefix.info) $(t git.email_detected) $SSH_EMAIL"
                echo -n "$(t git.email_prompt) [$SSH_EMAIL]: "
            else
                echo -n "$(t git.email_prompt): "
            fi
            read -r input_email
            GIT_EMAIL="${input_email:-$SSH_EMAIL}"

            [ -z "$GIT_EMAIL" ] && {
                echo "$(t prefix.error) $(t git.email_empty)"
                exit 1
            }

            if ! echo "$GIT_EMAIL" \
                | grep -qE "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"; then
                echo "$(t prefix.error) $(t git.email_invalid)"
                exit 1
            fi
        fi

        echo ""
        echo "$(t git.scope_prompt)"
        echo "$(t git.scope_local)"
        echo "$(t git.scope_global)"
        echo -n "$(t git.scope_choice)"
        read -r config_scope
        config_scope="${config_scope:-2}"

        if [ "$config_scope" = "2" ]; then
            git config --global user.name  "$GIT_NAME"
            git config --global user.email "$GIT_EMAIL"
            echo "$(t prefix.ok) $(t git.identity_global)"
        else
            git config user.name  "$GIT_NAME"
            git config user.email "$GIT_EMAIL"
            echo "$(t prefix.ok) $(t git.identity_local)"
        fi

        echo "$(t prefix.info) $(t git.identity_name) $GIT_NAME"
        echo "$(t prefix.info) $(t git.identity_email) $GIT_EMAIL"
    else
        echo "$(t prefix.ok) $(t git.identity_ok)"
        echo "$(t prefix.info) $(t git.identity_name) $GIT_NAME"
        echo "$(t prefix.info) $(t git.identity_email) $GIT_EMAIL"
    fi
}

check_remote_url() {
    echo "$(t prefix.git) $(t git.remote_check)"

    REMOTE_URL=$(git config --get remote.origin.url)

    if [ -z "$REMOTE_URL" ]; then
        echo "$(t prefix.error) $(t git.no_remote)"
        exit 1
    fi

    if echo "$REMOTE_URL" | grep -q "https://"; then
        echo "$(t prefix.warn) $(t git.remote_https)"
        echo "$(t prefix.info) $(t git.remote_current) $REMOTE_URL"

        SSH_URL=$(echo "$REMOTE_URL" \
            | sed 's|https://github.com/|git@github.com:|')
        echo "$(t prefix.info) $(t git.remote_ssh_url) $SSH_URL"

        echo -n "$(t git.remote_convert)"
        read -r response

        if [[ "$response" =~ ^[SsYy]$ ]]; then
            git remote set-url origin "$SSH_URL"
            echo "$(t prefix.ok) $(t git.remote_converted)"
        else
            echo "$(t prefix.error) $(t git.requires_ssh)"
            echo "$(t prefix.hint) $(t git.convert_hint) $SSH_URL"
            exit 1
        fi
    else
        echo "$(t prefix.ok) $(t git.remote_ok)"
        echo "$(t prefix.info) $REMOTE_URL"
    fi
}

check_modifications() {
    echo "$(t prefix.git) $(t git.mods_check)"

    if [ -z "$(git status --porcelain)" ]; then
        echo "$(t prefix.warn) $(t git.no_mods)"
        exit 0
    fi

    echo "$(t prefix.ok) $(t git.mods_found)"
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

interactive_mode() {
    echo "════════════════════════════════════════"
    echo "  $(t interactive.title)"
    echo "════════════════════════════════════════"

    # STEP 1: TAG
    echo ""
    echo "────────────────────────────────────────"
    echo "  $(t interactive.step1)"
    echo "────────────────────────────────────────"
    echo ""
    echo "$(t prefix.example) $(t interactive.tag_eg)"
    echo ""
    echo -n "$(t interactive.tag_prompt)"
    read -r TAG

    if [ -z "$TAG" ]; then
        echo "$(t prefix.error) $(t interactive.tag_empty)"
        exit 1
    fi

    validate_tag_format "$TAG"

    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "$(t prefix.error) $(t interactive.tag_exists) $TAG"
        echo "$(t prefix.hint) $(t interactive.tag_hint) $TAG"
        exit 1
    fi

    echo "$(t prefix.ok) $(t interactive.tag_ok) $TAG"

    # STEP 2: TAG MESSAGE
    echo ""
    echo "────────────────────────────────────────"
    echo "  $(t interactive.step2)"
    echo "────────────────────────────────────────"

    local tagmsg_eg
    # shellcheck disable=SC2059
    tagmsg_eg=$(printf "$(t interactive.tagmsg_eg)" "$TAG")

    TAG_MSG=$(read_input_or_file \
        "$(t input.tagmsg_prompt)" \
        "$tagmsg_eg")

    # STEP 3: COMMIT MESSAGE
    echo ""
    echo "────────────────────────────────────────"
    echo "  $(t interactive.step3)"
    echo "────────────────────────────────────────"

    local msg_eg
    # shellcheck disable=SC2059
    msg_eg=$(printf "$(t interactive.msg_eg)" "$TAG" "$TAG")

    COMMIT_MSG=$(read_input_or_file \
        "$(t input.msg_prompt)" \
        "$msg_eg")

    echo ""
    echo "$(t prefix.ok) $(t interactive.collected)"
    echo ""
}

# ============================================================================
# MAIN PROCESSING
# ============================================================================

LEGACY_MODE=false
TAG_MSG_FILE=""
COMMIT_MSG_FILE=""

# Detect locale before any output
detect_locale

while [ $# -gt 0 ]; do
    case "$1" in
        --tag)
            TAG="$2"
            LEGACY_MODE=true
            shift 2
            ;;
        --msgtag)
            TAG_MSG_FILE="$2"
            shift 2
            ;;
        --msgcommit)
            COMMIT_MSG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "$(t prefix.error) $(t legacy.unknown_opt) $1"
            show_usage
            ;;
    esac
done

# Banner
show_banner

# SSH VALIDATIONS
echo "════════════════════════════════════════"
echo "$(t section.ssh)"
echo "════════════════════════════════════════"
echo ""

test_github_ssh
check_ssh_agent
check_ssh_keys_loaded

echo ""

# GIT VALIDATIONS
echo "════════════════════════════════════════"
echo "$(t section.git)"
echo "════════════════════════════════════════"
echo ""

check_git_repo
check_git_identity
check_remote_url
check_modifications

echo ""
echo "$(t prefix.info) $(t git.branch) $BRANCH"
echo ""

# OPERATION MODE
if [ "$LEGACY_MODE" = true ]; then
    echo "$(t prefix.info) $(t legacy.mode)"

    if [ -z "$TAG" ] || [ -z "$TAG_MSG_FILE" ] || [ -z "$COMMIT_MSG_FILE" ]; then
        echo "$(t prefix.error) $(t legacy.required)"
        show_usage
    fi

    validate_tag_format "$TAG"

    if [ ! -f "$TAG_MSG_FILE" ]; then
        echo "$(t prefix.error) $(t legacy.file_missing) $TAG_MSG_FILE"
        exit 1
    fi

    if [ ! -f "$COMMIT_MSG_FILE" ]; then
        echo "$(t prefix.error) $(t legacy.file_missing) $COMMIT_MSG_FILE"
        exit 1
    fi

    if [ ! -s "$TAG_MSG_FILE" ]; then
        echo "$(t prefix.error) $(t legacy.file_empty)"
        exit 1
    fi

    if [ ! -s "$COMMIT_MSG_FILE" ]; then
        echo "$(t prefix.error) $(t legacy.commit_empty)"
        exit 1
    fi

    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "$(t prefix.error) $(t interactive.tag_exists) $TAG"
        exit 1
    fi

    TAG_MSG=$(cat "$TAG_MSG_FILE")
    COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

    echo "$(t prefix.ok) $(t legacy.tag_ok) $TAG"
    echo "$(t prefix.ok) $(t legacy.tagmsg_ok) $TAG_MSG_FILE"
    echo "$(t prefix.ok) $(t legacy.msg_ok) $COMMIT_MSG_FILE"
else
    interactive_mode
fi

# EXECUTION
echo ""
echo "════════════════════════════════════════"
echo "  $(t proc.title)"
echo "════════════════════════════════════════"
echo ""

echo "$(t prefix.status) $(t proc.modified)"
git status --short
echo ""

echo "[1/5] $(t proc.adding)"
if git add .; then
    echo "$(t prefix.ok) $(t proc.added)"
else
    echo "$(t prefix.error) $(t proc.add_fail)"
    exit 1
fi
echo ""

echo "[2/5] $(t proc.committing)"
if echo "$COMMIT_MSG" | git commit -F -; then
    echo "$(t prefix.ok) $(t proc.committed)"
else
    echo "$(t prefix.error) $(t proc.commit_fail)"
    exit 1
fi
echo ""

echo "[3/5] $(t proc.tagging) $TAG"
if echo "$TAG_MSG" | git tag -a "$TAG" -F -; then
    echo "$(t prefix.ok) $(t proc.tagged) $TAG"
else
    echo "$(t prefix.error) $(t proc.tag_fail)"
    exit 1
fi
echo ""

echo "[4/5] $(t proc.pushing)"
if git push origin "$BRANCH"; then
    echo "$(t prefix.ok) $(t proc.pushed)"
else
    echo "$(t prefix.error) $(t proc.push_fail)"
    exit 1
fi
echo ""

echo "[5/5] $(t proc.pushing_tag)"
if git push origin "$TAG"; then
    echo "$(t prefix.ok) $(t proc.pushed_tag)"
else
    echo "$(t prefix.error) $(t proc.push_tag_fail)"
    exit 1
fi
echo ""

# SUMMARY
echo "════════════════════════════════════════"
echo "$(t section.done)"
echo "════════════════════════════════════════"
echo ""
echo "$(t summary.branch) $BRANCH"
echo "$(t summary.tag) $TAG"
echo "$(t summary.commit) ${COMMIT_MSG:0:50}..."
echo ""
echo "$(t summary.done)"
echo ""