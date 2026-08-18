#!/usr/bin/env bash
#
# organize_downloads.sh
#
# Organiza arquivos de uma pasta (por padrao, ~/Downloads) em subpastas por
# categoria, com base na extensao do arquivo.
#
# Reescrito em shell a partir de um script Python original inspirado em:
# https://medium.com/@gamsahamidah95/organize-files-in-folders-using-python-script-49fdd4afc6d5
#
# Correcoes em relacao ao script original:
#   - shutil.move() + os.remove() no arquivo de origem era redundante e o
#     erro era sempre engolido por "except: pass" -> aqui usamos `mv` puro
#     e tratamos erros de verdade.
#   - Comparacao de extensao era case-sensitive em alguns pontos (".PDF" e
#     ".pdf" viviam como entradas duplicadas) -> aqui tudo e comparado em
#     minusculas.
#   - "crdownload" estava sem o ponto e era tratado como categoria valida,
#     fazendo o script mover downloads *incompletos* -> aqui esses arquivos
#     sao ignorados por padrao (assim como .part, .tmp, .partial etc).
#   - Nao havia protecao contra conflito de nomes (um arquivo podia
#     sobrescrever outro na pasta de destino) -> aqui o script renomeia
#     automaticamente (ou pula/sobrescreve, conforme a opcao escolhida).
#   - Extensoes duplicadas na mesma categoria (.jpeg/.jpg repetidos) foram
#     removidas.
#   - Script so funcionava em Linux (os.getlogin()) -> aqui usamos $HOME,
#     que funciona em Linux e macOS.
#
# Funcionalidades novas:
#   --dry-run          Mostra o que seria feito, sem mover nada.
#   --log FILE          Grava um log (para permitir desfazer depois).
#   --undo FILE          Desfaz os movimentos registrados em um log.
#   --min-age N          So mexe em arquivos com mais de N minutos (evita
#                        pegar arquivo que ainda esta sendo baixado).
#   --recursive          Organiza tambem subpastas (ignorando as pastas de
#                        categoria ja criadas, para nao entrar em loop).
#   --include-hidden      Inclui arquivos ocultos (comecam com ".").
#   --no-catch-all        Nao move arquivos sem categoria para "Other".
#   --on-conflict MODE     rename (padrao) | skip | overwrite
#   --config FILE          Carrega um arquivo de configuracao (bash) que
#                        pode redefinir CATEGORIES / EXCLUDE_PATTERNS.
#   --list                Mostra as categorias/extensoes configuradas e sai.
#   --notify              Envia notificacao (notify-send) com o resumo.
#   --install-cron HH:MM    Instala uma tarefa cron diaria que roda este
#                        script com as mesmas opcoes.
#   --quiet / --verbose
#
# Uso:
#   ./organize_downloads.sh [opcoes]
#   ./organize_downloads.sh --dry-run
#   ./organize_downloads.sh --source ~/Desktop --recursive
#   ./organize_downloads.sh --undo ~/.organize_downloads.log
#
set -uo pipefail

# ---------------------------------------------------------------------------
# Configuracao padrao (pode ser sobrescrita por --config)
# ---------------------------------------------------------------------------

SOURCE_DIR="$HOME/Downloads"
DRY_RUN=false
VERBOSE=false
QUIET=false
RECURSIVE=false
INCLUDE_HIDDEN=false
CATCH_ALL=true
MIN_AGE_MIN=0
LOG_FILE=""
UNDO_FILE=""
CONFIG_FILE=""
CONFLICT_STRATEGY="rename"   # rename | skip | overwrite
NOTIFY=false
LIST_ONLY=false
INSTALL_CRON_TIME=""

# Ordem em que as categorias sao testadas (a primeira que combinar vence).
CATEGORY_ORDER=(Images Documents Archives Videos Audio Programming Installers Torrents Personal Work Other)

declare -A CATEGORIES=(
  [Images]=".jpg .jpeg .png .gif .svg .bmp .bitmap .webp .heic .tiff .ico"
  [Documents]=".doc .docx .pdf .txt .xlsx .xls .odt .odp .ods .csv .ppt .pptx .rtf .md .epub"
  [Archives]=".zip .rar .dmg .iso .bz2 .gz .7z .xz .tar .tgz .tar.gz .tar.bz2 .tar.xz"
  [Videos]=".mp4 .mov .mkv .srt .avi .webm .flv .wmv .m4v"
  [Audio]=".mp3 .wav .flac .ogg .m4a .aac"
  [Programming]=".sql .py .java .dia .json .php .html .htm .js .ts .css .sh .dtd .jar .mwb .bak .autosave .draw.io .drawio .yaml .yml .xml .c .cpp .go .rb"
  [Installers]=".flatpak .deb .rpm .exe .msi .appimage .flatpakref .whl .pkg"
  [Torrents]=".torrent"
  [Personal]=".opml"
  [Work]=".roz"
  [Other]=""
)

