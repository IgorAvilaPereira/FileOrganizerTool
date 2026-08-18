# Organize Downloads

Script Bash para **organizar automaticamente arquivos de uma pasta em subpastas por categoria**, utilizando a extensão dos arquivos como critério de classificação.

Por padrão, o script organiza a pasta `~/Downloads`, separando arquivos em categorias como `Images`, `Documents`, `Videos`, `Audio`, `Programming`, `Archives`, `Installers` e outras.

O script foi desenvolvido como uma reescrita em Shell de um script Python original, incorporando melhorias de segurança, tratamento de conflitos, possibilidade de desfazer operações, execução em modo de teste e configuração personalizada.

## ✨ Funcionalidades

* 📁 Organização automática por extensão.
* 🔤 Reconhecimento de extensões sem diferenciar maiúsculas e minúsculas.
* 🛡️ Proteção contra sobrescrita acidental de arquivos.
* 🔄 Renomeação automática em caso de conflito.
* 🧪 Modo `--dry-run` para simular a execução.
* ↩️ Possibilidade de desfazer movimentações usando `--undo`.
* 📝 Registro das movimentações em arquivo de log.
* ⏱️ Filtro por idade dos arquivos com `--min-age`.
* 📂 Suporte à organização recursiva de subpastas.
* 👻 Opção para incluir arquivos ocultos.
* 🚫 Ignora downloads incompletos e arquivos temporários.
* ⚙️ Suporte a arquivo de configuração personalizado.
* 🔔 Notificações via `notify-send`.
* 🕐 Instalação de execução automática diária via `cron`.
* 📋 Listagem das categorias e extensões configuradas.
* 🤫 Modo silencioso e modo detalhado.
* 🖥️ Compatível com Linux e macOS, utilizando `$HOME` em vez de mecanismos específicos de login.

---

## 📂 Categorias padrão

Os arquivos são classificados nas seguintes categorias:

| Categoria       | Extensões                                                                                                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Images**      | `.jpg`, `.jpeg`, `.png`, `.gif`, `.svg`, `.bmp`, `.bitmap`, `.webp`, `.heic`, `.tiff`, `.ico`                                                                                                       |
| **Documents**   | `.doc`, `.docx`, `.pdf`, `.txt`, `.xlsx`, `.xls`, `.odt`, `.odp`, `.ods`, `.csv`, `.ppt`, `.pptx`, `.rtf`, `.md`, `.epub`                                                                           |
| **Archives**    | `.zip`, `.rar`, `.dmg`, `.iso`, `.bz2`, `.gz`, `.7z`, `.xz`, `.tar`, `.tgz`, `.tar.gz`, `.tar.bz2`, `.tar.xz`                                                                                       |
| **Videos**      | `.mp4`, `.mov`, `.mkv`, `.srt`, `.avi`, `.webm`, `.flv`, `.wmv`, `.m4v`                                                                                                                             |
| **Audio**       | `.mp3`, `.wav`, `.flac`, `.ogg`, `.m4a`, `.aac`                                                                                                                                                     |
| **Programming** | `.sql`, `.py`, `.java`, `.json`, `.php`, `.html`, `.htm`, `.js`, `.ts`, `.css`, `.sh`, `.dtd`, `.jar`, `.mwb`, `.bak`, `.autosave`, `.draw.io`, `.yaml`, `.yml`, `.xml`, `.c`, `.cpp`, `.go`, `.rb` |
| **Installers**  | `.flatpak`, `.deb`, `.rpm`, `.exe`, `.msi`, `.appimage`, `.flatpakref`, `.whl`, `.pkg`                                                                                                              |
| **Torrents**    | `.torrent`                                                                                                                                                                                          |
| **Personal**    | `.opml`                                                                                                                                                                                             |
| **Work**        | `.roz`                                                                                                                                                                                              |
| **Other**       | Arquivos que não correspondem a nenhuma extensão conhecida                                                                                                                                          |

A primeira categoria que corresponder à extensão do arquivo será utilizada.

