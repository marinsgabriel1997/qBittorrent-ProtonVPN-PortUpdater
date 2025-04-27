Dim translations, systemLang
Set translations = CreateObject("Scripting.Dictionary")

systemLang = GetSystemLanguage()

If systemLang = "pt-BR" Then
    ' Portuguese
    translations.Add "START_CHECK", "Iniciando verificacao de conexao com qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Conexao estabelecida com qBittorrent."
    translations.Add "CONNECTION_FAIL", "Nao foi possivel conectar ao qBittorrent."
    translations.Add "PORT_FOUND", "Porta encontrada no log do ProtonVPN: "
    translations.Add "PORT_NOT_FOUND", "Nenhuma porta encontrada no log."
    translations.Add "LOG_FILE_NOT_FOUND", "Arquivo de log nao encontrado:"
    translations.Add "API_ERROR", "Erro ao conectar a API do qBittorrent:"
    translations.Add "HTTP_ERROR", "Erro HTTP ao atualizar porta:"
    translations.Add "PORT_UPDATED", "Porta atualizada no qBittorrent para: "
    translations.Add "PORT_UPDATED_TITLE", "qBittorrent - Porta Atualizada"
    translations.Add "PORT_UPDATED_BODY", "Nova porta: "
    translations.Add "START_PORT_EXTRACTION", "Iniciando extracao da porta."
    translations.Add "LAST_SENT_PORT", "Ultima porta enviada para o qBittorrent: "
    translations.Add "NEW_PORT_DETECTED", "Nova porta detectada. Atualizando qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Porta nao mudou. Nenhuma atualizacao necessaria."
    translations.Add "NO_PORT_FOUND", "Nenhuma porta encontrada ou log inacessivel."
    translations.Add "ERROR", "Erro"

ElseIf systemLang = "zh-CN" Then
    ' Chinese (Simplified)
    translations.Add "START_CHECK", "Zhengzai jiancha yu qBittorrent de lianjie."
    translations.Add "CONNECTION_SUCCESS", "Yu qBittorrent chenggong lianjie."
    translations.Add "CONNECTION_FAIL", "Wu fa lianjie qBittorrent."
    translations.Add "PORT_FOUND", "Zai rizhi zhong zhaodao duankou: "
    translations.Add "PORT_NOT_FOUND", "Wei zhaodao duankou."
    translations.Add "LOG_FILE_NOT_FOUND", "Wei zhaodao rizhi wenjian:"
    translations.Add "API_ERROR", "Lianjie qBittorrent API shi chucuo:"
    translations.Add "HTTP_ERROR", "Gengxin duankou shi HTTP chucuo:"
    translations.Add "PORT_UPDATED", "qBittorrent duankou yi gengxin wei: "
    translations.Add "PORT_UPDATED_TITLE", "Duankou Yi Gengxin"
    translations.Add "PORT_UPDATED_BODY", "Xin duankou: "
    translations.Add "START_PORT_EXTRACTION", "Zhengzai tiqiu duankou."
    translations.Add "LAST_SENT_PORT", "Shangci fasong de duankou: "
    translations.Add "NEW_PORT_DETECTED", "Jiance dao xin duankou. Zhengzai gengxin qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Duankou wei bianhua. Wu xu gengxin."
    translations.Add "NO_PORT_FOUND", "Wei zhaodao duankou huo rizhi wufa fangwen."
    translations.Add "ERROR", "Chucuo"

ElseIf systemLang = "es-ES" Then
    ' Spanish
    translations.Add "START_CHECK", "Iniciando verificacion de conexion con qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Conexion establecida con qBittorrent."
    translations.Add "CONNECTION_FAIL", "No se pudo conectar a qBittorrent."
    translations.Add "PORT_FOUND", "Puerto encontrado en el registro: "
    translations.Add "PORT_NOT_FOUND", "No se encontro puerto en el registro."
    translations.Add "LOG_FILE_NOT_FOUND", "Archivo de registro no encontrado:"
    translations.Add "API_ERROR", "Error al conectar con la API de qBittorrent:"
    translations.Add "HTTP_ERROR", "Error HTTP al actualizar puerto:"
    translations.Add "PORT_UPDATED", "Puerto actualizado en qBittorrent a: "
    translations.Add "PORT_UPDATED_TITLE", "Puerto Actualizado"
    translations.Add "PORT_UPDATED_BODY", "Puerto actualizado en qBittorrent a: "
    translations.Add "START_PORT_EXTRACTION", "Iniciando extraccion de puerto."
    translations.Add "LAST_SENT_PORT", "Ultimo puerto enviado: "
    translations.Add "NEW_PORT_DETECTED", "Nuevo puerto detectado. Actualizando qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "El puerto no cambio. No se necesita actualizar."
    translations.Add "NO_PORT_FOUND", "No se encontro puerto o registro inaccesible."
    translations.Add "ERROR", "Error"

