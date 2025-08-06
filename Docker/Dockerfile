# Use a specific version of Grafana OSS as the base image for reproducibility
FROM grafana/grafana:12.0.1

# Label the image for better tracking and metadata
LABEL maintainer="Hoouin Kyouma" \
      description="Customized Grafana image for Business Suite" \
      version="12.0.1"

ARG development=false
ARG TARGETARCH

ARG GO_VERSION=1.24.4
ARG GO_ARCH=amd64

# Switch to root user for system-level operations
USER root

##################################################################
# CONFIGURATION - Environment Variables for Grafana
##################################################################
ENV GF_ENABLE_GZIP=true \
    GF_USERS_DEFAULT_THEME=dark \
    GF_PANELS_DISABLE_SANITIZE_HTML=false \
    GF_ANALYTICS_CHECK_FOR_UPDATES=false \
    GF_NEWS_NEWS_FEED_ENABLED=false \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_PATHS_PLUGINS=/var/lib/grafana/plugins

ENV GF_DEFAULT_APP_MODE=development

##################################################################
# VISUAL CUSTOMIZATION - Replace branding assets
##################################################################
COPY --chown=grafana:root ./img/favicon.png /usr/share/grafana/public/img/fav32.png
COPY --chown=grafana:root ./img/favicon.png /usr/share/grafana/public/img/apple-touch-icon.png
COPY --chown=grafana:root ./img/logo.svg /usr/share/grafana/public/img/grafana_icon.svg

#####
RUN grafana cli --pluginUrl "https://github.com/mahendrapaipuri/grafana-dashboard-reporter-app/releases/download/v1.7.1/mahendrapaipuri-dashboardreporter-app-1.7.1.zip" plugins install mahendrapaipuri-dashboardreporter-app

##################################################################
# HTML & JS CUSTOMIZATION - Update titles, menus, and branding
##################################################################
# Update title and loading text in index.html
RUN sed -i 's|<title>\[\[.AppTitle\]\]</title>|<title>Business Suite</title>|g' /usr/share/grafana/public/views/index.html && \
    sed -i 's|Loading Grafana|Loading Business Suite|g' /usr/share/grafana/public/views/index.html

# Customize Mega and Help menu in index.html
RUN sed -i "s|\[\[.NavTree\]\],|nav,|g; \
    s|window.grafanaBootData = {| \
    let nav = [[.NavTree]]; \
    const dashboards = nav.find((element) => element.id === 'dashboards/browse'); \
    if (dashboards) { dashboards['children'] = [];} \
    const connections = nav.find((element) => element.id === 'connections'); \
    if (connections) { connections['url'] = '/datasources'; connections['children'].shift(); } \
    const help = nav.find((element) => element.id === 'help'); \
    if (help) { help['subTitle'] = 'Business Customization 12.0.1'; help['children'] = [];} \
    window.grafanaBootData = {|g" \
    /usr/share/grafana/public/views/index.html && \
    sed -i "s|window.grafanaBootData = {| \
    nav.splice(3, 1); \
    window.grafanaBootData = {|g" \
    /usr/share/grafana/public/views/index.html

# Update JavaScript files for branding and feature toggles
RUN find /usr/share/grafana/public/build/ -name "*.js" -type f \
    -exec sed -i 's|AppTitle="Grafana"|AppTitle="xxxx Sentry"|g' {} \; \
    -exec sed -i 's|LoginTitle="Welcome to Grafana"|LoginTitle="Welcome to xxxx Sentry System"|g' {} \; \
    -exec sed -i 's|\[{target:"_blank",id:"documentation".*grafana_footer"}\]|\[\]|g' {} \; \
    -exec sed -i 's|({target:"_blank",id:"license",.*licenseUrl})|()|g' {} \; \
    -exec sed -i 's|({target:"_blank",id:"version",text:..versionString,url:.?"https://github.com/grafana/grafana/blob/main/CHANGELOG.md":void 0})|()|g' {} \; \
    -exec sed -i 's|(0,t.jsx)(d.I,{tooltip:(0,b.t)("dashboard.toolbar.switch-old-dashboard","Switch to old dashboard page"),icon:"apps",onClick:()=>{s.Ny.partial({scenes:!1})}},"view-in-old-dashboard-button")|null|g' {} \; \
    -exec sed -i 's|.push({target:"_blank",id:"version",text:`${..edition}${.}`,url:..licenseUrl,icon:"external-link-alt"})||g' {} \;

