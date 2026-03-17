import Foundation

// アプリ言語設定
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case ja = "ja"
    case en = "en"
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case ko = "ko"
    case ru = "ru"
    case es = "es"
    case fr = "fr"
    case de = "de"
    case it = "it"
    case pt = "pt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            switch resolved {
            case .ja: return "システム設定に従う"
            case .zhHant: return "跟隨系統設定"
            case .zhHans: return "跟随系统设置"
            case .ko: return "시스템 설정 따르기"
            case .ru: return "Системные настройки"
            case .es: return "Configuración del sistema"
            case .fr: return "Paramètres système"
            case .de: return "Systemeinstellung"
            case .it: return "Impostazioni di sistema"
            case .pt: return "Configuração do sistema"
            default: return "System Default"
            }
        case .ja: return "日本語"
        case .en: return "English"
        case .zhHant: return "繁體中文"
        case .zhHans: return "简体中文"
        case .ko: return "한국어"
        case .ru: return "Русский"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .it: return "Italiano"
        case .pt: return "Português"
        }
    }

    var resolved: ResolvedLanguage {
        switch self {
        case .ja: return .ja
        case .en: return .en
        case .zhHant: return .zhHant
        case .zhHans: return .zhHans
        case .ko: return .ko
        case .ru: return .ru
        case .es: return .es
        case .fr: return .fr
        case .de: return .de
        case .it: return .it
        case .pt: return .pt
        case .system:
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("ja") { return .ja }
            if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh_Hant") || preferred == "zh-TW" || preferred == "zh-HK" { return .zhHant }
            if preferred.hasPrefix("zh") { return .zhHans }
            if preferred.hasPrefix("ko") { return .ko }
            if preferred.hasPrefix("ru") { return .ru }
            if preferred.hasPrefix("es") { return .es }
            if preferred.hasPrefix("fr") { return .fr }
            if preferred.hasPrefix("de") { return .de }
            if preferred.hasPrefix("it") { return .it }
            if preferred.hasPrefix("pt") { return .pt }
            return .en
        }
    }
}

enum ResolvedLanguage {
    case ja, en, zhHant, zhHans, ko, ru, es, fr, de, it, pt
}

// MARK: - ローカライズ文字列
enum L10n {
    static var lang: ResolvedLanguage {
        let raw = UserDefaults.standard.string(forKey: "language") ?? "system"
        let appLang = AppLanguage(rawValue: raw) ?? .system
        return appLang.resolved
    }

    // 11言語ヘルパー
    private static func t(
        _ ja: String, _ en: String,
        zhHant: String, zhHans: String,
        ko: String, ru: String,
        es: String, fr: String,
        de: String, it: String,
        pt: String
    ) -> String {
        switch lang {
        case .ja: return ja
        case .en: return en
        case .zhHant: return zhHant
        case .zhHans: return zhHans
        case .ko: return ko
        case .ru: return ru
        case .es: return es
        case .fr: return fr
        case .de: return de
        case .it: return it
        case .pt: return pt
        }
    }

    // MARK: - 共通

    static var close: String {
        t("閉じる", "Close",
          zhHant: "關閉", zhHans: "关闭",
          ko: "닫기", ru: "Закрыть",
          es: "Cerrar", fr: "Fermer",
          de: "Schließen", it: "Chiudi",
          pt: "Fechar")
    }

    static var cancel: String {
        t("キャンセル", "Cancel",
          zhHant: "取消", zhHans: "取消",
          ko: "취소", ru: "Отмена",
          es: "Cancelar", fr: "Annuler",
          de: "Abbrechen", it: "Annulla",
          pt: "Cancelar")
    }

    static var error: String {
        t("エラー", "Error",
          zhHant: "錯誤", zhHans: "错误",
          ko: "오류", ru: "Ошибка",
          es: "Error", fr: "Erreur",
          de: "Fehler", it: "Errore",
          pt: "Erro")
    }

    static var unknown: String {
        t("不明", "Unknown",
          zhHant: "未知", zhHans: "未知",
          ko: "알 수 없음", ru: "Неизвестно",
          es: "Desconocido", fr: "Inconnu",
          de: "Unbekannt", it: "Sconosciuto",
          pt: "Desconhecido")
    }

    static var settings: String {
        t("設定", "Settings",
          zhHant: "設定", zhHans: "设置",
          ko: "설정", ru: "Настройки",
          es: "Ajustes", fr: "Réglages",
          de: "Einstellungen", it: "Impostazioni",
          pt: "Configurações")
    }

    // MARK: - メイン画面

    static var fetchingVideoInfo: String {
        t("動画情報を取得中...", "Fetching video info...",
          zhHant: "正在取得影片資訊…", zhHans: "正在获取视频信息…",
          ko: "동영상 정보를 가져오는 중...", ru: "Получение информации о видео…",
          es: "Obteniendo información del vídeo…", fr: "Récupération des informations vidéo…",
          de: "Videoinfo wird abgerufen…", it: "Recupero informazioni video…",
          pt: "Obtendo informações do vídeo…")
    }

    static var enterURLPlaceholder: String {
        t("URLを入力して動画情報を取得してください", "Enter a URL to fetch video info",
          zhHant: "輸入 URL 以取得影片資訊", zhHans: "输入 URL 以获取视频信息",
          ko: "URL을 입력하여 동영상 정보를 가져오세요", ru: "Введите URL для получения информации о видео",
          es: "Introduce una URL para obtener información del vídeo", fr: "Entrez une URL pour récupérer les informations vidéo",
          de: "URL eingeben, um Videoinfo abzurufen", it: "Inserisci un URL per ottenere le informazioni del video",
          pt: "Insira um URL para obter informações do vídeo")
    }

    static var settingsToolbar: String { settings }

    static var supportedSites: String {
        t("対応サイト", "Supported Sites",
          zhHant: "支援網站", zhHans: "支持的网站",
          ko: "지원 사이트", ru: "Поддерживаемые сайты",
          es: "Sitios compatibles", fr: "Sites pris en charge",
          de: "Unterstützte Seiten", it: "Siti supportati",
          pt: "Sites suportados")
    }

    static var supportedSitesList: String {
        t("対応サイト一覧", "Supported Sites",
          zhHant: "支援網站一覽", zhHans: "支持的网站列表",
          ko: "지원 사이트 목록", ru: "Список поддерживаемых сайтов",
          es: "Lista de sitios compatibles", fr: "Liste des sites pris en charge",
          de: "Liste unterstützter Seiten", it: "Elenco siti supportati",
          pt: "Lista de sites suportados")
    }

    // MARK: - URL入力

    static var urlInputPlaceholder: String {
        t("動画のURLを入力 (複数行で一括DL)...", "Enter video URL (multiple lines for batch DL)...",
          zhHant: "輸入影片 URL（多行可批次下載）…", zhHans: "输入视频 URL（多行可批量下载）…",
          ko: "동영상 URL 입력 (여러 줄로 일괄 다운로드)...", ru: "Введите URL видео (несколько строк для пакетной загрузки)…",
          es: "Introduce la URL del vídeo (varias líneas para descarga masiva)…", fr: "Entrez l'URL de la vidéo (plusieurs lignes pour téléchargement groupé)…",
          de: "Video-URL eingeben (mehrere Zeilen für Stapel-DL)…", it: "Inserisci URL del video (più righe per download multiplo)…",
          pt: "Insira o URL do vídeo (várias linhas para download em lote)…")
    }

    static func bulkDownload(_ count: Int) -> String {
        t("一括DL (\(count)件)", "Batch DL (\(count))",
          zhHant: "批次下載（\(count) 個）", zhHans: "批量下载（\(count) 个）",
          ko: "일괄 다운로드 (\(count)건)", ru: "Пакетная загрузка (\(count))",
          es: "Descarga masiva (\(count))", fr: "Téléchargement groupé (\(count))",
          de: "Stapel-DL (\(count))", it: "Download multiplo (\(count))",
          pt: "Download em lote (\(count))")
    }

    static var fetch: String {
        t("詳細取得", "Details",
          zhHant: "詳細取得", zhHans: "获取详情",
          ko: "상세 정보", ru: "Подробнее",
          es: "Detalles", fr: "Détails",
          de: "Details", it: "Dettagli",
          pt: "Detalhes")
    }

    static var quickDownload: String {
        t("クイックDL", "Quick DL",
          zhHant: "快速下載", zhHans: "快速下载",
          ko: "빠른 다운로드", ru: "Быстрая загрузка",
          es: "Descargar", fr: "Télécharger",
          de: "Download", it: "Scarica",
          pt: "Baixar")
    }

    static var quickDownloadHint: String {
        t("最高画質・最高音質", "Best quality",
          zhHant: "最高畫質・最高音質", zhHans: "最高画质・最高音质",
          ko: "최고 화질・최고 음질", ru: "Лучшее качество",
          es: "Mejor calidad", fr: "Meilleure qualité",
          de: "Beste Qualität", it: "Migliore qualità",
          pt: "Melhor qualidade")
    }

    static func bulkURLDetected(_ count: Int) -> String {
        t("\(count)件のURLを検出 — デフォルト設定で一括ダウンロードします",
          "\(count) URLs detected — will download with default settings",
          zhHant: "偵測到 \(count) 個 URL — 將使用預設設定批次下載",
          zhHans: "检测到 \(count) 个 URL — 将使用默认设置批量下载",
          ko: "\(count)개의 URL 감지 — 기본 설정으로 일괄 다운로드합니다",
          ru: "Обнаружено \(count) URL — загрузка с настройками по умолчанию",
          es: "\(count) URLs detectadas — se descargarán con la configuración predeterminada",
          fr: "\(count) URLs détectées — téléchargement avec les paramètres par défaut",
          de: "\(count) URLs erkannt — Download mit Standardeinstellungen",
          it: "\(count) URL rilevati — download con impostazioni predefinite",
          pt: "\(count) URLs detectados — download com configurações padrão")
    }

    // MARK: - フォーマット選択

    static var downloadSettings: String {
        t("ダウンロード設定", "Download Settings",
          zhHant: "下載設定", zhHans: "下载设置",
          ko: "다운로드 설정", ru: "Настройки загрузки",
          es: "Ajustes de descarga", fr: "Paramètres de téléchargement",
          de: "Download-Einstellungen", it: "Impostazioni download",
          pt: "Configurações de download")
    }

    static func maxResolution(_ label: String) -> String {
        t("最大解像度: \(label)", "Max resolution: \(label)",
          zhHant: "最大解析度：\(label)", zhHans: "最大分辨率：\(label)",
          ko: "최대 해상도: \(label)", ru: "Макс. разрешение: \(label)",
          es: "Resolución máxima: \(label)", fr: "Résolution max : \(label)",
          de: "Max. Auflösung: \(label)", it: "Risoluzione max: \(label)",
          pt: "Resolução máxima: \(label)")
    }

