#!/usr/bin/env bash
# ==============================================================================
# AI Statement of Purpose (SOP) Generator - Installer for Linux & macOS
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}  🎓 AI Statement of Purpose (SOP) Generator Setup  ${NC}"
echo -e "${CYAN}====================================================${NC}\n"

# Helper function to ensure Git is installed
ensure_git_installed() {
    if command -v git >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] Found Git $(git --version)${NC}"
        return 0
    fi

    echo -e "${YELLOW}[!] Git is not installed. Attempting to install Git automatically...${NC}"

    OS_TYPE="$(uname -s)"

    if [ "$OS_TYPE" = "Darwin" ]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via Homebrew...${NC}"
            brew install git
        else
            echo -e "${BLUE}[*] Triggering Xcode Command Line Tools for Git...${NC}"
            xcode-select --install || true
            echo -e "${YELLOW}[!] Please complete the Xcode Command Line Tools installation and rerun this script.${NC}"
            exit 1
        fi
    elif [ "$OS_TYPE" = "Linux" ]; then
        # Linux package managers
        SUDO_CMD=""
        if [ "$(id -u)" -ne 0 ]; then
            if command -v sudo >/dev/null 2>&1; then
                SUDO_CMD="sudo"
            else
                echo -e "${RED}[Error] Root or sudo access is required to install Git.${NC}"
                exit 1
            fi
        fi

        if command -v apt-get >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via apt-get...${NC}"
            $SUDO_CMD apt-get update -y && $SUDO_CMD apt-get install -y git
        elif command -v dnf >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via dnf...${NC}"
            $SUDO_CMD dnf install -y git
        elif command -v yum >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via yum...${NC}"
            $SUDO_CMD yum install -y git
        elif command -v pacman >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via pacman...${NC}"
            $SUDO_CMD pacman -Sy --noconfirm git
        elif command -v apk >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via apk...${NC}"
            $SUDO_CMD apk add git
        elif command -v zypper >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing Git via zypper...${NC}"
            $SUDO_CMD zypper install -y git
        else
            echo -e "${RED}[Error] Could not identify package manager to install Git automatically.${NC}"
            echo -e "Please install Git manually (e.g. sudo apt install git / brew install git)."
            exit 1
        fi
    else
        echo -e "${RED}[Error] Unsupported operating system for automatic Git installation: $OS_TYPE${NC}"
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo -e "${RED}[Error] Failed to install Git automatically.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Successfully installed $(git --version)${NC}"
}

# 1. Locate Python 3
PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo -e "${RED}[Error] Python 3 is not installed.${NC}"
    echo -e "Please install Python 3.9 or newer and try again."
    exit 1
fi

# Check Python version (>= 3.9)
PY_VERSION=$($PYTHON_BIN -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$($PYTHON_BIN -c "import sys; print(sys.version_info.major)")
PY_MINOR=$($PYTHON_BIN -c "import sys; print(sys.version_info.minor)")

if [ "$PY_MAJOR" -lt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 9 ]); then
    echo -e "${RED}[Error] Python 3.9+ is required (found Python $PY_VERSION).${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] Found Python $PY_VERSION ($PYTHON_BIN)${NC}"

# 2. Check if inside repository or clone it
REPO_URL="https://github.com/intelQong/markitdown-sop-generator.git"
TARGET_DIR="markitdown-sop-generator"

if [ -f "src/sop_engine.py" ]; then
    PROJECT_DIR="$(pwd)"
elif [ -d "$TARGET_DIR" ] && [ -f "$TARGET_DIR/src/sop_engine.py" ]; then
    PROJECT_DIR="$(pwd)/$TARGET_DIR"
    cd "$PROJECT_DIR"
else
    ensure_git_installed
    echo -e "${BLUE}[*] Cloning repository from ${REPO_URL}...${NC}"
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
    PROJECT_DIR="$(pwd)"
fi

echo -e "${GREEN}[✓] Working directory: $PROJECT_DIR${NC}"

# 3. Create virtual environment
VENV_DIR="$PROJECT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${BLUE}[*] Creating Python virtual environment in .venv...${NC}"
    $PYTHON_BIN -m venv "$VENV_DIR" || {
        echo -e "${YELLOW}[!] Failed to create venv with $PYTHON_BIN -m venv.${NC}"
        echo -e "${YELLOW}[!] On Ubuntu/Debian, you may need: sudo apt install python3-venv${NC}"
        exit 1
    }
fi
echo -e "${GREEN}[✓] Virtual environment ready at .venv${NC}"

# 4. Activate virtual environment and install dependencies
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo -e "${BLUE}[*] Upgrading pip and installing required packages...${NC}"
pip install --upgrade pip --quiet
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --quiet
elif [ -f "src/requirements.txt" ]; then
    pip install -r src/requirements.txt --quiet
fi

# Optional editable install for CLI entrypoint
pip install -e . --quiet

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}  ✨ Installation Completed Successfully!          ${NC}"
echo -e "${GREEN}====================================================${NC}\n"

echo -e "To get started, activate the virtual environment:\n"
echo -e "  ${CYAN}cd $(pwd)${NC}"
echo -e "  ${CYAN}source .venv/bin/activate${NC}\n"
echo -e "Run the CLI engine:"
echo -e "  ${CYAN}sop-engine --help${NC}   (or: ${CYAN}python src/sop_engine.py --help${NC})\n"
echo -e "Ingest applicant files:"
echo -e "  ${CYAN}sop-engine --ingest \"path/to/applicant_folder\" --output-md \"applicant_context.md\"${NC}\n"
echo -e "Export SOP to Word (.docx):"
echo -e "  ${CYAN}sop-engine --export-docx \"final_sop.txt\" --docx-out \"SOP.docx\" --name \"Applicant Name\" --course \"Degree\" --country \"Country\"${NC}\n"
