# qBittorrent + ProtonVPN Port Updater (Windows)

Sincroniza automaticamente a porta de escuta do qBittorrent com a porta de encaminhamento liberada pelo ProtonVPN. Ideal para quem usa servidores com port forwarding e não quer ajustar a porta manualmente toda vez que reconecta.

## Como funciona
### Explicação rápida
1. Você conecta no ProtonVPN (em um servidor com port forwarding) e o script captura automaticamente a porta liberada, guardando-a em memória.
2. A porta do qBittorrent é ajustada sozinha em dois cenários: quando você abre o app já conectado à VPN ou quando conecta na VPN com o qBittorrent aberto.
3. Tudo roda em segundo plano via tarefa agendada/disparo silencioso, sem nenhuma interação manual com os scripts.


### Explicação técnica
1. `ProtonVPN-PortMonitor.ps1` monitora `%LocalAppData%\Proton\Proton VPN\Logs\client-logs.txt` e identifica o par `Port pair XXXX->YYYY` mais recente.
2. A porta é gravada na variável de ambiente do usuário `PROTON_VPN_PORT_FORWARDING` e registrada em `protonvpn-port.log`.
3. `qBittorrent-PortSync.ps1` lê essa porta, autentica no Web UI do qBittorrent e atualiza `listen_port` via endpoint `/api/v2/app/setPreferences`, gerando `qbittorrent-update.log` e notificação (BurntToast ou MessageBox).
4. `update_port.vbs` executa monitor + sync em sequência e de forma silenciosa.
5. Uma tarefa agendada dispara o VBS quando o `qbittorrent.exe` inicia (evento 4688) ou quando o perfil de rede "ProtonVPN" conecta (EventID 10000).

## Componentes
| Arquivo | Função |
| --- | --- |
| `ProtonVPN-PortMonitor.ps1` | Extrai a porta do log do cliente ProtonVPN e atualiza a variável de ambiente. |
| `qBittorrent-PortSync.ps1` | Aplica a porta no qBittorrent via API, com log e toast opcional. |
| `update_port.vbs` | Wrapper silencioso para rodar os dois scripts em série. |
| `setup.ps1` | Copia os arquivos para `C:\Program Files\QbittorrentProtonVPNUpdater` e cria a tarefa agendada. |
| `task_config.xml` | Template usado pelo instalador para configurar a tarefa. |

## Pré-requisitos
- Windows 10/11 x64 com PowerShell 5.1+ (PowerShell 7 funciona também).
- Cliente ProtonVPN oficial com port forwarding habilitado e logs em `%LocalAppData%\Proton\Proton VPN\Logs\client-logs.txt`.
- qBittorrent com Web UI acessível em `http://localhost:<porta>`.
  - Use “Ignorar autenticação para clientes no host local” **ou** defina `$qbUsername`/`$qbPassword` em `qBittorrent-PortSync.ps1`.
- Permissão de administrador somente para rodar `setup.ps1` (criar tarefa e copiar arquivos).

## Instalação rápida
1. Clone/baixe este diretório.
2. Abra o PowerShell como administrador na pasta `qBittorrent-ProtonVPN-PortUpdater`.
3. Execute `.\setup.ps1` e informe o caminho do `qbittorrent.exe` quando solicitado (ex.: `C:\Program Files\qBittorrent\qbittorrent.exe`).
4. O instalador copia os scripts para `C:\Program Files\QbittorrentProtonVPNUpdater`, cria a tarefa “Qbittorrent-ProtonVPN port Updater” e tenta habilitar a auditoria “Criação de processo”.

## Configuração complementar
- **qBittorrent Web UI**: confirme porta, usuário e senha. Ajuste variáveis no `qBittorrent-PortSync.ps1` se necessário.
- **Notificações**: o script tenta instalar o módulo `BurntToast`. Falhando, cai para MessageBox; instale manualmente com `Install-Module BurntToast -Scope CurrentUser` se quiser toasts nativos.
- **Gatilhos**: verifique se o perfil de rede aparece como “ProtonVPN”. Em Windows não-PT/EN pode ser necessário habilitar manualmente a auditoria de “Criação de processo”.

## Operação
- Depois de instalado, nada mais a fazer: a tarefa monitora o início do qBittorrent ou a conexão no perfil ProtonVPN e roda `update_port.vbs` em background.
- Execução manual (útil para testes):
  ```powershell
  powershell -ExecutionPolicy Bypass -NoProfile -File .\ProtonVPN-PortMonitor.ps1
  powershell -ExecutionPolicy Bypass -NoProfile -File .\qBittorrent-PortSync.ps1
  # ou
  C:\Program Files\QbittorrentProtonVPNUpdater\update_port.vbs
  ```

## Logs e variável de ambiente
- `protonvpn-port.log` e `qbittorrent-update.log` ficam ao lado dos scripts instalados (padrão: `C:\Program Files\QbittorrentProtonVPNUpdater`).
- `PROTON_VPN_PORT_FORWARDING` (escopo Usuário) guarda a última porta detectada:
  ```powershell
  [Environment]::GetEnvironmentVariable('PROTON_VPN_PORT_FORWARDING','User')
  ```

## Solução de problemas
- **Porta não detectada**: confirme que o servidor ProtonVPN possui port forwarding e que o arquivo `client-logs.txt` existe e contém “Port pair”. Reconectar no app geralmente renova o par.
- **qBittorrent não atualiza**: abra `http://localhost:<porta>` no navegador para validar o Web UI e revise as credenciais no script.
- **Tarefa agendada não dispara**: rode-a manualmente no Agendador e confira se o evento 4688 está sendo registrado (auditoria ativa) e se o perfil de rede se chama “ProtonVPN”.
- **BurntToast falhou**: as notificações cairão para MessageBox; instale o módulo manualmente se preferir toasts.

## Desinstalação
```powershell
Unregister-ScheduledTask -TaskName "Qbittorrent-ProtonVPN port Updater" -Confirm:$false
Remove-Item "C:\Program Files\QbittorrentProtonVPNUpdater" -Recurse -Force
[Environment]::SetEnvironmentVariable('PROTON_VPN_PORT_FORWARDING',$null,'User')  # opcional
```

## Licença
- MIT