    static var qualityFormat: String {
        t("画質・フォーマット", "Quality & Format",
          zhHant: "畫質與格式", zhHans: "画质与格式",
          ko: "화질 및 포맷", ru: "Качество и формат",
          es: "Calidad y formato", fr: "Qualité et format",
          de: "Qualität & Format", it: "Qualità e formato",
          pt: "Qualidade e formato")
    }

    static var video: String {
        t("動画", "Video",
          zhHant: "影片", zhHans: "视频",
          ko: "동영상", ru: "Видео",
          es: "Vídeo", fr: "Vidéo",
          de: "Video", it: "Video",
          pt: "Vídeo")
    }

    static var audioOnly: String {
        t("音声のみ", "Audio Only",
          zhHant: "僅音訊", zhHans: "仅音频",
          ko: "오디오만", ru: "Только аудио",
          es: "Solo audio", fr: "Audio uniquement",
          de: "Nur Audio", it: "Solo audio",
          pt: "Somente áudio")
    }

    static var unavailable: String {
        t("利用不可", "N/A",
          zhHant: "不可用", zhHans: "不可用",
          ko: "사용 불가", ru: "Недоступно",
          es: "No disponible", fr: "Indisponible",
          de: "Nicht verfügbar", it: "Non disponibile",
          pt: "Indisponível")
    }

    static var customFormatLabel: String {
        t("カスタムフォーマット文字列 (-f オプション)", "Custom format string (-f option)",
          zhHant: "自訂格式字串（-f 選項）", zhHans: "自定义格式字符串（-f 选项）",
          ko: "사용자 지정 포맷 문자열 (-f 옵션)", ru: "Произвольная строка формата (опция -f)",
          es: "Cadena de formato personalizada (opción -f)", fr: "Chaîne de format personnalisée (option -f)",
          de: "Benutzerdefinierter Formatstring (-f Option)", it: "Stringa formato personalizzata (opzione -f)",
          pt: "String de formato personalizado (opção -f)")
    }

    static var customFormatPlaceholder: String { "bestvideo[height<=1080]+bestaudio" }

    static var startDownload: String {
        t("ダウンロード", "Download",
          zhHant: "下載", zhHans: "下载",
          ko: "다운로드", ru: "Скачать",
          es: "Descargar", fr: "Télécharger",
          de: "Herunterladen", it: "Scarica",
          pt: "Iniciar download")
    }

    static func resolutionLabel(_ height: Int) -> String {
        switch height {
        case 2160...: return "\(height)p (4K)"
        case 1440...: return "\(height)p (2K)"
        case 1080...:
            return t("\(height)p (フルHD)", "\(height)p (Full HD)",
                     zhHant: "\(height)p (全高清)", zhHans: "\(height)p (全高清)",
                     ko: "\(height)p (풀HD)", ru: "\(height)p (Full HD)",
                     es: "\(height)p (Full HD)", fr: "\(height)p (Full HD)",
                     de: "\(height)p (Full HD)", it: "\(height)p (Full HD)",
                     pt: "\(height)p (Full HD)")
        case 720...: return "\(height)p (HD)"
        case 480...: return "\(height)p (SD)"
        default: return "\(height)p"
        }
    }

    // MARK: - ダウンロードリスト

    static var downloads: String {
        t("ダウンロード", "Downloads",
          zhHant: "下載", zhHans: "下载",
          ko: "다운로드", ru: "Загрузки",
          es: "Descargas", fr: "Téléchargements",
          de: "Downloads", it: "Download",
          pt: "Downloads")
    }

    static func activeCount(_ count: Int) -> String {
        t("\(count)件 実行中", "\(count) active",
          zhHant: "\(count) 個進行中", zhHans: "\(count) 个进行中",
          ko: "\(count)건 진행 중", ru: "\(count) активных",
          es: "\(count) activas", fr: "\(count) en cours",
          de: "\(count) aktiv", it: "\(count) attivi",
          pt: "\(count) ativos")
    }

    static var noDownloadTasks: String {
        t("ダウンロードタスクなし", "No download tasks",
          zhHant: "沒有下載任務", zhHans: "没有下载任务",
          ko: "다운로드 작업 없음", ru: "Нет задач загрузки",
          es: "Sin tareas de descarga", fr: "Aucune tâche de téléchargement",
          de: "Keine Download-Aufgaben", it: "Nessun download",
          pt: "Nenhuma tarefa de download")
    }

    static var clearCompleted: String {
        t("完了済みをクリア", "Clear Completed",
          zhHant: "清除已完成", zhHans: "清除已完成",
          ko: "완료된 항목 지우기", ru: "Очистить завершённые",
          es: "Borrar completadas", fr: "Effacer les terminés",
          de: "Erledigte löschen", it: "Cancella completati",
          pt: "Limpar concluídos")
    }

    // MARK: - ダウンロード行

    static func downloadingPhase(_ phase: String) -> String {
        t("\(phase)をダウンロード中", "Downloading \(phase)",
          zhHant: "正在下載\(phase)", zhHans: "正在下载\(phase)",
          ko: "\(phase) 다운로드 중", ru: "Загрузка: \(phase)",
          es: "Descargando \(phase)", fr: "Téléchargement \(phase)",
          de: "\(phase) wird heruntergeladen", it: "Download \(phase) in corso",
          pt: "Baixando \(phase)")
    }

    static var cancelHelp: String { cancel }

    static func remaining(_ eta: String) -> String {
        t("残り \(eta)", "\(eta) left",
          zhHant: "剩餘 \(eta)", zhHans: "剩余 \(eta)",
          ko: "\(eta) 남음", ru: "Осталось \(eta)",
          es: "\(eta) restante", fr: "\(eta) restant",
          de: "\(eta) verbleibend", it: "\(eta) rimanente",
          pt: "\(eta) restante")
    }

    static var converting: String {
        t("変換処理中...", "Converting...",
          zhHant: "轉換處理中…", zhHans: "转换处理中…",
          ko: "변환 처리 중...", ru: "Конвертация…",
          es: "Convirtiendo…", fr: "Conversion en cours…",
          de: "Konvertierung…", it: "Conversione in corso…",
          pt: "Convertendo…")
    }

    static var completed: String {
        t("完了", "Completed",
          zhHant: "完成", zhHans: "完成",
          ko: "완료", ru: "Завершено",
          es: "Completado", fr: "Terminé",
          de: "Abgeschlossen", it: "Completato",
          pt: "Concluído")
    }

    static var openFile: String {
        t("ファイルを開く", "Open File",
          zhHant: "開啟檔案", zhHans: "打开文件",
          ko: "파일 열기", ru: "Открыть файл",
          es: "Abrir archivo", fr: "Ouvrir le fichier",
          de: "Datei öffnen", it: "Apri file",
          pt: "Abrir arquivo")
    }

    static var revealInFinder: String {
        t("Finderで表示", "Reveal in Finder",
          zhHant: "在 Finder 中顯示", zhHans: "在 Finder 中显示",
          ko: "Finder에서 보기", ru: "Показать в Finder",
          es: "Mostrar en Finder", fr: "Afficher dans le Finder",
          de: "Im Finder anzeigen", it: "Mostra nel Finder",
          pt: "Mostrar no Finder")
    }

    static var removeFromList: String {
        t("リストから削除", "Remove from List",
          zhHant: "從列表中移除", zhHans: "从列表中移除",
          ko: "목록에서 삭제", ru: "Удалить из списка",
          es: "Eliminar de la lista", fr: "Retirer de la liste",
          de: "Aus Liste entfernen", it: "Rimuovi dalla lista",
          pt: "Remover da lista")
    }

    static var resume: String {
        t("再開", "Resume",
          zhHant: "繼續", zhHans: "继续",
          ko: "재개", ru: "Возобновить",
          es: "Reanudar", fr: "Reprendre",
          de: "Fortsetzen", it: "Riprendi",
          pt: "Retomar")
    }

    // MARK: - ダウンロードフェーズ

    static var phaseVideo: String {
        t("動画", "Video",
          zhHant: "影片", zhHans: "视频",
          ko: "동영상", ru: "Видео",
          es: "Vídeo", fr: "Vidéo",
          de: "Video", it: "Video",
          pt: "Vídeo")
    }

    static var phaseAudio: String {
        t("音声", "Audio",
          zhHant: "音訊", zhHans: "音频",
          ko: "오디오", ru: "Аудио",
          es: "Audio", fr: "Audio",
          de: "Audio", it: "Audio",
          pt: "Áudio")
    }

    static var phasePostProcess: String {
        t("変換処理", "Post-processing",
          zhHant: "轉換處理", zhHans: "转换处理",
          ko: "후처리", ru: "Обработка",
          es: "Postprocesamiento", fr: "Post-traitement",
          de: "Nachbearbeitung", it: "Post-elaborazione",
          pt: "Pós-processamento")
    }

    // MARK: - ダウンロードステータス

    static var statusWaiting: String {
        t("待機中", "Waiting",
          zhHant: "等候中", zhHans: "等待中",
          ko: "대기 중", ru: "Ожидание",
          es: "En espera", fr: "En attente",
          de: "Wartend", it: "In attesa",
          pt: "Aguardando")
    }

    static var statusDownloading: String {
        t("ダウンロード中", "Downloading",
          zhHant: "下載中", zhHans: "下载中",
          ko: "다운로드 중", ru: "Загрузка",
          es: "Descargando", fr: "Téléchargement",
          de: "Wird heruntergeladen", it: "Download in corso",
          pt: "Baixando")
    }

    static var statusProcessing: String {
        t("処理中", "Processing",
          zhHant: "處理中", zhHans: "处理中",
          ko: "처리 중", ru: "Обработка",
          es: "Procesando", fr: "Traitement",
          de: "Verarbeitung", it: "Elaborazione",
          pt: "Processando")
    }

    static var statusCompleted: String { completed }

    static var statusFailed: String {
        t("エラー", "Failed",
          zhHant: "錯誤", zhHans: "错误",
          ko: "오류", ru: "Ошибка",
          es: "Error", fr: "Erreur",
          de: "Fehler", it: "Errore",
          pt: "Erro")
    }

    static var statusCancelled: String {
        t("キャンセル", "Cancelled",
          zhHant: "已取消", zhHans: "已取消",
          ko: "취소됨", ru: "Отменено",
          es: "Cancelado", fr: "Annulé",
          de: "Abgebrochen", it: "Annullato",
          pt: "Cancelado")
    }

