# Dev Env Stack

一組跨平台的開發環境設定，包含 WezTerm、Starship、bash helper、tmux，以及 Claude Code / Antigravity CLI statusline。

這個專案已經整理成 GNU Stow 結構，可以很快套到新機器上。

## 內容

- `stow/windows/.wezterm.lua`：Windows 版 WezTerm 設定
- `stow/macos/.wezterm.lua`：macOS 版 WezTerm 設定
- `stow/macos/.config/starship.toml`：macOS 的 Starship 設定
- `stow/macos/.claude/statusline.sh`：Claude Code statusline script（macOS）
- `stow/macos/.gemini/antigravity-cli/statusline.sh`：Antigravity CLI statusline script（macOS）
- `stow/wsl/.config/starship.toml`：WSL bash 的 Starship 設定
- `stow/wsl/.bashrc.d/dev-env-stack.sh`：bash helper
- `stow/wsl/.tmux.conf`：tmux 設定
- `stow/wsl/.gemini/antigravity-cli/statusline.sh`：Antigravity CLI statusline script（WSL）
- `stow/linux/.gemini/antigravity-cli/statusline.sh`：Antigravity CLI statusline script（Linux）
- `install.sh`：一鍵安裝腳本
- `Makefile`：常用指令

## 對應位置

- WezTerm (Windows) -> `C:\Users\<你>\.wezterm.lua`
- WezTerm (macOS) -> `~/.wezterm.lua`
- Claude Code statusline -> `~/.claude/statusline.sh`
- Antigravity CLI statusline -> `~/.gemini/antigravity-cli/statusline.sh`
- Starship -> `~/.config/starship.toml`
- bash helper -> `~/.bashrc.d/dev-env-stack.sh`
- tmux -> `~/.tmux.conf`

## 安裝

先在 WSL 安裝 `stow`：

```bash
sudo apt update
sudo apt install stow
```

然後執行：

```bash
./install.sh
```

或使用 `make`：

```bash
make install
make check
make preview
```

注意：

- Windows 與 WSL 端設定皆使用 GNU Stow 建立連結
- macOS 安裝後需在 `~/.zshrc` 加入：`eval "$(starship init zsh)"`

## 使用

bash helper 需要在 `~/.bashrc` 裡加一行：

```bash
source ~/.bashrc.d/dev-env-stack.sh
```

## 功能

- WezTerm 預設進入 WSL
- tab 顯示目前資料夾名稱
- 類 tmux 的 `Ctrl+b` 操作
- 右鍵可複製或貼上（有選取時複製，否則貼上）
- `Ctrl+C` 有選取時複製，無選取時照常送 SIGINT
- `Ctrl+V` 貼上
- `Ctrl + 滾輪` 可調字體
- Starship 顯示路徑、分支和時間
- Claude Code statusline 顯示模型、context 用量、費用、rate limit、cache 命中率等
- Antigravity CLI statusline 顯示代理狀態、模型、分支/變更、沙盒、context 進度條、各項計數與 quota 倒數

## Claude Code Statusline

`~/.claude/statusline.sh` 是一個三行式 statusline，安裝後需在 `~/.claude/settings.json` 加入：

```json
"statusLine": {
  "type": "command",
  "command": "/Users/<你>/.claude/statusline.sh"
}
```

注意：路徑需使用絕對路徑，`~` 在 settings.json 中不會被展開。

顯示內容：
- **Line 1**：模型名稱、context 大小、版本、repo/目錄、git branch、行數變化、git 狀態、agent 名稱、vim 模式
- **Line 2**：context 使用量進度條、費用、執行時間、rate limit（5h/7d）
- **Line 3**：cache 命中率、累計 token 數、API 等待時間、當前 token 細節

## Antigravity CLI Statusline

`~/.gemini/antigravity-cli/statusline.sh` 是專為 Google Antigravity CLI（`agy`）設計的 statusline。
安裝後需在 `~/.gemini/antigravity-cli/settings.json`（或 `~/.gemini/settings.json`）加入：

```json
"statusLine": {
  "type": "command",
  "command": "<絕對路徑>/.gemini/antigravity-cli/statusline.sh",
  "enabled": true
}
```

注意：
- 路徑需使用絕對路徑（例如 `/Users/<你>/.gemini/...` 或 `/home/<你>/.gemini/...`）。
- Antigravity CLI 具備安全防護機制，自訂 statusline 需在 `~/.gemini/trusted_hooks.json` 註冊信任（`install.sh` 已自動處理註冊）。

顯示內容：
- **狀態（Agent State）**：`READY` / `THINKING` / `WORKING` / `TOOL`
- **模型與分支**：目前模型名稱、Git 分支名稱（有 dirty 變更標記紅色 `*`）
- **沙盒與脈絡**：Sandbox ON/OFF、Context Window ASCII 進度條與百分比（依用量分段變色）
- **計數指標**：Artifacts 數量、Subagents 數、Background Tasks 數
- **API 額度（Quota）**：各 Quota Bucket 剩餘額度百分比與重置倒數計時（例如 `95% ↻ 2h`）
- **自適應排版**：終端機寬度 $\ge$ 120 欄為單行模式；80 ~ 120 欄為雙行方框模式；$<$ 80 欄為緊湊模式