# Update feature toggles in configuration
RUN sed -i 's|\[feature_toggles\]|\[feature_toggles\]\npinNavItems = false\nonPremToCloudMigrations = false\ncorrelations = false|g' /usr/share/grafana/conf/defaults.ini

##################################################################
# CLEANUP - Remove unused data sources and panels
##################################################################
# Remove native data sources
RUN rm -rf \
    /usr/share/grafana/public/app/plugins/datasource/azuremonitor \
    /usr/share/grafana/public/build/azureMonitor* \
    /usr/share/grafana/public/app/plugins/datasource/cloudwatch \
    /usr/share/grafana/public/build/cloudwatch* \
    /usr/share/grafana/public/app/plugins/datasource/cloud-monitoring \
    /usr/share/grafana/public/build/cloudMonitoring*

# Remove Cloud and Enterprise categories from JS files
RUN find /usr/share/grafana/public/build/ -name "*.js" -type f \
    -exec sed -i 's|.id==="enterprise"|.id==="notanenterprise"|g' {} \; \
    -exec sed -i 's|.id==="cloud"|.id==="notacloud"|g' {} \;

# Remove native panels
RUN rm -rf \
    /usr/share/grafana/public/app/plugins/panel/alertlist \
    /usr/share/grafana/public/app/plugins/panel/annolist \
    /usr/share/grafana/public/app/plugins/panel/dashlist \
    /usr/share/grafana/public/app/plugins/panel/news \
    /usr/share/grafana/public/app/plugins/panel/geomap \
    /usr/share/grafana/public/app/plugins/panel/table-old \
    /usr/share/grafana/public/app/plugins/panel/traces \
    /usr/share/grafana/public/app/plugins/panel/flamegraph

# Install chromium
RUN apk add chromium

RUN if [ "${development}" = "true" ]; then \
    if grep -i -q alpine /etc/issue; then \
        apk add supervisor inotify-tools git; \
    elif grep -i -q ubuntu /etc/issue; then \
      DEBIAN_FRONTEND=noninteractive && \
      apt-get update && \
      apt-get install -y supervisor inotify-tools git && \
      rm -rf /var/lib/apt/lists/*; \
    else \
      echo 'ERROR: Unsupported base image' && /bin/false; \
    fi \
    fi

COPY supervisord/supervisord.conf /etc/supervisor.d/supervisord.ini
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN if [ "${development}" = "true" ]; then \
    curl -O -L https://golang.org/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz && \
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bashrc && \
    rm -f go${GO_VERSION}.linux-${GO_ARCH}.tar.gz; \
    fi

# Installing delve for debugging
RUN if [ "${development}" = "true" ]; then \
    /usr/local/go/bin/go install github.com/go-delve/delve/cmd/dlv@latest; \
    fi

# Installing mage for plugin (re)building
RUN if [ "${development}" = "true" ]; then \
    git clone https://github.com/magefile/mage; \
    cd mage; \
    export PATH=$PATH:/usr/local/go/bin; \
    go run bootstrap.go; \
    fi

# Inject livereload script into grafana index.html
RUN sed -i 's/<\/body><\/html>/<script src=\"http:\/\/localhost:35729\/livereload.js\"><\/script><\/body><\/html>/g' /usr/share/grafana/public/views/index.html


##################################################################
# FINALIZE - Switch back to non-root user for security
##################################################################

# Expose Grafana default port
EXPOSE 3000

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

USER grafana
# Healthcheck to ensure Grafana is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/health
