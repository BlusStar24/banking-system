#!/bin/sh

echo "⏳ Kiểm tra file /init/import-all.sh..."
ls -l /init
echo "✅ Kiểm tra xong!"

chmod +x ./bonita/init/check-and-run.sh
chmod +x ./bonita/init/import-all.sh
# Chạy script import-all.sh
/bin/sh /init/import-all.sh
