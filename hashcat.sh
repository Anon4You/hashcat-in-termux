#!/usr/bin/env bash

HASHCAT_DIR="$PREFIX/opt/hashcat"
GPU_HASHCAT="$HOME/.local/share/hashcat"

RED="$(printf '\033[1;31m')"
GREEN="$(printf '\033[1;32m')"
BLUE="$(printf '\033[0;34m')"
NC="$(printf '\033[0m')"
YELLOW="$(printf '\033[33;1m')"

BANNER(){
  clear
  cat <<- EOF 

   ${YELLOW}      8   8    db    .d88b. 8   8 .d88b    db    88888
   ${BLUE}      8www8   dPYb   YPwww. 8www8 8P      dPYb     8
   ${RED}      8   8  dPwwYb      d8 8   8 8b     dPwwYb    8
   ${GREEN}      8   8 dP    Yb \`Y88P' 8   8 \`Y88P dP    Yb   8
 ${NC}
EOF
  echo -e "${GREEN}   Hashcat installer script for termux!! | Alienkrishn [Anon4You]${NC}"
  echo
}


SETUP_TERMUX(){
  [ -d "$HASHCAT_DIR" ] && { rm -rf "$HASHCAT_DIR";}

  [ -d "$GPU_HASHCAT" ] && { rm -rf "$GPU_HASHCAT";}
  mkdir -p $PREFIX/opt
  mkdir -p $GPU_HASHCAT
}

DOWNLOAD_EXTRACT(){
  wget --show-progress -q --progress=bar:force:noscroll -O "$TMPDIR/hashcat-7.1.2.zip" \
https://github.com/hashcat/hashcat/archive/refs/tags/v7.1.2.zip
  
  unzip -q "$TMPDIR/hashcat-7.1.2.zip" -d "$TMPDIR" || print_error "Extraction failed"
mv "$TMPDIR/hashcat-7.1.2" "$HASHCAT_DIR"
}

INSTALL_DEPS() {
    echo "Installing dependencies..."
    
    apt update -y
    
    apt install -y \
        libc++ \
        libiconv \
        opencl-vendor-driver \
        wget \
        unzip \
        rust \
        python \
        perl
    
    echo "All dependencies installed successfully!"
}

APPLY_PATCH(){
  cd $HASHCAT_DIR
  line=$(grep -n "\$(LDFLAGS)" src/Makefile | awk -F ":" '{print $1}')
[ -n "$line" ] && {
    let ln=$line-1
    sed -i "${ln}a LDFLAGS += -liconv" src/Makefile || echo "Failed to modify src/Makefile"
    echo "Updated LDFLAGS with -liconv"
} || echo "Could not find LDFLAGS in src/Makefile"

line=$(grep -n "affinity.h" src/affinity.c | awk -F ":" '{print $1}' | head -n 1)
[ -n "$line" ] && {
    let ln=$line+1
    sed -i "${ln}a#ifdef __ANDROID__\nint pthread_setaffinity_np(pthread_t thread, size_t cpusetsize, const cpu_set_t *cpuset) {\n    return 0;\n}\n#endif" src/affinity.c || echo "Failed to modify src/affinity.c"
    echo "Added stub for pthread_setaffinity_np"
} || echo "Could not find affinity.h in src/affinity.c"

}

BANNER
SETUP_TERMUX
INSTALL_DEPS
DOWNLOAD_EXTRACT
APPLY_PATCH

cd $HASHCAT_DIR
make -j$(nproc --all) 
ln -srf "$HASHCAT_DIR/hashcat" "$PREFIX/bin/"

echo -e "${GREEN}Hashcat installation process completed!${NC}"
if [ -f "$PREFIX/bin/hashcat" ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo "  hashcat -b                    # Benchmark"
    echo "  hashcat -m 0 hash.txt wordlist.txt  # MD5 cracking"
    echo "  hashcat -I                    # List OpenCL devices"
fi