ElseIf systemLang = "hi-IN" Then
    ' Hindi
    translations.Add "START_CHECK", "qBittorrent ke sath connection check shuru kar raha hai."
    translations.Add "CONNECTION_SUCCESS", "qBittorrent ke sath connection sthapit."
    translations.Add "CONNECTION_FAIL", "qBittorrent se connect nahi ho paya."
    translations.Add "PORT_FOUND", "Log mein port mila: "
    translations.Add "PORT_NOT_FOUND", "Log mein koi port nahi mila."
    translations.Add "LOG_FILE_NOT_FOUND", "Log file nahi mili:"
    translations.Add "API_ERROR", "qBittorrent API se connect karne mein error:"
    translations.Add "HTTP_ERROR", "Port update karne mein HTTP error:"
    translations.Add "PORT_UPDATED", "qBittorrent mein port update hua: "
    translations.Add "PORT_UPDATED_TITLE", "Port Update Hua"
    translations.Add "PORT_UPDATED_BODY", "qBittorrent mein port update hua: "
    translations.Add "START_PORT_EXTRACTION", "Port extraction shuru kar raha hai."
    translations.Add "LAST_SENT_PORT", "Pichla bheja gaya port: "
    translations.Add "NEW_PORT_DETECTED", "Naya port mila. qBittorrent update kar raha hai."
    translations.Add "PORT_NOT_CHANGED", "Port nahi badla. Update ki zaroorat nahi."
    translations.Add "NO_PORT_FOUND", "Koi port nahi mila ya log inaccessible."
    translations.Add "ERROR", "Error"

ElseIf systemLang = "ar-SA" Then
    ' Arabic
    translations.Add "START_CHECK", "Badou altahqiq min alittisal ma qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Itisal mouassas ma qBittorrent."
    translations.Add "CONNECTION_FAIL", "La yomken alittisal ma qBittorrent."
    translations.Add "PORT_FOUND", "Almawrid wajad fi alsejel: "
    translations.Add "PORT_NOT_FOUND", "Lam yajad almawrid fi alsejel."
    translations.Add "LOG_FILE_NOT_FOUND", "Lam yajad malaf alsejel:"
    translations.Add "API_ERROR", "Khataa fi alittisal ma API qBittorrent:"
    translations.Add "HTTP_ERROR", "Khataa HTTP fi tatweer almawrid:"
    translations.Add "PORT_UPDATED", "Tatweer almawrid fi qBittorrent ila: "
    translations.Add "PORT_UPDATED_TITLE", "Tatweer Almawrid"
    translations.Add "PORT_UPDATED_BODY", "Tatweer almawrid fi qBittorrent ila: "
    translations.Add "START_PORT_EXTRACTION", "Badou istikhraj almawrid."
    translations.Add "LAST_SENT_PORT", "Akhir mawrid ersal: "
    translations.Add "NEW_PORT_DETECTED", "Kashif almawrid aljadid. Tatweer qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Almawrid lam yataghayar. La hajat liltatweer."
    translations.Add "NO_PORT_FOUND", "Lam yajad almawrid aw alsejel ghayr mutasahil."
    translations.Add "ERROR", "Khataa"