# Arquivos que NUNCA devem ser movidos (downloads em andamento, temporarios).
EXCLUDE_PATTERNS=(".crdownload" ".part" ".partial" ".download" ".tmp" ".!qb" ".opdownload")

declare -A MOVED_COUNT=()
SKIPPED_COUNT=0
ERROR_COUNT=0

# ---------------------------------------------------------------------------
# Cores (desativadas se a saida nao for um terminal)
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'; C_BLUE=$'\033[34m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_BLUE=""; C_BOLD=""
fi

log_info()  { $QUIET || echo "${C_BLUE}[info]${C_RESET} $*"; }
log_ok()    { $QUIET || echo "${C_GREEN}[ok]${C_RESET} $*"; }
log_warn()  { echo "${C_YELLOW}[aviso]${C_RESET} $*" >&2; }
log_err()   { echo "${C_RED}[erro]${C_RESET} $*" >&2; }
log_verbose() { $VERBOSE && echo "${C_BOLD}[verbose]${C_RESET} $*"; return 0; }

# ---------------------------------------------------------------------------
# Ajuda
# ---------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Uso: organize_downloads.sh [opcoes]

Opcoes:
  -s, --source DIR        Pasta a organizar (padrao: ~/Downloads)
  -n, --dry-run           Mostra o que seria feito, sem mover nada
  -r, --recursive         Entra em subpastas (ignora pastas de categoria)
      --include-hidden    Inclui arquivos ocultos (comecam com '.')
      --no-catch-all      Nao cria/usa a categoria "Other" para sobras
      --min-age MINUTOS   So mexe em arquivos mais antigos que N minutos
      --on-conflict MODO  rename (padrao) | skip | overwrite
  -l, --log ARQUIVO       Grava um log das movimentacoes (para --undo)
  -u, --undo ARQUIVO      Desfaz as movimentacoes registradas nesse log
  -c, --config ARQUIVO    Carrega definicoes customizadas de categorias
      --list              Lista categorias/extensoes configuradas e sai
      --notify            Notifica o resultado via notify-send (se houver)
      --install-cron HH:MM  Instala tarefa cron diaria com estas opcoes
  -v, --verbose           Log detalhado
  -q, --quiet             Log minimo (so erros)
  -h, --help              Mostra esta ajuda

Exemplos:
  organize_downloads.sh --dry-run
  organize_downloads.sh --source ~/Desktop --recursive --min-age 5
  organize_downloads.sh --log ~/.organize.log
  organize_downloads.sh --undo ~/.organize.log
EOF
}

# ---------------------------------------------------------------------------
# Parse de argumentos
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source) SOURCE_DIR="$2"; shift 2 ;;
    -n|--dry-run) DRY_RUN=true; shift ;;
    -r|--recursive) RECURSIVE=true; shift ;;
    --include-hidden) INCLUDE_HIDDEN=true; shift ;;
    --no-catch-all) CATCH_ALL=false; shift ;;
    --min-age) MIN_AGE_MIN="$2"; shift 2 ;;
    --on-conflict) CONFLICT_STRATEGY="$2"; shift 2 ;;
    -l|--log) LOG_FILE="$2"; shift 2 ;;
    -u|--undo) UNDO_FILE="$2"; shift 2 ;;
    -c|--config) CONFIG_FILE="$2"; shift 2 ;;
    --list) LIST_ONLY=true; shift ;;
    --notify) NOTIFY=true; shift ;;
    --install-cron) INSTALL_CRON_TIME="$2"; shift 2 ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -q|--quiet) QUIET=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log_err "Opcao desconhecida: $1"; usage; exit 1 ;;
  esac
done

if [[ -n "$CONFIG_FILE" ]]; then
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    log_verbose "Configuracao carregada de $CONFIG_FILE"
  else
    log_err "Arquivo de configuracao nao encontrado: $CONFIG_FILE"
    exit 1
  fi
fi

# Expande ~ manualmente (util quando vem de --source/--log/--undo)
expand_path() { eval echo "$1"; }
SOURCE_DIR="$(expand_path "$SOURCE_DIR")"
[[ -n "$LOG_FILE" ]] && LOG_FILE="$(expand_path "$LOG_FILE")"
[[ -n "$UNDO_FILE" ]] && UNDO_FILE="$(expand_path "$UNDO_FILE")"

# ---------------------------------------------------------------------------
# --list
# ---------------------------------------------------------------------------

if $LIST_ONLY; then
  echo "${C_BOLD}Categorias configuradas:${C_RESET}"
  for cat in "${CATEGORY_ORDER[@]}"; do
    printf "  %-12s %s\n" "$cat" "${CATEGORIES[$cat]:-<catch-all>}"
  done
  echo
  echo "${C_BOLD}Sempre ignorados:${C_RESET} ${EXCLUDE_PATTERNS[*]}"
  exit 0