    static var statusPaused: String {
        t("一時停止", "Paused",
          zhHant: "已暫停", zhHans: "已暂停",
          ko: "일시정지", ru: "Пауза",
          es: "En pausa", fr: "En pause",
          de: "Pausiert", it: "In pausa",
          pt: "Pausado")
    }

    // MARK: - 動画情報

    static func formatCount(video: Int, audio: Int) -> String {
        t("利用可能: 動画 \(video)形式, 音声 \(audio)形式",
          "Available: \(video) video, \(audio) audio formats",
          zhHant: "可用：\(video) 種影片格式、\(audio) 種音訊格式",
          zhHans: "可用：\(video) 种视频格式、\(audio) 种音频格式",
          ko: "사용 가능: 동영상 \(video)개, 오디오 \(audio)개 형식",
          ru: "Доступно: \(video) видео, \(audio) аудио форматов",
          es: "Disponibles: \(video) vídeo, \(audio) audio formatos",
          fr: "Disponibles : \(video) vidéo, \(audio) audio formats",
          de: "Verfügbar: \(video) Video-, \(audio) Audioformate",
          it: "Disponibili: \(video) video, \(audio) formati audio",
          pt: "Disponíveis: \(video) vídeo, \(audio) formatos de áudio")
    }

    static func viewCount(_ count: Int) -> String {
        switch lang {
        case .ja:
            if count >= 10000 { return String(format: "%.1f万", Double(count) / 10000) }
            return "\(count)"
        case .zhHant, .zhHans:
            if count >= 10000 { return String(format: "%.1f萬", Double(count) / 10000) }
            return "\(count)"
        case .ko:
            if count >= 10000 { return String(format: "%.1f만", Double(count) / 10000) }
            return "\(count)"
        default:
            if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
            if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
            return "\(count)"
        }
    }

    static func uploadDate(year: String, month: String, day: String) -> String {
        switch lang {
        case .ja: return "\(year)年\(month)月\(day)日"
        case .zhHant, .zhHans: return "\(year)年\(month)月\(day)日"
        case .ko: return "\(year)년 \(month)월 \(day)일"
        case .de: return "\(day).\(month).\(year)"
        case .fr, .it, .pt: return "\(day)/\(month)/\(year)"
        case .ru: return "\(day).\(month).\(year)"
        default: return "\(year)/\(month)/\(day)"
        }
    }

    // MARK: - 設定画面

    static var generalTab: String {
        t("一般", "General",
          zhHant: "一般", zhHans: "通用",
          ko: "일반", ru: "Основные",
          es: "General", fr: "Général",
          de: "Allgemein", it: "Generali",
          pt: "Geral")
    }

    static var dependenciesTab: String {
        t("依存ライブラリ", "Dependencies",
          zhHant: "相依套件", zhHans: "依赖项",
          ko: "의존성", ru: "Зависимости",
          es: "Dependencias", fr: "Dépendances",
          de: "Abhängigkeiten", it: "Dipendenze",
          pt: "Dependências")
    }

    static var downloadDestination: String {
        t("ダウンロード先", "Download Location",
          zhHant: "下載位置", zhHans: "下载位置",
          ko: "다운로드 위치", ru: "Папка загрузок",
          es: "Ubicación de descarga", fr: "Emplacement de téléchargement",
          de: "Download-Ordner", it: "Posizione download",
          pt: "Local de download")
    }

    static var changeButton: String {
        t("変更...", "Change...",
          zhHant: "變更…", zhHans: "更改…",
          ko: "변경...", ru: "Изменить…",
          es: "Cambiar…", fr: "Modifier…",
          de: "Ändern…", it: "Cambia…",
          pt: "Alterar…")
    }

    static var defaultSettings: String {
        t("デフォルト設定", "Default Settings",
          zhHant: "預設設定", zhHans: "默认设置",
          ko: "기본 설정", ru: "По умолчанию",
          es: "Configuración predeterminada", fr: "Paramètres par défaut",
          de: "Standardeinstellungen", it: "Impostazioni predefinite",
          pt: "Configurações padrão")
    }

    static var defaultFormat: String {
        t("デフォルトフォーマット", "Default Format",
          zhHant: "預設格式", zhHans: "默认格式",
          ko: "기본 포맷", ru: "Формат по умолчанию",
          es: "Formato predeterminado", fr: "Format par défaut",
          de: "Standardformat", it: "Formato predefinito",
          pt: "Formato padrão")
    }

    static var containerFormat: String {
        t("コンテナ形式", "Container Format",
          zhHant: "容器格式", zhHans: "容器格式",
          ko: "컨테이너 형식", ru: "Формат контейнера",
          es: "Formato contenedor", fr: "Format conteneur",
          de: "Containerformat", it: "Formato contenitore",
          pt: "Formato de contêiner")
    }

    static var concurrentDownloads: String {
        t("並列ダウンロード数", "Concurrent Downloads",
          zhHant: "同時下載數", zhHans: "同时下载数",
          ko: "동시 다운로드 수", ru: "Одновременных загрузок",
          es: "Descargas simultáneas", fr: "Téléchargements simultanés",
          de: "Gleichzeitige Downloads", it: "Download simultanei",
          pt: "Downloads simultâneos")
    }

    static var fileNameTemplate: String {
        t("ファイル名テンプレート", "Filename Template",
          zhHant: "檔名範本", zhHans: "文件名模板",
          ko: "파일명 템플릿", ru: "Шаблон имени файла",
          es: "Plantilla de nombre", fr: "Modèle de nom de fichier",
          de: "Dateinamenvorlage", it: "Modello nome file",
          pt: "Modelo de nome de arquivo")
    }

    static var preset: String {
        t("プリセット", "Preset",
          zhHant: "預設", zhHans: "预设",
          ko: "프리셋", ru: "Пресет",
          es: "Preajuste", fr: "Préréglage",
          de: "Voreinstellung", it: "Preimpostazione",
          pt: "Predefinição")
    }

    static var customTemplate: String {
        t("カスタムテンプレート", "Custom Template",
          zhHant: "自訂範本", zhHans: "自定义模板",
          ko: "사용자 지정 템플릿", ru: "Свой шаблон",
          es: "Plantilla personalizada", fr: "Modèle personnalisé",
          de: "Benutzerdefinierte Vorlage", it: "Modello personalizzato",
          pt: "Modelo personalizado")
    }

    static var otherSettings: String {
        t("その他", "Other",
          zhHant: "其他", zhHans: "其他",
          ko: "기타", ru: "Прочее",
          es: "Otros", fr: "Autres",
          de: "Sonstiges", it: "Altro",
          pt: "Outros")
    }

    static var clipboardMonitoring: String {
        t("クリップボード監視", "Clipboard Monitoring",
          zhHant: "剪貼簿監控", zhHans: "剪贴板监控",
          ko: "클립보드 모니터링", ru: "Мониторинг буфера обмена",
          es: "Monitoreo del portapapeles", fr: "Surveillance du presse-papiers",
          de: "Zwischenablage überwachen", it: "Monitoraggio appunti",
          pt: "Monitoramento da área de transferência")
    }

    static var extraArgsLabel: String {
        t("yt-dlp 追加引数 (上級者向け)", "yt-dlp extra arguments (advanced)",
          zhHant: "yt-dlp 額外參數（進階）", zhHans: "yt-dlp 额外参数（高级）",
          ko: "yt-dlp 추가 인수 (고급)", ru: "yt-dlp дополнительные аргументы (для опытных)",
          es: "Argumentos extra de yt-dlp (avanzado)", fr: "Arguments supplémentaires yt-dlp (avancé)",
          de: "yt-dlp zusätzliche Argumente (erweitert)", it: "Argomenti extra yt-dlp (avanzato)",
          pt: "Argumentos extras do yt-dlp (avançado)")
    }

    static var extraArgsPlaceholder: String { "例: --cookies-from-browser safari" }

    static var chooseDownloadFolder: String {
        t("ダウンロード先フォルダを選択", "Choose Download Folder",
          zhHant: "選擇下載資料夾", zhHans: "选择下载文件夹",
          ko: "다운로드 폴더 선택", ru: "Выберите папку загрузок",
          es: "Seleccionar carpeta de descarga", fr: "Choisir le dossier de téléchargement",
          de: "Download-Ordner auswählen", it: "Scegli cartella download",
          pt: "Escolher pasta de download")
    }

    static var languageSection: String {
        t("言語", "Language",
          zhHant: "語言", zhHans: "语言",
          ko: "언어", ru: "Язык",
          es: "Idioma", fr: "Langue",
          de: "Sprache", it: "Lingua",
          pt: "Idioma")
    }

    static var languagePicker: String {
        t("表示言語", "Display Language",
          zhHant: "顯示語言", zhHans: "显示语言",
          ko: "표시 언어", ru: "Язык интерфейса",
          es: "Idioma de visualización", fr: "Langue d'affichage",
          de: "Anzeigesprache", it: "Lingua di visualizzazione",
          pt: "Idioma de exibição")
    }

    // MARK: - テンプレートプリセット

    static var templateTitle: String {
        t("タイトル", "Title",
          zhHant: "標題", zhHans: "标题",
          ko: "제목", ru: "Название",
          es: "Título", fr: "Titre",
          de: "Titel", it: "Titolo",
          pt: "Título")
    }

    static var templateTitleID: String {
        t("タイトル + ID", "Title + ID",
          zhHant: "標題 + ID", zhHans: "标题 + ID",
          ko: "제목 + ID", ru: "Название + ID",
          es: "Título + ID", fr: "Titre + ID",
          de: "Titel + ID", it: "Titolo + ID",
          pt: "Título + ID")
    }

    static var templateChannelTitle: String {
        t("チャンネル / タイトル", "Channel / Title",
          zhHant: "頻道 / 標題", zhHans: "频道 / 标题",
          ko: "채널 / 제목", ru: "Канал / Название",
          es: "Canal / Título", fr: "Chaîne / Titre",
          de: "Kanal / Titel", it: "Canale / Titolo",
          pt: "Canal / Título")
    }

    static var templateDateTitle: String {
        t("日付 - タイトル", "Date - Title",
          zhHant: "日期 - 標題", zhHans: "日期 - 标题",
          ko: "날짜 - 제목", ru: "Дата - Название",
          es: "Fecha - Título", fr: "Date - Titre",
          de: "Datum - Titel", it: "Data - Titolo",
          pt: "Data - Título")
    }

    // MARK: - プリセット表示名

