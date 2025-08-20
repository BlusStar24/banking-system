# FROM bonita:2024.3
# COPY init/ /opt/bonita/init/
# COPY server/conf/database.properties /opt/bonita/conf/database.properties
# RUN chmod +x /opt/bonita/init/import-all.sh
FROM bonita:2024.3-u0

# Tạo thư mục chứa file import nếu cần
COPY init /opt/bonita/init
