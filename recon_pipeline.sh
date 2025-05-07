# Target domain
DOMAIN=$1

# Output directories
OUTDIR="output/$DOMAIN"
mkdir -p "$OUTDIR"

echo "[*] Starting recon pipeline for $DOMAIN"
echo "[*] Output directory: $OUTDIR"

# 1. Subdomain enumeration
echo "[+] Running subfinder..."
subfinder -d "$DOMAIN" -silent -o "$OUTDIR/subdomains.txt"

# 2. DNS resolution
echo "[+] Resolving subdomains with dnsx..."
dnsx -l "$OUTDIR/subdomains.txt" -silent -o "$OUTDIR/resolved.txt"

# 3. Probing alive hosts
echo "[+] Probing alive hosts with httpx..."
httpx -l "$OUTDIR/resolved.txt" -silent -o "$OUTDIR/alive.txt"

# 4. Crawling with Katana
echo "[+] Crawling with Katana..."
katana -list "$OUTDIR/alive.txt" -silent -o "$OUTDIR/katana_urls.txt"

# 5. Archive data: gau + waybackurls
echo "[+] Fetching URLs from gau and waybackurls..."
gau "$DOMAIN" >> "$OUTDIR/archive_urls.txt"
waybackurls "$DOMAIN" >> "$OUTDIR/archive_urls.txt"

# 6. Combine all URLs
echo "[+] Consolidating and deduplicating URLs..."
cat "$OUTDIR/katana_urls.txt" "$OUTDIR/archive_urls.txt" | sort -u > "$OUTDIR/all_urls.txt"

# 7. Vulnerability scanning with Nuclei
echo "[+] Scanning with Nuclei..."
nuclei -l "$OUTDIR/alive.txt" -silent -o "$OUTDIR/nuclei_results.txt"

# Done
echo "[*] Recon pipeline completed!"
echo "[*] Alive hosts: $OUTDIR/alive.txt"
echo "[*] Discovered URLs: $OUTDIR/all_urls.txt"
echo "[*] Nuclei results: $OUTDIR/nuclei_results.txt"