ElseIf systemLang = "fr-FR" Then
    ' French
    translations.Add "START_CHECK", "Verification de la connexion avec qBittorrent en cours."
    translations.Add "CONNECTION_SUCCESS", "Connexion etablie avec qBittorrent."
    translations.Add "CONNECTION_FAIL", "Impossible de se connecter a qBittorrent."
    translations.Add "PORT_FOUND", "Port trouve dans le journal: "
    translations.Add "PORT_NOT_FOUND", "Aucun port trouve dans le journal."
    translations.Add "LOG_FILE_NOT_FOUND", "Fichier journal introuvable:"
    translations.Add "API_ERROR", "Erreur de connexion a l'API qBittorrent:"
    translations.Add "HTTP_ERROR", "Erreur HTTP lors de la mise a jour du port:"
    translations.Add "PORT_UPDATED", "Port mis a jour dans qBittorrent: "
    translations.Add "PORT_UPDATED_TITLE", "Port Mis a Jour"
    translations.Add "PORT_UPDATED_BODY", "Port mis a jour dans qBittorrent: "
    translations.Add "START_PORT_EXTRACTION", "Extraction du port en cours."
    translations.Add "LAST_SENT_PORT", "Dernier port envoye: "
    translations.Add "NEW_PORT_DETECTED", "Nouveau port detecte. Mise a jour de qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Le port n'a pas change. Aucune mise a jour necessaire."
    translations.Add "NO_PORT_FOUND", "Aucun port trouve ou journal inaccessible."
    translations.Add "ERROR", "Erreur"

ElseIf systemLang = "ru-RU" Then
    ' Russian
    translations.Add "START_CHECK", "Proverka podklyucheniya k qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Soedinenie s qBittorrent ustanovleno."
    translations.Add "CONNECTION_FAIL", "Nevozmozhno podklyuchitsya k qBittorrent."
    translations.Add "PORT_FOUND", "Port nayden v log: "
    translations.Add "PORT_NOT_FOUND", "Port ne nayden v log."
    translations.Add "LOG_FILE_NOT_FOUND", "Log-fayl ne nayden:"
    translations.Add "API_ERROR", "Oshibka podklyucheniya k API qBittorrent:"
    translations.Add "HTTP_ERROR", "HTTP osibka pri obnovlenii porta:"
    translations.Add "PORT_UPDATED", "Port obnovlen v qBittorrent: "
    translations.Add "PORT_UPDATED_TITLE", "Port Obnovlen"
    translations.Add "PORT_UPDATED_BODY", "Port obnovlen v qBittorrent: "
    translations.Add "START_PORT_EXTRACTION", "Nachalo izvlecheniya porta."
    translations.Add "LAST_SENT_PORT", "Posledniy otpravlenny port: "
    translations.Add "NEW_PORT_DETECTED", "Noviy port obnaruzhen. Obnovlenie qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Port ne izmenilsya. Obnovlenie ne trebuetsya."
    translations.Add "NO_PORT_FOUND", "Port ne nayden ili log nedostupen."
    translations.Add "ERROR", "Oshibka"

Else
    ' English (default)
    translations.Add "START_CHECK", "Starting connection check with qBittorrent."
    translations.Add "CONNECTION_SUCCESS", "Connection established with qBittorrent."
    translations.Add "CONNECTION_FAIL", "Could not connect to qBittorrent after 20 attempts."
    translations.Add "PORT_FOUND", "Port found in log: "
    translations.Add "PORT_NOT_FOUND", "No port found in the log."
    translations.Add "LOG_FILE_NOT_FOUND", "Log file not found:"
    translations.Add "API_ERROR", "Error connecting to qBittorrent API:"
    translations.Add "HTTP_ERROR", "HTTP error updating port:"
    translations.Add "PORT_UPDATED", "Port updated in qBittorrent to: "
    translations.Add "PORT_UPDATED_TITLE", "Port Updated"
    translations.Add "PORT_UPDATED_BODY", "Port updated in qBittorrent to: "
    translations.Add "START_PORT_EXTRACTION", "Starting port extraction."
    translations.Add "LAST_SENT_PORT", "Last sent port: "
    translations.Add "NEW_PORT_DETECTED", "New port detected. Updating qBittorrent."
    translations.Add "PORT_NOT_CHANGED", "Port did not change. No update needed."
    translations.Add "NO_PORT_FOUND", "No port found or log inaccessible."
    translations.Add "ERROR", "Error"
End If

Function GetText(key)
    If translations.Exists(key) Then
        GetText = translations(key)
    Else
        GetText = key
    End If
End Function

Function GetSystemLanguage()
    Dim wshShell
    Set wshShell = CreateObject("WScript.Shell")
    GetSystemLanguage = wshShell.RegRead("HKEY_CURRENT_USER\Control Panel\International\LocaleName")
    Set wshShell = Nothing
End Function