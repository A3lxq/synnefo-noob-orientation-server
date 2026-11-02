# Tools you'll use in this box

| Tool | What it's for here |
|---|---|
| `nmap` | Discover which ports/services are open (22, 21, 80). |
| Browser / `curl` | View page source, fetch files, read `robots.txt`. |
| `ftp` / `lftp` | Connect to anonymous FTP and list/download files. |
| `base64` (CLI) or CyberChef | Decode a base64 blob back to text. |
| CyberChef / `tr` / Python `codecs` | Decode a ROT13 (Caesar shift-13) cipher. |
| `fcrackzip` or `zip2john` + `john` | Brute-force a small numeric zip password. |
| `hashcat` or `john` + a wordlist (e.g. `rockyou.txt`) | Crack an MD5 hash of a weak, common password. |
| `openssl` | Decrypt an AES-256-CBC file once you have the key (the cracked password). |
| `ssh` | Log in once you have valid credentials. |
| `ls -la`, `find . -name ".*"` | Spot hidden dotfiles that `ls` alone won't show. |
| `sudo -l` + GTFOBins (gtfobins.github.io) | Find and abuse a sudo misconfiguration to escalate. |

None of these tools need to be run against anything other than this one
container's published ports.
