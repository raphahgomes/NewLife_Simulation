extends Node

## AdManager — Monetização (AdMob + Google Play Billing)
##
## SETUP NECESSÁRIO (Android — faça antes de exportar):
##
##  1. Plugin AdMob (Godot 4):
##     https://github.com/Shin-NiL/godot-admob-android/releases
##     → Extraia os arquivos para android/plugins/
##
##  2. Plugin Google Play Billing:
##     https://github.com/godotengine/godot-google-play-billing/releases
##     → Extraia os arquivos para android/plugins/
##
##  3. No AdMob Console (https://admob.google.com):
##     → Crie uma unidade de Banner e atualize BANNER_UNIT_ID abaixo
##     → (REWARDED_UNIT_ID já está configurado)
##
##  4. No Google Play Console:
##     → Crie um produto in-app com ID "premium_no_ads"

# ── IDs de Produção ──────────────────────────────────────────
const ADMOB_APP_ID     := "ca-app-pub-1511076292042912~8991791555"
const BANNER_UNIT_ID   := "ca-app-pub-1511076292042912/4138443797"
const REWARDED_UNIT_ID := "ca-app-pub-1511076292042912/6581250639"
const PREMIUM_SKU      := "premium_no_ads"  # ID do produto no Google Play Console

# ── IDs de Teste do AdMob (usados automaticamente em debug builds) ──
const _TEST_BANNER_ID   := "ca-app-pub-3940256099942544/6300978111"
const _TEST_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"

const _PREMIUM_SAVE_KEY := "has_premium"

# ── Estado ───────────────────────────────────────────────────
var has_premium    := false
var _admob                   # Singleton AdMob (Android)
var _billing                 # Singleton GodotGooglePlayBilling (Android)
var _admob_ready   := false
var _billing_ready := false
var _reward_type   := ""
var _reward_earned := false

# ── Sinais ───────────────────────────────────────────────────
signal ad_loaded
signal ad_failed
signal rewarded_ad_completed(reward_type: String)
signal rewarded_ad_closed
signal premium_purchased
signal premium_purchase_failed(reason: String)


# ════════════════════════════════════════════════════════════
func _ready() -> void:
	_load_premium_status()

	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD":
			# Build PC (Steam/Epic no futuro) → sempre sem anúncios
			has_premium = true
		"Android":
			_init_admob()
			_init_billing()


# ── Premium ─────────────────────────────────────────────────

func _load_premium_status() -> void:
	has_premium = SaveManager.load_setting(_PREMIUM_SAVE_KEY, false)

func _grant_premium() -> void:
	has_premium = true
	SaveManager.save_setting(_PREMIUM_SAVE_KEY, true)
	hide_banner()
	premium_purchased.emit()

func buy_premium() -> void:
	if has_premium:
		premium_purchased.emit()
		return

	if _billing_ready and _billing != null:
		_billing.purchase(PREMIUM_SKU)
	elif OS.get_name() != "Android":
		# Editor/PC: simula compra imediatamente
		_grant_premium()
	else:
		premium_purchase_failed.emit("Plugin de compras não disponível.")


# ── AdMob ────────────────────────────────────────────────────

func _init_admob() -> void:
	if not Engine.has_singleton("AdMob"):
		push_warning("AdManager: Plugin AdMob não encontrado. Anúncios desativados.")
		return

	_admob = Engine.get_singleton("AdMob")
	_admob.initialization_completed.connect(_on_admob_initialized)
	_admob.banner_loaded.connect(_on_banner_loaded)
	_admob.banner_failed_to_load.connect(_on_banner_failed)
	_admob.rewarded_loaded.connect(_on_rewarded_loaded)
	_admob.rewarded_failed_to_load.connect(_on_rewarded_failed)
	_admob.rewarded_earned_reward.connect(_on_rewarded_earned)
	_admob.rewarded_closed.connect(_on_rewarded_closed)

	var is_real: bool = not OS.is_debug_build()
	_admob.initialize(is_real, ADMOB_APP_ID)

func _on_admob_initialized(_status: Dictionary) -> void:
	_admob_ready = true
	if not has_premium:
		_load_banner()