    static var presetBestVideo: String {
        t("最高画質 (動画+音声)", "Best Quality (Video+Audio)",
          zhHant: "最高畫質（影片+音訊）", zhHans: "最高画质（视频+音频）",
          ko: "최고 화질 (동영상+오디오)", ru: "Лучшее качество (видео+аудио)",
          es: "Mejor calidad (vídeo+audio)", fr: "Meilleure qualité (vidéo+audio)",
          de: "Beste Qualität (Video+Audio)", it: "Migliore qualità (video+audio)",
          pt: "Melhor qualidade (vídeo+áudio)")
    }

    static var presetBestAudio: String {
        t("最高音質 (音声のみ)", "Best Audio (Audio Only)",
          zhHant: "最高音質（僅音訊）", zhHans: "最高音质（仅音频）",
          ko: "최고 음질 (오디오만)", ru: "Лучшее аудио (только аудио)",
          es: "Mejor audio (solo audio)", fr: "Meilleur audio (audio uniquement)",
          de: "Beste Audioqualität (nur Audio)", it: "Miglior audio (solo audio)",
          pt: "Melhor áudio (somente áudio)")
    }

    static var preset4K: String { "4K (2160p)" }

    static var preset1080p: String {
        t("1080p (フルHD)", "1080p (Full HD)",
          zhHant: "1080p (全高清)", zhHans: "1080p (全高清)",
          ko: "1080p (풀HD)", ru: "1080p (Full HD)",
          es: "1080p (Full HD)", fr: "1080p (Full HD)",
          de: "1080p (Full HD)", it: "1080p (Full HD)",
          pt: "1080p (Full HD)")
    }

    static var preset720p: String { "720p (HD)" }
    static var preset480p: String { "480p (SD)" }

    static var presetMP3: String {
        t("MP3 (音声のみ)", "MP3 (Audio Only)",
          zhHant: "MP3（僅音訊）", zhHans: "MP3（仅音频）",
          ko: "MP3 (오디오만)", ru: "MP3 (только аудио)",
          es: "MP3 (solo audio)", fr: "MP3 (audio uniquement)",
          de: "MP3 (nur Audio)", it: "MP3 (solo audio)",
          pt: "MP3 (somente áudio)")
    }

    static var presetM4A: String {
        t("M4A (音声のみ)", "M4A (Audio Only)",
          zhHant: "M4A（僅音訊）", zhHans: "M4A（仅音频）",
          ko: "M4A (오디오만)", ru: "M4A (только аудио)",
          es: "M4A (solo audio)", fr: "M4A (audio uniquement)",
          de: "M4A (nur Audio)", it: "M4A (solo audio)",
          pt: "M4A (somente áudio)")
    }

    static var presetOpus: String {
        t("Opus (音声のみ)", "Opus (Audio Only)",
          zhHant: "Opus（僅音訊）", zhHans: "Opus（仅音频）",
          ko: "Opus (오디오만)", ru: "Opus (только аудио)",
          es: "Opus (solo audio)", fr: "Opus (audio uniquement)",
          de: "Opus (nur Audio)", it: "Opus (solo audio)",
          pt: "Opus (somente áudio)")
    }

    static var presetCustom: String {
        t("カスタム", "Custom",
          zhHant: "自訂", zhHans: "自定义",
          ko: "사용자 지정", ru: "Пользовательский",
          es: "Personalizado", fr: "Personnalisé",
          de: "Benutzerdefiniert", it: "Personalizzato",
          pt: "Personalizado")
    }

    // MARK: - コンテナ

    static var containerMP4: String {
        t("MP4 (推奨)", "MP4 (Recommended)",
          zhHant: "MP4（推薦）", zhHans: "MP4（推荐）",
          ko: "MP4 (권장)", ru: "MP4 (рекомендуется)",
          es: "MP4 (recomendado)", fr: "MP4 (recommandé)",
          de: "MP4 (empfohlen)", it: "MP4 (consigliato)",
          pt: "MP4 (recomendado)")
    }

    // MARK: - 依存ライブラリ

    static var dependencyManagement: String {
        t("依存ライブラリの管理", "Dependency Management",
          zhHant: "相依套件管理", zhHans: "依赖项管理",
          ko: "의존성 관리", ru: "Управление зависимостями",
          es: "Gestión de dependencias", fr: "Gestion des dépendances",
          de: "Abhängigkeitsverwaltung", it: "Gestione dipendenze",
          pt: "Gerenciamento de dependências")
    }

    static var dependencySubtitle: String {
        t("yt-dlp-swift は以下のツールを使用します", "yt-dlp-swift requires the following tools",
          zhHant: "yt-dlp-swift 需要以下工具", zhHans: "yt-dlp-swift 需要以下工具",
          ko: "yt-dlp-swift는 다음 도구가 필요합니다", ru: "yt-dlp-swift использует следующие инструменты",
          es: "yt-dlp-swift requiere las siguientes herramientas", fr: "yt-dlp-swift nécessite les outils suivants",
          de: "yt-dlp-swift benötigt folgende Tools", it: "yt-dlp-swift richiede i seguenti strumenti",
          pt: "yt-dlp-swift requer as seguintes ferramentas")
    }

    static var log: String {
        t("ログ", "Log",
          zhHant: "日誌", zhHans: "日志",
          ko: "로그", ru: "Журнал",
          es: "Registro", fr: "Journal",
          de: "Protokoll", it: "Log",
          pt: "Log")
    }

    static var running: String {
        t("実行中...", "Running...",
          zhHant: "執行中…", zhHans: "运行中…",
          ko: "실행 중...", ru: "Выполняется…",
          es: "Ejecutando…", fr: "En cours…",
          de: "Wird ausgeführt…", it: "In esecuzione…",
          pt: "Executando…")
    }

    static var checkingVersion: String {
        t("バージョン確認中...", "Checking version...",
          zhHant: "確認版本中…", zhHans: "检查版本中…",
          ko: "버전 확인 중...", ru: "Проверка версии…",
          es: "Verificando versión…", fr: "Vérification de la version…",
          de: "Version wird überprüft…", it: "Verifica versione…",
          pt: "Verificando versão…")
    }

    static var checkingUpdate: String {
        t("最新版を確認中...", "Checking for updates...",
          zhHant: "檢查更新中…", zhHans: "检查更新中…",
          ko: "최신 버전 확인 중...", ru: "Проверка обновлений…",
          es: "Buscando actualizaciones…", fr: "Recherche de mises à jour…",
          de: "Nach Updates suchen…", it: "Verifica aggiornamenti…",
          pt: "Verificando atualizações…")
    }

    static var upToDate: String {
        t("- 最新です", "- Up to date",
          zhHant: "- 已是最新", zhHans: "- 已是最新",
          ko: "- 최신", ru: "- Актуальная версия",
          es: "- Actualizado", fr: "- À jour",
          de: "- Aktuell", it: "- Aggiornato",
          pt: "- Atualizado")
    }

    static func updateAvailable(_ version: String) -> String {
        t("- 最新: \(version)", "- Latest: \(version)",
          zhHant: "- 最新：\(version)", zhHans: "- 最新：\(version)",
          ko: "- 최신: \(version)", ru: "- Доступно: \(version)",
          es: "- Última: \(version)", fr: "- Dernière : \(version)",
          de: "- Neueste: \(version)", it: "- Ultima: \(version)",
          pt: "- Última: \(version)")
    }

    static var notInstalled: String {
        t("未インストール", "Not installed",
          zhHant: "未安裝", zhHans: "未安装",
          ko: "미설치", ru: "Не установлено",
          es: "No instalado", fr: "Non installé",
          de: "Nicht installiert", it: "Non installato",
          pt: "Não instalado")
    }

    static var autoInstall: String {
        t("自動インストール", "Auto Install",
          zhHant: "自動安裝", zhHans: "自动安装",
          ko: "자동 설치", ru: "Автоустановка",
          es: "Instalar automáticamente", fr: "Installation automatique",
          de: "Automatisch installieren", it: "Installazione automatica",
          pt: "Instalação automática")
    }

    static var skip: String {
        t("スキップ", "Skip",
          zhHant: "略過", zhHans: "跳过",
          ko: "건너뛰기", ru: "Пропустить",
          es: "Omitir", fr: "Ignorer",
          de: "Überspringen", it: "Salta",
          pt: "Pular")
    }

    static var recheck: String {
        t("再チェック", "Recheck",
          zhHant: "重新檢查", zhHans: "重新检查",
          ko: "다시 확인", ru: "Перепроверить",
          es: "Volver a comprobar", fr: "Revérifier",
          de: "Erneut prüfen", it: "Ricontrolla",
          pt: "Verificar novamente")
    }

    static var install: String {
        t("インストール", "Install",
          zhHant: "安裝", zhHans: "安装",
          ko: "설치", ru: "Установить",
          es: "Instalar", fr: "Installer",
          de: "Installieren", it: "Installa",
          pt: "Instalar")
    }

    static var update: String {
        t("更新", "Update",
          zhHant: "更新", zhHans: "更新",
          ko: "업데이트", ru: "Обновить",
          es: "Actualizar", fr: "Mettre à jour",
          de: "Aktualisieren", it: "Aggiorna",
          pt: "Atualizar")
    }

    static var installComplete: String {
        t("インストール完了", "Installation complete",
          zhHant: "安裝完成", zhHans: "安装完成",
          ko: "설치 완료", ru: "Установка завершена",
          es: "Instalación completa", fr: "Installation terminée",
          de: "Installation abgeschlossen", it: "Installazione completata",
          pt: "Instalação concluída")
    }

    static var installDone: String {
        t("完了しました", "Done",
          zhHant: "已完成", zhHans: "已完成",
          ko: "완료됨", ru: "Готово",
          es: "Listo", fr: "Terminé",
          de: "Fertig", it: "Fatto",
          pt: "Concluído")
    }

    // 依存ライブラリ名

    static var depYtDlp: String {
        t("yt-dlp (動画ダウンローダー)", "yt-dlp (Video Downloader)",
          zhHant: "yt-dlp（影片下載器）", zhHans: "yt-dlp（视频下载器）",
          ko: "yt-dlp (동영상 다운로더)", ru: "yt-dlp (загрузчик видео)",
          es: "yt-dlp (descargador de vídeo)", fr: "yt-dlp (téléchargeur vidéo)",
          de: "yt-dlp (Video-Downloader)", it: "yt-dlp (scaricatore video)",
          pt: "yt-dlp (baixador de vídeo)")
    }

    static var depFFmpeg: String {
        t("FFmpeg (動画変換エンジン)", "FFmpeg (Video Converter)",
          zhHant: "FFmpeg（影片轉換引擎）", zhHans: "FFmpeg（视频转换引擎）",
          ko: "FFmpeg (동영상 변환 엔진)", ru: "FFmpeg (конвертер видео)",
          es: "FFmpeg (convertidor de vídeo)", fr: "FFmpeg (convertisseur vidéo)",
          de: "FFmpeg (Video-Konverter)", it: "FFmpeg (convertitore video)",
          pt: "FFmpeg (conversor de vídeo)")
    }