fi

# ---------------------------------------------------------------------------
# --install-cron
# ---------------------------------------------------------------------------

if [[ -n "$INSTALL_CRON_TIME" ]]; then
  if ! command -v crontab >/dev/null 2>&1; then
    log_err "crontab nao disponivel neste sistema."
    exit 1
  fi
  hh="${INSTALL_CRON_TIME%%:*}"
  mm="${INSTALL_CRON_TIME##*:}"
  script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  cron_line="$mm $hh * * * \"$script_path\" --source \"$SOURCE_DIR\" --log \"$HOME/.organize_downloads.log\" --min-age 5 >> \"$HOME/.organize_downloads.cron.log\" 2>&1"
  ( crontab -l 2>/dev/null | grep -vF "$script_path"; echo "$cron_line" ) | crontab -
  log_ok "Tarefa cron instalada para rodar todo dia as $INSTALL_CRON_TIME."
  exit 0
fi

# ---------------------------------------------------------------------------
# --undo
# ---------------------------------------------------------------------------

if [[ -n "$UNDO_FILE" ]]; then
  if [[ ! -f "$UNDO_FILE" ]]; then
    log_err "Arquivo de log nao encontrado: $UNDO_FILE"
    exit 1
  fi
  log_info "Desfazendo movimentacoes de $UNDO_FILE ..."
  restored=0
  # Le o log de tras pra frente, formato: timestamp|origem|destino
  while IFS='|' read -r ts src dst; do
    [[ -z "${dst:-}" ]] && continue
    if [[ -f "$dst" ]]; then
      if [[ -e "$src" ]]; then
        log_warn "Origem ja existe, pulando: $src"
        continue
      fi
      mkdir -p "$(dirname "$src")"
      if $DRY_RUN; then
        log_info "[dry-run] restauraria: $dst -> $src"
      else
        mv -- "$dst" "$src" && { log_ok "Restaurado: $src"; restored=$((restored+1)); }
      fi
    else
      log_warn "Destino nao existe mais, pulando: $dst"
    fi
  done < <(tac -- "$UNDO_FILE" 2>/dev/null || tail -r -- "$UNDO_FILE")
  log_ok "Concluido. $restored arquivo(s) restaurado(s)."
  exit 0
fi

# ---------------------------------------------------------------------------
# Validacoes
# ---------------------------------------------------------------------------

if [[ ! -d "$SOURCE_DIR" ]]; then
  log_err "Pasta de origem nao existe: $SOURCE_DIR"
  exit 1
fi

case "$CONFLICT_STRATEGY" in
  rename|skip|overwrite) ;;
  *) log_err "Valor invalido para --on-conflict: $CONFLICT_STRATEGY (use rename|skip|overwrite)"; exit 1 ;;
esac

if [[ -n "$LOG_FILE" ]]; then
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
fi

log_info "Organizando: $SOURCE_DIR"
$DRY_RUN && log_info "Modo dry-run ativado: nada sera movido de fato."

# ---------------------------------------------------------------------------
# Funcoes principais
# ---------------------------------------------------------------------------

# Verifica se um nome de arquivo deve ser ignorado (download incompleto etc.)
is_excluded() {
  local fname_lc="${1,,}"
  local pat
  for pat in "${EXCLUDE_PATTERNS[@]}"; do
    [[ "$fname_lc" == *"${pat,,}" ]] && return 0
  done
  return 1
}

# Descobre a categoria de um arquivo com base na extensao (case-insensitive).
# Ecoa o nome da categoria e retorna 0, ou retorna 1 se nao achou nenhuma
# (e catch-all estiver desativado).
get_category() {
  local fname_lc="${1,,}"
  local cat pats pat
  for cat in "${CATEGORY_ORDER[@]}"; do
    [[ "$cat" == "Other" ]] && continue
    pats="${CATEGORIES[$cat]:-}"
    for pat in $pats; do
      [[ -z "$pat" ]] && continue
      if [[ "$fname_lc" == *"${pat,,}" ]]; then
        echo "$cat"
        return 0
      fi
    done
  done
  if $CATCH_ALL; then
    echo "Other"
    return 0
  fi
  return 1
}

# Gera um caminho de destino livre, evitando sobrescrever arquivos.
unique_destination() {
  local dest_dir="$1" fname="$2" base ext candidate n=1
  candidate="$dest_dir/$fname"
  if [[ ! -e "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi
  case "$CONFLICT_STRATEGY" in
    overwrite) echo "$candidate"; return 0 ;;
    skip) echo ""; return 0 ;;
  esac
  # rename: nome (1).ext, nome (2).ext, ...
  if [[ "$fname" == *.* && "$fname" != .* ]]; then
    base="${fname%.*}"
    ext=".${fname##*.}"
  else
    base="$fname"
    ext=""
  fi
  while [[ -e "$dest_dir/${base} (${n})${ext}" ]]; do
    n=$((n+1))
  done
  echo "$dest_dir/${base} (${n})${ext}"
}

