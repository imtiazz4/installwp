# WordPress Auto Installer Script for XAMPP (Windows)

Automate WordPress setup on XAMPP using Git Bash. This script downloads WordPress, creates a database, installs selected plugins, installs and activates the Blocksy theme, deletes default plugins and themes, and opens `wp-admin` and the plugin folder in VS Code.

---

## Features

- Interactive site name and database creation  
- Automatic WordPress download and installation  
- WP-CLI included for plugin and theme management  
- Install selected plugins from a pre-defined list  
- Automatically activate plugins and Blocksy theme  
- Delete default WordPress plugins and themes  
- Open the site `wp-admin` page and plugin folder in VS Code  

---

## Requirements

- Windows  
- [XAMPP](https://www.apachefriends.org/index.html) installed  
- Git Bash  
- PHP installed and accessible in your PATH (comes with XAMPP)  
- [VS Code](https://code.visualstudio.com/) installed for opening plugin folder  

---

## Predefined Plugins

| Plugin Name | Slug |
|-------------|------|
| WooCommerce | woocommerce |
| UpdraftPlus | updraftplus |
| Blocksy Companion | blocksy-companion |
| Admin Site Enhancements | admin-site-enhancements |
| Advanced Custom Fields | advanced-custom-fields |
| JSM Show Post Metadata | jsm-show-post-meta |

You can choose which plugins to install during the script execution.  

---

## How to Use

1. **Open Git Bash** and navigate to the folder containing the script.  
2. **Run the script**:

```bash
bash wordpress-auto-install.sh
