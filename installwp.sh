#!/bin/bash

# XAMPP paths
HTDOCS="/c/xampp/htdocs"
MYSQL="/c/xampp/mysql/bin/mysql"
DBUSER="root"
DBPASS=""   # leave blank if root has no password

# WordPress credentials
WPUSER="admin"
WPPASS="admin"
WPEMAIL="test@mail.com"

# ---------------------
# Plugins Section (Ask First)
# ---------------------
PLUGINS=(
  "WooCommerce|woocommerce"
  "UpdraftPlus|updraftplus"
  "Blocksy Companion|blocksy-companion"
  "Admin Site Enhancements|admin-site-enhancements"
  "Advanced Custom Fields|advanced-custom-fields"
  "JSM Show Post Metadata|jsm-show-post-meta"
)

echo "Select plugins to install (separate multiple choices with spaces):"
echo "-1) All plugins"

for i in "${!PLUGINS[@]}"; do
    IFS="|" read -r PLUGIN_NAME PLUGIN_SLUG <<< "${PLUGINS[$i]}"
    echo "$((i+1))) $PLUGIN_NAME"
done

read -p "Enter numbers: " choices

if [[ " $choices " == *" -1 "* ]]; then
    selected_indexes=("${!PLUGINS[@]}")
else
    selected_indexes=()
    for choice in $choices; do
        selected_indexes+=($((choice-1)))
    done
fi

# ---------------------
# Ask Site Name & Install WordPress
# ---------------------
while true; do
    read -p "Enter your site name: " SITENAME

    SITEPATH="$HTDOCS/$SITENAME"
    DBNAME="${SITENAME//[- ]/_}"  # replace spaces/dashes with underscores

    # Check folder existence
    if [ -d "$SITEPATH" ]; then
        echo "❌ Folder '$SITEPATH' already exists. Try another name."
        continue
    fi

    # Check database existence
    if [ -z "$DBPASS" ]; then
        DBEXISTS=$($MYSQL -u$DBUSER -N -B -e "SHOW DATABASES LIKE '$DBNAME';")
    else
        DBEXISTS=$($MYSQL -u$DBUSER -p$DBPASS -N -B -e "SHOW DATABASES LIKE '$DBNAME';")
    fi

    if [ "$DBEXISTS" == "$DBNAME" ]; then
        echo "❌ Database '$DBNAME' already exists. Try another name."
        continue
    fi

    break
done

# Download WordPress
cd $HTDOCS
echo "⬇ Downloading WordPress..."
curl -L https://wordpress.org/latest.zip -o wordpress.zip
unzip wordpress.zip
rm wordpress.zip
mv wordpress "$SITENAME"

cd "$SITEPATH"

# Create database
if [ -z "$DBPASS" ]; then
    $MYSQL -u$DBUSER -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
else
    $MYSQL -u$DBUSER -p$DBPASS -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

# Setup wp-config
cp wp-config-sample.php wp-config.php
sed -i.bak "s/database_name_here/$DBNAME/" wp-config.php
sed -i.bak "s/username_here/$DBUSER/" wp-config.php
sed -i.bak "s/password_here/$DBPASS/" wp-config.php

# WP-CLI
if [ ! -f wp-cli.phar ]; then
    echo "⬇ Downloading WP-CLI..."
    curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o wp-cli.phar
fi

php wp-cli.phar core install \
  --url="http://localhost/$SITENAME" \
  --title="$SITENAME" \
  --admin_user="$WPUSER" \
  --admin_password="$WPPASS" \
  --admin_email="$WPEMAIL"

echo "✅ WordPress installed successfully!"
echo "👉 URL: http://localhost/$SITENAME"
echo "👉 Username: $WPUSER"
echo "👉 Password: $WPPASS"

# ---------------------
# Install Selected Plugins
# ---------------------
PLUGIN_DIR="$SITEPATH/wp-content/plugins"

for index in "${selected_indexes[@]}"; do
    IFS="|" read -r PLUGIN_NAME PLUGIN_SLUG <<< "${PLUGINS[$index]}"
    PLUGIN_PATH="$PLUGIN_DIR/$PLUGIN_SLUG"

    if [ -d "$PLUGIN_PATH" ]; then
        echo "$PLUGIN_NAME already exists. Skipping..."
        continue
    fi

    echo "⬇ Installing $PLUGIN_NAME..."
    PLUGIN_URL="https://downloads.wordpress.org/plugin/$PLUGIN_SLUG.latest-stable.zip"
    curl -L -o "$PLUGIN_DIR/$PLUGIN_SLUG.zip" "$PLUGIN_URL"

    if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$PLUGIN_DIR/$PLUGIN_SLUG.zip" -d "$PLUGIN_DIR"
    else
        powershell.exe -Command "Expand-Archive -Path '$PLUGIN_DIR/$PLUGIN_SLUG.zip' -DestinationPath '$PLUGIN_DIR' -Force"
    fi

    rm "$PLUGIN_DIR/$PLUGIN_SLUG.zip"
    echo "✅ $PLUGIN_NAME installed."

    # Activate plugin
    php wp-cli.phar plugin activate "$PLUGIN_SLUG"
done

# ---------------------
# Delete Default Plugins
# ---------------------
DEFAULT_PLUGINS=("hello.php" "akismet")
for PLUGIN in "${DEFAULT_PLUGINS[@]}"; do
    if [ -d "$PLUGIN_DIR/$PLUGIN" ] || [ -f "$PLUGIN_DIR/$PLUGIN" ]; then
        php wp-cli.phar plugin deactivate "$PLUGIN" 2>/dev/null
        php wp-cli.phar plugin delete "$PLUGIN" 2>/dev/null
        echo "🗑 Deleted default plugin $PLUGIN"
    fi
done

# ---------------------
# Install Blocksy Theme & Activate
# ---------------------
THEMES_DIR="$SITEPATH/wp-content/themes"
THEME_NAME="Blocksy"
THEME_SLUG="blocksy"

if [ -d "$THEMES_DIR/$THEME_SLUG" ]; then
    echo "$THEME_NAME already exists. Skipping..."
else
    echo "⬇ Installing Blocksy theme..."
    THEME_URL="https://downloads.wordpress.org/theme/$THEME_SLUG.latest-stable.zip"
    curl -L -o "$THEMES_DIR/$THEME_SLUG.zip" "$THEME_URL"

    if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$THEMES_DIR/$THEME_SLUG.zip" -d "$THEMES_DIR"
    else
        powershell.exe -Command "Expand-Archive -Path '$THEMES_DIR/$THEME_SLUG.zip' -DestinationPath '$THEMES_DIR' -Force"
    fi

    rm "$THEMES_DIR/$THEME_SLUG.zip"
    echo "✅ Blocksy theme installed."
fi

# Activate theme
php wp-cli.phar theme activate "$THEME_SLUG"

# ---------------------
# Delete default WordPress themes (2023, 2024, 2025)
# ---------------------
DEFAULT_THEMES=("twentytwentythree" "twentytwentyfour" "twentytwentyfive")
for THEME in "${DEFAULT_THEMES[@]}"; do
    THEME_PATH="$THEMES_DIR/$THEME"
    if [ -d "$THEME_PATH" ]; then
        php wp-cli.phar theme delete "$THEME" 2>/dev/null
        echo "🗑 Deleted default theme $THEME"
    fi
done


# ---------------------
# Open wp-admin & plugin folder
# ---------------------
echo "🎉 Opening wp-admin and plugin folder..."
start "http://localhost/$SITENAME/wp-admin"
code "$SITEPATH"

echo "The window will close in 10 seconds..."
sleep 10
