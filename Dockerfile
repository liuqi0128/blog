FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docs/.vitepress/dist /usr/share/nginx/html

EXPOSE 7777

CMD ["nginx", "-g", "daemon off;"]