    static var depFFprobe: String {
        t("FFprobe (メディア解析)", "FFprobe (Media Analyzer)",
          zhHant: "FFprobe（媒體分析）", zhHans: "FFprobe（媒体分析）",
          ko: "FFprobe (미디어 분석기)", ru: "FFprobe (анализатор медиа)",
          es: "FFprobe (analizador de medios)", fr: "FFprobe (analyseur média)",
          de: "FFprobe (Medienanalyse)", it: "FFprobe (analizzatore media)",
          pt: "FFprobe (analisador de mídia)")
    }

    static var depDeno: String {
        t("Deno (JavaScriptランタイム)", "Deno (JavaScript Runtime)",
          zhHant: "Deno（JavaScript 執行環境）", zhHans: "Deno（JavaScript 运行时）",
          ko: "Deno (JavaScript 런타임)", ru: "Deno (среда выполнения JavaScript)",
          es: "Deno (entorno de ejecución JavaScript)", fr: "Deno (environnement JavaScript)",
          de: "Deno (JavaScript-Laufzeit)", it: "Deno (runtime JavaScript)",
          pt: "Deno (runtime JavaScript)")
    }

    // 依存エラー

    static func depNotInstalled(_ name: String) -> String {
        t("\(name) がインストールされていません", "\(name) is not installed",
          zhHant: "\(name) 尚未安裝", zhHans: "\(name) 尚未安装",
          ko: "\(name)이(가) 설치되지 않았습니다", ru: "\(name) не установлен",
          es: "\(name) no está instalado", fr: "\(name) n'est pas installé",
          de: "\(name) ist nicht installiert", it: "\(name) non è installato",
          pt: "\(name) não está instalado")
    }

    static func depDownloadFailed(_ name: String, _ msg: String) -> String {
        t("\(name) のダウンロードに失敗しました: \(msg)", "Failed to download \(name): \(msg)",
          zhHant: "\(name) 下載失敗：\(msg)", zhHans: "\(name) 下载失败：\(msg)",
          ko: "\(name) 다운로드 실패: \(msg)", ru: "Не удалось загрузить \(name): \(msg)",
          es: "Error al descargar \(name): \(msg)", fr: "Échec du téléchargement de \(name) : \(msg)",
          de: "Download von \(name) fehlgeschlagen: \(msg)", it: "Download di \(name) fallito: \(msg)",
          pt: "Falha ao baixar \(name): \(msg)")
    }

    static func depInstallFailed(_ name: String, _ msg: String) -> String {
        t("\(name) のインストールに失敗しました: \(msg)", "Failed to install \(name): \(msg)",
          zhHant: "\(name) 安裝失敗：\(msg)", zhHans: "\(name) 安装失败：\(msg)",
          ko: "\(name) 설치 실패: \(msg)", ru: "Не удалось установить \(name): \(msg)",
          es: "Error al instalar \(name): \(msg)", fr: "Échec de l'installation de \(name) : \(msg)",
          de: "Installation von \(name) fehlgeschlagen: \(msg)", it: "Installazione di \(name) fallita: \(msg)",
          pt: "Falha ao instalar \(name): \(msg)")
    }

    static var downloadURLNotFound: String {
        t("ダウンロードURLが取得できませんでした", "Download URL not found",
          zhHant: "無法取得下載 URL", zhHans: "无法获取下载 URL",
          ko: "다운로드 URL을 가져올 수 없습니다", ru: "URL для загрузки не найден",
          es: "URL de descarga no encontrada", fr: "URL de téléchargement introuvable",
          de: "Download-URL nicht gefunden", it: "URL di download non trovato",
          pt: "URL de download não encontrado")
    }

    static var extractionFailed: String {
        t("展開に失敗しました", "Extraction failed",
          zhHant: "解壓縮失敗", zhHans: "解压失败",
          ko: "압축 해제 실패", ru: "Ошибка распаковки",
          es: "Error de extracción", fr: "Échec de l'extraction",
          de: "Entpacken fehlgeschlagen", it: "Estrazione fallita",
          pt: "Falha na extração")
    }

    static func binaryNotFoundInArchive(_ name: String) -> String {
        t("\(name) が見つかりませんでした", "\(name) not found in archive",
          zhHant: "在封存檔中找不到 \(name)", zhHans: "在压缩包中找不到 \(name)",
          ko: "아카이브에서 \(name)을(를) 찾을 수 없습니다", ru: "\(name) не найден в архиве",
          es: "\(name) no encontrado en el archivo", fr: "\(name) introuvable dans l'archive",
          de: "\(name) im Archiv nicht gefunden", it: "\(name) non trovato nell'archivio",
          pt: "\(name) não encontrado no arquivo")
    }

    static func assetNotFound(_ name: String) -> String {
        t("アセット '\(name)' が見つかりません", "Asset '\(name)' not found",
          zhHant: "找不到資源「\(name)」", zhHans: "找不到资源「\(name)」",
          ko: "에셋 '\(name)'을(를) 찾을 수 없습니다", ru: "Ресурс '\(name)' не найден",
          es: "Recurso '\(name)' no encontrado", fr: "Ressource '\(name)' introuvable",
          de: "Asset '\(name)' nicht gefunden", it: "Asset '\(name)' non trovato",
          pt: "Ativo '\(name)' não encontrado")
    }

    static var invalidDownloadURL: String {
        t("無効なダウンロードURL", "Invalid download URL",
          zhHant: "無效的下載 URL", zhHans: "无效的下载 URL",
          ko: "잘못된 다운로드 URL", ru: "Недействительный URL загрузки",
          es: "URL de descarga no válida", fr: "URL de téléchargement invalide",
          de: "Ungültige Download-URL", it: "URL di download non valido",
          pt: "URL de download inválido")
    }

    static var githubAPIError: String {
        t("GitHub APIエラー", "GitHub API error",
          zhHant: "GitHub API 錯誤", zhHans: "GitHub API 错误",
          ko: "GitHub API 오류", ru: "Ошибка GitHub API",
          es: "Error de API de GitHub", fr: "Erreur de l'API GitHub",
          de: "GitHub-API-Fehler", it: "Errore API GitHub",
          pt: "Erro da API do GitHub")
    }

    static var downloadHTTPError: String {
        t("ダウンロードHTTPエラー", "Download HTTP error",
          zhHant: "下載 HTTP 錯誤", zhHans: "下载 HTTP 错误",
          ko: "다운로드 HTTP 오류", ru: "Ошибка HTTP при загрузке",
          es: "Error HTTP de descarga", fr: "Erreur HTTP de téléchargement",
          de: "Download-HTTP-Fehler", it: "Errore HTTP download",
          pt: "Erro HTTP de download")
    }

    // MARK: - yt-dlpエラー

    static var ytDlpNotFound: String {
        t("yt-dlpが見つかりません。依存ライブラリの設定を確認してください。",
          "yt-dlp not found. Please check dependency settings.",
          zhHant: "找不到 yt-dlp。請檢查相依套件設定。",
          zhHans: "找不到 yt-dlp。请检查依赖项设置。",
          ko: "yt-dlp를 찾을 수 없습니다. 의존성 설정을 확인하세요.",
          ru: "yt-dlp не найден. Проверьте настройки зависимостей.",
          es: "yt-dlp no encontrado. Verifique la configuración de dependencias.",
          fr: "yt-dlp introuvable. Vérifiez les paramètres des dépendances.",
          de: "yt-dlp nicht gefunden. Bitte überprüfen Sie die Abhängigkeitseinstellungen.",
          it: "yt-dlp non trovato. Controlla le impostazioni delle dipendenze.",
          pt: "yt-dlp não encontrado. Verifique as configurações de dependências.")
    }

    static var invalidURL: String {
        t("無効なURLです。", "Invalid URL.",
          zhHant: "無效的 URL。", zhHans: "无效的 URL。",
          ko: "잘못된 URL입니다.", ru: "Недействительный URL.",
          es: "URL no válida.", fr: "URL invalide.",
          de: "Ungültige URL.", it: "URL non valido.",
          pt: "URL inválido.")
    }

    static func fetchFailed(_ msg: String) -> String {
        t("動画情報の取得に失敗しました: \(msg)", "Failed to fetch video info: \(msg)",
          zhHant: "取得影片資訊失敗：\(msg)", zhHans: "获取视频信息失败：\(msg)",
          ko: "동영상 정보를 가져오지 못했습니다: \(msg)", ru: "Не удалось получить информацию о видео: \(msg)",
          es: "Error al obtener información del vídeo: \(msg)", fr: "Échec de la récupération des informations vidéo : \(msg)",
          de: "Videoinfo konnte nicht abgerufen werden: \(msg)", it: "Impossibile ottenere le informazioni del video: \(msg)",
          pt: "Falha ao obter informações do vídeo: \(msg)")
    }

    static func downloadFailed(_ msg: String) -> String {
        t("ダウンロードに失敗しました: \(msg)", "Download failed: \(msg)",
          zhHant: "下載失敗：\(msg)", zhHans: "下载失败：\(msg)",
          ko: "다운로드 실패: \(msg)", ru: "Ошибка загрузки: \(msg)",
          es: "Error de descarga: \(msg)", fr: "Échec du téléchargement : \(msg)",
          de: "Download fehlgeschlagen: \(msg)", it: "Download fallito: \(msg)",
          pt: "Falha no download: \(msg)")
    }

    static func jsonParseFailed(_ msg: String) -> String {
        t("動画情報の解析に失敗しました: \(msg)", "Failed to parse video info: \(msg)",
          zhHant: "解析影片資訊失敗：\(msg)", zhHans: "解析视频信息失败：\(msg)",
          ko: "동영상 정보를 분석하지 못했습니다: \(msg)", ru: "Ошибка разбора информации о видео: \(msg)",
          es: "Error al analizar la información del vídeo: \(msg)", fr: "Échec de l'analyse des informations vidéo : \(msg)",
          de: "Videoinfo konnte nicht analysiert werden: \(msg)", it: "Impossibile analizzare le informazioni del video: \(msg)",
          pt: "Falha ao analisar informações do vídeo: \(msg)")
    }

    static func unknownError(_ exitCode: Int32) -> String {
        t("不明なエラー (終了コード: \(exitCode))", "Unknown error (exit code: \(exitCode))",
          zhHant: "未知錯誤（結束碼：\(exitCode)）", zhHans: "未知错误（退出码：\(exitCode)）",
          ko: "알 수 없는 오류 (종료 코드: \(exitCode))", ru: "Неизвестная ошибка (код выхода: \(exitCode))",
          es: "Error desconocido (código de salida: \(exitCode))", fr: "Erreur inconnue (code de sortie : \(exitCode))",
          de: "Unbekannter Fehler (Exit-Code: \(exitCode))", it: "Errore sconosciuto (codice di uscita: \(exitCode))",
          pt: "Erro desconhecido (código de saída: \(exitCode))")
    }

