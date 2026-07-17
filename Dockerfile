FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
# 与 base: "/blog/" 对齐，站点挂在 /blog/ 下
COPY docs/.vitepress/dist /usr/share/nginx/html/blog

EXPOSE 7777

CMD ["nginx", "-g", "daemon off;"]