move_one_file() {
  local src="$1" fname dest_dir dest category
  fname="$(basename -- "$src")"

  if ! $INCLUDE_HIDDEN && [[ "$fname" == .* ]]; then
    log_verbose "Ignorando oculto: $fname"
    return 0
  fi

  if is_excluded "$fname"; then
    log_verbose "Ignorando (download incompleto/temporario): $fname"
    return 0
  fi

  if ! category="$(get_category "$fname")"; then
    log_verbose "Sem categoria e catch-all desativado, pulando: $fname"
    SKIPPED_COUNT=$((SKIPPED_COUNT+1))
    return 0
  fi

  dest_dir="$SOURCE_DIR/$category"
  dest="$(unique_destination "$dest_dir" "$fname")"

  if [[ -z "$dest" ]]; then
    log_warn "Conflito, pulando (on-conflict=skip): $fname"
    SKIPPED_COUNT=$((SKIPPED_COUNT+1))
    return 0
  fi

  if $DRY_RUN; then
    log_info "[dry-run] $fname -> $category/"
    MOVED_COUNT[$category]=$(( ${MOVED_COUNT[$category]:-0} + 1 ))
    return 0
  fi

  mkdir -p "$dest_dir"
  if mv -- "$src" "$dest" 2>/tmp/organize_err.$$; then
    log_verbose "$fname -> $category/"
    MOVED_COUNT[$category]=$(( ${MOVED_COUNT[$category]:-0} + 1 ))
    if [[ -n "$LOG_FILE" ]]; then
      printf '%s|%s|%s\n' "$(date -Iseconds 2>/dev/null || date)" "$src" "$dest" >> "$LOG_FILE"
    fi
  else
    log_err "Falha ao mover '$fname': $(cat /tmp/organize_err.$$ 2>/dev/null)"
    ERROR_COUNT=$((ERROR_COUNT+1))
  fi
  rm -f /tmp/organize_err.$$
}

# ---------------------------------------------------------------------------
# Cria as pastas de categoria de antemao (exceto em dry-run)
# ---------------------------------------------------------------------------

if ! $DRY_RUN; then
  for cat in "${CATEGORY_ORDER[@]}"; do
    mkdir -p "$SOURCE_DIR/$cat"
  done
fi

# ---------------------------------------------------------------------------
# Monta a lista de arquivos a processar
# ---------------------------------------------------------------------------

find_args=("$SOURCE_DIR")
if ! $RECURSIVE; then
  find_args+=(-mindepth 1 -maxdepth 1)
else
  find_args+=(-mindepth 1)
  # Nao entra nas pastas de categoria que o proprio script criou/usa,
  # para nao reprocessar arquivos ja organizados.
  prune_expr=()
  for cat in "${CATEGORY_ORDER[@]}"; do
    prune_expr+=(-path "$SOURCE_DIR/$cat" -o)
  done
  unset 'prune_expr[${#prune_expr[@]}-1]'   # remove o -o final
  find_args+=(\( "${prune_expr[@]}" \) -prune -o)
fi
find_args+=(-type f)
if [[ "$MIN_AGE_MIN" =~ ^[0-9]+$ ]] && [[ "$MIN_AGE_MIN" -gt 0 ]]; then
  find_args+=(-mmin "+$MIN_AGE_MIN")
fi
find_args+=(-print0)

file_count=0
while IFS= read -r -d '' filepath; do
  file_count=$((file_count+1))
  move_one_file "$filepath"
done < <(find "${find_args[@]}" 2>/dev/null)

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------

echo
echo "${C_BOLD}Resumo${C_RESET}"
total_moved=0
for cat in "${CATEGORY_ORDER[@]}"; do
  count="${MOVED_COUNT[$cat]:-0}"
  [[ "$count" -eq 0 ]] && continue
  total_moved=$((total_moved+count))
  printf "  %-12s %s\n" "$cat" "$count"
done
echo "  ------------------------"
echo "  Movidos:  $total_moved"
echo "  Pulados:  $SKIPPED_COUNT"
echo "  Erros:    $ERROR_COUNT"
$DRY_RUN && echo "  (dry-run: nada foi realmente movido)"

if $NOTIFY && command -v notify-send >/dev/null 2>&1; then
  notify-send "Organize Downloads" "Movidos: $total_moved | Pulados: $SKIPPED_COUNT | Erros: $ERROR_COUNT"
fi

if [[ "$ERROR_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