    static var emptyJSON: String {
        t("JSON出力が空です", "JSON output is empty",
          zhHant: "JSON 輸出為空", zhHans: "JSON 输出为空",
          ko: "JSON 출력이 비어있습니다", ru: "JSON-вывод пуст",
          es: "La salida JSON está vacía", fr: "La sortie JSON est vide",
          de: "JSON-Ausgabe ist leer", it: "L'output JSON è vuoto",
          pt: "A saída JSON está vazia")
    }

    static func exitCodeError(_ code: Int32) -> String {
        t("終了コード: \(code)", "Exit code: \(code)",
          zhHant: "結束碼：\(code)", zhHans: "退出码：\(code)",
          ko: "종료 코드: \(code)", ru: "Код выхода: \(code)",
          es: "Código de salida: \(code)", fr: "Code de sortie : \(code)",
          de: "Exit-Code: \(code)", it: "Codice di uscita: \(code)",
          pt: "Código de saída: \(code)")
    }

    // MARK: - 通知

    static var downloadComplete: String {
        t("ダウンロード完了", "Download Complete",
          zhHant: "下載完成", zhHans: "下载完成",
          ko: "다운로드 완료", ru: "Загрузка завершена",
          es: "Descarga completada", fr: "Téléchargement terminé",
          de: "Download abgeschlossen", it: "Download completato",
          pt: "Download concluído")
    }

    // MARK: - 対応サイト

    static var searchSitesPlaceholder: String {
        t("サイトを検索...", "Search sites...",
          zhHant: "搜尋網站…", zhHans: "搜索网站…",
          ko: "사이트 검색...", ru: "Поиск сайтов…",
          es: "Buscar sitios…", fr: "Rechercher des sites…",
          de: "Seiten suchen…", it: "Cerca siti…",
          pt: "Pesquisar sites…")
    }

    static var requiresLogin: String {
        t("要ログイン", "Login Required",
          zhHant: "需登入", zhHans: "需登录",
          ko: "로그인 필요", ru: "Требуется вход",
          es: "Requiere inicio de sesión", fr: "Connexion requise",
          de: "Anmeldung erforderlich", it: "Accesso richiesto",
          pt: "Login necessário")
    }

    static var jsRequired: String {
        t("JS必須", "JS Required",
          zhHant: "需 JS", zhHans: "需 JS",
          ko: "JS 필수", ru: "Нужен JS",
          es: "Requiere JS", fr: "JS requis",
          de: "JS erforderlich", it: "JS richiesto",
          pt: "JS necessário")
    }

    static var loggedIn: String {
        t("ログイン済み", "Logged In",
          zhHant: "已登入", zhHans: "已登录",
          ko: "로그인됨", ru: "Выполнен вход",
          es: "Sesión iniciada", fr: "Connecté",
          de: "Angemeldet", it: "Connesso",
          pt: "Conectado")
    }

    static var reLogin: String {
        t("再ログイン", "Re-login",
          zhHant: "重新登入", zhHans: "重新登录",
          ko: "재로그인", ru: "Войти заново",
          es: "Iniciar sesión de nuevo", fr: "Se reconnecter",
          de: "Erneut anmelden", it: "Accedi di nuovo",
          pt: "Fazer login novamente")
    }

    static var logoutDeleteCookies: String {
        t("ログアウト (Cookie削除)", "Logout (Delete Cookies)",
          zhHant: "登出（刪除 Cookie）", zhHans: "登出（删除 Cookie）",
          ko: "로그아웃 (쿠키 삭제)", ru: "Выйти (удалить Cookie)",
          es: "Cerrar sesión (eliminar cookies)", fr: "Déconnexion (supprimer les cookies)",
          de: "Abmelden (Cookies löschen)", it: "Esci (elimina cookie)",
          pt: "Sair (excluir cookies)")
    }

    static var login: String {
        t("ログイン", "Login",
          zhHant: "登入", zhHans: "登录",
          ko: "로그인", ru: "Войти",
          es: "Iniciar sesión", fr: "Connexion",
          de: "Anmelden", it: "Accedi",
          pt: "Entrar")
    }

    static func totalSitesSupported(_ count: Int) -> String {
        t("yt-dlp は合計 \(count) サイトに対応しています",
          "yt-dlp supports \(count) sites in total",
          zhHant: "yt-dlp 總共支援 \(count) 個網站",
          zhHans: "yt-dlp 总共支持 \(count) 个网站",
          ko: "yt-dlp는 총 \(count)개의 사이트를 지원합니다",
          ru: "yt-dlp поддерживает \(count) сайтов",
          es: "yt-dlp es compatible con \(count) sitios en total",
          fr: "yt-dlp prend en charge \(count) sites au total",
          de: "yt-dlp unterstützt insgesamt \(count) Seiten",
          it: "yt-dlp supporta \(count) siti in totale",
          pt: "yt-dlp suporta \(count) sites no total")
    }

    // MARK: - ログインWebView

    static var webViewInitFailed: String {
        t("WebViewの初期化に失敗しました", "Failed to initialize WebView",
          zhHant: "WebView 初始化失敗", zhHans: "WebView 初始化失败",
          ko: "WebView 초기화 실패", ru: "Не удалось инициализировать WebView",
          es: "Error al inicializar WebView", fr: "Échec de l'initialisation de WebView",
          de: "WebView-Initialisierung fehlgeschlagen", it: "Inizializzazione WebView fallita",
          pt: "Falha ao inicializar WebView")
    }

    static var saveCookiesAndLogin: String {
        t("Cookieを保存してログイン完了", "Save Cookies & Complete Login",
          zhHant: "儲存 Cookie 並完成登入", zhHans: "保存 Cookie 并完成登录",
          ko: "쿠키 저장 및 로그인 완료", ru: "Сохранить Cookie и завершить вход",
          es: "Guardar cookies y completar inicio de sesión", fr: "Enregistrer les cookies et terminer la connexion",
          de: "Cookies speichern und Anmeldung abschließen", it: "Salva cookie e completa l'accesso",
          pt: "Salvar cookies e completar login")
    }

    static var cookieSaved: String {
        t("Cookieの保存が完了しました", "Cookies saved successfully",
          zhHant: "Cookie 儲存完成", zhHans: "Cookie 保存完成",
          ko: "쿠키 저장이 완료되었습니다", ru: "Cookie успешно сохранены",
          es: "Cookies guardadas correctamente", fr: "Cookies enregistrés avec succès",
          de: "Cookies erfolgreich gespeichert", it: "Cookie salvati con successo",
          pt: "Cookies salvos com sucesso")
    }

    static func saveError(_ msg: String) -> String {
        t("保存エラー: \(msg)", "Save error: \(msg)",
          zhHant: "儲存錯誤：\(msg)", zhHans: "保存错误：\(msg)",
          ko: "저장 오류: \(msg)", ru: "Ошибка сохранения: \(msg)",
          es: "Error al guardar: \(msg)", fr: "Erreur de sauvegarde : \(msg)",
          de: "Speicherfehler: \(msg)", it: "Errore di salvataggio: \(msg)",
          pt: "Erro ao salvar: \(msg)")
    }

    // MARK: - About画面

    static var version: String {
        t("バージョン 1.1.0", "Version 1.1.0",
          zhHant: "版本 1.1.0", zhHans: "版本 1.1.0",
          ko: "버전 1.1.0", ru: "Версия 1.1.0",
          es: "Versión 1.1.0", fr: "Version 1.1.0",
          de: "Version 1.1.0", it: "Versione 1.1.0",
          pt: "Versão 1.1.0")
    }

    static var appDescription: String {
        t("macOS向け yt-dlp GUIアプリケーション", "yt-dlp GUI application for macOS",
          zhHant: "macOS 版 yt-dlp 圖形介面應用程式", zhHans: "macOS 版 yt-dlp 图形界面应用",
          ko: "macOS용 yt-dlp GUI 애플리케이션", ru: "GUI-приложение yt-dlp для macOS",
          es: "Aplicación GUI de yt-dlp para macOS", fr: "Application GUI yt-dlp pour macOS",
          de: "yt-dlp GUI-Anwendung für macOS", it: "Applicazione GUI yt-dlp per macOS",
          pt: "Aplicativo GUI yt-dlp para macOS")
    }

    static var licenseNote: String {
        t("yt-dlp, FFmpeg, Deno はそれぞれのライセンスに基づきます",
          "yt-dlp, FFmpeg, Deno are subject to their respective licenses",
          zhHant: "yt-dlp、FFmpeg、Deno 依其各自授權條款",
          zhHans: "yt-dlp、FFmpeg、Deno 遵循各自的许可证",
          ko: "yt-dlp, FFmpeg, Deno는 각각의 라이선스를 따릅니다",
          ru: "yt-dlp, FFmpeg, Deno распространяются под собственными лицензиями",
          es: "yt-dlp, FFmpeg, Deno están sujetos a sus respectivas licencias",
          fr: "yt-dlp, FFmpeg, Deno sont soumis à leurs licences respectives",
          de: "yt-dlp, FFmpeg, Deno unterliegen ihren jeweiligen Lizenzen",
          it: "yt-dlp, FFmpeg, Deno sono soggetti alle rispettive licenze",
          pt: "yt-dlp, FFmpeg, Deno estão sujeitos às suas respectivas licenças")
    }

    // MARK: - プレイリスト

    static var playlistBehavior: String {
        t("プレイリストの動作", "Playlist behavior",
          zhHant: "播放清單行為", zhHans: "播放列表行为",
          ko: "재생목록 동작", ru: "Поведение плейлиста",
          es: "Comportamiento de la lista", fr: "Comportement de la playlist",
          de: "Playlist-Verhalten", it: "Comportamento playlist",
          pt: "Comportamento da playlist")
    }

    static var playlistSingleOnly: String {
        t("常に単一動画のみ", "Always single video only",
          zhHant: "總是僅下載單一影片", zhHans: "总是仅下载单个视频",
          ko: "항상 단일 동영상만", ru: "Только одно видео",
          es: "Solo un video", fr: "Vidéo unique uniquement",
          de: "Immer nur einzelnes Video", it: "Solo video singolo",
          pt: "Apenas vídeo único")
    }

