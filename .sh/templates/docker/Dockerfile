# default version if empty 
ARG DIRECTUS_VERSION=11.12.0

FROM directus/directus:${DIRECTUS_VERSION}

USER root
RUN npm install -g pnpm@10.11.0 --force

USER node
RUN pnpm install @directus-labs/seo-plugin
