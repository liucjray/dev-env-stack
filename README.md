# Dev Env Stack

一組給 Windows + WSL 使用的開發環境設定，包含 WezTerm、Starship、bash helper 和 tmux。

這個專案已經整理成 GNU Stow 結構，可以很快套到新機器上。

## 內容

- `stow/windows/.wezterm.lua`：Windows 版 WezTerm 設定
- `stow/wsl/.config/starship.toml`：WSL bash 的 Starship 設定
- `stow/wsl/.bashrc.d/dev-env-stack.sh`：bash helper
- `stow/wsl/.tmux.conf`：tmux 設定
- `install.sh`：一鍵安裝腳本
- `Makefile`：常用指令

## 對應位置

- WezTerm -> `C:\Users\<你>\.wezterm.lua`
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