    static var playlistAll: String {
        t("常にプレイリスト全体", "Always entire playlist",
          zhHant: "總是下載整個播放清單", zhHans: "总是下载整个播放列表",
          ko: "항상 전체 재생목록", ru: "Весь плейлист",
          es: "Lista completa", fr: "Playlist entière",
          de: "Immer gesamte Playlist", it: "Intera playlist",
          pt: "Playlist inteira")
    }

    static var playlistAsk: String {
        t("毎回確認する", "Ask every time",
          zhHant: "每次詢問", zhHans: "每次询问",
          ko: "매번 확인", ru: "Спрашивать каждый раз",
          es: "Preguntar siempre", fr: "Demander à chaque fois",
          de: "Jedes Mal fragen", it: "Chiedi ogni volta",
          pt: "Perguntar sempre")
    }

    static var playlistDetectedTitle: String {
        t("プレイリストが検出されました", "Playlist detected",
          zhHant: "偵測到播放清單", zhHans: "检测到播放列表",
          ko: "재생목록이 감지되었습니다", ru: "Обнаружен плейлист",
          es: "Lista de reproducción detectada", fr: "Playlist détectée",
          de: "Playlist erkannt", it: "Playlist rilevata",
          pt: "Playlist detectada")
    }

    static var playlistDetectedMessage: String {
        t("このURLにはプレイリストが含まれています。どのようにダウンロードしますか？",
          "This URL contains a playlist. How would you like to download?",
          zhHant: "此網址包含播放清單。您要如何下載？",
          zhHans: "此网址包含播放列表。您想如何下载？",
          ko: "이 URL에 재생목록이 포함되어 있습니다. 어떻게 다운로드하시겠습니까?",
          ru: "Этот URL содержит плейлист. Как вы хотите скачать?",
          es: "Esta URL contiene una lista. ¿Cómo desea descargar?",
          fr: "Cette URL contient une playlist. Comment souhaitez-vous télécharger ?",
          de: "Diese URL enthält eine Playlist. Wie möchten Sie herunterladen?",
          it: "Questo URL contiene una playlist. Come vuoi scaricare?",
          pt: "Este URL contém uma playlist. Como deseja baixar?")
    }

    static var downloadSingleVideo: String {
        t("この動画のみ", "This video only",
          zhHant: "僅此影片", zhHans: "仅此视频",
          ko: "이 동영상만", ru: "Только это видео",
          es: "Solo este video", fr: "Cette vidéo uniquement",
          de: "Nur dieses Video", it: "Solo questo video",
          pt: "Apenas este vídeo")
    }

    static var downloadEntirePlaylist: String {
        t("プレイリスト全体", "Entire playlist",
          zhHant: "整個播放清單", zhHans: "整个播放列表",
          ko: "전체 재생목록", ru: "Весь плейлист",
          es: "Lista completa", fr: "Playlist entière",
          de: "Gesamte Playlist", it: "Intera playlist",
          pt: "Playlist inteira")
    }

    // MARK: - メニューバー

    static var menuBarResident: String {
        t("メニューバーに常駐", "Show in menu bar",
          zhHant: "顯示在選單列", zhHans: "显示在菜单栏",
          ko: "메뉴 막대에 표시", ru: "Показывать в строке меню",
          es: "Mostrar en la barra de menú", fr: "Afficher dans la barre des menus",
          de: "In Menüleiste anzeigen", it: "Mostra nella barra dei menu",
          pt: "Mostrar na barra de menus")
    }

    static var menuBarURLPlaceholder: String {
        t("URLを貼り付け", "Paste URL",
          zhHant: "貼上網址", zhHans: "粘贴网址",
          ko: "URL 붙여넣기", ru: "Вставьте URL",
          es: "Pegar URL", fr: "Coller l'URL",
          de: "URL einfügen", it: "Incolla URL",
          pt: "Colar URL")
    }

    static var menuBarPaste: String {
        t("クリップボードから貼り付け", "Paste from clipboard",
          zhHant: "從剪貼簿貼上", zhHans: "从剪贴板粘贴",
          ko: "클립보드에서 붙여넣기", ru: "Вставить из буфера обмена",
          es: "Pegar desde el portapapeles", fr: "Coller depuis le presse-papiers",
          de: "Aus Zwischenablage einfügen", it: "Incolla dagli appunti",
          pt: "Colar da área de transferência")
    }

    static var menuBarDownload: String {
        t("ダウンロード", "Download",
          zhHant: "下載", zhHans: "下载",
          ko: "다운로드", ru: "Скачать",
          es: "Descargar", fr: "Télécharger",
          de: "Herunterladen", it: "Scarica",
          pt: "Baixar")
    }

    static var menuBarRecentDownloads: String {
        t("最近のダウンロード", "Recent Downloads",
          zhHant: "最近的下載", zhHans: "最近的下载",
          ko: "최근 다운로드", ru: "Недавние загрузки",
          es: "Descargas recientes", fr: "Téléchargements récents",
          de: "Aktuelle Downloads", it: "Download recenti",
          pt: "Downloads recentes")
    }

    static var menuBarOpenMainWindow: String {
        t("メインウィンドウを開く", "Open Main Window",
          zhHant: "開啟主視窗", zhHans: "打开主窗口",
          ko: "기본 창 열기", ru: "Открыть главное окно",
          es: "Abrir ventana principal", fr: "Ouvrir la fenêtre principale",
          de: "Hauptfenster öffnen", it: "Apri finestra principale",
          pt: "Abrir janela principal")
    }

    static var menuBarQuit: String {
        t("終了", "Quit",
          zhHant: "結束", zhHans: "退出",
          ko: "종료", ru: "Выход",
          es: "Salir", fr: "Quitter",
          de: "Beenden", it: "Esci",
          pt: "Sair")
    }

    // MARK: - Python3検出

    static func python3Detected(_ version: String) -> String {
        t("Python3 検出済み (v\(version))", "Python3 Detected (v\(version))",
          zhHant: "已偵測到 Python3 (v\(version))", zhHans: "已检测到 Python3 (v\(version))",
          ko: "Python3 감지됨 (v\(version))", ru: "Python3 обнаружен (v\(version))",
          es: "Python3 detectado (v\(version))", fr: "Python3 détecté (v\(version))",
          de: "Python3 erkannt (v\(version))", it: "Python3 rilevato (v\(version))",
          pt: "Python3 detectado (v\(version))")
    }

    static var python3DetectedDetail: String {
        t("yt-dlpはPython版 (pip) で高速にインストール・実行されます",
          "yt-dlp will be installed via pip for faster performance",
          zhHant: "yt-dlp 將透過 pip 安裝以獲得更快的效能",
          zhHans: "yt-dlp 将通过 pip 安装以获得更快的性能",
          ko: "yt-dlp가 더 빠른 성능을 위해 pip로 설치됩니다",
          ru: "yt-dlp будет установлен через pip для большей скорости",
          es: "yt-dlp se instalará via pip para un mejor rendimiento",
          fr: "yt-dlp sera installé via pip pour de meilleures performances",
          de: "yt-dlp wird via pip für bessere Leistung installiert",
          it: "yt-dlp verrà installato tramite pip per prestazioni migliori",
          pt: "yt-dlp será instalado via pip para melhor desempenho")
    }

    static var python3NotFound: String {
        t("Python3 が見つかりません", "Python3 Not Found",
          zhHant: "未找到 Python3", zhHans: "未找到 Python3",
          ko: "Python3을 찾을 수 없음", ru: "Python3 не найден",
          es: "Python3 no encontrado", fr: "Python3 non trouvé",
          de: "Python3 nicht gefunden", it: "Python3 non trovato",
          pt: "Python3 não encontrado")
    }

    static var python3NotFoundDetail: String {
        t("Python3がないため、yt-dlpはスタンドアロン版でインストールされます。スタンドアロン版は起動が遅いため、Python3のインストールを推奨します。",
          "Without Python3, yt-dlp will be installed as a standalone binary. The standalone version has slower startup. Installing Python3 is recommended.",
          zhHant: "沒有 Python3，yt-dlp 將以獨立二進制檔安裝。獨立版啟動較慢，建議安裝 Python3。",
          zhHans: "没有 Python3，yt-dlp 将以独立二进制文件安装。独立版启动较慢，建议安装 Python3。",
          ko: "Python3 없이 yt-dlp는 독립 실행 파일로 설치됩니다. 독립 버전은 시작이 느리므로 Python3 설치를 권장합니다.",
          ru: "Без Python3 yt-dlp будет установлен как автономный бинарник. Автономная версия медленнее запускается. Рекомендуется установить Python3.",
          es: "Sin Python3, yt-dlp se instalará como binario independiente. La versión independiente es más lenta. Se recomienda instalar Python3.",
          fr: "Sans Python3, yt-dlp sera installé en binaire autonome. La version autonome démarre plus lentement. L'installation de Python3 est recommandée.",
          de: "Ohne Python3 wird yt-dlp als eigenständige Binary installiert. Die eigenständige Version startet langsamer. Die Installation von Python3 wird empfohlen.",
          it: "Senza Python3, yt-dlp verrà installato come binario standalone. La versione standalone è più lenta. Si consiglia di installare Python3.",
          pt: "Sem Python3, yt-dlp será instalado como binário independente. A versão independente é mais lenta. Recomenda-se instalar o Python3.")
    }

    static var python3InstallHint: String {
        t("インストール方法: brew install python3", "Install: brew install python3",
          zhHant: "安裝方式：brew install python3", zhHans: "安装方式：brew install python3",
          ko: "설치: brew install python3", ru: "Установка: brew install python3",
          es: "Instalar: brew install python3", fr: "Installer : brew install python3",
          de: "Installation: brew install python3", it: "Installazione: brew install python3",
          pt: "Instalar: brew install python3")
    }

    // MARK: - yt-dlpパス設定

    static var ytDlpPathSection: String {
        t("yt-dlp バイナリ", "yt-dlp Binary",
          zhHant: "yt-dlp 執行檔", zhHans: "yt-dlp 可执行文件",
          ko: "yt-dlp 바이너리", ru: "Бинарный файл yt-dlp",
          es: "Binario yt-dlp", fr: "Binaire yt-dlp",
          de: "yt-dlp Binary", it: "Binario yt-dlp",
          pt: "Binário yt-dlp")
    }

    static var ytDlpPathLabel: String {
        t("使用するパス", "Binary Path",
          zhHant: "使用路徑", zhHans: "使用路径",
          ko: "사용할 경로", ru: "Путь к файлу",
          es: "Ruta del binario", fr: "Chemin du binaire",
          de: "Binärpfad", it: "Percorso binario",
          pt: "Caminho do binário")
    }

