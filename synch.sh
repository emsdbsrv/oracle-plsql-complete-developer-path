cd /c/EMS/Terraform/oracle-plsql-complete-developer-path || exit
git add .
git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main --force
