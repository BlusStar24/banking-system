FROM nginx:alpine

# Nhận đối số để chọn folder (customer/staff)
ARG BUILD_DIR=customer

# Copy đúng thư mục con vào nginx
COPY ${BUILD_DIR} /usr/share/nginx/html

EXPOSE 80
