FROM node:12
WORKDIR /usr/src/app
COPY package.json .
COPY yarn.lock .
RUN yarn install
COPY . .
ARG ANOTATE_URL
ENV ANNOTATE_URL ANNOTATE_URL
ENV API_URL https://hypothes.is/api/
RUN yarn build