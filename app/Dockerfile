FROM node:15 as builder
LABEL ceros-devops-code-challenge-main.com=frontend

WORKDIR /usr/src/app

COPY . .

RUN npm ci --only-production && npm run build


# Multistage build
FROM node:17-alpine3.14
LABEL ceros-devops-code-challenhe-main.com=frontend

ARG USER=appuser

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app ./

# Start with rootless user
USER $USER

ENTRYPOINT ["npm", "start"]

# Conntainer port
EXPOSE 8080