---

## 🚀 Instalação

Clone ou copie o script para o computador e dê permissão de execução:

```bash
chmod +x organize_downloads.sh
```

Depois, execute:

```bash
./organize_downloads.sh
```

Por padrão, a pasta organizada será:

```text
~/Downloads
```

Após a execução, a estrutura poderá ficar semelhante a:

```text
Downloads/
├── Images/
├── Documents/
├── Archives/
├── Videos/
├── Audio/
├── Programming/
├── Installers/
├── Torrents/
├── Personal/
├── Work/
└── Other/
```

---

## 📖 Uso

Sintaxe geral:

```bash
./organize_downloads.sh [opções]
```

### Simular a organização

Antes de mover qualquer arquivo, é possível verificar o que seria feito:

```bash
./organize_downloads.sh --dry-run
```

Nesse modo, nenhum arquivo é realmente movido.

---

### Organizar outra pasta

Para organizar uma pasta diferente de `~/Downloads`:

```bash
./organize_downloads.sh --source ~/Desktop
```

Também é possível utilizar caminhos absolutos:

```bash
./organize_downloads.sh --source /home/igor/Downloads
```

---

### Organização recursiva

Por padrão, somente os arquivos diretamente dentro da pasta de origem são processados.

Para incluir subpastas:

```bash
./organize_downloads.sh --recursive
```

As próprias pastas de categoria (`Images`, `Documents`, etc.) são ignoradas durante a busca, evitando que arquivos já organizados sejam processados novamente.

---

### Ignorar arquivos recém-baixados

Para evitar que um arquivo ainda esteja sendo baixado enquanto o script tenta movê-lo:

```bash
./organize_downloads.sh --min-age 5
```

Nesse exemplo, somente arquivos com mais de **5 minutos** serão processados.

Essa opção é especialmente útil quando o script é executado automaticamente.

---

## 🔀 Conflitos de nomes

Se já existir um arquivo com o mesmo nome na pasta de destino, o comportamento pode ser configurado com `--on-conflict`.

### Renomear automaticamente — padrão

```bash
./organize_downloads.sh --on-conflict rename
```

Por exemplo:

```text
relatorio.pdf
relatorio (1).pdf
relatorio (2).pdf
```

### Ignorar o arquivo

```bash
./organize_downloads.sh --on-conflict skip
```

### Sobrescrever

```bash
./organize_downloads.sh --on-conflict overwrite
```

> ⚠️ Use `overwrite` com cuidado, pois um arquivo existente poderá ser substituído.

---

## 📝 Logs

É possível registrar cada movimentação realizada:

```bash
./organize_downloads.sh --log ~/.organize_downloads.log
```

O log registra as informações necessárias para posteriormente desfazer as movimentações.

O formato utilizado é:

```text
timestamp|origem|destino
```

Exemplo:

```text
2026-08-18T13:30:00-03:00|/home/user/Downloads/documento.pdf|/home/user/Downloads/Documents/documento.pdf
```

---

## ↩️ Desfazer movimentações

Para restaurar os arquivos utilizando um log:

```bash
./organize_downloads.sh --undo ~/.organize_downloads.log
```

As movimentações são processadas **do final para o início**, o que ajuda a preservar a ordem das operações.

Também é possível simular o desfazer:

```bash
./organize_downloads.sh --undo ~/.organize_downloads.log --dry-run
```

Se o arquivo de origem já existir, a restauração é ignorada para evitar sobrescrever dados.

---

## ⚙️ Configuração personalizada

As categorias padrão podem ser modificadas através de um arquivo de configuração Bash.

Execute:

```bash
./organize_downloads.sh --config config.sh
```

Um arquivo de configuração pode redefinir, por exemplo:

```bash
CATEGORIES[Documents]=".pdf .docx .txt .md"
CATEGORIES[Images]=".jpg .jpeg .png .webp"
```

Também é possível personalizar os arquivos que devem ser ignorados:

```bash
EXCLUDE_PATTERNS=(
  ".crdownload"
  ".part"
  ".partial"
  ".tmp"
)
```

O arquivo de configuração é carregado com `source`, portanto deve conter **código Bash válido**.

> ⚠️ Só utilize arquivos de configuração de fontes confiáveis.

---

## 📋 Listar configurações

Para visualizar as categorias e extensões atualmente configuradas:

```bash
./organize_downloads.sh --list
```

Exemplo:

```text
Categorias configuradas:
  Images       .jpg .jpeg .png ...
  Documents    .doc .docx .pdf ...
  Archives     .zip .rar .dmg ...
  Videos       .mp4 .mov .mkv ...
  Audio        .mp3 .wav .flac ...
  Programming  .sql .py .java ...
  Installers   .deb .rpm .exe ...
  Torrents     .torrent
  Personal     .opml
  Work         .roz
  Other        <catch-all>
```

---

## 👻 Arquivos ocultos

Por padrão, arquivos cujo nome começa com `.` são ignorados.

Para incluí-los:

```bash
./organize_downloads.sh --include-hidden
```

Isso permite, por exemplo, processar arquivos ocultos que tenham extensões reconhecidas.

---

## 📦 Arquivos incompletos

O script ignora automaticamente arquivos associados a downloads incompletos ou arquivos temporários.

São ignorados, entre outros:

```text
.crdownload
.part
.partial
.download
.tmp
.!qb
.opdownload
```

Isso evita mover arquivos que ainda podem estar sendo baixados.

---

## 🗂️ Arquivos sem categoria

Por padrão, arquivos que não correspondem a nenhuma extensão conhecida são enviados para:

```text
Other/
```

Para não utilizar essa categoria:

```bash
./organize_downloads.sh --no-catch-all
```

Nesse caso, arquivos sem categoria serão simplesmente ignorados.

---

## 🔔 Notificações

Em sistemas que possuem `notify-send`, é possível receber uma notificação ao final da execução:

```bash
./organize_downloads.sh --notify
```

O resumo informa:

* quantidade de arquivos movidos;
* quantidade de arquivos ignorados;
* quantidade de erros.

Para verificar se `notify-send` está disponível:

```bash
command -v notify-send
```

---

## 🕐 Execução automática com Cron

O script pode instalar uma tarefa `cron` para execução diária.

Por exemplo, para executar todos os dias às **19:00**:

```bash
./organize_downloads.sh --install-cron 19:00
```

A tarefa instalada utiliza automaticamente:

```text
--min-age 5
```

e grava um log em:

```text
~/.organize_downloads.log
```

As mensagens da execução automática são registradas em:

```text
~/.organize_downloads.cron.log
```

Para verificar as tarefas agendadas:

```bash
crontab -l
```

---

## 🖥️ Exemplos completos

### Organização básica

```bash
./organize_downloads.sh
```

### Simulação

```bash
./organize_downloads.sh --dry-run
```

### Desktop recursivamente

```bash
./organize_downloads.sh \
  --source ~/Desktop \
  --recursive
```

### Downloads com arquivos de pelo menos 5 minutos

```bash
./organize_downloads.sh \
  --min-age 5
```

### Organização com log

```bash
./organize_downloads.sh \
  --log ~/.organize_downloads.log
```

### Organização detalhada

```bash
./organize_downloads.sh \
  --verbose
```

### Organização silenciosa

```bash
./organize_downloads.sh \
  --quiet
```

### Organização com várias opções

```bash
./organize_downloads.sh \
  --source ~/Downloads \
  --recursive \
  --min-age 5 \
  --on-conflict rename \
  --log ~/.organize_downloads.log \
  --notify
```

### Desfazer

```bash
./organize_downloads.sh \
  --undo ~/.organize_downloads.log
```

---

## 🛠️ Opções disponíveis