    static var ytDlpPathAuto: String {
        t("自動検出", "Auto Detect",
          zhHant: "自動偵測", zhHans: "自动检测",
          ko: "자동 감지", ru: "Автоопределение",
          es: "Detección automática", fr: "Détection automatique",
          de: "Automatisch erkennen", it: "Rilevamento automatico",
          pt: "Detecção automática")
    }

    static var ytDlpPathPip: String {
        t("Python版 (pip) — 推奨", "Python (pip) — Recommended",
          zhHant: "Python 版 (pip) — 推薦", zhHans: "Python 版 (pip) — 推荐",
          ko: "Python 버전 (pip) — 권장", ru: "Python (pip) — Рекомендуется",
          es: "Python (pip) — Recomendado", fr: "Python (pip) — Recommandé",
          de: "Python (pip) — Empfohlen", it: "Python (pip) — Consigliato",
          pt: "Python (pip) — Recomendado")
    }

    static var ytDlpPathCustom: String {
        t("カスタムパス…", "Custom Path…",
          zhHant: "自訂路徑…", zhHans: "自定义路径…",
          ko: "사용자 지정 경로…", ru: "Другой путь…",
          es: "Ruta personalizada…", fr: "Chemin personnalisé…",
          de: "Benutzerdefinierter Pfad…", it: "Percorso personalizzato…",
          pt: "Caminho personalizado…")
    }

    static var ytDlpPathCustomPlaceholder: String {
        t("/path/to/yt-dlp", "/path/to/yt-dlp",
          zhHant: "/path/to/yt-dlp", zhHans: "/path/to/yt-dlp",
          ko: "/path/to/yt-dlp", ru: "/path/to/yt-dlp",
          es: "/path/to/yt-dlp", fr: "/path/to/yt-dlp",
          de: "/path/to/yt-dlp", it: "/path/to/yt-dlp",
          pt: "/path/to/yt-dlp")
    }

    static var ytDlpChooseBinary: String {
        t("yt-dlp バイナリを選択", "Choose yt-dlp Binary",
          zhHant: "選擇 yt-dlp 執行檔", zhHans: "选择 yt-dlp 可执行文件",
          ko: "yt-dlp 바이너리 선택", ru: "Выберите бинарный файл yt-dlp",
          es: "Seleccionar binario yt-dlp", fr: "Choisir le binaire yt-dlp",
          de: "yt-dlp Binary auswählen", it: "Seleziona binario yt-dlp",
          pt: "Selecionar binário yt-dlp")
    }

    static var browseButton: String {
        t("選択…", "Browse…",
          zhHant: "瀏覽…", zhHans: "浏览…",
          ko: "찾아보기…", ru: "Обзор…",
          es: "Examinar…", fr: "Parcourir…",
          de: "Durchsuchen…", it: "Sfoglia…",
          pt: "Procurar…")
    }

    static func ytDlpCurrentPath(_ path: String) -> String {
        t("現在のパス: \(path)", "Current path: \(path)",
          zhHant: "目前路徑：\(path)", zhHans: "当前路径：\(path)",
          ko: "현재 경로: \(path)", ru: "Текущий путь: \(path)",
          es: "Ruta actual: \(path)", fr: "Chemin actuel : \(path)",
          de: "Aktueller Pfad: \(path)", it: "Percorso attuale: \(path)",
          pt: "Caminho atual: \(path)")
    }

    // MARK: - ライブ配信録画

    static var modeDownload: String {
        t("ダウンロード", "Download",
          zhHant: "下載", zhHans: "下载",
          ko: "다운로드", ru: "Загрузка",
          es: "Descarga", fr: "Téléchargement",
          de: "Download", it: "Download",
          pt: "Download")
    }

    static var modeLiveRecording: String {
        t("配信録画", "Live Recording",
          zhHant: "直播錄影", zhHans: "直播录制",
          ko: "라이브 녹화", ru: "Запись трансляции",
          es: "Grabación en vivo", fr: "Enregistrement live",
          de: "Live-Aufnahme", it: "Registrazione live",
          pt: "Gravação ao vivo")
    }

    static var startRecording: String {
        t("録画開始", "Start Recording",
          zhHant: "開始錄影", zhHans: "开始录制",
          ko: "녹화 시작", ru: "Начать запись",
          es: "Iniciar grabación", fr: "Démarrer l'enregistrement",
          de: "Aufnahme starten", it: "Avvia registrazione",
          pt: "Iniciar gravação")
    }

    static var quickRecording: String {
        t("クイック録画", "Quick Record",
          zhHant: "快速錄影", zhHans: "快速录制",
          ko: "빠른 녹화", ru: "Быстрая запись",
          es: "Grabación rápida", fr: "Enregistrement rapide",
          de: "Schnellaufnahme", it: "Registrazione rapida",
          pt: "Gravação rápida")
    }

    static var stopRecording: String {
        t("録画停止", "Stop Recording",
          zhHant: "停止錄影", zhHans: "停止录制",
          ko: "녹화 중지", ru: "Остановить запись",
          es: "Detener grabación", fr: "Arrêter l'enregistrement",
          de: "Aufnahme stoppen", it: "Ferma registrazione",
          pt: "Parar gravação")
    }

    static var statusRecording: String {
        t("録画中", "Recording",
          zhHant: "錄影中", zhHans: "录制中",
          ko: "녹화 중", ru: "Запись",
          es: "Grabando", fr: "Enregistrement",
          de: "Aufnahme läuft", it: "Registrazione",
          pt: "Gravando")
    }

    static var phaseLiveRecording: String {
        t("録画", "Recording",
          zhHant: "錄影", zhHans: "录制",
          ko: "녹화", ru: "Запись",
          es: "Grabación", fr: "Enregistrement",
          de: "Aufnahme", it: "Registrazione",
          pt: "Gravação")
    }

    static var liveFromStart: String {
        t("最初から録画", "Record from start",
          zhHant: "從頭錄影", zhHans: "从头录制",
          ko: "처음부터 녹화", ru: "Записать с начала",
          es: "Grabar desde el inicio", fr: "Enregistrer depuis le début",
          de: "Von Anfang an aufnehmen", it: "Registra dall'inizio",
          pt: "Gravar desde o início")
    }

    static var liveFromNow: String {
        t("今から録画", "Record from now",
          zhHant: "從現在錄影", zhHans: "从现在录制",
          ko: "지금부터 녹화", ru: "Записать с текущего момента",
          es: "Grabar desde ahora", fr: "Enregistrer à partir de maintenant",
          de: "Ab jetzt aufnehmen", it: "Registra da adesso",
          pt: "Gravar a partir de agora")
    }

    static var liveBadge: String {
        t("LIVE", "LIVE",
          zhHant: "直播", zhHans: "直播",
          ko: "라이브", ru: "LIVE",
          es: "EN VIVO", fr: "EN DIRECT",
          de: "LIVE", it: "LIVE",
          pt: "AO VIVO")
    }

    static var upcomingBadge: String {
        t("配信予定", "Upcoming",
          zhHant: "即將直播", zhHans: "即将直播",
          ko: "예정", ru: "Скоро",
          es: "Próximo", fr: "À venir",
          de: "Geplant", it: "In programma",
          pt: "Em breve")
    }

    static var recordingComplete: String {
        t("録画完了", "Recording Complete",
          zhHant: "錄影完成", zhHans: "录制完成",
          ko: "녹화 완료", ru: "Запись завершена",
          es: "Grabación completa", fr: "Enregistrement terminé",
          de: "Aufnahme abgeschlossen", it: "Registrazione completata",
          pt: "Gravação concluída")
    }

    static func recordingElapsed(_ time: String) -> String {
        t("経過 \(time)", "\(time) elapsed",
          zhHant: "已錄 \(time)", zhHans: "已录 \(time)",
          ko: "\(time) 경과", ru: "Прошло \(time)",
          es: "\(time) transcurrido", fr: "\(time) écoulé",
          de: "\(time) vergangen", it: "\(time) trascorso",
          pt: "\(time) decorrido")
    }

    static var enterLiveURLPlaceholder: String {
        t("配信URLを入力して録画を開始", "Enter a live stream URL to start recording",
          zhHant: "輸入直播 URL 以開始錄影", zhHans: "输入直播 URL 以开始录制",
          ko: "라이브 스트림 URL을 입력하여 녹화 시작", ru: "Введите URL трансляции для записи",
          es: "Introduce la URL del directo para grabar", fr: "Entrez l'URL du stream pour enregistrer",
          de: "Stream-URL eingeben, um aufzunehmen", it: "Inserisci l'URL dello stream per registrare",
          pt: "Insira o URL da transmissão para gravar")
    }

    static var liveStreamDetected: String {
        t("ライブ配信を検出しました", "Live stream detected",
          zhHant: "偵測到直播", zhHans: "检测到直播",
          ko: "라이브 스트림 감지됨", ru: "Обнаружена трансляция",
          es: "Transmisión en vivo detectada", fr: "Flux en direct détecté",
          de: "Livestream erkannt", it: "Stream live rilevato",
          pt: "Transmissão ao vivo detectada")
    }

    // MARK: - アプリアップデート

    static var checkForUpdates: String {
        t("アップデートを確認…", "Check for Updates…",
          zhHant: "檢查更新…", zhHans: "检查更新…",
          ko: "업데이트 확인…", ru: "Проверить обновления…",
          es: "Buscar actualizaciones…", fr: "Rechercher les mises à jour…",
          de: "Nach Updates suchen…", it: "Verifica aggiornamenti…",
          pt: "Verificar atualizações…")
    }

    static var appUpdateSection: String {
        t("アプリのアップデート", "App Updates",
          zhHant: "應用程式更新", zhHans: "应用更新",
          ko: "앱 업데이트", ru: "Обновление приложения",
          es: "Actualización de la app", fr: "Mise à jour de l'app",
          de: "App-Aktualisierung", it: "Aggiornamento app",
          pt: "Atualização do app")
    }

    static var appVersion: String {
        t("現在のバージョン", "Current Version",
          zhHant: "目前版本", zhHans: "当前版本",
          ko: "현재 버전", ru: "Текущая версия",
          es: "Versión actual", fr: "Version actuelle",
          de: "Aktuelle Version", it: "Versione attuale",
          pt: "Versão atual")
    }

    static var autoCheckUpdates: String {
        t("自動でアップデートを確認", "Automatically check for updates",
          zhHant: "自動檢查更新", zhHans: "自动检查更新",
          ko: "자동으로 업데이트 확인", ru: "Проверять автоматически",
          es: "Buscar actualizaciones automáticamente", fr: "Vérifier automatiquement les mises à jour",
          de: "Automatisch nach Updates suchen", it: "Verifica automaticamente gli aggiornamenti",
          pt: "Verificar atualizações automaticamente")
    }
}
