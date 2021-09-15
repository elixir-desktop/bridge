require Bridge
Bridge.generate_bridge_calls(:wxLocale, [:getSystemLanguage, :getCanonicalName])
Bridge.generate_bridge_calls(:wxMenuItem, [:getId, :check])
Bridge.generate_bridge_calls(:wxMenu, [:appendSeparator, :append, :enable])

Bridge.generate_bridge_calls(:wxMenuBar, [
  :remove,
  :append,
  :replace,
  :getMenuCount,
  :oSXGetAppleMenu
])

Bridge.generate_bridge_calls(:wxWebView, [
  :isBackendAvailable,
  :enableContextMenu,
  :isContextMenuEnabled,
  :isShownOnScreen,
  :loadURL
])

Bridge.generate_bridge_calls(:wxHtmlWindow, [:setPage])
Bridge.generate_bridge_calls(:wxTaskBarIcon, [:removeIcon, :setIcon, :popupMenu])

Bridge.generate_bridge_calls(:wxNotificationMessage, [
  :useTaskBarIcon,
  :setTitle,
  :setMessage,
  :show
])

Bridge.generate_bridge_calls(:wx, [:set_env, :get_env, :subscribe_events, :getObjectType, :batch])

Bridge.generate_bridge_calls(:wxFrame, [
  :raise,
  :getSizer,
  :setSizer,
  :clear,
  :refresh,
  :centerOnScreen,
  :show,
  :isShown,
  :iconize,
  :isIconized,
  :setIcon,
  :setMenuBar,
  :hide,
  :setTitle
])

Bridge.generate_bridge_calls(:wxWindow, [
  :raise,
  :getSizer,
  :setSizer,
  :clear,
  :refresh,
  :centerOnScreen,
  :show,
  :isShown,
  :iconize,
  :isIconized,
  :setFocus,
  :setIcon,
  :setMenuBar,
  :hide,
  :setTitle
])

Bridge.generate_bridge_calls(:wxTopLevelWindow, [
  :raise,
  :getSizer,
  :setSizer,
  :clear,
  :refresh,
  :centerOnScreen,
  :show,
  :isShown,
  :iconize,
  :isIconized,
  :setFocus,
  :setIcon,
  :setMenuBar,
  :hide,
  :setTitle
])

Bridge.generate_bridge_calls(:wxIcon, [:copyFromBitmap])
Bridge.generate_bridge_calls(:wxImage, [])
Bridge.generate_bridge_calls(:wxBitmap, [])

Bridge.generate_bridge_calls(:wxButton, [
  :show,
  :setLabel,
  :setFocus,
  :setDefault,
  :isEnabled,
  :hide,
  :enable,
  :disable
])

Bridge.generate_bridge_calls(:wxBoxSizer, [
  :layout,
  :show,
  :hide,
  :clear,
  :add,
  :fit,
  :setMinSize,
  :setSizeHints
])

Bridge.generate_bridge_calls(:wxSizer, [
  :layout,
  :show,
  :hide,
  :clear,
  :add,
  :fit,
  :setMinSize,
  :setSizeHints
])

Bridge.generate_bridge_calls(:wxSizerItem, [:setBorder, :getBorder])
Bridge.generate_bridge_calls(:wxSizerFlags, [:proportion, :expand, :border])
Bridge.generate_bridge_calls(:wxMessageDialog, [])
Bridge.generate_bridge_calls(:wxGauge, [:pulse, :setValue])
Bridge.generate_bridge_calls(:wxFileDialog, [:getReturnCode, :getPath])
Bridge.generate_bridge_calls(:wxDirDialog, [:getReturnCode, :getPath])

Bridge.generate_bridge_calls(:wxDialog, [
  :showModal,
  :setSizer,
  :setAutoLayout,
  :setAffirmativeId,
  :centre
])

Bridge.generate_bridge_calls(:wx_misc, [:launchDefaultBrowser, :getOsDescription])
Bridge.generate_bridge_calls(:wxImage, [:getAlpha, :getData, :replace, :setAlpha, :setData])

Bridge.generate_bridge_calls(:wxStaticText, [:show, :setLabel, :getLabel, :setForegroundColour, :hide])
Bridge.generate_bridge_calls(:wxTextCtrl, [:setValue, :getValue, :enable])
Bridge.generate_bridge_calls(:wxStdDialogButtonSizer, [:realize, :addButton])
Bridge.generate_bridge_calls(:wxCloseEvent, [:canVeto, :veto])