| Opção                  | Descrição                                           |
| ---------------------- | --------------------------------------------------- |
| `-s, --source DIR`     | Define a pasta de origem                            |
| `-n, --dry-run`        | Simula a operação sem mover arquivos                |
| `-r, --recursive`      | Processa também subpastas                           |
| `--include-hidden`     | Inclui arquivos ocultos                             |
| `--no-catch-all`       | Não utiliza a categoria `Other`                     |
| `--min-age MINUTOS`    | Processa somente arquivos mais antigos que o limite |
| `--on-conflict MODE`   | Define o comportamento para nomes duplicados        |
| `-l, --log ARQUIVO`    | Salva o registro das movimentações                  |
| `-u, --undo ARQUIVO`   | Desfaz movimentações registradas                    |
| `-c, --config ARQUIVO` | Carrega configuração personalizada                  |
| `--list`               | Lista categorias e extensões                        |
| `--notify`             | Envia notificação ao terminar                       |
| `--install-cron HH:MM` | Instala execução diária via cron                    |
| `-v, --verbose`        | Exibe informações detalhadas                        |
| `-q, --quiet`          | Reduz a saída no terminal                           |
| `-h, --help`           | Exibe a ajuda                                       |

---

## 🔒 Segurança

O script foi projetado para reduzir riscos durante a organização:

1. **Downloads incompletos são ignorados.**
2. **Arquivos ocultos não são processados por padrão.**
3. **Conflitos de nomes não sobrescrevem arquivos por padrão.**
4. O modo `--dry-run` permite verificar as operações antes de executá-las.
5. O `--on-conflict rename` cria nomes alternativos automaticamente.
6. As movimentações podem ser registradas em log para permitir uma operação de desfazer.
7. Arquivos sem categoria podem ser mantidos no local original usando `--no-catch-all`.

Apesar disso, recomenda-se testar alterações utilizando:

```bash
./organize_downloads.sh --dry-run
```

antes de executar a organização definitivamente.

---

## 💻 Compatibilidade

O script utiliza recursos comuns do Bash e de sistemas Unix-like.

Foi desenvolvido para funcionar principalmente em:

* Linux;
* macOS.

O script utiliza `$HOME` para localizar o diretório pessoal, evitando dependência de mecanismos como `os.getlogin()` utilizados na versão Python original.

Alguns recursos dependem de ferramentas específicas do sistema, como:

* `bash`;
* `find`;
* `mv`;
* `mkdir`;
* `crontab` — somente para `--install-cron`;
* `notify-send` — somente para notificações;
* `tac` ou `tail -r` — utilizado durante `--undo`.

---

## 📜 Origem

O script foi reescrito em Bash a partir de um script Python originalmente inspirado no artigo:

**Organize Files in Folders Using Python Script**, de Gamsa Hamidah.

A versão Bash incorpora diversas correções e melhorias em relação à implementação original, especialmente no tratamento de extensões, arquivos incompletos, conflitos de nomes, erros de movimentação e possibilidade de desfazer operações.

---

## 📄 Licença

Este projeto pode ser distribuído e modificado conforme a licença definida pelo repositório/projeto.

Caso nenhuma licença tenha sido definida, recomenda-se adicionar um arquivo `LICENSE` ao projeto antes de publicar o código.

---

## 🤝 Contribuições

Sugestões, correções e melhorias são bem-vindas.

Algumas ideias de futuras melhorias:

* suporte a arquivos por MIME type, além de extensão;
* configuração via arquivo externo mais estruturado;
* exclusão de diretórios personalizados;
* suporte a múltiplas pastas de origem;
* relatório em JSON ou CSV;
* modo interativo;
* testes automatizados;
* suporte a mais sistemas Unix-like.

---

## 📌 Resumo rápido

Para começar:

```bash
chmod +x organize_downloads.sh
./organize_downloads.sh --dry-run
```

Se o resultado estiver correto:

```bash
./organize_downloads.sh --log ~/.organize_downloads.log
```

E, caso seja necessário desfazer:

```bash
./organize_downloads.sh --undo ~/.organize_downloads.log
```