func _load_banner() -> void:
	if _admob == null or not _admob_ready or has_premium:
		return
	var unit := _TEST_BANNER_ID if OS.is_debug_build() else BANNER_UNIT_ID
	_admob.load_banner(unit, true, 0)  # true = topo, 0 = tamanho BANNER padrão

func _on_banner_loaded() -> void:
	_admob.show_banner()
	ad_loaded.emit()

func _on_banner_failed(error_code: int) -> void:
	push_warning("AdManager: Banner falhou (código %d)" % error_code)
	ad_failed.emit()

func show_banner() -> void:
	if has_premium or _admob == null:
		return
	if _admob_ready:
		_load_banner()

func hide_banner() -> void:
	if _admob != null and _admob_ready:
		_admob.hide_banner()

func show_rewarded_ad(reward_type: String) -> void:
	if has_premium:
		await get_tree().create_timer(0.1).timeout
		rewarded_ad_completed.emit(reward_type)
		return

	_reward_type = reward_type
	_reward_earned = false

	if _admob != null and _admob_ready:
		var unit := _TEST_REWARDED_ID if OS.is_debug_build() else REWARDED_UNIT_ID
		_admob.load_rewarded(unit)
	else:
		# Stub para editor/PC (sem plugin)
		await get_tree().create_timer(1.0).timeout
		rewarded_ad_completed.emit(reward_type)
		_reward_type = ""

func _on_rewarded_loaded() -> void:
	_admob.show_rewarded()

func _on_rewarded_failed(error_code: int) -> void:
	push_warning("AdManager: Rewarded falhou (código %d)" % error_code)
	ad_failed.emit()
	_reward_type = ""
	_reward_earned = false

func _on_rewarded_earned(_type: String, _amount: int) -> void:
	_reward_earned = true

func _on_rewarded_closed() -> void:
	if _reward_earned:
		rewarded_ad_completed.emit(_reward_type)
		_reward_earned = false
	else:
		rewarded_ad_closed.emit()
	_reward_type = ""


# ── Google Play Billing ──────────────────────────────────────

func _init_billing() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		push_warning("AdManager: Plugin GodotGooglePlayBilling não encontrado. Compras desativadas.")
		return

	_billing = Engine.get_singleton("GodotGooglePlayBilling")
	_billing.connected.connect(_on_billing_connected)
	_billing.disconnected.connect(_on_billing_disconnected)
	_billing.connect_error.connect(_on_billing_connect_error)
	_billing.purchases_updated.connect(_on_purchases_updated)
	_billing.purchase_error.connect(_on_purchase_error)
	_billing.sku_details_query_completed.connect(_on_sku_details_ready)
	_billing.purchase_acknowledged.connect(_on_purchase_acknowledged)
	_billing.startConnection()

func _on_billing_connected() -> void:
	_billing_ready = true
	# Restaurar compras existentes (ex.: reinstalação do app)
	_billing.queryPurchases("inapp")
	_billing.querySkuDetails([PREMIUM_SKU], "inapp")

func _on_billing_disconnected() -> void:
	_billing_ready = false

func _on_billing_connect_error(code: int, message: String) -> void:
	push_warning("AdManager: Billing erro de conexão %d: %s" % [code, message])

func _on_sku_details_ready(_sku_details: Array) -> void:
	pass  # Pode usar sku_details[0]["price"] para exibir preço dinâmico no botão

func _on_purchases_updated(purchases: Array) -> void:
	for purchase in purchases:
		var sku: String = purchase.get("productId", "")
		var state: int  = purchase.get("purchaseState", -1)
		if sku == PREMIUM_SKU and state == 1:  # 1 = PURCHASED
			var token: String = purchase.get("purchaseToken", "")
			if not purchase.get("isAcknowledged", false) and token != "":
				_billing.acknowledgePurchase(token)
			else:
				_grant_premium()

func _on_purchase_acknowledged(_token: String) -> void:
	_grant_premium()

func _on_purchase_error(code: int, message: String) -> void:
	push_warning("AdManager: Erro na compra %d: %s" % [code, message])
	premium_purchase_failed.emit(message)
