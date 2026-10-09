#!/usr/bin/env bash
# ==============================================
#  Dotfiles installer - Arch Linux + i3 setup
#  Idempotente: comprueba qué falta e instala solo eso
#  (o todo, si no hay nada), despliega los dotfiles y
#  deja habilitados los servicios para que la interfaz
#  gráfica arranque en cada reboot.
# ==============================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

STOW_PACKAGES=(i3 kitty polybar rofi picom dunst starship gtk bash wallpapers)

# Servicios de sistema a habilitar (se omiten los que no existan en el sistema).
SYSTEM_SERVICES=(NetworkManager.service lightdm.service docker.service snapper-timeline.timer)
# Servicios solo relevantes dentro de una VM VMware.
VM_SERVICES=(vmtoolsd.service)
# Servicios de usuario (audio).
USER_SERVICES=(pipewire.socket pipewire-pulse.socket wireplumber.service)

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m==>\033[0m %s\n' "$1"; }

# Instala una lista con pacman de forma TOLERANTE: intenta el lote y, si falla
# (un paquete inexistente o en conflicto aborta toda la transacción), reintenta
# uno por uno para que un solo paquete malo no impida instalar el resto.
pacman_install() {
    (( $# == 0 )) && return 0
    if sudo pacman -Syu --needed --noconfirm "$@"; then
        return 0
    fi
    warn "El lote de pacman falló (algún paquete problemático). Reintento uno por uno..."
    local p
    for p in "$@"; do
        sudo pacman -S --needed --noconfirm "$p" || warn "pacman: falló '$p', se omite."
    done
}

# Igual pero con paru (AUR).
paru_install() {
    (( $# == 0 )) && return 0
    if paru -S --needed --noconfirm "$@"; then
        return 0
    fi
    warn "El lote de paru (AUR) falló. Reintento uno por uno..."
    local p
    for p in "$@"; do
        paru -S --needed --noconfirm "$p" || warn "paru: falló '$p', se omite."
    done
}

# --- 0. Comprobaciones previas ---
if [[ $EUID -eq 0 ]]; then
    warn "No ejecutes este script como root. Lánzalo con tu usuario; pedirá sudo cuando haga falta."
    exit 1
fi

info "Refrescando base de datos de pacman y asegurando herramientas base..."
sudo pacman -Sy --needed --noconfirm git base-devel stow >/dev/null

# --- 1. Paquetes oficiales (pacman) ---
if [[ -f pkglist.txt ]]; then
    mapfile -t want < <(grep -vE '^\s*(#|$)' pkglist.txt)
    missing=()
    for p in "${want[@]}"; do
        pacman -Qq "$p" &>/dev/null || missing+=("$p")
    done
    if (( ${#missing[@]} == 0 )); then
        ok "Paquetes oficiales: ya están los ${#want[@]}."
    else
        info "Paquetes oficiales: faltan ${#missing[@]} de ${#want[@]}, instalando..."
        pacman_install "${missing[@]}"
    fi
else
    warn "pkglist.txt no encontrado, salto paquetes oficiales."
fi

# --- 2. paru (AUR helper) si falta ---
if ! command -v paru &>/dev/null; then
    info "Instalando paru (AUR helper)..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
else
    ok "paru ya instalado."
fi

# --- 3. Paquetes AUR (paru) ---
if [[ -f aur-pkglist.txt ]]; then
    mapfile -t awant < <(grep -vE '^\s*(#|$)' aur-pkglist.txt)
    amissing=()
    for p in "${awant[@]}"; do
        pacman -Qq "$p" &>/dev/null || amissing+=("$p")
    done
    if (( ${#amissing[@]} == 0 )); then
        ok "Paquetes AUR: ya están los ${#awant[@]}."
    else
        info "Paquetes AUR: faltan ${#amissing[@]} de ${#awant[@]}, instalando..."
        paru_install "${amissing[@]}"
    fi
else
    warn "aur-pkglist.txt no encontrado, salto paquetes AUR."
fi

# --- 4. Herramientas Python (pipx) ---
if [[ -f pipx-pkglist.txt ]]; then
    sudo pacman -S --needed --noconfirm python-pipx rust >/dev/null
    installed_pipx="$(pipx list --short 2>/dev/null | awk '{print $1}')"
    while IFS= read -r tool; do
        [[ -z "$tool" || "$tool" == \#* ]] && continue
        if grep -qxF "$tool" <<<"$installed_pipx"; then
            ok "pipx: $tool ya instalado."
        else
            info "pipx: instalando $tool..."
            pipx install "$tool" || warn "pipx falló con $tool"
        fi
    done < pipx-pkglist.txt
    pipx ensurepath >/dev/null 2>&1 || true
else
    warn "pipx-pkglist.txt no encontrado, salto herramientas pipx."
fi

# --- 5. Desplegar dotfiles con stow (idempotente) ---
info "Desplegando dotfiles con stow..."
for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ ! -d "$pkg" ]]; then
        warn "Paquete stow '$pkg' no encontrado, se omite."
        continue
    fi
    # Respaldar archivos reales (no symlinks) que estorben antes de enlazar.
    while IFS= read -r -d '' file; do
        rel="${file#"$pkg"/}"
        target="$HOME/$rel"
        if [[ -e "$target" && ! -L "$target" ]]; then
            warn "Respaldo $target -> $target.bak"
            mv "$target" "$target.bak"
        fi
    done < <(find "$pkg" -type f -print0)
    stow -R -v "$pkg"   # -R (restow) = re-ejecutable sin romper nada
    ok "Stow: $pkg"
done

# --- 6. Habilitar servicios ---
enable_system_service() {
    local unit="$1"
    if systemctl cat "$unit" &>/dev/null; then
        sudo systemctl enable --now "$unit" >/dev/null 2>&1 \
            && ok "Servicio activo: $unit" \
            || warn "No se pudo habilitar $unit (revísalo a mano)."
    else
        warn "$unit no está disponible en el sistema, se omite."
    fi
}

enable_user_service() {
    local unit="$1"
    if systemctl --user cat "$unit" &>/dev/null; then
        systemctl --user enable --now "$unit" >/dev/null 2>&1 \
            && ok "Servicio de usuario activo: $unit" \
            || warn "No se pudo habilitar (usuario) $unit."
    fi
}

info "Habilitando servicios del sistema..."
for s in "${SYSTEM_SERVICES[@]}"; do enable_system_service "$s"; done

# vmtoolsd solo tiene sentido dentro de VMware.
if [[ "$(systemd-detect-virt 2>/dev/null || echo none)" == "vmware" ]]; then
    info "VM VMware detectada: habilitando integración..."
    for s in "${VM_SERVICES[@]}"; do enable_system_service "$s"; done
fi

info "Habilitando servicios de usuario (audio)..."
for s in "${USER_SERVICES[@]}"; do enable_user_service "$s"; done

# Asegurar que el arranque va a modo gráfico (login manager) en cada reboot.
info "Fijando graphical.target como objetivo de arranque por defecto..."
sudo systemctl set-default graphical.target >/dev/null

# --- 7. Verificación del stack gráfico ---
gui_missing=()
for p in lightdm xorg-server i3-wm; do
    pacman -Qq "$p" &>/dev/null || gui_missing+=("$p")
done
if (( ${#gui_missing[@]} > 0 )); then
    err "ATENCIÓN: faltan paquetes críticos para la GUI: ${gui_missing[*]}"
    err "Instálalos a mano y reintenta:  sudo pacman -S --needed ${gui_missing[*]}"
    err "La interfaz gráfica NO arrancará hasta instalarlos."
fi
if [[ "$(systemd-detect-virt 2>/dev/null || echo none)" == "none" ]]; then
    warn "Hardware real detectado (no VM): si la GUI no arranca puede faltar el driver de vídeo."
    warn "  AMD: sudo pacman -S --needed mesa xf86-video-amdgpu vulkan-radeon"
    warn "  Intel: sudo pacman -S --needed mesa vulkan-intel"
    warn "  NVIDIA: sudo pacman -S --needed nvidia nvidia-utils"
fi

# --- 8. Fin ---
ok "Listo."
echo ""
echo "  La interfaz gráfica (lightdm) debería arrancar ya y en cada reboot."
echo "  Si sigues en consola: 'sudo systemctl start lightdm' o reinicia."
echo "  Notas:"
echo "  - Recarga i3 con Super+Shift+R si ya estás dentro."
echo "  - Abre una terminal nueva para que el PATH de pipx tenga efecto."
echo "  - Wallpapers en ~/.config/wallpapers/ (usados por la config de i3)."
echo ""
